# Guía de redacción

Se aplica a todo lo que se escribe en cualquier proyecto: documentación, issues, comentarios de código, commits, y respuestas en la conversación. Las reglas de un proyecto concreto pueden añadir, no contradecir.

## Idioma y tono

- En español, salvo que el proyecto diga otra cosa (identificadores de código incluidos si el proyecto ya los tiene en español).
- Directo: primero el resultado o la respuesta, después el detalle. Sin preámbulos sobre lo que se va a hacer ni narración de los pasos seguidos.
- Conciso sin simplificar: cada matiz que cambie el modelo mental del lector se queda; el relleno y los ejemplos forzados se quitan. Un ejemplo, si se pone, sale del comportamiento real, no de un caso hipotético llamativo.
- Al citar documentación o webs de herramientas Linux u open source (Termux, adb, paquetes), traducir la jerga del gremio («dotfiles», «batteries included», «readline»...) y explicar en una línea lo que da por sabido: se usa Linux a diario, pero sin la cultura de esa comunidad.
- Para validar un resumen del usuario: confirmar en una línea lo que está bien, añadir numerados solo los matices que lo corrigen (cada uno con su apoyo concreto) y cerrar con el resumen ya corregido.

## Documentos vivos

- Un documento vivo (metodología, visión, ficha, guía) describe el estado actual, en presente, como si siempre hubiera dicho eso. Nada de "decidido el día X, sustituye a...", ni de justificar dentro del texto por qué cambió: el historial es git.
- El porqué de una decisión solo se guarda en documentos que son en sí un registro de decisión (ADR: Contexto / Decisión / Alternativas / Consecuencias / Estado).
- Una sección que nace de una pregunta puntual se escribe como contenido autónomo, sin atribuir autoría ni fecha de la duda ("Duda puntual de David (fecha): ...").
- Al editar un documento, leerlo entero antes y seguir su estructura y estilo.
- Una página, un propósito: no mezclar en una guía de pasos la explicación de fondo; si hace falta, va en su propio apartado o documento y se enlaza.

## Resúmenes y simplificaciones

- Resumir o "pasar a lenguaje llano" un documento con listas conserva su esqueleto (mismos números, mismos apartados): solo cambia el contenido de cada punto. La prosa fluida, solo si el original ya era prosa o se pide un resumen narrativo.

## Formato markdown

- Un párrafo es una sola línea, sin cortes manuales a un ancho fijo: el ancho lo pone quien lo muestra (Obsidian, GitHub, el editor). Vale para cualquier `.md`. El formato de las bóvedas de Obsidian está en `estilo/obsidian/`.

## Issues

- Si ya existe un documento de análisis que cubre el tema, el cuerpo del issue es corto: situación en 1–2 frases, enlace al documento y plan en bullets. El detalle vive en el documento, no se duplica.
- Antes de crear un issue, mirar si la documentación del proyecto ya lo recoge (visión, ampliaciones futuras, ADR) para no duplicar una decisión.

## Comentarios de código

- Recogen el porqué actual, no la historia de cómo se llegó al valor (nada de "se probó 0.9, luego se bajó a 0.75"). Git y el hilo del issue son el changelog.
- Una referencia a un issue vale si nombra una restricción no obvia; antes de citarla, comprobar que el issue existe (`gh issue view`). Lo mismo para un `#NN` sacado de un comentario de código o de la memoria antes de repetirlo en un commit, un comentario de GitHub o una respuesta: el código puede citar issues que no existen o que hoy tratan de otra cosa.
- Misma densidad de comentarios, nombres e idioma que el código de alrededor.

## Commits

- Asunto `tipo(ámbito): resumen breve` (`feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`), y pie `Issue: #NN` cuando el trabajo sale de un issue.
- Un cambio pedido en la conversación sobre algo que salió de un issue (un retoque, un arreglo) lleva el pie de ese issue: el `git log` de los ficheros tocados lo dice. Si no sale de ninguno, se avisa antes del commit de que el hook pedirá confirmación.
- Antes de `git add`, `git status --short`: se añaden solo las rutas propias, por nombre. Una rama distinta de la esperada o cambios que la conversación no explica pueden ser de otra sesión en paralelo sobre el mismo checkout: se avisa y se pregunta, sin revertirlos, mezclarlos ni cambiar de rama. Un fichero sin seguimiento (`??`) que no ha creado Claude (exportaciones, notas, mockups, datos) no entra en el commit sin preguntar: puede no estar decidido o no deber salir del repo local.
