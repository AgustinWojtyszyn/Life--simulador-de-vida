# Ciudad y Android

Esta iteración conserva el barrio inicial y el sistema por **Argentina, Japón,
Italia, Brasil y Estados Unidos**. No agrega provincias ni cambia las partidas.

## Catálogo y calles

- 16 familias nuevas por país (80 recursos AtlasTexture), además de las fachadas
  y vistas direccionales anteriores. Incluye casas, departamentos de varias
  alturas, comercios, restaurantes, supermercados, talleres, oficinas, edificios
  públicos y médicos; Japón tiene estacionamiento y los demás, estación de servicio.
- Dos manzanas mixtas al sur, calles y pasos peatonales conectados; mundo de
  2400 × 2400. Las nuevas fachadas tienen entrada al sur y se usan exclusivamente
  en lotes compatibles. No se rotan ni se espejan sprites.
- Se conserva el orden por anclaje al suelo (`y_sort_enabled`) y la proporción
  de cada sprite. Se corrigió el lote lateral que usaba una oficina frontal.
- Los bancos sólo se admiten en zonas públicas explícitas, con acceso libre.
  Una ubicación bloqueada se omite: no se desplaza el banco a otra fachada.
  Otros props también respetan el espacio reservado delante de las puertas.

Los edificios nuevos se encuentran siguiendo las calles hacia el sur. Los
comercios reutilizan los interiores existentes; servicios sin interior permiten
consultar su información. No se agregan simulaciones de combustible o educación.

## Interfaz táctil

- Android, pantalla táctil o `--touch-test` activan joystick analógico con zona
  muerta gradual y acción independiente por dedo. El botón permanece visible y
  se activa al acercarse a una interacción.
- Se libera el joystick al perder foco, suspender, pausar, cambiar de escena o
  redimensionar. Volver de Android abre/cierra el menú de pausa.
- Diseño horizontal; HUD compacto, zoom 1.12, áreas seguras compartidas por
  controles, menús, diario y pausa. Creador, países y diario se desplazan
  verticalmente; elecciones y botones principales tienen al menos 48 unidades.
- Se conserva el guardado automático existente al suspender, y se pausa el juego.
- Suelo estático en una textura de 1200 × 1200 en móvil (un cuarto de los píxeles
  de la versión de escritorio); un atlas por país para las 16 fachadas nuevas,
  límites de textura cacheados y población distante inactiva.

## Validación reproducible

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script tests/android_city_test.gd
godot --headless --path . --script tests/orientation_test.gd
godot --headless --path . --script tests/regional_streets_test.gd
godot --headless --path . --script tests/phase1_test.gd
# Capturas reales con renderizador, no mockups:
godot --path . --script tests/android_city_preview.gd
# Interactivo:
godot --path . -- --touch-test
```

`android_city_test` comprueba las 16 familias colocadas en cada país, atlas propio,
orientación, entradas libres, bancos públicos, tamaño de caché móvil, creador sin
scroll horizontal en 800×450, 960×432 y 640×360, selección de países, multitouch,
pérdida de foco, pausa y resize. Las pruebas regionales comprueban solapamientos,
calzadas, props y patrimonio gráfico previo. `phase1_test` recorre el flujo completo
con vivienda, guardado, carga y movimiento en los cinco países.

Las capturas se guardan en `build/mobile/` (ignorado por Git). La validación local
usa Godot 4.7.2 en escritorio. No hay SDK/JDK, templates Android ni dispositivo
conectado en este entorno: **no se generó ni se probó un APK** y no se afirma FPS
medido en un teléfono. El preset ARM64/Compatibility sigue disponible.

## Recursos y generación

Los atlas y sus regiones viven en `assets/catalog/`. Se utilizó la herramienta
integrada `image_gen`, con las fachadas originales `houses/ar/common.png` y
`buildings/jp/market.png` como referencias de estilo. No se reemplazaron las
imágenes originales. Los prompts están documentados en `assets/catalog/README.md`.
`tools/catalog_regions.py` detecta componentes alfa y genera regiones `.tres`;
no modifica imágenes. Requiere Pillow, NumPy y SciPy sólo para regenerar regiones,
no para ejecutar ni exportar el juego.
