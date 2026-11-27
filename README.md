# Método

Fuente única de lo que se repite entre proyectos: skills, plantillas y reglas de redacción. Un proyecto no copia nada de aquí; declara qué usa y lo carga.

**Beta.** Se usa a diario, pero los skills todavía cambian a menudo y aún no cumple los criterios de una versión estable: varias semanas sin cambios de fondo en los skills, sin regresiones en los proyectos que lo usan y una adopción que funcione solo con este README. Licencia MIT ([`LICENSE`](LICENSE)); `plugins/dev/skills/developing-with-streamlit/` conserva su Apache 2.0.

## Qué hay

| Ruta | Qué es | Cómo llega a cada proyecto |
|---|---|---|
| `estilo/redaccion.md` | Reglas de escritura para docs, issues, comentarios y respuestas | Importado con `@` desde el `CLAUDE.md` global (`maquina/CLAUDE.plantilla.md`): se aplica en todos los proyectos |
| `estilo/diseno-web.md` | Reglas de maquetación: tipografía y espaciado fluidos, layouts flexibles, mobile first | Importado con `@` desde el `CLAUDE.md` global (`maquina/CLAUDE.plantilla.md`): se aplica en todos los proyectos |
| `estilo/proporcion.md` | Esfuerzo proporcional: cuándo profundizar, cuándo ir breve y qué no se recorta nunca | Importado con `@` desde el `CLAUDE.md` global (`maquina/CLAUDE.plantilla.md`): se aplica en todos los proyectos |
| `estilo/obsidian/` | Fragmento CSS común de las bóvedas de Obsidian (`metodo.css`) y cómo enlazarlo y activarlo | Enlazado desde `.obsidian/snippets/` de cada bóveda |
| `maquina/` | Plantillas del `CLAUDE.md` global y de `settings.json`, hooks de usuario, `instalar.sh` y las sesiones desatendidas (`desatendido/`) | Generados en `~/.claude` de cada máquina con `maquina/instalar.sh`; el temporizador desatendido, con `--desatendido` (ver `maquina/README.md`) |
| `doc/piezas.md` | Cómo encajan el Método, los MCP de proyecto, los conectores de claude.ai, Chrome, los subagentes y la memoria, y cuál se usa para cada cosa | No llega: se lee desde aquí |
| `doc/A2-ADR/` | Decisiones de arquitectura del propio método | No llega: se lee desde aquí |
| `.github/workflows/verificacion.yml` | Workflow reutilizable de GitHub Actions que pasa la Verificación de un proyecto Python en cada push | Lo llama el `ci.yml` del proyecto (ver abajo) |
| `local/` | Lo que es de una máquina o de una persona, ignorado por git: retros agregadas del método (`local/retros/`, de `/dev:retro-metodo`), tabla de proyectos y bóvedas de la máquina (`local/proyectos.md`), apps modelo de la guía Streamlit (`local/streamlit.md`), barridos de `/dev:siguiente` que un proyecto ya cumple (`local/barridos.md`) y evidencia de los patrones de `/dev:cosechar` (`local/cosechas/`) | No llega: los skills lo leen desde aquí si existe y, si no, usan valores genéricos |
| `plugins/dev/` | Ciclo de desarrollo con tablero de GitHub (`/dev:crear-issue`, `/dev:sprint`, `/dev:retro`...) y parte común de la metodología en tres niveles (`metodologia.md`) | Plugin `dev@metodo`, instalado a nivel de usuario |
| `plugins/marketing/` | Revisión de campañas de Google Ads cruzadas con la analítica web (`/marketing:revisar-ads`); datos de cada proyecto en su `## Marketing` (`plugins/marketing/README.md`) | Plugin `marketing@metodo`, activado solo en los proyectos que lo usan |
| `plugins/comercial/` | Prospección B2B de punta a punta, del cliente ideal al CRM, con informe diario (`/comercial:prospectar`); datos de cada negocio en su `## Prospección` (`plugins/comercial/README.md`) | Plugin `comercial@metodo`, activado solo en los proyectos que lo usan |

Este directorio es a la vez un marketplace de plugins de Claude Code (`.claude-plugin/marketplace.json`), registrado desde su ruta local. Las ediciones se aplican al empezar sesión o con `/reload-plugins`, sin publicar nada.

## Cómo se instala en una máquina

`maquina/instalar.sh` deja una máquina nueva (Linux, o Windows con Git Bash) con el `CLAUDE.md` global, los permisos, los hooks, los servidores MCP de usuario de la máquina y el plugin `dev@metodo`. Pasos y opciones en `maquina/README.md`.

## Cómo se adopta en un proyecto

0. El proyecto tiene su tablero en GitHub Projects. Se crea copiando uno existente, que trae los Status del ciclo y los campos Priority y Size sin las tarjetas: `gh project copy <número> --source-owner <owner> --target-owner <owner> --title "Nombre"`. Después se enlaza al repo con `gh project link <nuevo> --owner <owner> --repo <owner>/<repo>`. Si el código está en un submódulo, se enlaza al repo del submódulo.
1. El `CLAUDE.md` del proyecto tiene una sección `## Método` con sus datos (tablero, verificación, metodología...). El contrato está en `plugins/dev/README.md`.
2. Se borran las copias locales de los comandos que el plugin ya cubre (`.claude/commands/sprint.md`, etc.). Lo que sea propio del proyecto se queda en su `.claude/commands/`.
3. Lo que solo cambia en un proyecto (una verificación extra, un mapa de documentación) va en su sección `## Método`, no en una copia del skill.
4. Si tiene tests, su CI llama a la Verificación reutilizable, para que no dependa de que la sesión se acuerde de pasarlos. Es un `.github/workflows/ci.yml` del proyecto, que se confirma con el usuario antes de crearlo:

   ```yaml
   name: CI
   on:
     push:
       branches: [main]
     pull_request:
       branches: [main]
   concurrency:
     group: ci-${{ github.ref }}
     cancel-in-progress: true
   jobs:
     verificacion:
       uses: davidbp845/metodo/.github/workflows/verificacion.yml@main
       permissions:
         contents: write
       with:
         python-version: "3.12"                 # la de producción, si la hay
         instalar: pip install -r requirements-dev.txt
         verificacion: |                        # los comandos de su Verificación, sin el venv local
           python -m pytest
         rama-verificada: produccion            # opcional
   ```

   Con `rama-verificada`, un push a `main` que pasa la Verificación avanza esa rama hasta el commit. Si el servidor despliega desde ella y no desde `main`, solo le llega código con los tests en verde, sin guardar ningún token para consultar el CI. `Metodo` es público, así que cualquier repo puede llamar a sus workflows.

## Cómo se mejora

Una mejora del ciclo se hace aquí, una vez, y llega a todos los proyectos. Si una memoria de feedback de un proyecto resulta valer para todos, se pasa a `estilo/redaccion.md` o al skill que corresponda, y se borra de la memoria del proyecto. Un fichero nuevo en `estilo/` solo se aplica cuando `maquina/CLAUDE.plantilla.md` lo importa con `@` y se reinstala la configuración (`maquina/instalar.sh --sobrescribir`).

## Varias personas y sistemas

El método va a servir a cualquier persona en Linux, Windows o macOS, cada una con sus datos y en uno de dos papeles:

- **Usuario**: arranca y usa aplicaciones con la Lanzadera en el perfil `usuario`. No necesita el plugin `dev`, ni tablero, ni `gh`.
- **Desarrollador**: además, trabaja con el ciclo de `dev@metodo` y su tablero.

En la Lanzadera, el soporte de macOS y el perfil de usuario son los ADR [0018](https://github.com/davidbp845/lanzadera/blob/main/doc/A2-ADR/0018-lanzadera-en-macos.md) y [0019](https://github.com/davidbp845/lanzadera/blob/main/doc/A2-ADR/0019-perfil-de-usuario-final.md), en propuesta. En el método, hoy todavía hay cosas que dan por hecho una sola persona en Linux o Windows:

1. **Un solo papel**: `instalar.sh` instala siempre el plugin `dev` y exige `gh`. El papel de usuario solo necesita el `CLAUDE.md` global, las reglas de `estilo/` y los permisos.
2. **macOS**: `maquina/instalar.sh` ya instala la configuración en un Mac. Los scripts de `plugins/dev/scripts/` y el temporizador de las sesiones desatendidas (launchd) están adaptados a macOS y a su bash 3.2, pero todavía no se han probado en uno.
