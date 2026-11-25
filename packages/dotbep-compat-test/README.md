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

## Fuera de alcance

Estas pruebas no demuestran todavía compatibilidad integral de workflows,
persistencia de instancias, permisos, ni conformidad normativa.
Tampoco sustituyen pruebas de integración con archivos reales de proyectos.

La versión de dependencia está fijada para hacer reproducible el ensayo.
No se declara que las pruebas hayan sido ejecutadas hasta disponer de un
entorno Node.js y registrar sus resultados.
