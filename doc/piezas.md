# Cómo encajan las piezas

En una misma sesión, Claude combina piezas que se cargan desde sitios distintos y no están todas en todas partes. Este documento dice qué es cada una, cuándo está disponible y cuál se usa cuando dos sirven para lo mismo. Cómo se instala cada una está en [`README.md`](../README.md), [`maquina/README.md`](../maquina/README.md) y [`plugins/dev/README.md`](../plugins/dev/README.md); el mapa de ficheros, en [`maquina/ficheros.md`](../maquina/ficheros.md).

## Las piezas

| Pieza | Qué es | Desde dónde se carga | En qué sesiones está | Para qué sirve | Qué no puede hacer |
|---|---|---|---|---|---|
| Método | Reglas de `estilo/` y plugin `dev@metodo` (`/dev:*`), con los datos de cada proyecto en su `## Método` | `CLAUDE.md` global y plugin a nivel de usuario, generados con `maquina/instalar.sh` | Todas | Escribir igual en todos los proyectos y llevar el ciclo issue → In review en el tablero | Saber lo propio de un proyecto: eso lo pone su `## Método` |
| `CLAUDE.md` del proyecto | Instrucciones del proyecto | Su carpeta | Solo las abiertas en esa carpeta (o debajo) | Reglas del dominio, verificación, modo demo | Valer fuera de su carpeta: una sesión en otro proyecto no lo ve si no lo lee a propósito |
| Memoria | Recuerdos de Claude por proyecto (`~/.claude/projects/<proyecto>/memory/`) | `MEMORY.md`, al empezar sesión | Solo las de ese proyecto | Estado pendiente y preferencias aprendidas que no están en el repo | Compartirse entre proyectos ni entre máquinas; lo que vale para todos se pasa a `Metodo` |
| Skills y comandos del proyecto | `.claude/commands/`, `.claude/skills/` | Su carpeta | Solo las de ese proyecto | Flujos propios que el plugin no cubre | Usarse desde otro proyecto |
| MCP de proyecto | Servidor de herramientas de una app (`.mcp.json`) | Su carpeta, al abrir Claude Code | Solo las de esa carpeta, salvo que se cargue a nivel de usuario (abajo) | Actuar con la lógica y los datos de la app (su modo demo, sus permisos) | Recargar código: tras editar la app hay que reconectarlo (`/mcp`) |
| MCP de proyecto a nivel de usuario | El mismo servidor, declarado en `mcpServers` de `metodo-maquina.json` | `~/.claude.json`, registrado por `instalar.sh` | Todas | Tener la app a mano desde cualquier proyecto | Traer las reglas del proyecto: el `CLAUDE.md` global obliga a leer su `CLAUDE.md` antes de usarlo, y sus permisos se copian en `metodo-maquina.json` |
| Conectores de claude.ai | Gmail, Claude Docs... de la cuenta de claude.ai | La cuenta, al iniciar sesión | Todas las de esa cuenta | Servicios en la nube que no tienen app local | Ver los MCP de proyecto ni los datos locales; se usan con los permisos de la cuenta, no con los del proyecto |
| Claude in Chrome | Extensión que actúa en el Chrome del usuario, con sus sesiones abiertas | `/chrome` | La sesión que lo activa | Consolas web de proveedores, pruebas reales en una web, comprobar lo que los tests simulan | Escribir contraseñas ni crear claves o tokens: eso lo hace el usuario |
| Subagentes | Trabajos en paralelo dentro de una sesión | Los lanza la sesión (`/dev:sprint`, `/code-review`) | La que los lanza | Issues independientes en worktrees propios, revisiones de código | Lanzarse sobre issues del mismo flujo a la vez: chocan al juntarlos |
| `gh` y el tablero | CLI de GitHub y GitHub Projects | Instalado en la máquina, con `gh auth login` | Todas | Issues, Status del tablero, PR, releases | Nada fuera de GitHub |

## Qué pieza para cada cosa

Cuando dos piezas sirven para lo mismo, se usa la que trae la lógica y las reglas de la app; la genérica queda de respaldo.

| Para... | Se usa | De respaldo |
|---|---|---|
| Correo (leer, clasificar, borradores) | El MCP del proyecto de correo, a nivel de usuario | Conector de Gmail, para una cuenta que el MCP no tenga |
| Un documento o un formato de otro proyecto | Su MCP, si está cargado; si no, su CLI | Llamar a su código desde la sesión, como último recurso |
| Configurar un servicio externo | Claude in Chrome, en la consola del proveedor | Pasos escritos para que los haga el usuario |
| Recordar algo pendiente de un proyecto | Su memoria; si es un paso de puesta en marcha, su documentación | — |
| Una regla que vale para todos los proyectos | `Metodo` (`estilo/` o un skill) | — |

Un MCP de proyecto se carga a nivel de usuario cuando se usa a menudo desde otros proyectos. Si solo se usa trabajando en su app, se queda en su `.mcp.json`.

## Un caso real

Una sesión sobre hacer bidireccional la integración de calendario de una app usó casi todas las piezas:

1. **Análisis y decisión**: conversación sobre el diseño y `/dev:crear-issue` para abrir los issues.
2. **Sprint con subagentes**: `/dev:sprint` resolvió un issue en un worktree con un subagente mientras la sesión hacía el otro, con su ADR, y `/dev:revisar-docs` al cerrar cada uno.
3. **Publicar versión**: `/dev:publicar-version` lanzó `/code-review` antes de etiquetar. Los fallos que salieron (servicio externo caído, datos cambiando a la vez, dos issues paralelos del mismo flujo) volvieron al Método como cambios del ciclo.
4. **Claude in Chrome**: comprobó la configuración en la consola del proveedor, preparó un calendario de pruebas e investigó un comportamiento que solo destapó la prueba real. Las claves y contraseñas las puso el usuario.
5. **Prueba en local**: un arranque fallido por una ruta relativa en el `.env` acabó en un arreglo para que una credencial ilegible no tumbe la app.
6. **Correo**: el mensaje se maquetó con el código de otro proyecto, porque su MCP no estaba cargado en esa carpeta, y se dejó como borrador con el conector de Gmail. Con el MCP de correo a nivel de usuario, las dos cosas habrían salido de él.
7. **Memoria y documentación**: lo pendiente quedó en la memoria del proyecto y los pasos de puesta en marcha en su documentación.
