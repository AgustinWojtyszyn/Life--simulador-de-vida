# Fase 1 · Núcleo de vida

El juego real arranca en `scenes/app.tscn`: menú, creador, país, vivienda y calle.
El barrio original sigue formando el sector occidental de Argentina. Se
conservan sus assets, fuente, bancos, parking e interacciones.

## Datos y componentes

- `CountryData → CityData → DistrictData`: catálogo de cinco países con una ciudad
  ficticia y un distrito inicial por país. No hay selección de provincias.
- `world_catalog.gd`: fachadas, vegetación, comercios, anchos de calle secundaria,
  densidad, vivienda y posiciones de edificios. Los cinco distritos comparten
  `playground.tscn`, con calles y extensión modular hasta 2400×1600.
- `CityBuilding`: `EXTERIOR_ONLY`, `INTERACTABLE`, `ENTERABLE`; fachada, cartel,
  puerta e identidad. No todos los comercios tienen interior.
- `HomeSystem`: identificador estable, tipo de vivienda y puntos de entrada/salida.
  Hay una vivienda propia por país. El interior mínimo es reutilizable y cambia
  su acento regional; contiene dormitorio, cama, living, cocina y baño sugerido.
- `PlayerProfile`: nombre, género, piel, cabello/color, prendas, país, ciudad,
  distrito y vivienda. La apariencia usa bases PixelLab hombre/mujer y una paleta
  parametrizada. Los tres acabados de cabello son ajustes simples del flequillo;
  no constituyen un editor de peinados o prendas por capas.
- `CharacterVisual`: idle y cuatro frames de caminata en cuatro orientaciones.
  Las diagonales eligen orientación dominante. El ciclo avanza por desplazamiento
  real: no camina al chocar contra una pared ni sigue andando al soltar el control.
- `PopulationSystem`: 14–18 residentes con perfiles combinados; activa por distancia.
  Rutas con varias esquinas, pausas, banco, visita a comercio y cruce con espera.
  Son rutinas acotadas, sin navegación general ni interiores simulados para NPCs.
- Tráfico: seis cuerpos reutilizados, dos carriles, velocidades distintas,
  aceleración/frenado, separación y prioridad para jugador/peatones. Reciclado
  fuera de los límites visibles. Los autos estacionados permanecen en el parking.
  No hay giros ni red avanzada de tránsito en Fase 1.
- `city_interactions.gd`: punto central para E/botón táctil y objetivo cercano;
  puertas, cama, banco, fuente, vecino y consulta del comercio.
- `LifeEvents`: señales de interacción, ubicación, perfil, descanso y guardado.
  Son hooks para misiones, relaciones, economía, necesidades, propiedades y viajes;
  esos sistemas no están implementados en esta fase.

## Guardado

`SaveSystem` escribe `user://vida_save.json` (esquema 1), usando temporal y backup.
Guarda perfil, ubicación interior/calle, posición, descanso y ajustes. Continuar
valida la versión/país y recupera el backup si el principal quedó corrupto.
Menú permite guardar o guardar y volver; al cerrar la ventana o suspender Android
se intenta guardar. No se versionan partidas ni credenciales.

## Controles

PC: WASD/flechas, E, Escape/menú. Android: joystick izquierdo y botón contextual;
los índices multitouch son independientes. UI con anchors/contenedores y scroll
para pantallas bajas; se comprobaron 16:9, 16:10 y ultrawide. Ver `ANDROID.md`.

## Assets

`assets/regions/manifest.json` registra las generaciones PixelLab de fachadas,
palmera, casa y muebles y los IDs de personajes/animaciones. El arte anterior
permanece en su ubicación original. Todas las imágenes son locales.

## Verificación

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/phase1_test.gd
godot --headless --path . --script tests/playground_test.gd
godot --headless --path . --script tests/traffic_test.gd
godot --headless --path . --script tests/interactions_test.gd
mkdir -p build
godot --path . --script tests/water_render_test.gd
godot --path . --script tests/phase1_preview.gd
```

`phase1_test.gd` usa una partida de prueba separada y la elimina. Recorre los cinco
países: Alex mujer personalizada, vivienda, E para salir, NPCs/tránsito, regreso,
movimiento, cama, guardado, menú y recarga. Verifica también respaldo corrupto y
joystick/acción multitouch. `phase1_preview.gd` guarda capturas reales por país,
menús y relaciones de aspecto; no es un mockup.
