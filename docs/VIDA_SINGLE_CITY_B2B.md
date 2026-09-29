# VIDA B2B — Plataforma web de capacitación interactiva

## Norte de producto
VIDA deja de optimizarse como un life-sim de megaciudad. El producto objetivo es una plataforma B2B web donde una empresa configura una experiencia de capacitación y el trabajador aprende un procedimiento haciéndolo dentro de un escenario jugable.

Promesa: **practicar el trabajo antes de hacerlo de verdad**.

La ciudad pasa a ser un hub compacto y funcional. El valor está en empresas, interiores, procedimientos, herramientas, EPP, decisiones, consecuencias, feedback y métricas; no en kilómetros de mapa.

## Flujo objetivo
Empresa -> Rubro -> Lugar de trabajo -> Puesto -> Procedimiento -> Escenario -> Evidencia/resultado.

Rubros iniciales candidatos:
- Gastronomía
- Salud
- Industria
- Logística
- Construcción
- Retail/servicios
- Oficinas
- Energía

No implementar todos a la vez. El primer módulo comercial debe ser uno solo y excelente. Gastronomía es el candidato inicial para validar venta y autoservicio.

## Arquitectura B2B objetivo

### VIDA Core
Motor reutilizable e independiente del rubro:
- movimiento e interacción;
- inventario y equipamiento;
- interacción con objetos/NPC;
- secuencias de procedimiento;
- decisiones y consecuencias;
- escenarios ramificados;
- feedback;
- resultados y telemetría;
- persistencia;
- input desktop/web y compatibilidad touch.

### Industry Modules
Contenido reutilizable por rubro. Cada módulo define lugares, riesgos, equipamiento, EPP, procedimientos y escenarios. Nunca hardcodear un rubro en el motor.

### Company Layer
Personalización de cliente: identidad, sedes, puestos, procedimientos propios, branding y reglas internas. Un cliente estándar debe poder usar el catálogo sin intervención manual del desarrollador.

## Modelo de datos a construir
Los actuales CompanyData / WorkplaceData / JobRoleData / ScenarioData son la semilla, no el modelo final.

Agregar recursos data-driven equivalentes a:
- IndustryData
- ProcedureData
- ProcedureStepData
- PPEData / EquipmentData
- RuleReferenceData
- AssessmentData
- TrainingResultData

ProcedureStep debe poder representar como mínimo: acción requerida, orden, objetivo del mundo, prerequisitos, opcionalidad, feedback, error y evidencia registrada.

Las reglas/normas deben guardar jurisdicción, fuente, versión/vigencia y referencia. VIDA no debe inventar requisitos regulatorios. El contenido normativo sensible debe poder ser validado/versionado por especialistas.

## Evaluación
No reducir el entrenamiento a correcto/incorrecto. Registrar:
- pasos completados y omitidos;
- orden;
- errores;
- reintentos;
- tiempo;
- decisiones;
- uso de equipamiento/EPP cuando corresponda;
- resultado del escenario.

Separar la simulación de cualquier afirmación de certificación legal. El producto inicial es herramienta de práctica/capacitación interactiva.

## Mundo
Objetivo: un hub corporativo compacto, no una megaciudad.

Conservar assets actuales como biblioteca mientras se migra. No borrar masivamente arte regional ni romper saves. Reducir el mundo solamente después de inventariar posiciones authored, cámara, minimapa, rutas, interiores y Nexovial.

Los edificios prioritarios son arquetipos reutilizables:
- restaurante/cocina;
- hospital/clínica;
- oficina;
- depósito/logística;
- planta/fábrica;
- obra;
- taller;
- comercio/servicio.

## Tráfico y audio
Los semáforos están deshabilitados hasta contar con una implementación confiable. El tráfico recto debe entrar, recorrer y salir; no reciclarse mágicamente. Los circuitos cerrados heredados deben migrarse a rutas entrada->salida antes del MVP.

VIDA B2B no tiene banda sonora. Mantener únicamente SFX funcionales y audio contextual útil para escenarios.

## Web primero
Objetivo comercial: acceso por URL sin instalación. Desktop web es el cliente principal. Touch/móvil se conserva como compatibilidad y para escenarios que rindan correctamente, sin diseñar el producto alrededor de una megaciudad móvil.

Steam y tiendas de videojuegos no son prioridad del MVP B2B.

## Modelo comercial que condiciona arquitectura
El plan económico debe ser autoservicio. El precio de entrada no compra desarrollo personalizado. Catálogo estándar y configuración deben escalar sin intervención del desarrollador. Escenarios/edificios/procedimientos hechos a medida son implementación aparte.

## Legacy: congelar, no destruir
Mientras el pivot se estabiliza pueden permanecer por compatibilidad:
- country/regional assets;
- LifeSimulation;
- clima/ciclo temporal;
- vivienda;
- saves anteriores;
- misiones legacy.

No ampliar estos sistemas salvo que sean necesarios para B2B. Migrarlos o retirarlos únicamente con tests y compatibilidad explícita.

## Vertical existente: Nexovial
Nexovial es el primer test end-to-end y debe seguir funcionando durante el pivot. Su valor futuro es probar que el motor genérico soporta Company -> Workplace -> Role -> Procedure/Scenario. No agregar más lógica especial de Nexovial al Core.

---

# ASTRA FRIDAY — iteración grande

Objetivo de la sesión: convertir la semilla actual en un **vertical B2B genérico demostrable**, priorizando arquitectura y experiencia sobre cantidad de contenido.

## P0 — antes de crear contenido
1. Auditar repo completo y ejecutar tests/build disponibles. No asumir que main está sano.
2. Preservar Nexovial y saves; no regenerar assets masivamente.
3. Identificar y eliminar referencias activas a semáforos/música que hayan quedado, sin borrar material útil para una futura implementación.
4. Convertir tráfico circular restante a rutas abiertas entrada->salida y agregar spawner limitado si hace falta mantener calles vivas.
5. Medir nodos/NPC/tráfico y reducir coste del mundo antes de sumar escenarios.

## P0 — motor B2B
6. Implementar IndustryData, ProcedureData, ProcedureStepData, Equipment/PPE, RuleReference y TrainingResult de forma data-driven.
7. Crear ProcedureRunner independiente de UI y de empresas concretas.
8. Soportar prerequisitos, pasos obligatorios/opcionales, orden, errores, reintentos, interacción con world targets y feedback.
9. Crear telemetría local de sesión: timestamps, acciones, pasos, errores, omisiones, resultado. No recolectar PII innecesaria.
10. Integrar ProcedureRunner con Scenario/Shift sin convertir salario/dinero/reputación del viejo life-sim en el sistema de evaluación B2B.

## P1 — selector y primer módulo
11. Crear flujo Rubro -> Empresa/demo -> Puesto -> Capacitación.
12. Mantener Nexovial como vertical de oficina y migrarlo al nuevo ProcedureRunner.
13. Crear estructura del módulo Gastronomía con datos ficticios y sin afirmar certificación normativa.
14. Construir UN procedimiento jugable corto y pulido (higiene/preparación del puesto) usando equipamiento e interacciones reales del mundo.
15. El EPP/equipamiento debe depender del procedimiento/riesgo configurado; nunca imponer guantes/barbijo/cofia universalmente.

## P1 — experiencia empresarial
16. Resultado final entendible: completado, pasos, errores, omisiones, tiempo y feedback.
17. Separar UI del trabajador de futura UI administrativa.
18. Preparar interfaz/export serializable para que un backend web futuro pueda recibir TrainingResult.
19. No construir todavía autenticación, pagos ni dashboard SaaS dentro de Godot.

## P1 — mundo compacto
20. Inventariar todas las coordenadas authored antes de redimensionar.
21. Proponer y ejecutar una reducción segura del área jugable si Nexovial, rutas, cámara, minimapa e interiores pueden migrarse sin regresión.
22. Priorizar densidad y calidad de 4-8 edificios laborales sobre expansión urbana.
23. Mantener assets regionales como biblioteca visual; no volver a selección por países.

## Calidad obligatoria
- GDScript tipado donde evite inferencias ambiguas.
- Sin lógica por empresa dentro del Core.
- Sin strings mágicos para reglas críticas si pueden modelarse como datos.
- Tests unitarios/lógicos del ProcedureRunner.
- Test end-to-end de Nexovial.
- Smoke test del módulo Gastronomía.
- Desktop/web sin errores de parseo.
- No declarar Android/web “resuelto” sin probar la build correspondiente.
- Commits pequeños y reversibles.

## Definición de terminado de la sesión
Un usuario puede abrir VIDA, elegir un rubro disponible, entrar a una capacitación, realizar un procedimiento mediante acciones dentro del escenario, cometer un error, recibir feedback y finalizar con un TrainingResult estructurado. Nexovial sigue funcionando y el motor no contiene lógica específica del nuevo rubro.

Todo lo demás es secundario.
