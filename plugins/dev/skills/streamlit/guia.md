# Guía de apps Streamlit

Reglas para toda app Streamlit de los proyectos con `## Método`. Cada regla es comprobable en el código. Las de aspecto (`A`) mandan: una solución técnica (`T`) que choque con ellas se adapta, no al revés. Lo que ya dice `estilo/diseno-web.md` no se repite aquí; esta guía solo dice cómo se aplica en Streamlit.

Qué apps de una máquina sirven de modelo para cada regla, y cuáles la cumplen hoy, no va aquí: va en `local/streamlit.md` del repo del método, ignorado por git, si esa máquina lo tiene.

## Aspecto

### A1. Icono propio en cada app

Cada app tiene un icono distinto del de las demás y nunca el de serie de Streamlit. El estilo es el de Material Symbols, no un emoji.

- Cómo: `st.set_page_config(page_icon=":material/<nombre>:")`, con el nombre buscado en [Material Symbols](https://fonts.google.com/icons).

### A2. Menú lateral en vez de pestañas

Toda app con más de un apartado tiene un menú desplegable a la izquierda. Las pestañas solo se usan si es imprescindible ver los apartados dentro de la misma página.

- Cómo: `st.navigation([...])` con un `st.Page` por apartado (ver A3 y A4 para cómo pintarlo).

### A3. Título y frase explicativa en el menú

Arriba del menú lateral van el nombre de la app y una frase corta que dice para qué sirve.

- Cómo: `st.title(NOMBRE_APP)` y `st.caption("…")` dentro de `st.sidebar`, antes de las opciones. Con un menú pintado después (un `st.radio`) basta con eso, pero `st.navigation` (A4) pinta su menú encima de todo lo demás de la barra lateral. Para tener las dos cosas, `st.navigation(..., position="hidden")` y el menú se pinta a mano después del título, con un `st.page_link` por página, que conserva el icono y destaca la página activa:

  ```python
  paginas = [st.Page(contactos, title="Contactos", icon=":material/contacts:", url_path="contactos", default=True), ...]
  pagina = st.navigation(paginas, position="hidden")
  with st.sidebar:
      st.title(NOMBRE_APP, anchor=False)
      st.caption("Frase que dice para qué sirve la app")
      for p in paginas:
          st.page_link(p)
  pagina.run()
  ```

### A4. Opciones del menú con icono, la activa destacada y su propia URL

Cada opción lleva su icono y la opción en la que se está se ve destacada. Cada opción tiene además su propia URL (`/revision`, `/historial`): al recargar o abrir un enlace se vuelve a la misma opción, no a la primera. Un `st.radio` u otra forma de pintar el menú se sustituye por este formato.

- Cómo: un `st.Page(..., icon=":material/<nombre>:")` por apartado. `st.navigation` y `st.page_link` destacan solos la página activa; un `st.radio` no, solo marca un punto, y al recargar vuelve a la primera opción. La URL la da `st.navigation`: una página de fichero la toma del nombre del fichero (`app_pages/revision.py`); una página de función lleva `url_path="<apartado>"` explícito, legible y estable aunque cambie el nombre de la función. Lo que se elige dentro de la página va en la URL según T4.

### A5. Menú de los tres puntos siempre; Deploy solo si se despliega en Streamlit

Arriba a la derecha está siempre el menú de los tres puntos. El botón Deploy solo aparece en una app que se despliega en Streamlit, como Lanzadera; en las demás no tiene sentido y solo queda el menú.

- Cómo: `[client] toolbarMode = "viewer"` en `.streamlit/config.toml`: deja el menú y quita Deploy, Rerun y Clear cache. Una app que se despliega en Streamlit lleva `"auto"`, que en local enseña también Deploy y las opciones de desarrollo. `"minimal"` quita el menú entero y no se usa.

### A6. Ancho del contenido según lo que se muestra

La zona de contenido es ancha si muestra muchos datos en tablas y estrecha si muestra sobre todo párrafos de texto. En una tabla ancha se ven de entrada las columnas más usadas; las demás se pueden mostrar desde el menú de columnas.

- Cómo: `layout="wide"` o `layout="centered"` en `st.set_page_config`. Una tabla con muchas columnas puede reducir además el margen lateral de serie con CSS acotado (T1). Las columnas secundarias, con `hidden=True` en su `column_config` (ver T5).

### A7. Búsqueda por texto en tablas y listas

Toda tabla o lista de elementos en la que tenga sentido tiene un campo de búsqueda por texto. La lista cambia mientras se escribe, sin pulsar Intro. El campo tiene un ancho razonable (el del placeholder o una búsqueda verosímil), no el de toda la página aunque haya sitio.

- Cómo: `st.text_input("Buscar", type="search", live=True, placeholder="Buscar por …", label_visibility="collapsed", width=<px>)`. `type="search"` trae su botón de vaciar y `live=True` filtra al dejar de teclear; las dos opciones existen desde Streamlit 1.64, así que una app con una versión anterior tiene que subir. La comparación, con `casefold()` en los dos lados.

### A8. Selector de idioma, último en el menú

En una app multiidioma, el selector de idioma es un control segmentado y es el último elemento activo del menú lateral. Después solo puede ir una explicación sobre el origen de la app, como la que puede enseñar en modo demo.

- Cómo: `st.segmented_control("Idioma", IDIOMAS, default=…, required=True, format_func=str.upper, key="idioma")` en `st.sidebar`, después de las opciones del menú, y debajo un `st.caption` con el origen. Los textos, en el patrón de T11.

### A9. Leyendas con el contraste del texto normal

Las leyendas (`st.caption`), como la frase del menú de A3 o la explicación bajo el título de una página, se leen con el mismo contraste que el texto normal. Streamlit las pinta semitransparentes y en gris claro se leen mal.

- Cómo: una regla común en el fichero de entrada, justo después de `st.set_page_config`, que quita la transparencia en todas las páginas: `st.html('<style>.stMarkdown [data-testid="stCaptionContainer"] { opacity: 1; }</style>')`. Las leyendas siguen siendo más pequeñas que el texto y toman su color, también en modo oscuro. Es CSS inyectado (T1) porque no hay opción de tema para la opacidad de las leyendas.

### A10. Menú lateral del mismo color en todas las apps

El menú lateral tiene en todas las apps el fondo gris azulado de serie anterior a la 1.67 (`#F0F2F6` en modo claro), sea cual sea la versión de Streamlit. Desde la 1.67, el tema por defecto lo pinta en un gris cálido (`#F8F8F7`) y una app recién actualizada deja de parecerse a las demás.

- Cómo: en `.streamlit/config.toml`, `[theme.light.sidebar]` con `backgroundColor = "#F0F2F6"`. Solo en modo claro: la 1.67 también cambia el fondo de la página en modo oscuro, y fijar ahí el gris oscuro antiguo del menú lo haría desentonar.
- El ancho no se fija: es el de serie (300 px) en todas. El borde del menú se arrastra, y el ancho elegido queda guardado en el navegador para esa dirección (`sidebarWidth` en `localStorage`). Una app que se vea con el menú más estrecho o más ancho que las demás tiene un ancho arrastrado en ese navegador; doble clic en el borde vuelve al de serie.
- Una app por debajo de la 1.67 ya se ve así con su tema de serie, pero lo necesitará al actualizar.

## Técnica

### T1. Antes `config.toml` y parámetros que CSS inyectado

Todo lo que se pueda fijar en `.streamlit/config.toml` o con un parámetro del widget va ahí: se aplica antes del primer pintado. Un `<style>` inyectado con `st.markdown` o `st.html` llega después y provoca un parpadeo (el elemento aparece con su aspecto de serie y un instante después cambia), aunque solo fije un margen. Se reserva para lo que no tiene otra vía, y nunca para la cabecera ni para lo que mueve la parte de arriba de la página.

- El CSS que haga falta va acotado a un bloque: `st.container(key="x")` da la clase `.st-key-x`, y la regla solo toca lo de dentro.
- Para ocultar la descarga CSV de las tablas, `[client] disableDataExport = true`, no CSS.
- `st.chat_input` también parpadea: se ancla al fondo después del primer montaje. Un `st.form` con un `st.text_input` queda en su sitio desde el principio.

### T2. Arranque

- `streamlit run` solo añade a `sys.path` la carpeta del script. Si la app importa de la raíz del repo, la primera línea tras los imports de la biblioteca estándar es `sys.path.insert(0, str(Path(__file__).resolve().parent.parent))`.
- `st.set_page_config` es la primera llamada a Streamlit. Con `st.navigation`, se vuelve a llamar después con `page_title=pagina.title`: la pestaña del navegador dice en qué apartado se está.
- En modo demo, el título de la pestaña lleva `DEMO` detrás del nombre de la app, para no confundirla con la app de verdad abierta en otra pestaña: `titulo = f"{NOMBRE_APP} DEMO" if demo else NOMBRE_APP` en las dos llamadas a `st.set_page_config` (`page_title=f"{pagina.title} · {titulo}"` en la segunda).
- La app arranca aunque falten datos o configuración: avisa de lo que falta (`st.error` o `st.info` y `st.stop()`) en vez de romper.
- App local: `[server] address = "127.0.0.1"`, `headless = true`, un `port` fijo y propio (el que tiene en la Lanzadera), y `[browser] gatherUsageStats = false`.
- Una app en marcha relee el script principal en cada recarga del navegador, pero puede seguir con la versión vieja de los módulos que importa: si el script depende de un cambio en uno de ellos, la app falla (p. ej. un `KeyError` por una clave nueva) hasta reiniciarla. Al acabar un cambio así se avisa de que hace falta reiniciar; si la app es un servicio del que dependen otros procesos, se dice también qué se para y se pregunta antes de reiniciar. Si solo cambia el script principal, basta refrescar el navegador.
- Si la app importa `transformers` (embeddings), el vigilante de recarga llena el log de avisos: `logging.getLogger("streamlit.watcher.local_sources_watcher").setLevel(logging.ERROR)`.

### T3. Estado de los widgets

- Con `key`, el `value` o `index` de un widget solo vale la primera vez. Para cambiarlo desde fuera (otra página, un dato que cambió), se escribe `st.session_state[key]` antes de crear el widget, nunca después: asignar la clave de un widget ya pintado en la misma pasada lanza `StreamlitAPIException`.
- Lo que se decide desde varios sitios va en una clave propia, no en la de un widget.
- Streamlit borra el estado de los widgets de las páginas que no se pintan. Lo que tiene que seguir igual al volver de otra página (plegado, orden, filtros) va en una clave propia de `st.session_state`.
- Una acción que debe pasar antes del siguiente pintado (vaciar una caché, limpiar una selección) va en `on_click` u `on_change`, no en `if st.button(...)`: el callback corre antes del rerun.

### T4. La vista en la URL

Lo que define qué se está viendo (plan, sección, filtro) va en la URL, para que F5 o un enlace lleven a la misma vista.

- `bind="query-params"` en el widget, cuando lo admite (unas pastillas de etiquetas, `?etiqueta=`).
- Si no, `st.query_params` solo inicializa: el widget lleva `key` fija y sin `index`, y su valor inicial sale de la URL una sola vez. Recalcular el `index` en cada ejecución hace que Streamlit vea un widget nuevo y descarte la elección siguiente.

### T5. Tablas

- `st.dataframe(..., hide_index=True, width="stretch", height=…)`, con el alto limitado a unas 20 filas: `min(35 * (filas + 1) + 3, 35 * 21 + 3)`.
- Cada columna con su tipo en `column_config`: fechas con `DatetimeColumn(format=…)`, enlaces con `LinkColumn(display_text=…)`, etiquetas con `MultiselectColumn(color=…)`.
- Las columnas secundarias, con `hidden=True` y no fuera de `column_order`: al mostrarlas desde el menú de columnas salen en su sitio y no al final.
- Con buscador propio (A7), la lupa de la barra de la tabla sobra y se oculta: `[aria-label="Search"] { display: none }`, el único CSS que no tiene alternativa en `config.toml`.
- La selección de filas (`on_select="rerun"`) va por posición. Cuando cambia lo que se lista (búsqueda, filtro, borrado), se limpia cambiando la `key` de la tabla con un contador de versión; si no, la misma posición señala otra fila.

### T6. Formularios, diálogos y avisos

- Un campo de texto con su botón de enviar va en `st.form`: sincroniza los dos en un solo evento (sin form, el clic puede llegar antes que el último cambio del campo) y permite enviar con Intro. `clear_on_submit=True` cuando el formulario se vacía al enviar.
- Un `st.dialog` se abre con un indicador en `st.session_state`, no solo con el clic del botón: así sigue abierto en los reruns que provoca lo de dentro.
- Una acción terminada se confirma con `st.toast(..., icon=":material/check:")`. Los avisos y errores van en la página, porque hay que leerlos con calma.
- Un mensaje que tiene que verse después de `st.rerun()` se guarda antes en `st.session_state` y se pinta (y se borra) en la ejecución siguiente.

### T7. Caché

- `@st.cache_resource` para lo caro de crear y compartido: modelos, conexiones, el contexto de dependencias.
- `@st.cache_data(ttl=…)` para lecturas lentas que cambian poco (git, `gh`, ficheros grandes). Varias consultas independientes, en paralelo con un `ThreadPoolExecutor` dentro de la función cacheada.
- Un fallo no se guarda en caché: si el resultado trae un fallo, `funcion.clear(args)` y la siguiente ejecución vuelve a consultar.

### T8. Desplazamiento al cambiar de apartado

Al llegar a un apartado desde el menú, la página baja hasta su contenido; las recargas por escribir o marcar filas no mueven nada.

- Un `st.html(..., unsafe_allow_javascript=True)` con un marcador `data-vez` distinto en cada visita: Streamlit reutiliza el nodo de un `st.html` igual y su script no se vuelve a ejecutar.
- Se dispara solo cuando cambia la página guardada en `st.session_state`.

### T9. Detalles de presentación

- Títulos con `st.title(..., anchor=False)` o `st.header(..., anchor=False)`: sin el icono de enlace que Streamlit añade al pasar el ratón.
- Texto del usuario dentro de Markdown, escapado: `*`, `_`, `:`, `[` y compañía cambian el formato.
- `st.pills` no admite un color por opción, y un `format_func` con color cambiaría el valor que se guarda en la URL: el color va por CSS sobre la posición de cada botón.
- Streamlit no hace clicable un contenedor: un botón transparente lo cubre.
- En móvil, `st.columns` apila las columnas por un `min-width` fijo. Una fila de botones que debe seguir en una línea va en un `st.container(key=…)` que anula ese `min-width` solo ahí.

### T10. Pruebas del panel

- El panel se prueba con `streamlit.testing.v1.AppTest` sobre una carpeta de datos temporal: la ruta de datos sale de una variable de entorno, fijada en un `conftest.py` raíz con `autouse=True` hacia `tmp_path`, para que ningún test escriba en los datos reales.
- Los widgets se buscan por `key`, no por posición.
- `AppTest` no maneja `st.data_editor`: lo que hay detrás de una tabla editable (qué se guarda, qué se valida) vive en una función fuera de la vista y se prueba aparte. Del panel solo se prueba que pinta sin excepción.
- `AppTest.from_file(ruta, default_timeout=30)` si la primera ejecución lee mucho.

### T11. Textos en varios idiomas

- Los textos, en un módulo aparte con un diccionario por idioma y una función `t(clave, **huecos)`. El idioma se lee de `st.session_state["idioma"]` o, antes de pintar el selector, del de por defecto.
- Los números se formatean según el idioma: coma decimal en español, punto en inglés.
