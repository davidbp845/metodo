---
name: crear-decision
description: Registra una ADR y, si implica código, su issue de implementación
argument-hint: la decisión a registrar, en una frase
---
Registra una decisión de arquitectura para "$ARGUMENTS". Las ADR viven en `doc/A2-ADR/` (si el proyecto aún no tiene esa carpeta, pregunta antes de crearla).

Si `## Método` indica **Repo**, todos los comandos `gh` llevan `-R <repo>`, y `doc/`, el código, la Verificación y los commits son los de la carpeta que indica, no los de la raíz del proyecto. Con **Repos por área**, el repo, la carpeta y la Verificación son los del área del issue, con las reglas de [Repos por área](../../README.md#repos-por-área).

1. Comprueba si contradice o sustituye una ADR existente de `doc/A2-ADR/`. Si es así, la antigua pasa a "Superada por ADR-NNNN" (en su Estado y en el índice) y la nueva la cita en el Contexto.

   **Formato que se lee desde fuera** (la página ADR de la Lanzadera lee los ficheros, no el índice): la primera línea es `# NNNN — Decisión`, y la sección `## Estado` empieza por una de estas palabras: `Propuesta`, `Aceptada`, `Superada` o `Rechazada`. Detrás, texto libre (fecha, matices). Los issues relacionados van en esa misma sección, como `#NN` (del repo del proyecto), `owner/repo#NN` o enlace `https://github.com/owner/repo/issues/NN`. Que esté implementada no se escribe: sale de si sus issues están cerrados.
2. Toma el siguiente número correlativo de los ficheros existentes en `doc/A2-ADR/` (`0001-*.md`, `0002-*.md`...).
3. Redacta `doc/A2-ADR/NNNN-titulo-corto.md` con cinco secciones: Contexto (qué fuerza la decisión) · Decisión · Alternativas consideradas y por qué se descartaron · Consecuencias (qué se vuelve más fácil o más difícil) · Estado (empieza en "Propuesta"). Si falta contexto real para las Alternativas o las Consecuencias, pregunta antes de rellenarlas.
4. Añade la decisión, con su Estado, al índice de `doc/A2-ADR/README.md`.
5. Si la decisión implica trabajo de código, crea el issue de implementación con el skill `dev:crear-issue` (Skill tool): cuerpo basado en la Decisión y las Consecuencias, citando el fichero de la ADR. Si la ADR afecta a un repo relacionado concreto, créalo también en su tablero. Pon Status = **Ready**, no Backlog: el diseño técnico ya está en la ADR. Enlaza en los dos sentidos: el número de issue en el Estado de la ADR ("Propuesta — issue #NN", o `owner/repo#NN` si el issue es de otro repo) y el fichero de la ADR en el cuerpo del issue. Si solo cambia documentación o criterio, no hay issue.
6. Haz commit local de la ADR y el índice (`docs(adr): ...`). Nunca push.
7. Invoca el skill `dev:revisar-docs` (Skill tool) sin argumento, para que `CLAUDE.md`, el README y el resto de `doc/` que describan lo mismo reflejen la decisión.
8. Confirma con un resumen: fichero de la ADR, ADR superadas si las hay, issues creados con sus enlaces, y que los commits quedan locales.

Si la decisión no está clara, pregunta antes de inventar el Contexto o las Alternativas.
