# PRE-ASTRA AUDIT — VIDA B2B

Estado preparado para la iteración grande. Este documento distingue deuda real de decisiones ya tomadas para evitar que una siguiente iteración restaure accidentalmente sistemas legacy.

## Corregido antes de Astra
- Semáforos fuera del runtime y del minimapa.
- Eliminada referencia inválida a TrafficSignalScript que quedó después del primer retiro.
- Banda sonora retirada de runtime y UI; SFX funcionales conservados.
- Tráfico recto deja el mundo en sus límites; eliminado cálculo de distancia circular heredado.
- Circuitos cerrados de autos/expansión/colectivos retirados del hub.
- Test de tráfico actualizado al contrato entrada->salida.
- ProcedureRunner genérico agregado con test lógico.
- Datos base de rubro, procedimiento, paso, equipamiento/EPP, referencia normativa y resultado agregados.
- Company/Workplace/Role preparados para asociarse a rubros/procedimientos.
- README y documento rector actualizados a B2B web-first.

## Riesgos/deuda que Astra debe atacar

### P0 — compilación y regresiones
Ejecutar Godot real sobre main antes de ampliar contenido:
1. importar proyecto;
2. revisar errores/warnings de parseo;
3. ejecutar procedure_runner_test;
4. ejecutar b2b_vertical_test;
5. ejecutar traffic_test;
6. ejecutar el resto de suites y clasificar cada fallo como regresión o expectativa legacy.

No cambiar código correcto sólo para satisfacer un test de megaciudad obsoleto: actualizar o archivar el test con justificación.

### P0 — desacople de Nexovial
InteractionTarget todavía contiene acciones `nexovial_*`. NexovialInterior crea targets específicos. Migrar esas acciones a ProcedureRunner/metadata genérica y dejar InteractionTarget sin conocimiento de empresas.

ShiftSystem todavía mezcla evaluación laboral con LifeSimulation.money/reputation. Mantener compatibilidad del vertical, pero TrainingResult debe convertirse en la fuente B2B; sueldo/economía no deben contaminar módulos nuevos.

### P0 — catálogo B2B
CompanyCatalog registra Nexovial manualmente. Crear TrainingCatalog/IndustryCatalog data-driven para industrias, procedimientos, equipment y rules. Validar IDs duplicados, referencias inexistentes y procedimientos vacíos al registrar.

### P0 — contenido normativo
RuleReferenceData es infraestructura, no contenido validado. No inventar normas. Todo requisito real debe incluir fuente/jurisdicción/versionado y marcarse verified sólo tras validación.

### P1 — web
El repo actualmente conserva preset Android pero no preset Web versionado. Crear y probar un preset Web con Godot 4.7, export release y smoke en navegador. No declarar web lista hasta hacerlo.

Revisar peso del PCK, assets exportados y carga inicial. Evitar exportar tests/docs/tools al producto final. Medir en Chromium y un navegador móvil real si se mantiene compatibilidad touch.

### P1 — mundo compacto
DistrictData sigue en 4800x3200 y DistrictBlocks conserva layout de megaciudad. No reducir a ciegas: inventariar coordenadas authored (home, Nexovial, POI, NPC, roads, camera/minimap), diseñar un hub compacto y migrar posiciones con test de bounds.

El objetivo no es una ciudad vacía más chica: es un hub denso de lugares de trabajo reutilizables.

### P1 — legacy por desacoplar
WorldManager todavía conserva CountryData/profile.country_id para saves/assets.
Home, ShopInterior, RegionalAssets, Weather y parte del HUD usan country.
Mantener compatibilidad mientras se crea una identidad neutral B2B. No extender regionalización.

### P1 — interacción/performance
CityInteractions busca grupos globalmente cada frame. Para escenarios densos, reemplazar por proximidad/área o caché espacial.
Minimap también recorre tráfico/NPC periódicamente; medir antes de optimizar.
NPC/traffic deben tener presupuestos explícitos por escenario para Web.

### P1 — datos y privacidad
TrainingResult actual es local y no contiene identidad del trabajador. Mantener el Core libre de PII. Diseñar posteriormente IDs externos/pseudónimos y backend separado.
No agregar auth/pagos/backend dentro del runtime Godot en esta iteración.

## Contrato para varios rubros
Astra puede crear varios rubros sólo si todos usan el mismo Core:
- ningún `if industry == "gastronomia"` en ProcedureRunner;
- ningún `nexovial_*` nuevo en sistemas genéricos;
- EPP/equipment se define por procedimiento/paso, no por rubro global;
- escenarios deben producir TrainingResult comparable;
- contenido específico vive en recursos/catálogos/módulos.

## Rubros para la sesión
Prioridad de profundidad:
1. Gastronomía — vertical completo.
2. Salud — vertical corto que demuestre equipamiento dependiente de tarea.
3. Logística — vertical corto de flujo/seguridad.
4. Industria — estructura y un escenario breve.
5. Construcción/retail/oficina/energía sólo si los cuatro anteriores están sanos.

Más rubros no compensan un ProcedureRunner roto.

## Definition of Ready para Astra
Astra debe comenzar leyendo:
1. README.md
2. docs/VIDA_SINGLE_CITY_B2B.md
3. este documento
4. ProcedureRunner y sus data classes
5. Nexovial + b2b_vertical_test

Luego ejecutar tests antes de editar.

## Definition of Done del viernes
- Core genérico sin conocimiento de empresa/rubro.
- Nexovial migrado sin regresión.
- Al menos Gastronomía end-to-end y varios rubros demostrando reutilización real del Core.
- TrainingResult visible y serializable.
- tests B2B verdes o fallos documentados con causa reproducible.
- Web export real probado.
- mapa/hub más enfocado sólo si la migración de coordenadas fue validada.
- ningún bug P0 conocido ocultado o etiquetado como “resuelto” sin reproducción/prueba.
