# Metodología en tres niveles: parte común

Parte común de la metodología de diseño y desarrollo de los proyectos que usan el plugin `dev`. Cada proyecto la activa con el campo **Metodología** de su `## Método`, que apunta a su propio documento (por convención, `doc/A0-Metodologia/metodologia-de-diseno-y-desarrollo.md`). Ese documento enlaza aquí y añade solo lo suyo:

- su nivel B, que es distinto en cada proyecto;
- los ajustes a A y C: las capas o carpetas que activan C2 y C3, las etiquetas de área, lo que se comprueba a mano en C5, los destinos del aprendizaje en C7 y los documentos de A que tenga además de visión y ADR (manual de usuario, despliegue...);
- las excepciones a lo de aquí, cada una con su porqué.

Sin el campo, nada de esto se aplica: no se exige diseño técnico ni UX previo, y no hay documento de visión ni carpeta de ADR.

Donde este documento dice `doc/A1-Vision/` o `doc/C*/`, la carpeta es la del campo **Documentación** de `## Método` (`doc/` por defecto). Así, cuando varios tableros comparten repo, cada uno guarda su visión, sus mockups y sus retros en su carpeta (`doc/<proyecto>/A1-Vision/`). A0, A2 y A3 siguen en `doc/`, comunes a todo el repo.

Es un guion de arranque, no una norma cerrada. Cada etapa se describe con **documento**, **índice** (secciones esperadas), **resultado** (qué queda al terminar), **columna** del tablero (campo Status: Backlog / Ready / In progress / In review / Done) y **skill** de Claude Code, si hay uno. Lo propio del proyecto que leen los skills (tablero, Verificación, etiquetas, retoques, mapa de documentación) está en su `## Método`, no en la metodología.

## De dónde viene

Es un mosaico de prácticas conocidas, adaptadas a un desarrollador con Claude Code como operador:

- El tablero y el flujo Backlog → Ready → In progress → In review → Done son el **Kanban Method** de Anderson, con Ready como puerta de "Definition of Ready" (Scrumban) antes de entrar en desarrollo.
- A2 es el patrón de **Architecture Decision Records** de Nygard.
- El documento de visión (A1) se parece a los one-pager o RFC de iniciativa (fase de *shaping* de Shape Up) antes de comprometer trabajo.
- `/dev:retro` y `/dev:revisar-docs` adaptan `/retro` y `/document-release` de [gstack](https://github.com/garrytan/gstack): retrospectiva medida a partir de commits e issues, y mapa de cobertura de la documentación a partir del diff, recortados a un único desarrollador, su tablero y `doc/` como fuente de verdad.

Lo propio del método es el mapeo explícito de cada tipo de documento a una columna del tablero y a un skill concreto.

## Los tres niveles

| Nivel | Qué decide | Frecuencia | ¿Vive en el tablero? |
|---|---|---|---|
| **A. Visión y arquitectura** | Qué hace el proyecto y decisiones que afectan a todo o a varias capas | Baja | No directamente: genera issues B/C |
| **B. Eje de extensión** | Cómo encaja una pieza nueva del eje por el que crece el proyecto (lo define cada uno) | Por pieza nueva | Un issue paraguas por alta |
| **C. Feature/issue** | Una funcionalidad, un bug, un retoque | Continua | Sí, 1:1 con las columnas |

**Lo que no es trabajo de desarrollo**: el *uso* del proyecto (operar sobre sus datos, aprobar, corregir un registro) y su contenido. Sus efectos, si los hay, se versionan donde viven los datos; no generan issues ni documentos. Cada proyecto dice cuál es su uso.

---

## Nivel A — Visión y arquitectura

### A1. Visión y alcance

- **Documento**: documento de visión, vivo, en `doc/A1-Vision/`: un fichero por elemento del índice con un `README.md` que los enlaza, o un único `README.md` si el proyecto es pequeño.
- **Índice**: problema que resuelve · usuarios o entradas y salidas · modelo de datos · casos de uso · fuera de alcance · métricas de éxito · riesgos · ampliaciones futuras (ideas sin contexto suficiente aún para una ADR). El proyecto añade los suyos (panel, integraciones, catálogo de tools...).
- **Resultado**: documentos de referencia que no se "cierran": se actualizan cuando cambia la visión y alimentan el Backlog.
- **Columna**: no aplica directamente; cuando algo madura en trabajo accionable, nace un issue en **Backlog**.
- **Skills**: `/dev:nueva-vision` actualiza el documento y, si lo que cambia ya es accionable, abre los issues con trazabilidad al fichero de A1.

### A2. Decisiones de arquitectura (ADR)

- **Documento**: `doc/A2-ADR/NNNN-titulo-corto.md`, una decisión por fichero, con un índice en `doc/A2-ADR/README.md`.
- **Índice** (secciones dentro de cada ADR): Contexto (qué fuerza la decisión) · Decisión · Alternativas consideradas y por qué se descartaron · Consecuencias (qué se vuelve más fácil o más difícil) · Estado.
- **Formato que se lee desde fuera**: la primera línea es `# NNNN — Decisión` y `## Estado` empieza por `Propuesta`, `Aceptada`, `Superada` o `Rechazada`, con texto libre detrás. Los issues relacionados van en esa sección (`#NN`, `owner/repo#NN` o enlace). La primera palabra del Estado y la fila del índice dicen lo mismo.
- **Resultado**: fichero versionado, citado desde el código o desde el issue de implementación.
- **Columna**: nace de un issue existente (se redacta en **Ready**, antes de implementarlo) o al revés, decisión primero: entonces genera su propio issue de implementación, directamente en **Ready**. Una decisión no está completa solo con el fichero: tiene que quedar accionable en el tablero.
- **Skills**: `Plan` (subagente arquitecto) para bosquejar alternativas · `/dev:crear-decision` para redactarla y crear su issue · `/code-review` sobre lo implementado, para contrastarlo con lo decidido. `/dev:cerrar-issue` pregunta si una ADR en `Propuesta` pasa a `Aceptada` cuando se cierra su último issue.

---

## Nivel B — Eje de extensión

Lo define cada proyecto: qué es una pieza nueva (un negocio, una fuente de datos, una automatización, una norma...), qué se decide antes de programarla y cómo se comprueba que funciona. La forma habitual es:

- **B1. Ficha**, redactada antes de programar, en `doc/B1-<...>/`.
- **B2. Diseño técnico** en el issue (o en `doc/B2-Disenos-tecnicos/` si no cabe), y una ADR si la pieza obliga a cambiar un puerto o una entidad.
- **B3. Puesta en marcha**: checklist única en `doc/B3-Puesta-marcha/`.
- Un solo issue paraguas para B1–B3, que recorre Backlog → Ready → In progress → In review como uno de C.

---

## Nivel C — Ciclo de feature/issue

El detalle de cada etapa vive en el issue, y su estado, en el tablero, que es el único índice de issues. Si el proyecto tiene carpetas `doc/C*/`, solo describen su etapa o guardan capturas y mockups.

### C1. Análisis — **Backlog**

- **Documento**: el cuerpo del issue.
- **Índice**:
	- Situación o diagnóstico (qué pasa o qué falta).
	- Plan (qué se va a hacer).
	- Alcance: qué capas o zonas toca (las nombra el proyecto). Sirve para anticipar si hará falta C2 o C3.
	- Tests existentes que el plan puede dejar obsoletos (contenido reubicado, comportamiento movido de sitio), además de los que hará falta añadir. Sin condición de capa: los cambios de una sola capa son justo los que rompen tests sin pasar por C2.
- **Etiquetas**: una de área (la principal; una segunda solo si toca dos áreas a partes iguales) de las de `## Método`, y la de tipo que diga su campo. Si va a una rama larga y no a la principal, además `rama:<nombre de la rama>` ([Ramas largas](README.md#ramas-largas)).
- **Skills**: `/dev:crear-issue` · `/dev:detectar-bug` cuando el análisis nace de un comportamiento observado y hay que diagnosticar antes si es bug, límite conocido o petición.

### C2. Diseño técnico — **Backlog → Ready**

Solo cuando el issue toca los puertos o las entidades, añade un adaptador o afecta a más de una capa; el proyecto concreta qué es eso en su código. Un fix o retoque de una sola capa pasa directo a Ready.

Si un issue que lo necesitaba llega a Ready sin pasar por aquí, `/dev:resolver-issue` y `/dev:sprint` lo detectan antes de implementar y añaden ellos el comentario de diseño. Con C3 no basta un comentario: falta el visto bueno del usuario al mockup. `/dev:resolver-issue` lo pide y espera; `/dev:sprint` deja el issue en Ready con el mockup enlazado y sigue con el siguiente.

- **Documento**: comentario "Diseño técnico" en el issue, o una ADR corta (A2) si la decisión trasciende ese issue.
- **Índice**: puertos o entidades afectados · adaptadores a tocar · modos de fallo: qué pasa si un servicio externo está caído, lento o sin permiso, si otro proceso cambia los mismos datos a la vez, y qué llamada se repite en un bucle (lo que se probó con un doble del servicio y lo que solo se ve contra el real) · alternativas descartadas y por qué · tests a añadir por capa y tests existentes que el cambio deja obsoletos.
- **Resultado**: plan técnico validado y comentado en el issue.
- **Columna**: mueve el issue de **Backlog** a **Ready**.
- **Skills**: `Plan` para bosquejar el diseño · `/code-review` después de implementar, para contrastar el resultado con lo planeado.

### C3. Diseño UX/UI — **Ready**

Solo cuando el issue cambia lo que se ve (el proyecto dice en qué carpetas).

- **Documento**: mockup o descripción visual del cambio, enlazado desde el issue. Las capturas que se guarden van con datos ficticios.
- **Índice**: pantallas o páginas afectadas · estado antes y después · breakpoints (mobile first, según `estilo/diseno-web.md`) · qué acciones escriben datos o tienen efectos fuera de la página.
- **Resultado**: diseño con el visto bueno del usuario, a 390 px y en escritorio, anotado en el issue. Los ajustes de posición, anchura o estilo se hacen en el mockup, donde no cuestan commits ni tests; con el código ya en marcha, cada uno es un commit más.
- **Columna**: **Ready**.
- **Skills**: `Artifact` (mockup) antes de tocar código · `dev:developing-with-streamlit` si es un panel Streamlit · `/dev:crear-retoque` para un ajuste menor que no necesita issue propio ni mockup: queda anotado en el issue paraguas de su zona.

### C4. Implementación — **In progress**

- **Documento**: el código y los tests, más el comentario de plan que `/dev:resolver-issue` y `/dev:sprint` dejan en el issue al empezar.
- **Resultado**: commit local con pie `Issue: #NN` y la Verificación de `## Método` en verde.
- **Criterio**: un bug se arregla en su causa. Si un componente reacciona a algo que no le corresponde, se corta lo que lo acopla con el otro, para que cada uno atienda solo sus eventos. Ocultar, retrasar o dejar detrás de un clic algo que el usuario ya ve es un recorte, no un arreglo: solo se propone como compromiso, preguntando.
- **Columna**: **In progress**.
- **Skills**: `/dev:sprint` · `/dev:resolver-issue` · `/dev:resolver-retoques` para los retoques anotados, uno a uno.

### C5. Verificación — **In progress → In review**

- **Documento**: comentario de verificación en el issue (lo escribe `/dev:cerrar-issue`).
- **Índice**:
	- Tests y comandos de Verificación ejecutados, y las Verificaciones extra que tocaban.
	- Prueba manual en la app arrancada (navegador, panel, CLI), no solo lectura de código; en modo demo si el proyecto tiene el campo Demo ([modo demo](README.md#modo-demo)). Un servidor de prueba se arranca con `run_in_background` del tool Bash, en un puerto propio: `nohup`, `disown` o `setsid` no sobreviven entre llamadas. Se para por ese puerto (`fuser -k <puerto>/tcp`), nunca con un patrón amplio como `pkill -f "streamlit run"`, que tumba también las apps que el usuario tiene en marcha.
	- Variantes probadas, no solo el escenario exacto del issue: datos de forma distinta (una cita corta y una de varias horas, un elemento y muchos), porque un cambio en una condición compartida rompe los casos vecinos que el issue no nombra.
	- Capturas si el cambio es visual, de un navegador real (Playwright headless si no hay otro) a 390 px y en escritorio, y en horizontal si el móvil importa. Cubren los estados del componente (vacío y con contenido, abierto y cerrado), y se miran las imágenes, no solo que el comando termine: un layout que parece correcto leyendo el código puede no serlo, porque el framework impone CSS propio (Streamlit apila `st.columns` por debajo de cierto ancho).
	- Con datos reales, en el issue solo totales y recuentos.
	- Revisión de código del diff del issue con `/code-review low`, antes de cerrarlo. Lo que encuentre dentro del alcance del issue se arregla en él; lo ajeno, en un issue aparte. Con el diff pequeño es barato, y la revisión de `/dev:publicar-version` no carga con todo el sprint.
- **Resultado**: comentario de verificación en el issue.
- **Columna**: mueve el issue a **In review**.
- **Skills**: `/run` para arrancar y explorar la app · `security-review` si toca superficie sensible (credenciales, datos personales, envío de datos a un servicio externo) · `/dev:revisar-docs` para dejar la documentación al día; `/dev:resolver-issue` y `/dev:sprint` lo invocan solos antes de cerrar.

### C6. Revisión — **In review**

- **Documento**: hallazgos de revisión, en el diff o resumidos en el issue.
- **Índice**: hallazgos por severidad · veredicto (aprobado / cambios pedidos).
- **Resultado**: issue aprobado, o reabierto con los cambios pendientes.
- **Columna**: **In review**. La cola tiene un límite (`Límite de In review` de `## Método`, 10 por defecto): es la revisión del usuario, y cerrar más rápido de lo que se revisa solo acumula fallos que aparecen días después. Al llegar al límite, `/dev:sprint` para y `/dev:resolver-issue` avisa antes de empezar.
- **Skills**: `/code-review` (nivel según lo crítico del cambio) · `/simplify` para limpieza de calidad que no busca bugs.

### C7. Cierre — **Done**

- **Documento**: comentario de cierre y, si dejó un aprendizaje reutilizable, este va a su sitio según su naturaleza (el proyecto concreta los suyos):
	- conocimiento **del dominio o del producto** → `doc/A1-Vision/`, la ficha B1 que corresponda o `doc/Z-Anexos/`;
	- conocimiento **técnico reutilizable** → fuera del proyecto, donde el usuario guarde sus notas técnicas;
	- **regla de colaboración** con Claude → memoria de Claude Code (`feedback` o `project`), o el método común si vale para todos los proyectos.
- **Resultado**: issue cerrado y aprendizaje archivado en vez de perdido en el historial del issue.
- **Columna**: el flujo de Claude termina en **In review**; el paso a **Done** lo hace el usuario tras revisar.
- **Skills**: `/dev:cerrar-issue` · `/dev:retro` (periódico).

## Tabla resumen del nivel C

| Etapa | Documento | Columna | Skill |
|---|---|---|---|
| C1 Análisis | Cuerpo del issue | Backlog | `/dev:crear-issue`, `/dev:detectar-bug` |
| C2 Diseño técnico | Comentario "Diseño técnico" / ADR | Backlog → Ready | `Plan`, `/code-review` |
| C3 Diseño UX/UI | Mockup / descripción | Ready | `Artifact`, `/dev:crear-retoque` |
| C4 Implementación | Código + tests | In progress | `/dev:sprint`, `/dev:resolver-issue`, `/dev:resolver-retoques` |
| C5 Verificación | Comentario de verificación | In progress → In review | `/run`, `security-review`, `/dev:revisar-docs` |
| C6 Revisión | Hallazgos | In review | `/code-review`, `/simplify` |
| C7 Cierre | Comentario + aprendizaje archivado | In review (Done lo pone el usuario) | `/dev:cerrar-issue`, `/dev:retro` |

---

## Mantenimiento periódico

### Higiene del tablero

Son dos problemas distintos, con soluciones distintas:

- **Done que se acumula**: no compite por atención con nada, solo ocupa la vista. Se archiva (la función "Archive item" de GitHub Projects) lo que lleva tiempo cerrado: no se borra ni se reabre, sigue buscable por etiqueta y texto, y deja de contar en los gráficos de Insights.
- **Backlog que se acumula**: archivar no decide nada. Toca repasarlo entero, cerrar como `wontfix` lo que ya no aplica (`/dev:cerrar-issue-wontfix`) y mover a Ready lo que se va a coger pronto.

`/dev:higiene-tablero` cubre los dos y avisa de los issues revisados con commits sin subir. Propone y solo actúa tras confirmación. Periodicidad sugerida: trimestral, o antes de un sprint largo o de un alta de nivel B.

### Retrospectiva

`/dev:retro [ventana]` (7 días por defecto) reúne commits, issues cerrados, abiertos y reabiertos, lo que espera en In review y los retoques nuevos, y propone como mucho 3 mejoras apoyadas en esos datos, cada una al sitio que le toca según C7. Repasa también las memorias de feedback del proyecto y propone pasar al método común las que valen para todos. Solo aplica tras confirmación. Cada retro se guarda en `doc/C7-Cierre/retros/AAAA-MM-DD.md` para que la siguiente compare. Periodicidad sugerida: semanal mientras hay actividad diaria.
