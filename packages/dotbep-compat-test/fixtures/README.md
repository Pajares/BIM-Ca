# Fixtures de compatibilidad

Los archivos binarios `.bep` generados durante las pruebas se guardan en
`artifacts/` y no se versionan inicialmente.

Cuando se incorporen fixtures de referencia:
- registrar su procedencia y versión de `@dotbep/core`;
- conservar una copia original inmutable;
- calcular y registrar SHA-256;
- no incluir información real, personal ni datos de proyectos públicos.
