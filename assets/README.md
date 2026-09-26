# Dirección visual de VIDA

La ampliación de Fase 1 agrega `regions/`, `interior/` y personajes direccionales
en `characters/male/` y `characters/female/`. Sus IDs están en
[regions/manifest.json](regions/manifest.json); la integración actual se documenta
en [docs/PHASE1.md](../docs/PHASE1.md). El barrio descrito abajo se conserva como
úcleo del distrito argentino.

Barrio porteño de tarde, perspectiva elevada de tres cuartos, fachadas con
volumen, luz cálida desde arriba a la izquierda, sombras frías, crema,
terracota, turquesa y oliva. Pixel art con transparencia y filtro nearest.
El mundo conserva controles cartesianos: la profundidad es faux-isométrica,
con sprites elevados, sombras y ordenamiento por Y; no usa una grilla isométrica.

## Assets actuales

Todos los PNG de `city/` se generaron con **PixelLab MCP**, herramienta
`mcp__pixellab__create_image_pro_flash`. Prompts completos, tamaños solicitados,
IDs de imagen y jobs se conservan en [city/manifest.json](city/manifest.json).
Los tres vehículos nuevos usan el hatchback como referencia de perspectiva y
sombreado; sus prompts e IDs están en [city/vehicles/manifest.json](city/vehicles/manifest.json).

| Archivo | Uso | Canvas solicitado |
| --- | --- | --- |
| `city/buildings/cafe.png` | Fachada de tres plantas, balcones y café | 192×224 |
| `city/buildings/market.png` | Comercio de ladrillo y terraza | 192×192 |
| `city/vehicles/car.png` | Hatchback turquesa | 96×64 |
| `city/vehicles/taxi.png` | Sedán taxi negro y amarillo | 96×64 |
| `city/vehicles/van.png` | Furgón blanco de reparto | 112×80 |
| `city/vehicles/coupe.png` | Coupé rojo | 96×64 |
| `city/vegetation/tree.png` | Árboles de vereda y plaza | 96×128 |
| `city/props/bench.png` | Bancos de madera | 64×48 |
| `city/props/lamp.png` | Faroles dobles | 48×96 |
| `city/props/planter.png` | Canteros de piedra con vegetación | 64×48 |
| `city/props/fountain.png` | Fuente de piedra y agua turquesa | 128×96 |

El suelo, cordones, señalización vial, sombras, alcorques y carteles pequeños se
dibujan en Godot. `city_ground.gd` se renderiza una sola vez a una textura del
mapa; `city_prop.gd` dibuja los dos detalles geométricos restantes. Las fachadas,
árboles y mobiliario usan sprites independientes con posición de apoyo y
huella de colisión explícitas en `playground.gd`. Fachadas y copas se atenúan
cuando ocultan al jugador. Los cuatro autos estacionados tienen colisión estática.
Los seis vehículos de `city_vehicle.gd` son cuerpos móviles con colisión propia,
ordenados por Y; recorren `TRAFFIC_LANES` en dos sentidos, frenan ante el personaje
y mantienen distancia con el vehículo que los precede. Los sprites se orientan
según el sentido y se anclan por su región visible, sin el margen transparente.

## Poses e interacción

`characters/resident/seated.png` y `wave.png` son poses nuevas de 32×32 generadas
con PixelLab a partir del residente original. Prompts, referencia e IDs están en
[characters/resident/interactions.json](characters/resident/interactions.json).
Se usan al sentarse y saludar; los vecinos también muestran la pose de saludo.

`shaders/fountain_water.gdshader` anima únicamente los tonos turquesa de la fuente
existente: desplazamiento por píxeles, reflejos y corrientes. La piedra y la
silueta no se deforman. `fountain_water.gd` controla el tiempo y agrega la moneda
y las ondas al pedir un deseo. No hay nuevas llamadas de generación durante el juego.

El parking señalizado reemplaza el bloque residencial sudeste. Los cuatro autos
estáticos se ubican dentro de sus plazas; se retiraron las marcas de aparcamiento
en la avenida. Los seis vehículos de tránsito siguen circulando por sus carriles.

## Assets anteriores conservados

`characters/resident/{south,north,east,west}.png` (32×32) sigue siendo el personaje
controlable y la base de los peatones ambientales. Se generó previamente con
PixelLab, con el sur como referencia de identidad para las otras orientaciones.

| Orientación | Job |
| --- | --- |
| Sur | `15fdd84f-eb15-4ba0-a19e-53589edfd877` |
| Norte | `e678e82b-cc4e-4f00-b7b1-5fade7d8c123` |
| Este | `5b008005-252f-4bdf-8055-33ab8a3b514b` |
| Oeste | `09b858d7-4ff4-49c4-a902-4a2706b08766` |

`environment/{grass,ground,sidewalk,obstacle}.png` permanece como material legado;
la escena nueva ya no lo utiliza. Jobs originales, respectivamente:
`08b16a4b-d7bc-4aab-970d-ea3c44d72982`, `7b8fd2f3-74a8-4f6e-8041-b646d21474e3`,
`718a8b14-b6f0-4cd1-a3ef-1541c2cceedc`, `bc01789c-ff38-4eb8-9ccb-1b6de3795584`.

Todos los assets finales son locales. El juego no se conecta a PixelLab.
