#!/usr/bin/env python3
"""Comprueba las cuentas de prospección y genera el HTML y el CSV junto al JSON.

Uso:
    python3 exportar.py cuentas.json [--salida DIR] [--hoy AAAA-MM-DD] [--meses 6]
                        [--solo-comprobar] [--entrada DIR]

Sin --salida, prospeccion.html y prospeccion.csv quedan en la carpeta de cuentas.json.
Con --entrada, copia además cuentas.json a esa carpeta (la de entrada del CRM) como
prospeccion-AAAA-MM-DD.json, sin pisar ningún fichero.

Formato de cuentas.json (empresa y negocio inventados):
{
  "negocio": {"nombre": "Clima Ejemplo", "zona": "Ciudad"},
  "comprobar_a_mano": ["Qué no se ha podido abrir y por qué", ...],
  "cuentas": [
    {
      "empresa": "Nombre", "web": "https://...", "zona": "Ciudad",
      "prioridad": "A",                        # A, B o C
      "senal": "Abre una clínica nueva en el centro",
      "url_senal": "https://...", "fecha_senal": "2026-08-27",   # AAAA-MM-DD
      "estado": "Confirmado",                  # Confirmado o Hipótesis
      "que_hace": "Una frase",
      "problema": "¿...?",
      "quien_decide": "Cargo (nombre solo si la empresa lo publica)",
      "canal": "Formulario de contacto de su web",
      "asunto": "Asunto (si es correo)",
      "mensaje": "Primer mensaje",
      "seguimientos": ["Día 3 ...", "Día 7 ..."]   # opcional
    }
  ]
}

Errores (salida 1, no genera nada): faltan campos, URL no válida, fecha sin formato,
futura o fuera de la ventana, prioridad o estado que no existen, mensaje fuera de 50-125
palabras, empresas repetidas.
Avisos (genera igualmente): problema que no es pregunta, asunto de más de 6 palabras,
correo que parece personal, número de cuentas distinto de 10, señales en Hipótesis.
"""

import argparse
import csv
import datetime as dt
import html
import json
import re
import shutil
import sys
from pathlib import Path

COLUMNAS = ["Empresa", "Web", "Zona", "Prioridad", "Primer contacto", "Señal", "URL de la señal",
            "Fecha de la señal", "Problema", "Quién decide", "Canal", "Asunto", "Primer mensaje"]
OBLIGATORIOS = ["empresa", "prioridad", "senal", "url_senal", "fecha_senal", "estado", "problema",
                "quien_decide", "canal", "mensaje"]
# Días laborables hasta el primer contacto, por prioridad.
DIAS_CONTACTO = {"A": 1, "B": 3, "C": 7}
GENERICOS = {"info", "hola", "contacte", "contacto", "contact", "hello", "admin", "administracio",
             "administracion", "comercial", "vendes", "ventas", "sales", "office", "oficina", "recepcio",
             "recepcion", "atencio", "atencion", "clients", "clientes", "general", "marketing", "rrhh", "rh",
             "feina", "empleo", "jobs", "premsa", "prensa", "press", "suport", "soporte", "support", "cites",
             "citas", "reserves", "reservas"}


def palabras(txt):
    return len(re.findall(r"\b[\wÀ-ÿ'’·-]+\b", txt or ""))


def mas_laborables(desde, dias):
    fecha = desde
    while dias:
        fecha += dt.timedelta(days=1)
        if fecha.weekday() < 5:
            dias -= 1
    return fecha


def primer_contacto(cuenta, hoy):
    dias = DIAS_CONTACTO.get(cuenta.get("prioridad"))
    return mas_laborables(hoy, dias).isoformat() if dias else ""


def comprobar(datos, hoy, meses):
    errores, avisos = [], []
    cuentas = datos.get("cuentas") or []
    if not cuentas:
        errores.append("No hay cuentas.")
    if cuentas and len(cuentas) != 10:
        avisos.append(f"Hay {len(cuentas)} cuentas (el método trabaja con 10).")
    limite = hoy - dt.timedelta(days=round(meses * 30.44))
    vistas = set()
    for i, c in enumerate(cuentas, 1):
        n = c.get("empresa") or f"cuenta {i}"
        for campo in OBLIGATORIOS:
            if not str(c.get(campo, "")).strip():
                errores.append(f"{n}: falta «{campo}».")
        clave = n.strip().lower()
        if clave in vistas:
            errores.append(f"{n}: empresa repetida.")
        vistas.add(clave)
        for campo in ("url_senal", "web"):
            v = str(c.get(campo, "")).strip()
            if v and not re.match(r"^https?://[^\s/]+\.[^\s]+", v):
                errores.append(f"{n}: «{campo}» no es una URL válida ({v}).")
        f = str(c.get("fecha_senal", "")).strip()
        if f:
            try:
                fd = dt.date.fromisoformat(f)
                if fd > hoy:
                    errores.append(f"{n}: la fecha de la señal ({f}) es futura.")
                elif fd < limite:
                    errores.append(f"{n}: la señal ({f}) es de hace más de {meses:g} meses: no es motivo para escribir hoy.")
            except ValueError:
                errores.append(f"{n}: la fecha de la señal debe ser AAAA-MM-DD ({f}).")
        if c.get("prioridad") and c["prioridad"] not in DIAS_CONTACTO:
            errores.append(f"{n}: prioridad «{c['prioridad']}» (debe ser A, B o C).")
        if c.get("estado") and c["estado"] not in ("Confirmado", "Hipótesis"):
            errores.append(f"{n}: estado «{c['estado']}» (debe ser Confirmado o Hipótesis).")
        if c.get("estado") == "Hipótesis":
            avisos.append(f"{n}: la señal es una Hipótesis; dilo y valora pasarla a «Comprobar a mano».")
        np_ = palabras(c.get("mensaje"))
        if c.get("mensaje") and not 50 <= np_ <= 125:
            errores.append(f"{n}: el mensaje tiene {np_} palabras (debe tener entre 50 y 125).")
        if c.get("problema") and "?" not in c["problema"]:
            avisos.append(f"{n}: el problema no está escrito como pregunta.")
        if c.get("asunto") and palabras(c["asunto"]) > 6:
            avisos.append(f"{n}: el asunto tiene más de 6 palabras.")
        for campo in ("canal", "mensaje", "quien_decide"):
            for correo in re.findall(r"[\w.+-]+@[\w-]+\.[\w.-]+", str(c.get(campo, ""))):
                if correo.split("@")[0].lower() not in GENERICOS:
                    avisos.append(f"{n}: «{correo}» parece un correo personal. Solo vale si la empresa lo publica en su web; nunca deducido.")
        for s in c.get("seguimientos") or []:
            if palabras(s) > 90:
                avisos.append(f"{n}: un seguimiento tiene {palabras(s)} palabras (mejor por debajo de 70).")
    return errores, avisos


def escribir_csv(datos, ruta, hoy):
    with open(ruta, "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh, quoting=csv.QUOTE_MINIMAL)
        w.writerow(COLUMNAS)
        for c in datos["cuentas"]:
            w.writerow([c.get("empresa", ""), c.get("web", ""), c.get("zona", ""), c.get("prioridad", ""),
                        primer_contacto(c, hoy), c.get("senal", ""), c.get("url_senal", ""),
                        c.get("fecha_senal", ""), c.get("problema", ""), c.get("quien_decide", ""),
                        c.get("canal", ""), c.get("asunto", ""), c.get("mensaje", "")])


# Escala fluida entre 320 px (20rem) y el ancho del contenido (62.5rem).
ESTILO = """
:root{
  --step--1:clamp(0.8rem,0.7647rem + 0.1765vw,0.875rem);
  --step-0:clamp(1rem,0.9706rem + 0.1471vw,1.0625rem);
  --step-1:clamp(1.125rem,1.0662rem + 0.2941vw,1.25rem);
  --step-2:clamp(1.35rem,1.1618rem + 0.9412vw,1.75rem);
  --space-3xs:clamp(0.25rem,0.2353rem + 0.0735vw,0.3125rem);
  --space-2xs:clamp(0.5rem,0.4706rem + 0.1471vw,0.5625rem);
  --space-s:clamp(0.75rem,0.6324rem + 0.5882vw,1rem);
  --space-m:clamp(1rem,0.8824rem + 0.5882vw,1.25rem);
  --space-l:clamp(1.5rem,1.2647rem + 1.1765vw,2rem);
  --space-s-l:clamp(0.75rem,0.1618rem + 2.9412vw,2rem);
  --tinta:#14142b;--suave:#5b5b75;--linea:#e4e4f0;--fondo:#f6f6fb;--tarjeta:#fff;--acento:#1400ff;
  --a:#16a34a;--b:#d97706;--c:#6b7280
}
*{box-sizing:border-box}
body{margin:0;font-family:system-ui,-apple-system,"Segoe UI",sans-serif;font-size:var(--step-0);
  background:var(--fondo);color:var(--tinta);line-height:1.5}
.contenedor{width:min(100% - 2 * var(--space-m),62.5rem);margin-inline:auto;padding-block:var(--space-l) var(--space-s-l)}
h1{margin:0 0 var(--space-3xs);font-size:var(--step-2)}
.sub{color:var(--suave);margin:0 0 var(--space-m)}
.cifras{display:flex;gap:var(--space-s);flex-wrap:wrap;margin-bottom:var(--space-l)}
.cifra{background:var(--tarjeta);border:1px solid var(--linea);border-radius:12px;padding:var(--space-2xs) var(--space-m)}
.cifra b{font-size:var(--step-2);display:block}
.ficha{background:var(--tarjeta);border:1px solid var(--linea);border-radius:14px;padding:var(--space-m);margin-bottom:var(--space-m)}
.ficha header{display:flex;align-items:center;gap:var(--space-2xs);flex-wrap:wrap}
.ficha h2{margin:0;font-size:var(--step-1)}
.zona,.web{color:var(--suave);font-size:var(--step--1)}
.web{margin:var(--space-3xs) 0 var(--space-2xs);overflow-wrap:anywhere}
.prio{color:#fff;font-weight:700;border-radius:8px;padding:0 var(--space-2xs)}
.pA{background:var(--a)}.pB{background:var(--b)}.pC{background:var(--c)}
a{color:var(--acento)}
dl{display:grid;grid-template-columns:1fr;gap:var(--space-3xs) var(--space-s);margin:0 0 var(--space-s)}
dt{color:var(--suave)}dd{margin:0 0 var(--space-2xs);overflow-wrap:anywhere}
.estado{font-size:var(--step--1);border:1px solid var(--linea);border-radius:10px;padding:0 var(--space-2xs);color:var(--suave)}
.msg{border:1px solid var(--linea);border-radius:10px;margin-top:var(--space-2xs);overflow:hidden}
.msg.principal{border-color:var(--acento)}
.msg-cab{display:flex;justify-content:space-between;align-items:center;gap:var(--space-2xs);background:var(--fondo);
  padding:var(--space-3xs) var(--space-s);font-size:var(--step--1);font-weight:600}
.msg p{margin:0;padding:var(--space-2xs) var(--space-s);white-space:pre-wrap}
button{border:0;background:var(--acento);color:#fff;border-radius:8px;padding:var(--space-3xs) var(--space-s);
  cursor:pointer;font-weight:600;font-size:var(--step--1)}
.a-mano{background:var(--tarjeta);border:1px dashed var(--linea);border-radius:14px;padding:var(--space-s) var(--space-m)}
@media (min-width:40em){dl{grid-template-columns:minmax(6rem,8rem) 1fr}dd{margin:0}}
"""

COPIAR = """
function copiar(id,b){const t=document.getElementById(id).innerText;const ok=()=>{const o=b.textContent;b.textContent='Copiado';setTimeout(()=>b.textContent=o,1500)};
if(navigator.clipboard&&navigator.clipboard.writeText){navigator.clipboard.writeText(t).then(ok).catch(()=>alternativa(t,ok))}else{alternativa(t,ok)}}
function alternativa(t,ok){const a=document.createElement('textarea');a.value=t;document.body.appendChild(a);a.select();try{document.execCommand('copy');ok()}catch(e){}a.remove()}
"""


def escribir_html(datos, ruta, hoy):
    e = lambda s: html.escape(str(s or ""))  # noqa: E731
    neg = datos.get("negocio", {})
    orden = "ABC"
    cuentas = sorted(datos["cuentas"], key=lambda c: orden.index(c["prioridad"]) if c.get("prioridad") in DIAS_CONTACTO else 3)
    total = {p: sum(1 for c in cuentas if c.get("prioridad") == p) for p in orden}
    fichas = []
    for i, c in enumerate(cuentas):
        segs = "".join(
            f'<div class="msg"><div class="msg-cab"><span>Seguimiento {k + 1}</span>'
            f'<button onclick="copiar(\'s{i}_{k}\', this)">Copiar</button></div><p id="s{i}_{k}">{e(s)}</p></div>'
            for k, s in enumerate(c.get("seguimientos") or []))
        web = f'<a href="{e(c.get("web"))}" target="_blank" rel="noopener">{e(c.get("web"))}</a>' if c.get("web") else ""
        texto = (f"Asunto: {c['asunto']}\n\n" if c.get("asunto") else "") + str(c.get("mensaje", ""))
        asunto = f" · {e(c.get('asunto'))}" if c.get("asunto") else ""
        fichas.append(f'''
<article class="ficha">
  <header><span class="prio p{e(c.get('prioridad'))}">{e(c.get('prioridad'))}</span><h2>{e(c.get('empresa'))}</h2><span class="zona">{e(c.get('zona'))}</span></header>
  <p class="web">{web}</p>
  <dl>
    <dt>Qué hace</dt><dd>{e(c.get('que_hace')) or '—'}</dd>
    <dt>Señal</dt><dd>{e(c.get('senal'))} · <a href="{e(c.get('url_senal'))}" target="_blank" rel="noopener">fuente</a> · {e(c.get('fecha_senal'))} <span class="estado">{e(c.get('estado'))}</span></dd>
    <dt>Problema</dt><dd>{e(c.get('problema'))}</dd>
    <dt>Quién decide</dt><dd>{e(c.get('quien_decide'))}</dd>
    <dt>Canal</dt><dd>{e(c.get('canal'))}</dd>
    <dt>Primer contacto</dt><dd>{e(primer_contacto(c, hoy))}</dd>
  </dl>
  <div class="msg principal"><div class="msg-cab"><span>Primer mensaje{asunto}</span><button onclick="copiar('m{i}', this)">Copiar</button></div><p id="m{i}">{e(texto)}</p></div>
  {segs}
</article>''')
    a_mano = "".join(f"<li>{e(x)}</li>" for x in datos.get("comprobar_a_mano") or []) or "<li>Nada pendiente.</li>"
    cifras = "".join(f'<div class="cifra"><b>{total[p]}</b>Prioridad {p}</div>' for p in orden)
    doc = f'''<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Prospección · {e(neg.get('nombre'))}</title>
<style>{ESTILO}</style></head><body><main class="contenedor">
<h1>Prospección · {e(neg.get('nombre'))}</h1>
<p class="sub">{e(neg.get('zona'))} · {len(cuentas)} cuentas · generado el {hoy.isoformat()} · no se ha enviado nada</p>
<div class="cifras">{cifras}</div>
{''.join(fichas)}
<h2>Comprobar a mano</h2><div class="a-mano"><ul>{a_mano}</ul></div>
</main>
<script>{COPIAR}</script></body></html>'''
    Path(ruta).write_text(doc, encoding="utf-8")


def copiar_a_entrada(origen, entrada, hoy):
    entrada = Path(entrada)
    if not entrada.is_dir():
        sys.exit(f"ERROR: la carpeta de entrada no existe ({entrada}). No se ha copiado nada.")
    base, n = f"prospeccion-{hoy.isoformat()}", 1
    destino = entrada / f"{base}.json"
    while destino.exists():
        n += 1
        destino = entrada / f"{base}-{n}.json"
    shutil.copyfile(origen, destino)
    return destino


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("json")
    ap.add_argument("--salida", help="carpeta del HTML y el CSV (por defecto, la del JSON)")
    ap.add_argument("--hoy", help="AAAA-MM-DD (por defecto, hoy)")
    ap.add_argument("--meses", type=float, default=6)
    ap.add_argument("--solo-comprobar", action="store_true")
    ap.add_argument("--entrada", help="carpeta de entrada del CRM a la que se copia el JSON")
    a = ap.parse_args()
    hoy = dt.date.fromisoformat(a.hoy) if a.hoy else dt.date.today()
    ruta_json = Path(a.json)
    datos = json.loads(ruta_json.read_text(encoding="utf-8"))
    errores, avisos = comprobar(datos, hoy, a.meses)
    for x in avisos:
        print("AVISO:", x)
    if errores:
        for x in errores:
            print("ERROR:", x)
        print(f"\n{len(errores)} errores: corrígelos y vuelve a ejecutar. No se ha generado nada.")
        sys.exit(1)
    if a.solo_comprobar:
        print(f"OK: {len(datos['cuentas'])} cuentas sin errores ({len(avisos)} avisos).")
        return
    salida = Path(a.salida) if a.salida else ruta_json.parent
    salida.mkdir(parents=True, exist_ok=True)
    escribir_csv(datos, salida / "prospeccion.csv", hoy)
    escribir_html(datos, salida / "prospeccion.html", hoy)
    print(f"OK: {salida / 'prospeccion.html'} y {salida / 'prospeccion.csv'} ({len(datos['cuentas'])} cuentas, {len(avisos)} avisos).")
    if a.entrada:
        print(f"Copiado a la entrada del CRM: {copiar_a_entrada(ruta_json, a.entrada, hoy)}")


if __name__ == "__main__":
    main()
