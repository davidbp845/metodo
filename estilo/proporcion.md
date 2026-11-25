# Esfuerzo proporcional

Se aplica a cómo se trabaja en cualquier proyecto: cuánto investigar, cuándo preguntar, cuándo usar subagentes y cuándo profundizar. Lo que se escribe sigue `redaccion.md`; esto va del trabajo que hay detrás. Las reglas de un proyecto concreto pueden añadir, no contradecir.

## Más profundidad

Cuando el cambio tiene una de estas propiedades, se investiga más, se verifica con más cuidado y se pregunta antes de una decisión dudosa:

- No se deshace con git: estado de GitHub, servicios externos, datos fuera del repo, publicaciones.
- Es compartido: un cambio en el repo del método vale para todos los proyectos, y una pieza que leen varios sitios (un esquema, un campo de `## Método`) rompe a quien la lee.
- Puede fallar sin que nada lo detecte: no hay test, la Verificación no lo cubre o el fallo solo sale con datos reales.
- Da un resultado inesperado: un test que pasa sin motivo, una cifra que no cuadra, un comportamiento que contradice lo que dice el código. Se entiende antes de seguir.

## Más brevedad

Cuando el cambio es local, reversible con git y fácil de comprobar (un test, la Verificación, mirarlo), se actúa sin rodeos: se lee lo que hace falta, se cambia y se comprueba.

## Qué se recorta y qué no

- Se recorta: la narración de los pasos, las opciones que no se van a seguir, releer lo que ya está en la conversación, las preguntas que tienen un valor por defecto razonable (se toma y se dice) y los subagentes para lo que se hace igual de bien en la propia sesión.
- No se recorta nunca: la verificación de lo que se cambia y la lectura del código o documento que se toca.
