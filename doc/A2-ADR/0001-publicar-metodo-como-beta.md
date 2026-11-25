# 0001 — Publicar Metodo como beta en un repo público nuevo

## Contexto

`lanzadera` es público y su metodología remite al plugin `dev@metodo`, que vive en un repo privado: quien lee `lanzadera` no puede instalar el ciclo que describe. El repo actual no se puede abrir sin más, porque su historial contiene rutas de una máquina, nombres de proyectos privados y las retros agregadas con las cifras de cada proyecto.

El plan de publicación fijaba cinco criterios de madurez antes de publicar (estabilidad, sin regresiones, uso completo, adopción sin ayuda, reglas de texto cumplidas). No se cumplen todos, pero tener el ciclo legible e instalable compensa publicar antes, siempre que se marque como beta.

## Decisión

- Se publica como **beta**: el `README.md` lo dice, y esos criterios de madurez pasan a ser los de la primera versión estable.
- **Repo nuevo con un solo commit** y el actual renombrado y archivado, con el mismo patrón que la [ADR-0012 de lanzadera](https://github.com/davidbp845/lanzadera/blob/main/doc/A2-ADR/0012-lanzadera-sustituye-a-home.md). El repo nuevo conserva el nombre `metodo`, así que los workflows reutilizables que llaman otros repos (`<owner>/metodo/.github/workflows/verificacion.yml@main`) siguen funcionando.
- **Licencia MIT**, como `lanzadera`. `developing-with-streamlit` conserva su Apache 2.0 y su atribución. El plugin `comercial` atribuye la skill del taller de la que procede, cedida para usarla y modificarla.
- **Lo que es de una máquina o de una persona va en `local/`**, ignorada por git: las retros agregadas, la tabla de proyectos de la máquina, las bóvedas de Obsidian y las apps que la guía Streamlit pone de modelo. Los skills la leen si existe y, si no, usan valores genéricos. Las carpetas de proyectos de la configuración global salen de `metodo-maquina.json`, en el directorio de configuración de Claude Code, que ya guarda las reglas propias de cada máquina.
- El tablero sigue privado.

## Alternativas consideradas

- **Cambiar la visibilidad del repo actual.** Se descarta: el historial expone rutas, nombres de proyectos y cifras.
- **Esperar a los criterios de madurez.** Se descarta: el ciclo se usa a diario y lo que falta es estabilidad, no contenido. La etiqueta beta avisa de eso.
- **Mantener un repo privado de trabajo y uno público como espejo.** Se descarta: son dos repos que sincronizar a cada cambio, y las mejoras llegarían tarde al público.
- **Quitar del todo los datos de la máquina.** Se descarta: la tabla de proyectos y las apps modelo de la guía Streamlit le siguen sirviendo a quien trabaja en esa máquina.

## Consecuencias

- Cualquiera puede leer e instalar el método, y `lanzadera` ya no tiene que avisar de que el plugin es privado.
- Cada commit puede volver a meter una ruta o un nombre privado: hay que revisar lo que se sube, y conviene una comprobación automática.
- Las retros agregadas dejan de tener historial en git: viven en `local/retros/`.
- El historial anterior solo queda en el repo archivado, que sigue privado.
- Los issues abiertos se rehacen en el repo nuevo, revisando antes su texto.

## Estado

Aceptada.
