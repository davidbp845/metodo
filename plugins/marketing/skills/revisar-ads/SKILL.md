---
name: revisar-ads
description: Revisa una campaña de Google Ads con sus exportaciones, Search Console y la analítica web, guarda el informe y, tras cada cambio aplicado en Ads, comprueba que coincide con lo propuesto
argument-hint: "[pregunta o decisión que motiva la revisión] | verificar"
---
Revisión de la campaña de Google Ads del proyecto. "$ARGUMENTS" es la pregunta que la motiva (pausar, bajar el gasto, por qué no convierte...); con `verificar`, solo se comprueba un cambio ya aplicado (paso 9). Es solo lectura respecto a Ads y a la web: los cambios los aplica el usuario en la interfaz de Ads.

Lee antes la sección `## Marketing` del `CLAUDE.md` del proyecto. Si falta, o le falta la Carpeta, dilo y para.

## 1. Ordenar las descargas

Ads pone siempre el mismo nombre a cada informe, y una descarga nueva pisa a la anterior. Por eso cada descarga vive en su carpeta:

- `<Carpeta>/datos/AAAA-MM-DD/`: las exportaciones de Ads del rango completo, del día en que se bajaron.
- `<Carpeta>/datos/AAAA-MM-DD/desde-cambio/`: las de Ads con el rango que empieza en el último cambio aplicado.
- `<Carpeta>/datos/AAAA-MM-DD/search-console/`: las de Search Console.
- `<Carpeta>/informes/AAAA-MM-DD-revision-ads.md`: un informe por revisión.
- `<Carpeta>/checklist-descargas.md`, opcional: qué bajar en cada revisión y dónde está cada descarga en las pantallas de Google, con los datos del proyecto.

Mueve con `mv -n` los ficheros sueltos de la raíz de la Carpeta a la carpeta que les toca según la segunda línea (el rango) y la fecha de modificación. Si dos informes del mismo día y de la misma carpeta tienen rangos distintos, añade el rango al nombre (`Informe de términos de búsqueda (12-15 nov).csv`). Nunca borres una exportación: un duplicado `(1)` o `(2)` idéntico se deja donde está.

## 2. Convertir y fechar

Copia al scratchpad, no a la Carpeta, la versión en UTF-8 de cada exportación:

- Los CSV llegan mezclados: unos en UTF-16 con tabuladores, otros en UTF-8 con comas. Mira la codificación con `file -b --mime-encoding` antes de convertir; `iconv` sobre un UTF-8 lo destroza.
- Traen dos líneas de cabecera: el título y el rango de fechas. La tabla empieza en la tercera, y las filas `Total:` van al final.
- El Planificador de palabras clave exporta en UTF-16 con tabuladores y cabeceras en inglés (`Avg. monthly searches`...).
- Search Console exporta un `.zip` de CSV en UTF-8 (`Consultas.csv`, `Páginas.csv`, `Fechas.csv`...), sin líneas de cabecera extra; `Filtros.csv` dice el rango y los filtros aplicados.
- Un `.xlsx` (recomendaciones) se lee descomprimiéndolo (`xl/sharedStrings.xml`), sin openpyxl. Un `.zip` de tarjetas de la vista general se descomprime en el scratchpad.

Anota el rango de cada informe. No mezcles rangos en una misma cifra: «Desde siempre», el rango completo y el rango posterior al último cambio son tablas distintas.

## 3. Comprobar que está todo

Si la Carpeta tiene `checklist-descargas.md`, es la lista: compara lo descargado con ella. Si no, usa esta tabla y propón crear la checklist con los datos del proyecto (rutas, semillas del Planificador, URL de la landing). Di qué falta, con la ruta en la interfaz y el rango, y espera a que el usuario lo baje:

| Informe | Dónde | Rango |
|---|---|---|
| Campaña | Campañas | Desde el inicio |
| Serie temporal y tarjetas de la vista general (dispositivos, día y hora, redes) | Vista general → descargar | Desde el inicio |
| Términos de búsqueda | Estadísticas e informes → Términos de búsqueda | Desde el inicio **y** desde el último cambio |
| Palabras clave | Palabras clave → Palabras clave de búsqueda | Desde el inicio **y** desde el último cambio |
| Palabras clave negativas | Palabras clave → Palabras clave negativas | Desde siempre |
| Recursos | Recursos → Asociaciones | Desde el inicio |
| Páginas de destino | Páginas de destino | Desde el inicio |
| Ubicaciones | Ubicaciones | Desde el inicio |
| Configuración de campaña | Campañas → Configuración (la vista Campañas a secas no trae ubicación ni horario) | Solo si cambió desde la última revisión |
| Planificador de palabras clave | Herramientas → Planificador → Descubre nuevas palabras clave, con la ubicación del negocio | Últimos 12 meses, una vez al mes |
| Search Console: rendimiento | Rendimiento → Resultados de búsqueda → Exportar → Descargar CSV, con las cuatro métricas activas | Últimos 3 meses |
| Search Console: rendimiento de la landing | Lo mismo, con el filtro Página → URL de la landing | Últimos 3 meses |
| Search Console: indexación | Indexación → Páginas → Exportar | Una vez al mes |

El rango se cambia en el selector de fechas de arriba a la derecha (Personalizado) y se mantiene entre pantallas. Recuérdale al usuario que lo devuelva al rango completo después del corte.

## 4. Partir de la revisión anterior

Lee el informe más reciente de `informes/`. Sus secciones «Cambios aplicados» y «Pendiente para la próxima revisión» dicen qué hay que evaluar ahora y desde qué fecha cuenta el «después».

## 5. Cruzar con la analítica

Los clics de Ads no son visitas. Con la Analítica de `## Marketing`:

- Saca las visitas que vienen de los anuncios. Con Umami, usa `<carpeta del plugin>/scripts/umami-visitas.py` (la carpeta del plugin está dos niveles por encima de la carpeta base de este skill), con `python3 -I`, los datos de Analítica (`--url`, `--website`, `--usuario`, `--clave` con la ruta del fichero, nunca su contenido), `--desde` con el inicio de la Campaña y `--solo-cpc`. Recorre `/sessions` y su actividad, porque los filtros por parámetro de `/stats` y `/metrics` se ignoran, y da de cada visita la hora, el origen, el `utm_term`, la ciudad, el navegador, el referrer, las páginas vistas y los eventos. Pasa cada Exclusión que se pueda expresar por campos como `--excluir campo=valor,campo=valor` (`city`, `browser`, `os`, `device`, `utm_source`, `referrer`...).
- Si `## Marketing` tiene Landing, añade `--pagina` con su ruta y `--profundidad` con sus eventos en orden. El script da hasta dónde baja cada visita en la landing, por origen, con totales y porcentajes: cuántas llegan a cada sección y en cuál se quedan. Cuenta solo desde que existe la medición, que deduce del primer evento de profundidad o que se le pasa con `--medicion-desde`.
- Compara clics de Ads y visitas reales, en total y por palabra clave (`utm_term`). Si faltan muchas visitas, descarta antes las causas que no son fuga: extensiones de llamada o de ubicación (cuentan el clic sin visita), un filtro de la analítica que descarte visitas, una página pesada. Si sigue sin explicarse, dilo como hipótesis y propón la comprobación (los registros de acceso del servidor), sin darla por hecha.
- Aplica las Exclusiones de `## Marketing` (dispositivos del propio negocio, robots conocidos).
- Un referrer `syndicatedsearch.goog` son los partners de búsqueda de Google.

## 6. Analizar

Antes de recomendar nada sobre conversiones, lee el documento de Medición de conversiones de `## Marketing`: si dice que la medición es sin etiqueta de Ads, «0 conversiones» en Ads es lo esperado y la recomendación de configurarlas se descarta.

Por este orden:

1. **Volumen**: con menos de unas 50 visitas reales, ninguna tasa de conversión es concluyente. Dilo con la cifra, en vez de sacar conclusiones de 1 o 0 reservas.
2. **Antes y después del último cambio**, con las tablas de cada rango.
3. **Por palabra clave**: impresiones, clics, coste, nivel de calidad, estado («limitado») y visitas reales. Las genéricas («cerca de mí») suelen gastar sin traer visitas: quien las busca elige en el mapa.
4. **Términos de búsqueda con otra intención**: propón negativas, comprobando antes que no estén ya. Una negativa no cubre plurales ni variantes con o sin tilde: hay que poner cada forma.
5. **Presupuesto contra demanda**: impresiones diarias de la palabra que convierte frente a sus búsquedas mensuales del Planificador.
6. **Landing**, solo con lo que se puede comprobar: peso, imagen principal en diferido (`loading="lazy"`), contenido que carga tarde, qué ve el móvil sin bajar. Con la profundidad del paso 5, compara las visitas de anuncios con las de otros orígenes y con la revisión anterior, y da cuántas visitas hay detrás de cada porcentaje: con menos de unas 30, el reparto es orientativo. Si la analítica no mide hasta dónde baja el visitante, dilo: sin ese dato, «faltan fotos» o «falla el diseño» es una hipótesis.
7. **SEO desde el Planificador y Search Console**: del Planificador, volumen, competencia, tendencia a 3 meses y si ya está en la cuenta; avisa si los volúmenes parecen nacionales y no de la zona. De Search Console, posición media, impresiones y CTR orgánicos de las mismas búsquedas. Cruza las dos fuentes con Ads: una búsqueda que convierte y ya sale entre los 3 primeros resultados orgánicos necesita menos anuncio; una con muchas impresiones orgánicas y posición más allá de 10 es candidata a contenido. Si Search Console tiene pocas impresiones, dilo en vez de sacar posiciones de 2 o 3 búsquedas.

## 7. Informe en la conversación

En este orden y sin secciones vacías:

1. La respuesta a "$ARGUMENTS" en dos frases.
2. Tabla de cifras: clics en Ads, visitas reales, coste y conversiones, por rango.
3. Qué falla, por orden de importancia, cada punto con su dato.
4. Recomendaciones numeradas, cada una aplicable en la interfaz de Ads tal cual (qué palabra pausar, qué negativas añadir y con qué concordancia). Sin subir el gasto, salvo que los datos lo justifiquen.
5. SEO: lo que sale del Planificador, de Search Console y de los términos de búsqueda.

## 8. Guardar el informe

Escribe `<Carpeta>/informes/AAAA-MM-DD-revision-ads.md` (sufijo `-2` si ya existe) con el informe tal como se dio en la conversación. Añade al final:

- **Pendiente para la próxima revisión**: qué evaluar, desde qué fecha y qué comprobación quedó sin hacer.

La Carpeta no va a git: lleva cifras de gasto y datos de visitas. No hagas commit de nada de ella.

## 9. Verificar un cambio aplicado

Cuando el usuario aplica una recomendación en Ads y vuelve a exportar (o pide `/marketing:revisar-ads verificar`):

1. Ordena la descarga nueva (paso 1) y conviértela (paso 2).
2. Compara con lo propuesto en el último informe: estado (habilitada, pausada), tipo de concordancia y nivel (campaña, grupo de anuncios, lista de negativas). Di qué coincide y qué no, uno por línea.
3. Añade al informe una sección **Cambios aplicados** con la fecha, lo aplicado y lo que falta. Es la fecha desde la que la siguiente revisión cuenta el «después».

## 10. Cerrar

Pregunta qué recomendaciones convertir en issue. Solo tras confirmación invoca `dev:crear-issue` (Skill tool), uno por cambio de la web o del contenido. Lo que se aplica en la interfaz de Ads no lleva issue: queda en el informe.
