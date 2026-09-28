# VIDA — Pivot a megaciudad única B2B

## Decisión de producto
VIDA deja de presentar países/ciudades seleccionables. El jugador crea su personaje y entra a una única megaciudad ficticia, enorme, persistente y viva. El juego sigue siendo un videojuego de vida urbana; B2B se integra dentro del mundo mediante empresas, trabajos, capacitación, operaciones y escenarios, no mediante un menú corporativo separado.

## Regla de migración
NO borrar assets regionales existentes. Argentina, Japón, Italia, Brasil y Estados Unidos pasan a ser bibliotecas de arquitectura/variaciones reutilizables dentro de una sola ciudad. Durante la migración se conserva el id interno `ar` como compatibilidad hasta desacoplar sistemas que todavía dependen de `country.id`.

## Objetivo de mundo
Una ciudad continua con distritos:
- Centro / financiero: oficinas, bancos, servicios, departamentos, gastronomía.
- Industrial: fábricas, plantas, talleres, seguridad industrial.
- Logístico: depósitos, centros de distribución, flotas, estaciones.
- Comercial: supermercados, retail, restaurantes, hoteles.
- Residencial: casas, edificios, plazas, escuelas, gimnasios.
- Salud: clínica, hospital, farmacia, laboratorio.
- Tecnológico / campus: oficinas modernas, laboratorios, capacitación.
- Periferia: rutas, estaciones de servicio, industria pesada y futuros complejos.

Los estilos regionales se mezclan de manera coherente por barrios; nunca se presentan como países elegibles.

## Loop jugable B2B
Vida personal -> desplazamiento -> trabajo/empresa -> situación o misión -> decisiones/interacciones -> consecuencias -> progreso/feedback -> regreso a la ciudad.

Una empresa es un lugar real del mapa. Puede tener exterior, interior, roles, NPC, turnos, procesos, misiones y permisos. El mismo motor debe servir para empresas distintas.

## Arquitectura objetivo
1. `WorldManager`: una ciudad activa, múltiples distritos; eliminar gradualmente la semántica de country.
2. `WorldCatalog`: catálogo de distritos de la megaciudad, no catálogo de países.
3. `RegionalAssets`: conservarlo como biblioteca visual/style pool; que región signifique estilo, no ubicación.
4. `Company/Workplace`: capa data-driven para empresas, puestos y escenarios.
5. `MissionSystem`: misiones personales y laborales; resultados observables.
6. Saves: migración compatible con saves existentes; nunca invalidarlos silenciosamente.
7. Minimap/transporte/tráfico: deben funcionar entre distritos y escalar sin simular toda la ciudad fuera de cámara.

## Primer vertical demostrable
Construir un distrito funcional con:
- vivienda del jugador;
- calles/tráfico/NPC/transporte existentes;
- zona comercial;
- zona de oficinas;
- complejo industrial/logístico;
- al menos una empresa ficticia completa;
- flujo casa -> traslado -> ingreso -> tarea laboral -> resultado -> regreso.

La empresa ficticia debe demostrar onboarding, operación y una situación inesperada sin usar datos privados ni depender de una marca real.

## No hacer todavía
- No borrar carpetas `ar/us/jp/it/br`.
- No regenerar masivamente arte.
- No reescribir todos los sistemas en una sola iteración.
- No crear 15 mapas separados.
- No convertir el menú principal en dashboard SaaS.
- No sacrificar Android, controles, rendimiento o estabilidad por el pivot.

## Orden de implementación
P0: quitar selección de país del flujo nuevo (iniciado en esta rama).
P0: crear identidad/nombre neutral de la megaciudad y distrito inicial.
P0: mantener carga, guardado, Android y mundo actual funcionando.
P1: desacoplar `country.id` de audio, eventos, home y regional content mediante compatibilidad.
P1: modelar distritos y navegación/streaming entre distritos.
P1: reutilizar assets regionales como variaciones arquitectónicas.
P1: introducir CompanyData / WorkplaceData / JobRoleData / ScenarioData.
P2: primer complejo empresarial jugable y misión laboral end-to-end.
P2: métricas de escenario/resultados.
P2: expansión de la ciudad y transporte interdistrital.

## Criterios de aceptación inmediatos
- Nueva partida no pregunta país.
- El juego arranca y sigue siendo jugable.
- Saves existentes siguen cargando.
- No hay referencias visibles a “elegir Argentina/Japón/Italia/Brasil/Estados Unidos”.
- El cambio no rompe desktop ni Android.
- Los assets actuales se preservan.
