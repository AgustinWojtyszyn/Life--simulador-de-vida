# VIDA · Barrio del Sol

Escena urbana jugable en Godot 4: dirección visual 2.5D / faux-isométrica,
pixel art generado con PixelLab MCP y una tarde cálida de barrio porteño.

```sh
godot --path .
```

Movete con **WASD o las flechas**. La cámara sigue al personaje.
Acercate y presioná **E** cuando aparezca la indicación:

- **Bancos:** sentarte a descansar; E o una dirección para levantarte.
- **Vecinos:** saludar con una pose propia; el vecino se detiene, devuelve el saludo y continúa.
- **Fuente:** pedir un deseo, con una moneda y ondas sobre el agua.

El agua de la fuente tiene movimiento continuo de corrientes y reflejos; la piedra
permanece fija. El parking está al sudeste, junto a la calle vertical: cuatro
plazas numeradas, acceso señalizado y pasillo central libre.

 El barrio incluye
fachadas comerciales, balcones, toldos, calles con cruces peatonales,
autos estacionados y en circulación, una plaza con fuente, árboles, bancos, faroles y peatones.

Los objetos se ordenan por su contacto con el suelo. Edificios y copas se atenúan
si ocultan al personaje. Las colisiones corresponden a las bases, no a la altura
de las imágenes. Los peatones siguen rutas simples y responden al saludo; no
tienen IA de navegación. Hay cuatro modelos de vehículos (hatchback, taxi porteño, furgón y
coupé), cuatro estacionados y seis circulando por los dos carriles de la avenida.
El tránsito frena ante el personaje, mantiene distancia con el vehículo de
adelante y retoma la marcha cuando se libera el paso. Los vehículos reaparecen
fuera del área visible al llegar al extremo del recorrido. No hay giros ni
tránsito vertical en esta versión. La hora del HUD
representa la ambientación fija; no es un reloj de simulación.

El mapa mide 1440×960, con viewport de 800×450 y filtrado nearest. El terreno se
dibuja una vez a un SubViewport y luego se reutiliza como textura. No requiere
conexión ni generación de imágenes durante el juego.

## Verificación

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/playground_test.gd
godot --headless --path . --script tests/traffic_test.gd
godot --headless --path . --script tests/interactions_test.gd
mkdir -p build
godot --path . --script tests/city_capture.gd
godot --path . --script tests/water_render_test.gd
```

La prueba funcional cubre assets, aparición libre de obstáculos, movimiento,
orientaciones, aceleración, frenado, diagonales, deslizamiento, edificios,
autos, cuatro bordes, cámara y transparencia de oclusores. La prueba de tránsito
verifica modelos distintos, ambos sentidos, frenado y reanudación ante el
personaje, filas de vehículos, colisión móvil y reciclado fuera de cámara. La prueba gráfica
requiere un entorno con pantalla; guarda `build/street.png`, `build/plaza.png`
`build/crossing.png`, `build/parking.png` y `build/seated.png`, y mide 180 cuadros
después del calentamiento. La prueba de interacciones usa la tecla E y verifica
sentarse/levantarse, respuesta del vecino, deseo, alcance y posición del parking.
La prueba gráfica del agua compara dos instantes del shader: debe cambiar el
agua sin cambiar ningún píxel opaco de piedra.

Los assets y sus prompts/IDs de generación están documentados en
[assets/README.md](assets/README.md) y [assets/city/manifest.json](assets/city/manifest.json).
