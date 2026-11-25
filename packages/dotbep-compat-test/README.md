# Prototipo de compatibilidad dotBEP-PE

Pruebas aisladas para verificar operaciones básicas del paquete `.bep` con
`@dotbep/core` versión exacta `0.2.24`.

## Requisitos

- Node.js 22 o posterior.
- npm.
- Acceso al registro npm para instalar dependencias.

## Instalación y ejecución

Desde esta carpeta:

```powershell
npm install
npm run typecheck
npm test
npm run demo
```

El comando demo genera `artifacts/dotbep-compat-demo.bep`.

## Alcance actual

- Crear un BEP con metadatos de proyecto y `customData`.
- Guardar y reabrir el paquete.
- Comprobar preservación de metadatos.
- Modificar y volver a guardar.
- Comprobar persistencia de un recurso adicional del ZIP.
- Verificar commits `0.1` y `0.2`, `changelog.json`, diferencias y `baseline/bep.json`.
- Guardar y reabrir el paquete, reconstruir estados históricos con `history.get()`.
- Probar `history.revert()` como reversión no destructiva que crea una nueva versión.
- Crear workflows, consultar estado, emitir eventos y comprobar el historial de transiciones.
- Verificar cancelación y registro del actor en el historial de la instancia.
- Comprobar persistencia mediante un adaptador de prueba `InstanceStore` compartido entre reinicializaciones del motor.
- Verificar autorización RACI con el motor inicializado sin `skipRaci`: intersección rol-equipo, prioridad de Responsible sobre Accountable, autorización por correo explícito y registro de intentos denegados.

## Fuera de alcance

El adaptador compartido es una simulación de contrato, no una base de datos de producción.
Las pruebas no demuestran todavía persistencia real con PostgreSQL ni recuperación tras reinicio de proceso.
Tampoco prueban políticas institucionales completas, autorización para cancelar instancias,
segregación administrativa de aprobación ni conformidad normativa.
La matriz RACI de dotBEP debe evaluarse por separado para confirmar cómo representa asignaciones por equipo y correo, además de roles.
Las pruebas no sustituyen pruebas de integración con archivos reales de proyectos.

La versión de dependencia está fijada para hacer reproducible el ensayo.
Los resultados de ejecución local deben registrarse por separado; un archivo de prueba incorporado
al repositorio no implica que se haya ejecutado en todos los entornos.
