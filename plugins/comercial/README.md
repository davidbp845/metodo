# Plugin `comercial`

Prospección B2B del negocio de un proyecto, de punta a punta: cliente ideal, empresas con una señal que se puede abrir, primer contacto, carga en el CRM e informe diario. El skill es el mismo para todos los proyectos; lo que cambia entre negocios lo lee de la sección `## Prospección` del `CLAUDE.md` del proyecto.

Se instala con `/plugin install comercial --marketplace davidbp845/metodo`.

| Skill | Qué hace |
|---|---|
| `/comercial:prospectar` | Pasos 0 a 5: ficha del negocio, cliente ideal y señales, 15–20 candidatas calificadas A/B/C, fichas de las 10 mejores, mensajes con la rúbrica, HTML y CSV con `scripts/exportar.py`, y cuentas en el CRM. Con `informe`, el informe comercial del día, solo de lectura |

Procede de la skill `prospeccion-crm-ia` del taller de emprendeduría, cedida por el ponente para usarla y modificarla libremente. La original sigue en claude.ai para el ámbito del taller; esta versión está en castellano, saca el negocio a `## Prospección` y cambia HubSpot por un CRM local con carpeta de entrada. Las dos no compiten al activarse: esta solo se usa en proyectos con `## Prospección`.

Principios que no cambian entre proyectos: nada inventado, cada señal con URL y fecha, nunca se deducen correos ni teléfonos personales y nunca se envía nada.

## Carpeta de datos

Las tandas llevan el embudo comercial y los borradores de los mensajes, así que no van a ningún repo: la Carpeta está en el `.gitignore` del proyecto.

```
<Carpeta>/AAAA-MM-DD/
├── cuentas.json        # lo que monta el skill; formato en el comentario inicial de exportar.py
├── prospeccion.html    # fichas y mensajes con botón de copiar
└── prospeccion.csv     # 13 columnas, UTF-8, con la fecha del primer contacto
```

Con CRM, `exportar.py --entrada <ruta>` copia además `cuentas.json` a la carpeta de entrada del CRM como `prospeccion-AAAA-MM-DD.json`, sin pisar nada. De ahí sigue el flujo del CRM: importar, revisar y consolidar desde su panel.

## Sección `## Prospección` del proyecto

El skill la lee al empezar. Si falta, o le falta el Negocio, la Zona o la Carpeta, lo dice y para.

```markdown
## Prospección

- Negocio: `https://ejemplo.org`; mantenimiento de climatización para clínicas y comercios
- Cliente ideal: clínicas privadas de 5 a 50 empleados de la Zona; decide la gerencia; problema: averías en verano; compran al abrir o reformar
- Zona: Ciudad y comarca
- Idioma: castellano
- Carpeta: `prospeccion/` (ignorada por git)
- CRM: entrada en `../agenda/datos/entrada/`; MCP `agenda`, búsqueda `buscar_contacto`, recordatorios `recordatorios_pendientes`
- Límites: 6 búsquedas, 12 páginas, ventana de 6 meses
```

| Campo | Obligatorio | Uso |
|---|---|---|
| Negocio | Sí | Web, o qué vende y a quién en tres líneas, más las pruebas que puede citar (clientes, casos, años). De aquí sale la ficha del negocio (paso 0) |
| Cliente ideal | No | Los 6 campos ya validados (sector, tamaño, zona, quién decide, problema, qué le hace comprar ahora). Sin él, el paso 1 los propone |
| Zona | Sí | Dónde trabaja el negocio; filtra las candidatas |
| Idioma | No | Idioma de los mensajes a los clientes. Sin él, castellano. Las respuestas y las fichas van siempre en castellano |
| Carpeta | Sí | Dónde viven las tandas, relativa a la raíz del proyecto |
| CRM | No | Carpeta de entrada de un CRM local que importa lo que entra en ella. Opcionales: el MCP del CRM y sus herramientas de lectura de búsqueda de contactos y de recordatorios pendientes. Sin el campo, el CSV es el entregable |
| Límites | No | Búsquedas y páginas por tanda y ventana de las señales. Sin él, 6, 12 y 6 meses |
