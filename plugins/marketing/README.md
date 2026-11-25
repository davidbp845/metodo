# Plugin `marketing`

Revisión de campañas de pago y del tráfico que traen. Los skills son los mismos para todos los proyectos; lo que cambia entre proyectos lo leen de la sección `## Marketing` del `CLAUDE.md` del proyecto.

Se instala con `/plugin install marketing --marketplace davidbp845/metodo`.

| Skill | Qué hace |
|---|---|
| `/marketing:revisar-ads` | Ordena y convierte las exportaciones de Google Ads y Search Console, dice cuáles faltan, las cruza con la analítica web, da el informe y lo guarda; con `verificar`, comprueba un cambio aplicado en Ads contra lo propuesto |

## Scripts

| Script | Qué hace |
|---|---|
| `scripts/umami-visitas.py` | Lista las visitas de Umami una a una (origen, `utm_term`, ciudad, páginas, eventos) y, con `--pagina` y `--profundidad`, cuenta hasta dónde baja cada una en la landing, por origen. Solo lectura y solo biblioteca estándar; `--help` da las opciones |

## Carpeta de datos

Las exportaciones y los informes llevan cifras de gasto y datos de visitas, así que no van a ningún repo: la Carpeta está en el `.gitignore` del proyecto y entra en las copias de seguridad de la máquina.

```
<Carpeta>/
├── checklist-descargas.md           # opcional: qué bajar y dónde, con los datos del proyecto
├── datos/AAAA-MM-DD/                # exportaciones de Ads del rango completo, del día en que se bajaron
│   ├── desde-cambio/                # las de Ads desde el último cambio aplicado
│   └── search-console/
└── informes/AAAA-MM-DD-revision-ads.md
```

## Sección `## Marketing` del proyecto

El skill la lee al empezar. Si falta la Carpeta, lo dice y para.

```markdown
## Marketing

- Carpeta: `ads/` (ignorada por git)
- Campaña: «Búsqueda · Nombre» (ID `NNNN`), desde AAAA-MM-DD
- Analítica: Umami en `https://stats.ejemplo.org`, website `<id>`, equipo `<id>`; usuario de solo lectura `lector`, contraseña en `~/.umami-lector/clave.txt`
- Eventos: conversión `reserva-creada`; embudo `chat-abierto`, `chat-primer-mensaje`
- Landing: `/masaje-ciudad/`; profundidad `landing-precios`, `landing-resenas`, `landing-final`
- Medición de conversiones: `doc/A2-ADR/NNNN-medicion.md`
- Exclusiones:
  - Firefox de Android en Ciudad: el móvil del dueño
```

| Campo | Obligatorio | Uso |
|---|---|---|
| Carpeta | Sí | Dónde viven `datos/` e `informes/`, relativa a la raíz del proyecto |
| Campaña | No | Nombre, ID y fecha de inicio: el rango «desde el inicio» de las exportaciones |
| Analítica | No | Herramienta, URL, identificadores y dónde está la credencial (nunca la credencial). Sin él, el skill no cruza los clics con visitas y lo dice |
| Eventos | No | Evento de conversión y eventos previos del embudo |
| Landing | No | Ruta de la página de destino de los anuncios y, si la web los envía, los eventos que marcan hasta dónde baja la visita, de arriba abajo. Sin él, el skill no mide la profundidad |
| Medición de conversiones | No | Documento que decide cómo se miden las conversiones. Con él, el skill no recomienda una etiqueta de conversiones que ese documento descarta |
| Exclusiones | No | Visitas que no son clientes (dispositivos propios, robots conocidos), cada una con cómo reconocerla |
