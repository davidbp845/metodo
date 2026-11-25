# Guía de diseño web

Se aplica a toda maqueta y a todo CSS nuevo o rehecho, en cualquier proyecto. Las reglas de un proyecto concreto (paleta, tipografías, componentes) pueden añadir, no contradecir.

## Tipografía y espaciado fluidos

- Escalas tipo [Utopia](https://utopia.fyi): cada paso es un `clamp()` entre un viewport mínimo (320 px) y uno máximo (el ancho del contenido), en custom properties `--step-*` para el texto y `--space-*` para márgenes y huecos, más pares (`--space-s-l`) para los saltos grandes.
- Nada de tamaños de fuente fijos en px. Los valores de la escala se calculan una vez y se declaran en `:root`.

## Layouts flexibles

- Grid y flex con `minmax()`, `min()` y unidades relativas; sin anchos fijos. El contenedor se limita con `width: min(100% - 2 * <margen>, <ancho máximo>)`.
- Sin scroll horizontal a ningún ancho; se comprueba a 390 px, en un ancho intermedio y en escritorio.

## Mobile first

- Los estilos base son los del móvil y las media queries usan `min-width` para crecer. Aunque la página se use sobre todo en escritorio.
