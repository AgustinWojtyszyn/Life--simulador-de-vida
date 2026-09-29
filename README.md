# VIDA B2B

**Capacitación laboral interactiva: aprender el procedimiento haciéndolo.**

VIDA está migrando de un life-sim urbano a una plataforma B2B web-first de simulación y capacitación. El mundo actual se conserva como banco de assets y compatibilidad mientras el producto converge hacia escenarios compactos, reutilizables y medibles.

## Dirección actual

Flujo objetivo:

```text
Rubro -> Empresa -> Lugar de trabajo -> Puesto -> Procedimiento -> Escenario -> Resultado
```

El motor B2B debe ser independiente de cada cliente. Nexovial S.A. es el vertical de oficina existente y funciona como prueba de compatibilidad durante la migración.

Fundaciones disponibles:
- `CompanyData`, `WorkplaceData`, `JobRoleData`, `ScenarioData`;
- `IndustryData`;
- `ProcedureData` y `ProcedureStepData`;
- `EquipmentData` para herramientas/EPP;
- `RuleReferenceData` para referencias normativas versionables;
- `TrainingResultData`;
- `ProcedureRunner` para ejecución, orden, prerequisitos, errores y telemetría.

## Plataforma

Objetivo comercial principal: **Web/Desktop mediante URL**, sin instalación. Android/touch permanece soportado como compatibilidad y cliente secundario. El proyecto usa GL Compatibility, adecuado para mantener una ruta web de Godot; cada export real debe validarse en hardware/navegador objetivo.

## Qué está congelado

Países, megaciudad, vida personal, economía, clima y expansión urbana son legacy mientras no aporten a capacitación. No extenderlos. No borrarlos masivamente hasta desacoplar saves/assets/tests.

Semáforos y tráfico circular están retirados del hub B2B. La banda sonora está retirada; permanecen SFX funcionales.

## Desarrollo

```sh
godot --path .
godot --headless --script tests/procedure_runner_test.gd
godot --headless --script tests/b2b_vertical_test.gd
godot --headless --script tests/traffic_test.gd
```

No considerar una plataforma validada sólo porque el proyecto parsea: Web y Android requieren export y smoke test reales.

## Documentación principal

Leer primero [docs/VIDA_SINGLE_CITY_B2B.md](docs/VIDA_SINGLE_CITY_B2B.md). Contiene arquitectura objetivo, límites de producto y el plan de la iteración grande de Astra.

Los documentos `PHASE1`, `ITERATION_*` y `ANDROID` describen etapas anteriores y deben tratarse como historial/compatibilidad, no como dirección de producto.
