# Formato de las bóvedas de Obsidian

`metodo.css` es el fragmento CSS común de todas las bóvedas: texto a 65 caracteres y centrado, tablas compactas que miden lo que necesitan (centradas, como mucho el ancho del panel) y bloques de código alineados con el texto que crecen hacia la derecha. El ancho del texto se cambia en `--ancho-texto`.

## Llevarlo a una bóveda

1. Enlazarlo, para que un cambio aquí llegue a todas (`.obsidian/` está fuera de git en los repos de las bóvedas):

   ```sh
   mkdir -p <bóveda>/.obsidian/snippets
   ln -s <ruta a Metodo>/estilo/obsidian/metodo.css <bóveda>/.obsidian/snippets/metodo.css
   ```

2. Ajustes que lo acompañan:
   - `.obsidian/app.json`: `"readableLineLength": true` (el fragmento solo actúa con la longitud de línea legible activada).
   - `.obsidian/appearance.json`: `"enabledCssSnippets": ["metodo"]`, sin los fragmentos anteriores.
3. Activarlo a mano en Obsidian: Ajustes → Apariencia → Fragmentos CSS. Editar `appearance.json` con Obsidian abierto no lo activa.
4. Comprobar con `prueba-formato.md` (párrafo largo, tabla de dos columnas, tabla de diez, bloque de código, propiedades), en modo lectura y en edición.

Obsidian no ve los cambios de `metodo.css` mientras está abierto: el fragmento es un enlace y lo que cambia es el fichero de destino, fuera de la bóveda. Para verlos hay que cerrar y volver a abrir Obsidian.

## Bóvedas que lo usan

La lista de las bóvedas de cada máquina va en `local/proyectos.md` del repo del método, ignorado por git. En las bóvedas `<Raíz>_notas`, que se regeneran con `.regenerar.py`, el enlace de `.obsidian/` sobrevive a cada regeneración porque el script se salta las entradas que empiezan por punto.
