# Pixel art de VIDA

Assets generados con **PixelLab MCP**, a resolución nativa **32×32**.
Paleta urbana cálida: verde oliva, arena, piedra clara, mampostería azul gris
y chaqueta turquesa. Luz desde arriba a la izquierda, sombras frías y píxeles
nítidos. Sin filtros bilineales ni mipmaps.

## Archivos e integración

- `environment/grass.png`: pasto del mapa.
- `environment/ground.png`: suelo del camino horizontal.
- `environment/sidewalk.png`: vereda del camino vertical.
- `environment/obstacle.png`: mampostería de los cuatro obstáculos y del límite existente.
- `characters/resident/{south,north,east,west}.png`: orientaciones del único personaje.

`playground.gd` repite las texturas a escala 1:1, recortando en los límites de
los rectángulos originales. Las sombras y los bordes son detalles de renderizado.
`player.tscn` usa un `Sprite2D` con filtrado nearest; `player.gd` selecciona la
orientación según el movimiento existente. Las colisiones, velocidades, cámara,
dimensiones del mapa y posiciones originales se conservan.

No se incorporan animaciones, sistemas ni entidades adicionales.

## Procedencia

Generador de imágenes: `mcp__pixellab__create_image_pro_flash`.

| Asset | Job de PixelLab |
| --- | --- |
| Pasto | `08b16a4b-d7bc-4aab-970d-ea3c44d72982` |
| Suelo | `7b8fd2f3-74a8-4f6e-8041-b646d21474e3` |
| Vereda | `718a8b14-b6f0-4cd1-a3ef-1541c2cceedc` |
| Obstáculo | `bc01789c-ff38-4eb8-9ccb-1b6de3795584` |
| Personaje sur | `15fdd84f-eb15-4ba0-a19e-53589edfd877` |
| Personaje norte | `e678e82b-cc4e-4f00-b7b1-5fade7d8c123` |
| Personaje este | `5b008005-252f-4bdf-8055-33ab8a3b514b` |
| Personaje oeste | `09b858d7-4ff4-49c4-a902-4a2706b08766` |

Las orientaciones usan el sprite sur como referencia de identidad, paleta y
sombreado. Se descartó una primera generación de personaje porque el servicio
devolvió 48×48; no forma parte de los assets del proyecto.

Los PNG son locales; el juego no requiere conectarse a PixelLab.

## Verificación

```sh
godot --headless --path . --editor --import
godot --headless --path . --script tests/playground_test.gd
godot --path .
```

La prueba comprueba resolución de los ocho PNG, orientaciones del personaje,
movimiento, aceleración, frenado, normalización diagonal, colisiones, deslizamiento,
límites del mapa y seguimiento de cámara. También se revisó la escena con el
renderizador gráfico de Godot, tanto en el centro como junto al borde del mapa.
