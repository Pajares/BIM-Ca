# Prototipo de compatibilidad con @dotbep/core

**Proyecto:** dotBEP-PE  
**Rama de trabajo:** develop  
**Estado:** especificación de pruebas; ejecución pendiente

## 1. Objetivo

Construir una prueba aislada que permita comprobar la integración con una versión fijada de `@dotbep/core`, sin acoplar el dominio peruano a las estructuras internas del núcleo y sin modificar el repositorio original.

La prueba debe responder si dotBEP-PE puede crear, abrir, inspeccionar, modificar y volver a exportar paquetes `.bep` conservando la información que el núcleo reconoce.

## 2. Alcance de la primera prueba

Incluye:

- Instalación reproducible de una versión concreta de `@dotbep/core`.
- Creación de un BEP mínimo mediante la API pública.
- Exportación del paquete a archivo.
- Reapertura del archivo exportado.
- Lectura de entidades representativas.
- Cambio controlado de un dato admitido por el núcleo.
- Nueva exportación y reapertura.
- Comparación lógica de los datos antes y después.
- Registro de versión de paquete, Node.js, sistema operativo y resultado.

No incluye todavía:

- Conexión a ACC.
- Integración con Revit, Civil 3D o QGIS.
- Persistencia institucional PostgreSQL.
- Workflows productivos o autorizaciones institucionales.
- Modificación del esquema original para introducir campos peruanos.
- Validación de modelos IFC.

## 3. Estructura aislada propuesta

```text
packages/
  dotbep-adapter/
    package.json
    src/
      index.ts
      core-client.ts
      package-roundtrip.ts
    test/
      create-open-export.test.ts
      preservation.test.ts
      adapter-contract.test.ts
    fixtures/
      README.md
```

Esta estructura es una propuesta. Antes de crear archivos de código se debe confirmar la estructura real del repositorio y acordar el gestor de paquetes y la configuración TypeScript.

## 4. Contrato del adaptador

El resto de dotBEP-PE no debe importar clases internas de `@dotbep/core`. La integración se concentrará en una interfaz propia equivalente a:

```ts
export interface DotbepAdapter {
  create(input: CreateBepInput): Promise<BepPackage>;
  open(source: BepSource): Promise<BepPackage>;
  inspect(pkg: BepPackage): Promise<BepSummary>;
  export(pkg: BepPackage): Promise<Uint8Array>;
}
```

Los tipos anteriores son un contrato conceptual, no una afirmación sobre la API existente de `@dotbep/core`. La implementación se ajustará únicamente después de verificar las exportaciones públicas reales del paquete.

## 5. Casos de prueba y criterios de aceptación

### CP-01 — Instalación reproducible

- Fijar versión exacta de `@dotbep/core`.
- Registrar versión de Node.js y gestor de paquetes.
- Conservar lockfile.
- Instalar desde un entorno limpio.

**Aceptación:** la instalación se repite usando el lockfile sin resolver versiones diferentes.

### CP-02 — Creación

- Crear un BEP mínimo usando la API pública.
- Validar el objeto contra el esquema aplicable.
- Exportar un archivo `.bep`.

**Aceptación:** el paquete se genera y puede ser identificado como archivo ZIP válido con los componentes esperados.

### CP-03 — Apertura

- Abrir el archivo generado con la API pública.
- Inspeccionar proyecto, roles, disciplinas y entregables de prueba.

**Aceptación:** la apertura finaliza sin error y las entidades esperadas están disponibles.

### CP-04 — Modificación controlada

- Modificar un campo de prueba permitido por el modelo.
- Guardar/exportar el paquete.
- Reabrirlo.

**Aceptación:** el cambio persiste y no altera datos ajenos a la prueba.

### CP-05 — Preservación

Comparar el estado lógico anterior y posterior, excluyendo únicamente campos que el núcleo genere de manera legítima (por ejemplo, marcas temporales o metadatos de historial, si se demuestra su comportamiento).

**Aceptación:** no se pierden entidades, relaciones, archivos ni propiedades reconocidas.

### CP-06 — Datos desconocidos y archivos adicionales

- Comprobar el comportamiento frente a propiedades no reconocidas.
- Comprobar si archivos adicionales dentro del ZIP se conservan o se descartan al abrir y exportar.

**Aceptación:** el comportamiento queda documentado. No se exigirá preservar datos no soportados si el núcleo no lo garantiza; los datos peruanos críticos no se colocarán allí sin una solución validada.

### CP-07 — Historial

- Ejecutar un cambio controlado.
- Consultar commits, diffs o mecanismos públicos equivalentes.
- Comprobar qué cambios quedan registrados.

**Aceptación:** se identifica con precisión qué cubre el historial del BEP y qué queda fuera de él.

### CP-08 — Workflows y persistencia

- Crear una instancia de workflow de prueba.
- Ejecutar una transición permitida.
- Reiniciar el proceso con el mecanismo de almacenamiento seleccionado.
- Recuperar la instancia.

**Aceptación:** la instancia se recupera correctamente con almacenamiento persistente. El almacenamiento en memoria no será aceptado como persistencia de producción.

## 6. Evidencias que se deben guardar

Cada ejecución registrará:

- Identificador de prueba.
- Fecha y hora.
- Commit del repositorio dotBEP-PE.
- Versión exacta de `@dotbep/core`.
- Versión de Node.js y gestor de paquetes.
- Hash SHA-256 del archivo de entrada y salida.
- Resultado por caso de prueba.
- Diferencias detectadas.
- Logs de error y observaciones.

No se almacenarán credenciales, tokens ni datos personales reales en fixtures o logs.

## 7. Reglas de decisión

### Integración aceptada

Solo si se completan las pruebas de creación, apertura, exportación y preservación, y se conocen los límites del historial y workflows.

### Integración aceptada con restricciones

Si el ciclo BEP funciona, pero ciertas propiedades, archivos adicionales o mecanismos de runtime no se conservan. Las limitaciones deberán quedar encapsuladas en el adaptador.

### Integración no aceptada

Si se pierden datos esenciales, no existe una API pública suficiente o el comportamiento no puede probarse de manera reproducible. En ese caso se revisará la estrategia de integración antes de avanzar.

## 8. Orden de ejecución

1. Inspeccionar estructura real y scripts del repositorio destino.
2. Confirmar API pública y versión del núcleo.
3. Crear el paquete de prueba aislado.
4. Implementar CP-01 a CP-05.
5. Ejecutar y guardar evidencias.
6. Implementar CP-06 a CP-08.
7. Emitir un informe de compatibilidad con resultados reales.

## 9. Estado actual

Este documento define el plan y los criterios. **Las pruebas aún no se han ejecutado** y no se declara compatibilidad hasta contar con resultados reproducibles.
