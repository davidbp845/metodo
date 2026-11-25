#!/usr/bin/env python3
"""Visitas de Umami, una a una, y hasta dónde bajan en una landing.

Recorre /sessions y /sessions/<id>/activity: los filtros por parámetro de /stats y /metrics
(utm_medium, channel) se ignoran, así que es la única forma de separar las visitas de los
anuncios. Solo lectura. Usa solo la biblioteca estándar.

Una visita es un `visitId` de Umami (una sesión puede tener varias). Su origen sale de los
utm_* de la query (`cpc` = anuncios) o, sin ellos, del referrer.

Uso:
  umami-visitas.py --url https://stats.ejemplo.org --website <id> \
      --usuario lector --clave ~/.umami-lector/clave.txt --desde 2026-11-01 \
      [--hasta 2026-11-30] [--tz Europe/Madrid] [--solo-cpc] \
      [--pagina /landing/ --profundidad ev-1,ev-2,ev-3] \
      [--excluir browser=firefox,os=Android OS,city=Barcelona] [--excluir utm_source=instagram,city=Prineville]

Sin --pagina, lista las visitas. Con --pagina y --profundidad (eventos en el orden en que
aparecen al bajar), da además el recuento de hasta dónde llega cada visita a esa página, por
origen. Las visitas a la página anteriores al primer evento de profundidad registrado no
cuentan (la medición aún no existía): se toma el inicio de la primera visita con uno, salvo que --medicion-desde diga otra fecha.
"""

import argparse
import collections
import datetime as dt
import json
import os
import sys
import urllib.parse
import urllib.request
from zoneinfo import ZoneInfo


def argumentos():
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("--url", required=True, help="URL de Umami, sin /api")
    p.add_argument("--website", required=True)
    p.add_argument("--usuario", required=True)
    p.add_argument("--clave", required=True, help="fichero con la contraseña, una línea")
    p.add_argument("--desde", required=True, help="AAAA-MM-DD, hora local")
    p.add_argument("--hasta", help="AAAA-MM-DD incluido, hora local (por defecto, ahora)")
    p.add_argument("--tz", default="Europe/Madrid")
    p.add_argument("--solo-cpc", action="store_true", help="lista solo las visitas de anuncios")
    p.add_argument("--pagina", help="ruta de la landing, p. ej. /masaje-mataro/")
    p.add_argument("--profundidad", help="eventos de profundidad, separados por comas, de arriba abajo")
    p.add_argument("--medicion-desde", help="AAAA-MM-DD HH:MM local en que empezó la medición de profundidad")
    p.add_argument("--excluir", action="append", default=[],
                   help="campo=valor[,campo=valor...]: excluye la visita si cumple todos (city, browser, os, device, country, utm_source, referrer...)")
    p.add_argument("--json", action="store_true", help="vuelca las visitas en JSON en vez de tablas")
    return p.parse_args()


class Umami:
    def __init__(self, url, usuario, clave):
        self.base = url.rstrip("/") + "/api"
        with open(os.path.expanduser(clave)) as f:
            pw = f.read().strip()
        self.token = self._pedir("/auth/login", {"username": usuario, "password": pw})["token"]

    def _pedir(self, ruta, datos=None):
        cab = {"Content-Type": "application/json"}
        if getattr(self, "token", None):
            cab["Authorization"] = "Bearer " + self.token
        cuerpo = json.dumps(datos).encode() if datos else None
        with urllib.request.urlopen(urllib.request.Request(self.base + ruta, cuerpo, cab), timeout=60) as r:
            return json.load(r)

    def sesiones(self, web, ini, fin):
        q = f"startAt={ini}&endAt={fin}"
        todas, pag = [], 1
        while True:
            r = self._pedir(f"/websites/{web}/sessions?{q}&page={pag}&pageSize=200")
            todas += r["data"]
            if len(todas) >= r["count"] or not r["data"]:
                return todas
            pag += 1

    def actividad(self, web, sid, ini, fin):
        return self._pedir(f"/websites/{web}/sessions/{sid}/activity?startAt={ini}&endAt={fin}")


def ms(fecha):
    return int(fecha.timestamp() * 1000)


def utc(texto):
    return dt.datetime.fromisoformat(texto.replace("Z", "+00:00"))


def visitas(api, a, tz):
    ini = dt.datetime.fromisoformat(a.desde).replace(tzinfo=tz)
    fin = (dt.datetime.fromisoformat(a.hasta).replace(tzinfo=tz) + dt.timedelta(days=1)) if a.hasta else dt.datetime.now(tz)
    res = []
    for s in api.sesiones(a.website, ms(ini), ms(fin)):
        act = sorted(api.actividad(a.website, s["id"], ms(ini), ms(fin)), key=lambda x: x["createdAt"])
        por_visita = collections.defaultdict(list)
        for x in act:
            por_visita[x["visitId"]].append(x)
        for vid, filas in por_visita.items():
            utm = {}
            for x in filas:
                for k, v in urllib.parse.parse_qs(x.get("urlQuery") or "").items():
                    if k.startswith("utm_"):
                        utm.setdefault(k, v[0])
            ref = next((x["referrerDomain"] for x in filas if x.get("referrerDomain")), "")
            res.append({
                "inicio": utc(filas[0]["createdAt"]).astimezone(tz),
                "city": s.get("city") or "", "country": s.get("country") or "",
                "browser": s.get("browser") or "", "os": s.get("os") or "", "device": s.get("device") or "",
                "referrer": ref, **utm,
                "origen": origen(utm, ref),
                "paginas": [x["urlPath"] for x in filas if not x.get("eventName")],
                "eventos": [(x["eventName"], x["urlPath"], utc(x["createdAt"]).astimezone(tz)) for x in filas if x.get("eventName")],
            })
    return sorted(res, key=lambda v: v["inicio"])


def origen(utm, ref):
    if utm.get("utm_medium") == "cpc":
        return "anuncios"
    if utm.get("utm_source"):
        return f"{utm['utm_source']}/{utm.get('utm_medium', '')}".rstrip("/")
    return ref or "directo"


def excluida(v, reglas):
    for regla in reglas:
        pares = [p.split("=", 1) for p in regla.split(",") if "=" in p]
        if pares and all(str(v.get(k.strip(), "")).lower() == val.strip().lower() for k, val in pares):
            return regla
    return None


def pct(n, total):
    return f"{n} · {round(100 * n / total)} %" if total else "0"


def tabla(cab, filas):
    print("| " + " | ".join(cab) + " |")
    print("|" + "---|" * len(cab))
    for f in filas:
        print("| " + " | ".join(str(c) for c in f) + " |")
    print()


def listar(vs, solo_cpc):
    filas = []
    for v in vs:
        if solo_cpc and v["origen"] != "anuncios":
            continue
        filas.append((v["inicio"].strftime("%d/%m %H:%M"), v["origen"], v.get("utm_term", ""), v["city"],
                      f"{v['browser']} {v['os']}", v["referrer"], len(v["paginas"]),
                      ", ".join(e for e, _, _ in v["eventos"]) or "—"))
    print(f"## Visitas ({len(filas)})\n")
    tabla(["Inicio", "Origen", "utm_term", "Ciudad", "Navegador", "Referrer", "Págs", "Eventos"], filas)


def profundidad(vs, pagina, niveles, desde, tz):
    if desde is None:
        # El inicio de la visita, no la hora del evento: esa visita también cuenta.
        primeros = [v["inicio"] for v in vs if any(e in niveles for e, _, _ in v["eventos"])]
        if not primeros:
            print(f"## Profundidad en {pagina}\n\nNingún evento de profundidad ({', '.join(niveles)}) en el rango: la medición no existe o no ha saltado nunca.\n")
            return
        desde = min(primeros)
        aviso = f"desde la primera visita con un evento de profundidad ({desde:%d/%m %H:%M}); si la medición empezó antes, pásalo con --medicion-desde"
    else:
        aviso = f"desde {desde:%d/%m %H:%M}, inicio de la medición"
    en_pagina = [v for v in vs if pagina in v["paginas"] and v["inicio"] >= desde]
    grupos = collections.OrderedDict([("Total", en_pagina)])
    for v in en_pagina:
        grupos.setdefault(v["origen"], []).append(v)

    def nivel(v):
        vistos = {e for e, p, _ in v["eventos"] if p == pagina}
        return max((i + 1 for i, e in enumerate(niveles) if e in vistos), default=0)

    print(f"## Profundidad en {pagina}\n\n{len(en_pagina)} visitas, {aviso}.\n")
    cab = ["Llega a…"] + [f"{g} ({len(l)})" for g, l in grupos.items()]
    nombres = ["Entra en la página"] + niveles
    tabla(cab, [[nombres[i]] + [pct(sum(nivel(v) >= i for v in l), len(l)) for l in grupos.values()]
                for i in range(len(nombres))])
    cab = ["Se queda en…"] + cab[1:]
    nombres = ["Primera pantalla"] + niveles
    tabla(cab, [[nombres[i]] + [pct(sum(nivel(v) == i for v in l), len(l)) for l in grupos.values()]
                for i in range(len(nombres))])
    acciones = sorted({e for v in en_pagina for e, _, _ in v["eventos"] if e not in niveles})
    if acciones:
        tabla(["Además…"] + cab[1:], [[e] + [pct(sum(any(x == e for x, _, _ in v["eventos"]) for v in l), len(l))
                                             for l in grupos.values()] for e in acciones])


def main():
    a = argumentos()
    tz = ZoneInfo(a.tz)
    api = Umami(a.url, a.usuario, a.clave)
    vs = visitas(api, a, tz)
    fuera = collections.Counter()
    quedan = []
    for v in vs:
        r = excluida(v, a.excluir)
        if r:
            fuera[r] += 1
        else:
            quedan.append(v)
    if a.json:
        json.dump(quedan, sys.stdout, default=str, ensure_ascii=False, indent=1)
        return
    if fuera:
        print("Excluidas: " + "; ".join(f"{r} → {n}" for r, n in fuera.items()) + "\n")
    listar(quedan, a.solo_cpc)
    if a.pagina and a.profundidad:
        desde = dt.datetime.fromisoformat(a.medicion_desde).replace(tzinfo=tz) if a.medicion_desde else None
        profundidad(quedan, a.pagina, [e.strip() for e in a.profundidad.split(",")], desde, tz)


if __name__ == "__main__":
    main()
