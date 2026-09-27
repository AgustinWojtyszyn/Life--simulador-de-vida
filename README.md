# VIDA / LIFE

**Tu vida. Tu ciudad. Tus decisiones.**

Juego de vida en Godot 4, con pixel art 2.5D y una misma base para PC/Android.

```sh
godot --path .
```

**Nueva partida → crear personaje → elegir país → tu vivienda → explorar.**
Argentina, Estados Unidos, Japón, Italia y Brasil tienen una zona inicial jugable.
El barrio original se conserva dentro de Argentina y se amplía con calles,
viviendas, comercios y población. Cada país usa fachadas e identidad propias. Hay 16 familias nuevas por país
además del catálogo anterior, distribuidas en dos manzanas mixtas al sur.

- WASD/flechas para caminar; **E** para la interacción cercana.
- Puerta de tu casa: entrar/salir. Cama: descansar.
- Bancos: sentarte; E o movimiento para levantarte. Vecinos: saludar.
- Fuente: pedir un deseo sobre el agua animada. Comercios: consultar horario.
- **Escape / Menú:** guardar, continuar jugando o guardar y volver al inicio.
- Android: joystick multitouch y botón de acción contextual, sólo en móvil.

El creador ofrece hombre/mujer, nombre y apariencia básica con preview. Continuar
recupera perfil, país, vivienda, posición y estado básico desde `user://`.

La Fase 1 no incluye misiones, trabajos, economía, relaciones ni progresión.
Los interiores de viviendas son reutilizables y el tránsito aún no realiza giros.

Documentación de arquitectura, límites y pruebas: [docs/PHASE1.md](docs/PHASE1.md).
Preparación y límites de validación móvil: [docs/ANDROID.md](docs/ANDROID.md).
Assets anteriores: [assets/README.md](assets/README.md).

Iteración de ciudad y controles táctiles: [docs/ITERATION_ANDROID_CITY.md](docs/ITERATION_ANDROID_CITY.md).
