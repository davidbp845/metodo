---
name: prospectar
description: Prospección B2B del negocio de un proyecto cuyo CLAUDE.md tiene una sección `## Prospección`. Define el cliente ideal y las señales de compra, encuentra empresas reales con fuentes que se pueden abrir, las califica (A, B o C), escribe el primer contacto y los seguimientos, entrega un HTML y un CSV y deja las cuentas en el CRM de la sección; con `informe`, da el informe comercial del día. Solo en proyectos con `## Prospección`; fuera de ellos, no se usa.
argument-hint: "[paso 0–5 | todo | informe]"
---
Prospección comercial del negocio del proyecto: **encontrar → calificar → contactar → registrar → seguir**. Una cuenta encontrada que no acaba en el CRM con su siguiente paso y su fecha es una cuenta perdida; por eso el circuito termina en el CRM (o en un CSV que se importa en cualquiera). "$ARGUMENTS" dice qué paso hacer; `todo`, los seis en orden; `informe`, el informe comercial del día.

Lee antes la sección `## Prospección` del `CLAUDE.md` del proyecto (campos en el README del plugin). Si falta, o le falta el Negocio, la Zona o la Carpeta, dilo y para.

## Idioma

Las respuestas, las fichas, las tablas y el HTML, en castellano. Los mensajes a los clientes (primer contacto y seguimientos), en el Idioma de `## Prospección`; sin él, en castellano. Los nombres de las empresas, los cargos y los textos citados de una web se dejan como los publica la fuente.

## Principios

- **Nada inventado.** Ninguna cifra, cliente, caso, nombre ni dato de contacto que no salga de una fuente abierta en esta conversación, de `## Prospección` o de lo que diga el usuario. Lo que falta se marca `[FALTA]`. Un mensaje con un dato inventado rompe la confianza en el primer contacto, y no hay segunda oportunidad.
- **Cada empresa entra con una prueba que se puede abrir:** la señal, su URL y su fecha. Sin URL no hay señal; sin fecha no se sabe si es un motivo para escribir hoy.
- **Estado del dato:** `Confirmado` si se ha leído en la página; `Hipótesis` si se deduce. El problema del cliente siempre es una hipótesis y se escribe como pregunta.
- **Nunca se deducen correos ni teléfonos personales** (ni por el patrón nombre.apellido@ ni por ningún otro). Solo canales públicos: formulario, correo general de la web o teléfono de la web. Nombres de personas, solo si la propia empresa los publica en su web.
- **Nunca se envía nada.** Se dejan mensajes y borradores para que el usuario los revise y los envíe por su canal.
- **Lo que no se puede abrir** va a una lista «Comprobar a mano», en vez de suponerlo.

## Antes de empezar

Comprueba en una línea si tienes búsqueda web. Sin ella, dilo y no sigas con los pasos 1 a 3.

## Los seis pasos (0 a 5)

Haz el paso que se pida; si se piden varios, en orden. Al terminar un paso que necesita validación, para y pregunta, salvo en modo sin preguntas.

**Modo sin preguntas** (tareas programadas o si el usuario dice que no preguntes): no preguntes ni pidas validar nada. Decide con criterio, di en una línea qué has decidido y sigue. Lo que haga falta y no esté en `## Prospección` ni en el mensaje, márcalo `[FALTA]` y sigue.

Lo de cada tanda va en `<Carpeta>/AAAA-MM-DD/`, con la fecha de hoy.

### Paso 0 · El negocio

Parte del Negocio de `## Prospección`. Si da una web, lee como mucho tres páginas y escribe la **ficha del negocio**: qué vende, a quién, zona, pruebas que puede citar (clientes, casos, años) y tono. Lo que no salga de la web ni de la sección va como `[FALTA]`. Si la sección ya trae la ficha completa, úsala tal cual.

### Paso 1 · Cliente ideal, señales y filtro

Si `## Prospección` trae el Cliente ideal, es el punto de partida: complétalo, no lo rehagas.

- **Cliente ideal en 6 campos:** sector, tamaño, zona, quién decide (cargo), qué problema tiene y qué le hace comprar ahora. Si el negocio vende a particulares, el cliente ideal son las empresas que pueden recomendarlo o revenderlo (un fisioterapeuta: gimnasios y clubes deportivos).
- **6 señales de compra** que se vean en internet, cada una con dónde se ve. Mira `references/fuentes-y-senales.md`.
- **5 condiciones de sí o no:** encaja en el sector · encaja en el tamaño · está en la zona · tiene una señal dentro de la ventana · tiene un canal de contacto público.

Termina preguntando si cambia algo (en modo sin preguntas, da el paso por validado). Si el usuario lo valida y la sección no tenía el Cliente ideal, propón añadirlo a `## Prospección` para la próxima tanda.

### Paso 2 · Encontrar candidatas

- Límite por defecto: **6 búsquedas y 12 páginas abiertas**, salvo que `## Prospección` o el usuario den otro. Las búsquedas son lo lento; los resultados ya traen muchos nombres.
- Fuentes que sirven y que no: `references/fuentes-y-senales.md`. LinkedIn y Google Maps no se pueden leer: no los uses.
- Reúne **entre 15 y 20 empresas reales**. Cada fila: empresa, web, zona, señal con URL y fecha, estado del dato.
- Pasa las 5 condiciones (sí, no o por confirmar). **Prioridad:** A con 4–5 síes, B con 2–3, C con 0–1. «Por confirmar» no cuenta como sí.
- La ventana es de **6 meses** desde hoy, salvo que `## Prospección` diga otra. Una señal más antigua no es motivo para escribir hoy: esa condición es «no».
- Si el CRM de `## Prospección` nombra un MCP con herramienta de búsqueda y está conectado, busca con ella cada empresa (solo lee) y marca las que ya están en el CRM: no se vuelven a prospectar sin decirlo.
- Termina con la tabla ordenada por prioridad, las 10 mejores marcadas y la lista «Comprobar a mano». Si no llegas a 15, quédate con las que haya y di por qué.

### Paso 3 · Investigar y calificar las 10

Como mucho una página nueva por empresa. Si al investigarla deja de pasar el filtro, cámbiala por la siguiente de la tabla y dilo. Para cada una, una ficha de cinco líneas:

1. Qué hace, en una frase.
2. La señal, con su URL y su fecha.
3. El problema que podría tener, como pregunta.
4. Quién decide (cargo; nombre solo si la empresa lo publica).
5. Canal de contacto público y prioridad.

### Paso 4 · Primer contacto y entregables

- Un mensaje por empresa para el canal de su ficha; si es correo, asunto de como mucho 6 palabras.
- Cada mensaje pasa la **rúbrica de 7 puntos** de `references/rubrica-mensaje.md` y se corrige antes de entregarlo.
- Para las 3 de prioridad más alta, dos seguimientos más cortos (a los 3 y a los 7 días laborables).
- **Entregables:** monta `<Carpeta>/AAAA-MM-DD/cuentas.json` con el formato del comentario inicial de `scripts/exportar.py` y ejecuta el script. Su ruta es relativa a este `SKILL.md`, no a la carpeta de trabajo:

  ```bash
  python3 <carpeta-de-este-skill>/scripts/exportar.py <Carpeta>/AAAA-MM-DD/cuentas.json
  ```

  Comprueba las reglas (URL, fecha dentro de la ventana, prioridad, estado, longitud del mensaje, canales que parecen personales, duplicados) y genera, junto a `cuentas.json`, `prospeccion.html` (fichas y mensajes con botón de copiar) y `prospeccion.csv` (13 columnas, UTF-8), con la fecha del primer contacto según la prioridad: A, el próximo día laborable; B, a 3 días laborables; C, a 7. Con `--solo-comprobar` revisa sin generar nada; con `--meses` cambia la ventana. Si da errores, corrígelos y vuelve a ejecutarlo; los avisos se revisan y se explican al usuario.

### Paso 5 · Al CRM

Según el CRM de `## Prospección`:

- **Con carpeta de entrada:** sigue `references/crm-carpeta.md`. En resumen: el script copia `cuentas.json` a la carpeta de entrada del CRM y las cuentas siguen su flujo (importar → revisar → consolidar), que hace el usuario desde el panel del CRM. Este skill no consolida ni escribe en el consolidado.
- **Sin CRM:** el CSV es el entregable; dilo en una línea.

## Informe comercial (`informe`)

Solo lee: **sin crear, cambiar ni borrar nada** y sin enviar nada. Una tarea programada se quedaría esperando la aprobación de una escritura; los cambios se aplican después, en una conversación donde se ven antes.

Con un CRM cuyo MCP tiene herramienta de recordatorios (campo CRM de `## Prospección`), lee con ella los recordatorios pendientes de las cuentas de prospección, con su contacto y su última nota. Si el MCP no está conectado o no ofrece una herramienta de recordatorios pendientes, dilo y para: el informe no se rehace a partir de los CSV. Escribe:

- **Hoy y mañana:** como mucho 5 empresas con tareas vencidas, de hoy o del próximo día laborable (primero las vencidas), con la tarea, el siguiente paso y el borrador del mensaje, escrito solo con lo que dice su nota y en el Idioma de la sección.
- **Paradas:** cuentas de prospección sin tarea pendiente, con el siguiente paso propuesto, si el CRM lo puede dar.
- **Pipeline:** cuentas por etapa, si el CRM tiene etapas.
- Una lista final «Para aplicar en el CRM» con las tareas a crear o mover. Si no hay nada, dilo en una línea.

## Estilo

Breve: tablas y frases cortas. Nada sobre lo que es legal o ilegal: las reglas de este método se explican como reglas de método.
