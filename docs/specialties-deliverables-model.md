# Modelo físico: especialidades BIM y entregables

**Proyecto:** dotBEP-PE  
**Motor:** Microsoft SQL Server 2025  
**Rama:** `develop`  
**Migración:** `database/sql/002_especialidades_entregables.sql`  
**Dependencia:** requiere `001_inversiones_expedientes.sql`.

## 1. Objetivo

Extender el modelo de inversiones y expedientes con especialidades BIM, asignación de responsables, entregables y control de versiones. La estructura admite entregables generales del expediente, entregables asociados a componentes y entregables transversales a varios componentes o especialidades.

La migración no modifica las tablas de la migración 001.

## 2. Entidades incorporadas

| Tabla | Propósito |
|---|---|
| `bim.Especialidad` | Catálogo configurable de disciplinas. Incluye códigos iniciales ARQ, EST, SAN, ELE, MEC, COM, PCI, TOPO, GEO y EXT. |
| `bim.ExpedienteEspecialidad` | Asigna especialidades a expedientes; define alcance, estado y especialidad principal opcional. |
| `bim.RolEspecialidad` | Catálogo de roles de participación por especialidad. |
| `bim.ResponsableEspecialidad` | Asigna usuarios externos a una especialidad de un expediente y a un rol. |
| `bim.TipoEntregable` | Catálogo configurable de clases de entregable. |
| `bim.Entregable` | Registra el producto de información dentro de un expediente. |
| `bim.EntregableEspecialidad` | Asociación N:M entre entregables y especialidades del mismo expediente. |
| `bim.EntregableComponente` | Asociación N:M entre entregables y componentes incluidos en el mismo expediente. |
| `bim.EntregableVersion` | Historial de versiones, metadatos de archivo, estado y referencia externa. |

## 3. Relaciones y reglas

- Un expediente puede tener varias especialidades; una especialidad puede participar en varios expedientes.
- Un entregable pertenece a un solo expediente.
- Un entregable puede asociarse a ninguna, una o varias especialidades.
- Un entregable puede asociarse a ninguno, uno o varios componentes.
- Si un entregable no tiene filas en `EntregableComponente`, se interpreta como entregable general del expediente. Si tiene una o más filas, su alcance se concreta en esos componentes; varias asociaciones permiten entregables transversales.
- Las asociaciones de especialidad y componente se validan con claves foráneas compuestas para impedir asociaciones con otra asignación o expediente.
- Cada entregable puede tener varias versiones y un máximo de una marcada como vigente mediante índice único filtrado.
- El catálogo inicial no es cerrado: se pueden añadir códigos nuevos sin alterar el esquema.
- `UsuarioExternoId` y `CreadoPorExternoId` son identificadores de integración provisionales. No son todavía claves foráneas a un módulo de identidad/seguridad.
- Los roles de especialidad describen la participación asignada. No sustituyen la matriz RACI ni conceden por sí solos autorización para aprobar o cambiar estados.
- Los archivos binarios permanecen en ACC u otro repositorio documental. SQL Server conserva metadatos, identificadores externos, ubicación y hash SHA-256.

## 4. Estados iniciales

### Especialidad asignada
- `ACTIVA`
- `SUSPENDIDA`
- `CERRADA`

### Entregable
- `PLANIFICADO`
- `EN_PRODUCCION`
- `EN_REVISION`
- `OBSERVADO`
- `ACEPTADO`
- `CERRADO`
- `CANCELADO`

### Versión del entregable
- `BORRADOR`
- `ENVIADA`
- `EN_REVISION`
- `OBSERVADA`
- `ACEPTADA`
- `RECHAZADA`
- `SUPERADA`

Los estados son una base inicial para el flujo de trabajo. Su transición y autorización deben implementarse en la capa de dominio/workflow, con actor, fecha, evidencia y auditoría.

## 5. Índices y restricciones

La migración incorpora:
- Claves primarias y foráneas.
- Unicidad de códigos de especialidad, roles y tipos de entregable.
- Unicidad de código de entregable dentro del expediente.
- Máximo una especialidad principal activa por expediente.
- Máximo una especialidad responsable principal por entregable.
- Máximo una versión vigente por entregable.
- Unicidad del número de versión por entregable.
- Validaciones de estado, fechas, tamaño de archivo y formato hexadecimal del hash SHA-256.
- Índices para consultas por expediente, especialidad, usuario, componente y versión.

## 6. Validaciones que requieren lógica de aplicación

El DDL no garantiza por sí solo:
- Que un expediente tenga al menos una especialidad cuando su alcance lo requiera.
- Que toda asociación de componente tenga una asociación de especialidad, o viceversa; ambas relaciones son independientes intencionalmente.
- Que la especialidad principal de un entregable tenga asignado un responsable activo.
- Que los cambios de estado sigan transiciones permitidas.
- Que una versión aceptada sea inmutable y que los metadatos coincidan con el archivo externo.
- Que el usuario asignado tenga credenciales, pertenezca a la organización o cuente con permisos efectivos.
- Que el rol APROBADOR equivalga a una autorización de aprobación. La autorización deberá resolverse mediante workflow/RACI y políticas de seguridad.
- Que una inversión, expediente, componente o especialidad cumpla automáticamente requisitos normativos; estos requieren reglas y revisión técnica.

Estas reglas deben implementarse en servicios de dominio y operaciones transaccionales, y cubrirse con pruebas positivas y negativas.

## 7. Ejecución y validación pendientes

La migración fue publicada en `develop`, pero no se ha ejecutado en la instancia local del usuario. Antes de ejecutarla:

1. Confirmar que SSMS está conectado a la instancia correcta.
2. Seleccionar `dotBEP_PE_DEV`.
3. Confirmar que la migración 001 está aplicada y que existen sus tablas.
4. Revisar y respaldar la base de datos de desarrollo.
5. Ejecutar 002 una sola vez.
6. Verificar tablas, claves foráneas, índices y catálogos.
7. Probar un entregable general, uno asociado a un componente y uno transversal.
8. Probar varias especialidades por entregable y varias versiones por entregable.
9. Ejecutar pruebas negativas para impedir asociaciones entre expedientes distintos.

**Estado:** diseño y script publicados; ejecución y validación en SQL Server pendientes.
