---
name: revisar-docs
description: Comprueba si los cambios de un issue (o los commits sin subir) dejan documentación desactualizada, y la corrige
argument-hint: número de issue (opcional; sin él, los commits aún no subidos)
---
Auditoría de documentación tras un cambio, para que la documentación del proyecto siga siendo fiel al código. Lee antes la sección `## Método` del `CLAUDE.md` del proyecto (mapa de documentación, repos relacionados).

Si `## Método` indica **Repo**, todos los comandos `gh` llevan `-R <repo>`, y `doc/`, el código, la Verificación y los commits son los de la carpeta que indica, no los de la raíz del proyecto. Con **Repos por área**, el repo, la carpeta y la Verificación son los del área del issue, con las reglas de [Repos por área](../../README.md#repos-por-área).

1. **Alcance del cambio**:
   - Con "$ARGUMENTS": los commits del repo (y de los repos relacionados, si el issue los tocó) con pie `Issue: #$ARGUMENTS` (`git log --grep '^Issue: #$ARGUMENTS$' --format=%H`), más el diff sin commitear.
   - Sin argumento: `git log origin/main..HEAD` + el diff sin commitear.
   Si no hay ningún cambio, dilo y termina.
2. **Superficie afectada**: anota cada elemento nuevo, renombrado o eliminado que tenga un sitio fijo en la documentación según el Mapa de documentación del proyecto. Sin mapa, revisa al menos: variables de entorno (`.env.example`), scripts y comandos (`README.md`, `CLAUDE.md`), skills de `.claude/` (metodología, si la hay), decisiones de arquitectura (`doc/A2-ADR/`). Busca además con `grep` (rutas absolutas) en `doc/`, `README.md`, `CLAUDE.md` y los `.env.example` cada nombre eliminado o renombrado: cualquier mención que quede es una referencia rota. Si cambió una ADR, la primera palabra de su `## Estado` y su fila del índice `doc/A2-ADR/README.md` tienen que decir lo mismo.
3. **Mapa de cobertura**, antes de editar nada, un elemento por línea:
   `elemento — ✅ documentado y correcto | ⚠️ desactualizado (dónde) | ❌ sin documentar (dónde debería ir)`.
4. **Corregir**:
   - En `doc/`, `README.md` y `.env.example` del repo: aplica las correcciones ⚠️ y añade lo ❌ cuando el documento de destino ya exista. Lee el fichero entero antes y sigue su estilo. Estado actual, sin "antes era X" ni fechas de decisión.
   - No crees documentos nuevos para cubrir un ❌: si no hay sitio adecuado, déjalo como hueco en el informe.
   - `CLAUDE.md`, lo que haya bajo `.claude/` y los repos relacionados: propón el cambio exacto y espera confirmación.
   - Los diagramas desactualizados solo se señalan.
5. **Commit** local de lo aplicado: `docs(ámbito): resumen breve`, con pie `Issue: #$ARGUMENTS` si se pasó issue. Nunca push.
6. **Informe**: mapa de cobertura final, qué se corrigió (una línea por fichero), qué queda pendiente de confirmación y qué huecos no tienen documento.

Si todo está ✅, dilo en una línea y no hagas commit.

Si lo ha invocado otro skill (`resolver-issue`, `sprint`...), este informe es un paso de su ciclo, no el final del turno: al acabar, vuelve a ese skill y sigue con su paso siguiente.
