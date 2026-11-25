---
name: publicar-version
description: Sube la versión, crea la etiqueta y publica la release de GitHub, con confirmación antes de etiquetar
argument-hint: commit o rama a etiquetar (opcional; por defecto la punta de la rama principal)
---
Publica una versión nueva del proyecto sobre "$ARGUMENTS" (si está vacío, la punta de la rama principal). Lee antes la sección `## Método` del `CLAUDE.md` del proyecto.

Si `## Método` indica **Repo**, todos los comandos `gh` llevan `-R <repo>`, y el fichero de la versión, las etiquetas y los commits son los de la carpeta que indica, no los de la raíz del proyecto.

Si `## Método` no tiene el campo **Versionado**, di que el proyecto no versiona y termina sin tocar nada: versionar es una decisión del proyecto, no de este skill.

1. **Datos del proyecto.** Del campo Versionado:
   - **Minor**: cuándo un cambio sube minor. Lo que no lo cumple es patch. Major solo si el subcampo **Major** lo define o el usuario lo pide; mientras la versión sea `0.x`, nunca se propone.
   - **Fichero**: dónde vive el número. Sin él, `pyproject.toml` (`version` de `[project]`) o `package.json` (`version`), el que exista en la raíz; si hay los dos o ninguno, pregunta.
   - **Apartado de minor**: título del apartado escrito a mano que acompaña a una minor en la release. Sin él, una minor no lleva apartado.
   - **Review**: nivel del skill `code-review` del paso 5 (`low`, `medium`, `high`, `xhigh`, `max`), o `no` para saltarlo. Sin él, el nivel depende del tipo de versión: `low` en un patch, `medium` en una minor y `high` en una major. Cuanto más cambia para quien usa el proyecto, más cuesta un fallo publicado.
2. **Estado del repo.** `git status --short` limpio, rama principal, y al día con `origin` (`git fetch origin` y comparar con `origin/<rama>`). Si hay cambios sin commit, la rama es otra o va por detrás o por delante del remoto, dilo y para: la etiqueta tiene que caer en un commit que ya esté en el remoto, y lo que haya sin subir puede ser de otra sesión.
3. **Última versión.** `git describe --tags --abbrev=0 --match 'v[0-9]*'`. Lee también el número del Fichero en la punta.
   - Con etiqueta previa: `git log --format='%h %s' <etiqueta>..<commit>`. Si no hay commits, no hay nada que publicar: dilo y termina.
   - Sin etiqueta previa: la primera es `v0.1.0`, salvo que el Fichero ya declare otro número, que manda. Pregunta sobre qué commit va si el usuario no lo ha dicho: la primera versión suele marcar lo que ya corre en producción, que no tiene por qué ser la punta.
4. **Tipo de versión.** Clasifica cada commit con el criterio Minor (lee el diff con `git show --stat` cuando el asunto no basta: un campo de configuración o una migración no siempre se nombran en el asunto) y decide si la versión es patch, minor o major. De ahí salen el número siguiente y, sin subcampo Review, el nivel del review.
5. **Review.** Con etiqueta previa y Review distinto de `no`, invoca el skill `code-review` (Skill tool) con el nivel y el diff `<etiqueta>..<commit>` como objetivo. Sin etiqueta previa, el paso se salta: no hay versión anterior con la que comparar.
   - Cada hallazgo confirmado se abre como issue con el skill `dev:crear-issue`, con un título que describe el fallo tal como lo ve quien usa el proyecto, no con forma de asunto de commit (`fix(ámbito): ...`). Si ya hay un issue abierto para ese fallo, no se duplica: se apunta su número.
   - No se arregla nada dentro de este skill: el arreglo es un issue más y lleva su propio ciclo.
6. **Propuesta.** Propón el número siguiente y enseña:
   - número actual → número propuesto, y el commit sobre el que va;
   - los commits que hacen que sea minor, si lo es;
   - si es minor y hay Apartado de minor, un borrador de ese apartado escrito a partir de los diffs: qué tiene que cambiar quien usa el proyecto, en bullets. No incluye lo que ya cuentan las notas generadas.
   - el resultado del review: nivel, cuántos hallazgos hubo y el issue de cada uno, o que no hubo ninguno (o que se saltó, y por qué). Con hallazgos abiertos, lo que se propone es parar: resolverlos (`/dev:resolver-issue`) y volver a lanzar este skill, que revisará el diff con los arreglos dentro.
7. **Confirmación.** Pide confirmación explícita del número, del commit y del apartado antes de cualquier paso siguiente: etiquetar y publicar una release la exige la política de operación autónoma. Con hallazgos del review abiertos, publicar necesita además que el usuario diga expresamente que la versión sale con ellos; una confirmación del número que no los nombra no basta. Con cualquier corrección, vuelve a enseñar la propuesta.
8. **Subir el número.** Si el Fichero ya tiene el número confirmado en el commit elegido, no hay commit de versión. Si no:
   - El commit elegido tiene que ser la punta de la rama; si es uno anterior, dilo y pregunta, sin reescribir historia ni etiquetar un commit cuyo Fichero diga otro número.
   - Cambia solo el número en el Fichero (y en su lockfile si lo repite, como `package-lock.json`), y commit `chore(version): vX.Y.Z`. Si la Verificación del proyecto se puede pasar sin efectos externos, pásala antes.
9. **Etiqueta y publicación**, en este orden:
   - `git tag -a vX.Y.Z -m "vX.Y.Z" <commit>`;
   - `git push origin <rama>` si hubo commit de versión, y `git push origin vX.Y.Z`;
   - `gh release create vX.Y.Z --verify-tag --generate-notes --title vX.Y.Z`, y con el apartado de minor, si lo hay, en `--notes` o `--notes-file` (un fichero en un directorio temporal, no en el repo): empieza por `## <Apartado de minor>` y gh lo pone delante de las notas generadas.
   Nunca `--force`, ni mover ni borrar una etiqueta ya publicada: si algo sale mal a medias, dilo y pregunta.
10. **Resumen**: versión publicada, commit, enlace de la release, issues abiertos por el review y, si es minor, el apartado tal como quedó.
