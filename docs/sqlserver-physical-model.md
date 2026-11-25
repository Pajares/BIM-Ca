# Modelo físico inicial de dotBEP-PE para SQL Server

**Estado:** primera versión de diseño físico; pendiente de validación en SQL Server 2025 Express.  
**Rama:** `develop`.  
**Script:** `database/sql/001_inversiones_expedientes.sql`.

## 1. Decisión de dominio

La entidad raíz es `proyectos.Inversion`, no `Proyecto`. Esto permite representar proyectos de inversión, IOARR y modalidades futuras mediante `proyectos.TipoInversion`, sin convertir la modalidad en una enumeración rígida de la aplicación.

El CUI es un identificador externo opcional y no es clave primaria. El modelo conserva por separado la entidad, unidad ejecutora, fase y el historial de cambios de fase.

## 2. Expedientes y jerarquía

Una inversión puede tener múltiples expedientes. `bim.ExpedienteTecnico.EsPrincipal` permite identificar como máximo un expediente principal por inversión mediante un índice único filtrado. Los expedientes complementarios se vinculan mediante `bim.RelacionExpediente`.

Los componentes y etapas pertenecen a la inversión y se asignan a expedientes mediante tablas puente. Las claves foráneas compuestas impiden asociar a un expediente componentes o etapas de otra inversión.

## 3. Versionado

`bim.VersionExpediente` conserva registros de versión. Los archivos y paquetes BEP se mantienen fuera de SQL Server; el campo `ReferenciaPaqueteBEP` es una referencia, no almacenamiento binario.

## 4. Controles incluidos

- Claves primarias y foráneas.
- Códigos únicos por ámbito.
- Índice único filtrado para CUI no nulo.
- Índice único filtrado para expediente principal.
- Restricciones de estado, fechas y zona UTM.
- `ROWVERSION` en entidades de concurrencia.
- Restricción de pertenencia a la misma inversión en relaciones expediente-componente-etapa.
- Datos específicos JSON validados con `ISJSON`.

## 5. Controles que requieren lógica transaccional adicional

El DDL inicial no resuelve por sí solo:
- Que el catálogo de modalidad coincida con la tabla de detalle PI o IOARR.
- Que las relaciones entre expedientes no formen ciclos ni cadenas jerárquicas inválidas.
- Que un componente o etapa no tenga un padre perteneciente a otra inversión.
- Que un expediente marcado principal tenga el tipo PRINCIPAL y que los complementarios tengan tipo compatible.
- La sincronización de la fase vigente con el último registro del historial.
- Las reglas oficiales de Invierte.pe para cada modalidad.

Estas reglas deben implementarse con servicios de dominio y transacciones; algunas podrán reforzarse con procedimientos almacenados o triggers cuidadosamente evaluados. No se debe confiar exclusivamente en validaciones de interfaz.

## 6. Supuestos y límites

- El script se ejecuta dentro de una base de datos ya creada y seleccionada.
- Crea los esquemas `proyectos` y `bim` si no existen.
- No configura usuarios, roles SQL, permisos, backups ni políticas de seguridad.
- No se ha ejecutado contra la instancia local del usuario.
- No constituye una migración de producción.
- No sustituye los registros oficiales de Invierte.pe ni define por sí solo la obligatoriedad normativa.

## 7. Validación pendiente

1. Ejecutar en una base de datos de desarrollo vacía en SQL Server 2025 Express.
2. Confirmar creación de tablas, índices, restricciones y catálogos.
3. Insertar datos de prueba PI e IOARR.
4. Probar expediente principal, complementarios, componentes y etapas.
5. Añadir pruebas negativas de integridad y reglas transaccionales.
6. Revisar nombres, tipos y mapeos con `@dotbep/core` antes de implementar el adaptador de persistencia.
