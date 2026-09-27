# Atlas de arquitectura cotidiana

Generados con la herramienta integrada **image_gen**. Fuentes de estilo:
`assets/houses/ar/common.png`, `assets/buildings/jp/market.png`. Se preservaron
los originales. Los cinco PNG se usan directamente mediante 16 AtlasTexture
por país; `regions.json` registra los rectángulos. Ningún recurso depende de
archivos fuera del repositorio. Las variantes anteriores siguen en el mapa.

## Prompts de producción

Especificación común: production pixel-art game sprite atlas, genuine transparent
background, strict 4×4 grid of 16 separate complete buildings with generous
transparent gutters; match reference medium, muted palette, sharp pixel edges
and low overhead 2.5D camera; all south-facing front facades, right side wall
visible; no rotation, roads, benches, people, watermarks or outer labels;
complete isolated buildings inside their cells, different silhouettes, roofs,
materials, windows, balconies and entrances.

Secuencia por país, en orden de filas:

- **Argentina:** small stucco flat roof house; medium red tile roof courtyard
  house; modern concrete glass home; low brick apartments; medium four-floor
  plaster apartments; narrow seven-floor tower; kiosco; panadería; parrilla;
  café; supermarket; auto workshop; gas station canopy with pumps; glass and
  concrete offices; brick public school with flag; medical center green cross.
- **Japón:** traditional tiled-roof machiya; medium wooden home; compact concrete
  home; low apartments with exterior stairs; four-floor apartments; seven-floor
  tower; konbini; ramen shop; yakitori restaurant; kissaten; supermarket; auto
  repair; covered parking bays; glass offices; primary school; clinic.
- **Italia:** ochre tile-roof house; stone courtyard house; white modern home;
  terracotta low apartments; palazzo with shutters; contemporary tower;
  alimentari; artisan bakery; trattoria; caffè; supermarket; mechanic; petrol
  station; contemporary offices; historic stone public library; medical clinic.
  Edición aplicada: “Remove ALL background from this sprite atlas. Preserve all
  16 buildings pixel-for-pixel, same positions, same image dimensions, same grid,
  their details and colors. Every area between and around buildings must be
  genuine alpha=0 transparency. No brown or grey gradient, no background color,
  no shadows. This is a transparent sprite sheet for a game, not a picture on a
  background. Only buildings opaque.”
- **Brasil:** colorful stucco tile-roof house; pastel sobrado; modern tropical
  concrete home; low brick apartments; medium apartments with balconies;
  residential tower; mercearia; padaria; churrascaria; café; supermarket; mechanic;
  posto; glass offices; public school with Brazilian flag; medical center.
- **Estados Unidos:** suburban clapboard gable house; suburban porch home; modern
  home; brick townhouse; apartment walkup; residential tower; convenience store;
  donut bakery; diner; coffee shop; supermarket; auto repair; gas station;
  glass offices; brick public library; urgent care clinic.

Las imágenes contienen texto decorativo generado. Los rótulos interactivos y los
nombres visibles del juego se definen en `scripts/data/country_catalog.gd`.
La captura final se revisó en el renderizador de Godot, a la escala del juego.
