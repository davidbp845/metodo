# Método común (all projects)

What repeats across projects lives once in `{{DATA_NATIVA}}/Metodo`
(git), not copied into each project:
- Writing rules for docs, issues, code comments, commits and replies:
  @{{DATA_NATIVA}}/Metodo/estilo/redaccion.md
- Layout and CSS rules for any web page:
  @{{DATA_NATIVA}}/Metodo/estilo/diseno-web.md
- Development cycle with a GitHub Projects board: plugin `dev@metodo`
  (`/dev:crear-issue`, `/dev:sprint`, `/dev:resolver-issue`, `/dev:retro`...). Each project
  provides its data in a `## Método` section of its `CLAUDE.md`; the contract is in
  `Metodo/plugins/dev/README.md`.

An improvement to a shared skill or rule is made in `Metodo`, once — never in a project-local
copy. When a project's feedback memory turns out to apply to every project, propose moving
it to `Metodo` instead of leaving it siloed. A new file under `estilo/` only applies once
`Metodo/maquina/CLAUDE.plantilla.md` imports it with `@` and the config is reinstalled
(`maquina/instalar.sh --sobrescribir`); `~/.claude/CLAUDE.md` is generated, not edited by
hand. Once moved, the rule is deleted from the project memory. Editing `Metodo` follows the same rules as any
other project repo (local, reversible via git).

# A project's own MCP server (all projects)

A project's MCP server (in its `.mcp.json`) starts when Claude Code opens and does not reload
modules: after changing that project's code in the session, its `mcp__<project>__*` tools keep
running the old code. To check a change, use the project's CLI or ask the user to restart
Claude Code (or reconnect the server with `/mcp`); never trust an MCP result as verification
of code edited in the same session.

# Demo mode (all projects)

A project with a `Demo` field in its `## Método` has a file that picks real or demo data. Read
that file before any action that writes through the app (CLI, MCP, panel): it says whether the
action touches real data. A variable in the `Demo` field can force the mode for one command
only; an MCP server follows the file, not the variable. Claude may propose switching the mode,
but switches it only with the user's confirmation (a hook of plugin `dev` asks before any edit
of that file). Changes are verified in demo, never against real data.

# Autonomous Operation Policy (all projects)

Applies to every project under `{{PROYECTOS}}`,
and to the shared method repo `{{DATA_NATIVA}}/Metodo`.
A project's own `CLAUDE.md` may add rules of its own; it should not contradict this one.

Projects are tracked in git. Local, reversible changes can always be undone with
`git checkout` or by deleting an untracked file, so do NOT ask for approval before the
actions listed below. Act autonomously and report back with a summary when done.

The lists below are kept coherent with the enforcement in `~/.claude/settings.json`
(`permissions.allow/ask/deny`). If the two ever disagree, `settings.json` is what actually
fires — this section documents intent, not enforcement.

## Safe to do without asking (local, reversible via git)
- Read, search, and analyze any file in the project — except `.env` files and anything
  under a `secrets/` directory, which are blocked outright (see below).
- Create, edit, or delete files within the project working tree — except `.env` files,
  `CLAUDE.md` files, and anything under `.claude/` (settings, commands, skills...), which
  need confirmation or are blocked (see below).
- Implement features, refactor code, or fix bugs across any number of files.
- Run the test suite and any linters/formatters/type checkers.
- Run build commands.
- Install/update dependencies already declared in the project (`npm install`, `npm ci`,
  `pip install -r requirements.txt`) when they only modify local lockfiles/manifests
  tracked in git.
- Run scripts defined in the project's `package.json`.
- Create local git branches, `git add`, `git commit`, view `git diff`/`git log`/`git status`,
  and stash changes.
- After committing in a submodule whose parent is a local-only container, update the
  submodule pointer in the container (`git add <submodule>` and a commit of its own, with
  only the pointer). One pointer commit per task, when it's done, not one per submodule
  commit.
- `git push` (non-force) to `origin` of a project owned by the user.
- Read GitHub issues and pull requests (`gh issue list/view`, `gh pr list/view/diff`).
- Create or comment on GitHub issues to report progress or findings.
- Close an issue (moving it to *In review*) when a skill designed for it does so
  (`/cerrar-issue*`, `/resolver-issue`, `/sprint`, `/resolver-retoques-*`) or when the
  user explicitly asks. Anywhere else, propose the closure and wait for confirmation.
  Never move an issue to *Done* on my own: the flow ends at *In review* so the user's
  review isn't skipped. A hook of plugin `dev` asks for confirmation on any move to *Done*,
  except for an issue closed as *not planned*.
- Run scripts/commands that only read data (no external side effects), e.g. a read-only
  API or a query against a local/dev database.

## Blocked entirely (enforced in `settings.json`, not even askable in-session)
- `git push --force` to any remote.
- `git reset --hard` / `git clean -fd` — even when nothing uncommitted is at risk. If one
  is genuinely the right fix, ask the user to run it themselves rather than working
  around the block.
- `rm -rf` in any form — same reasoning: ask the user to run it.
- Reading any `.env` file, or anything under a `secrets/` directory — even to check a
  non-secret value. If something is needed from one, ask the user to paste the specific line.
- Editing any `.env` file.
- Known limit: the `.env`/`secrets/` block covers the Read/Edit tools and the common
  Bash readers (`cat`, `head`, `tail`, `grep`, `jq`) when the path is named. It can't stop
  an indirect read (`grep -r x .`, `find . -exec cat`). Don't rely on it as a sandbox, and
  never do such a read on purpose.
- A `deny` on a path, including the per-machine ones in `metodo-maquina.json`, makes that
  path off-limits for every tool, not only the one the rule names: no `ls`, `stat`, `find`
  or `du` on it, and no disk-wide search that would sweep into it. If a task seems to need
  something there, ask first.

## Still requires explicit confirmation
- Merging pull requests.
- Deleting a GitHub issue.
- Deleting or renaming remote branches, closing or reopening pull requests, reopening
  issues, changing labels/milestones in bulk.
- Publishing packages (`npm publish`), bumping the package version (`npm version`),
  tagging releases, or anything that touches a production/staging environment or
  deployment pipeline.
- Modifying CI/CD configuration or any secrets/environment-variable store other than a
  local `.env` file (that one is blocked outright).
- Editing a `CLAUDE.md` or anything else under `.claude/`.
- Installing global packages or anything that changes the system outside the project
  directory.
- Destructive database migrations or manual schema/data changes, and any command against
  a production/shared (non-local) database.
- Running tests or the app in a way that writes to a local database whose data isn't
  tracked in git.
- Running anything that talks to a real external service (calendars, messaging bots,
  payment providers...) unless the project's own docs say its credentials point to a
  development environment.

## General principle
If an action is fully contained inside the project's git repository and any mistake can be
undone with git or by deleting an untracked file, proceed without asking. If it affects
anything outside the repo (remote git history, GitHub issue/PR state, external services,
published artifacts, production systems), ask first. The items enforced as `deny`/`ask` in
`settings.json` fire regardless of this principle — they're a hard floor, not a default
that good judgment can override.
