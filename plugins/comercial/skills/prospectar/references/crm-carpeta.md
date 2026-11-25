# Paso 5 · Dejar las cuentas en un CRM local con carpeta de entrada

Un CRM local de este tipo importa cada fichero que entra en su carpeta de entrada, y el usuario lo revisa y lo consolida desde su propio panel. Este skill solo deja el fichero; el usuario decide qué entra.

## Qué se usa de su MCP

Si el campo CRM de `## Prospección` nombra un MCP, este skill solo usa las dos herramientas de lectura que nombra: la de búsqueda de contactos (paso 2, para no prospectar dos veces a la misma empresa) y la de recordatorios pendientes (informe). Si una no aparece entre las herramientas conectadas, el paso que la necesita lo dice y sigue sin ella (paso 2) o para (informe). Nunca se usa una escritura del MCP desde este skill.

## Orden de trabajo

1. **Comprobar:** que `cuentas.json` pasa `exportar.py` sin errores y que la carpeta de entrada de `## Prospección` existe. Si no existe, dilo y deja el CSV como entregable.
2. **Copiar:** vuelve a ejecutar el script con `--entrada <carpeta de entrada>`. Copia `cuentas.json` como `prospeccion-AAAA-MM-DD.json` (con `-2`, `-3`... si ya hay uno ese día) y no pisa nada.
3. **Informar:** tabla empresa · prioridad · fecha del primer contacto · ya en el CRM (sí/no, si hay herramienta de búsqueda), y el siguiente paso del usuario: importar el fichero desde el panel del CRM, revisarlo y consolidarlo.

La fecha del primer contacto va en la tabla y en el CSV. Si el CRM no crea el recordatorio al importar, el usuario lo apunta a mano desde su panel: dilo en una línea.
