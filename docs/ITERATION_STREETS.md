# Barrios e identidad — septiembre de 2026

- Las fachadas tienen tipo, nombre localizado y acceso coherentes. Las casas no abren comercios; clínicas y oficinas usan sus assets específicos. No se presenta ninguna oficina japonesa como estación.
- Los edificios reservan su envolvente visible antes del mobiliario. El tamaño respeta calles y estacionamiento; props y árboles se anclan a su región opaca, se reubican en veredas/plazas y comparten ordenamiento por Y. Los canteros siguen la ubicación final del árbol y los vecinos se sientan en bancos existentes.
- Argentina: almacén, panadería, kiosco, puesto de choripán y parrilla con compra de comida; canchita con pelota y vecinos, parada señalizada y dos colectivos en el carril este.
- Brasil: padaria, panadería de esquina, moto y palmeras. Japón: konbini, vending, bicicleta y edificio residencial mixto. Italia: pizzería, trattoria, caffè y scooter. USA: coffee shop, diner y grocery. La selección de viviendas cambia por país; se reutilizan casas compatibles del catálogo argentino donde faltan assets exclusivos.
- Jugador: aceleración gradual, frenado corto y animación según desplazamiento real. NPC: velocidades variadas, aceleración y frenado al destino. Vehículos: crucero de 160–201 px/s frente a 140 del jugador, con frenado, separación y reducción en curvas/lluvia.

Se integraron assets existentes, sin generaciones nuevas. Quedan para otra iteración viviendas exclusivas de más países, estación japonesa con su fachada real y orientaciones adicionales del colectivo para ampliar su recorrido. La parada es escenografía: todavía no permite viajar en colectivo. La canchita es una escena ambiental, no un minijuego.

## Verificación

Godot 4.7.2: `regional_streets_test`, `movement_test`, `traffic_test`, `playground_test`, `phase1_test`, `life_iteration_test` e `interactions_test` pasan sin errores. Ejecutar cada suite con:

```sh
godot --headless --path . --script tests/regional_streets_test.gd
```

La prueba regional recorre los cinco países y comprueba semántica, assets regionales integrados, variedad de fachadas, estacionamiento y ausencia de intersecciones entre fachadas, mobiliario y calles. Las demás cubren movimiento, frenado ante peatones, filas de tránsito, colisiones, interacción, misión, entrada/salida de vivienda y guardado/carga.

Capturas reproducibles (requiere renderizador gráfico):

```sh
godot --path . --script tests/regional_preview.gd
```

Se guardan en `build/previews/{ar,br,jp,it,us}_{street,overview}.png`, fuera de Git.
