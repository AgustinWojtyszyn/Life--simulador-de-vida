# Android

La misma escena `app.tscn` y los mismos sistemas funcionan en PC y Android.
El preset `Android` usa Compatibility, ARM64 y APK sin plugins ni permisos de red.
Orientación horizontal, UI con anchors/contenedores, joystick multitouch y botón
contextual independiente. Al perder foco se limpia el joystick; al suspenderse
se guarda en `user://`. Controles, HUD y paneles comparten el área segura del dispositivo.
El diseño se mantiene horizontal; menús y diario admiten scroll táctil.
Los botones principales tienen un mínimo de 48 unidades.

Cambios y pruebas actuales: [ITERATION_ANDROID_CITY.md](ITERATION_ANDROID_CITY.md).

Para probar los controles en escritorio:

```sh
godot --path . -- --touch-test
```

El preset está versionado sin claves ni contraseñas. Para generar el APK hacen
falta los export templates correspondientes a la versión local de Godot,
OpenJDK 17 y Android SDK configurados en el editor. Ver la
[guía oficial de exportación para Android](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html).
Después:

```sh
mkdir -p exports
godot --headless --path . --export-debug Android exports/vida-android.apk
```

En este entorno no hay JDK, SDK, export templates ni dispositivo Android.
La validación local cubre eventos multitouch sintéticos y UI horizontal; no
sustituye una prueba de APK en hardware. No se afirma rendimiento móvil medido.
