# Arquitectura de dotBEP-PE

**Estado:** propuesta técnica inicial  
**Repositorio:** `Pajares/BIM-Ca`  
**Rama:** `develop`  
**Piloto:** edificaciones públicas — desarrollo del expediente técnico

## 1. Propósito y límites

dotBEP-PE será una plataforma de gestión, planificación, control y trazabilidad de la información BIM del expediente técnico de inversiones públicas en el Perú.

No será un modelador BIM, no reemplazará Revit, Civil 3D, QGIS ni Autodesk Construction Cloud (ACC), y no sustituirá los registros ni las aprobaciones oficiales de Invierte.pe o de la entidad.

La plataforma relacionará requisitos, responsabilidades, entregables, revisiones, evidencias, versiones y decisiones. Las verificaciones automáticas apoyarán el control de calidad, pero no reemplazarán el juicio ni la aprobación de especialistas competentes.

## 2. Principios de arquitectura

1. **Núcleo separado:** reutilizar el proyecto original `@dotbep/core` como dependencia versionada; evitar bifurcarlo o modificarlo directamente salvo necesidad demostrada.
2. **Extensión peruana:** implementar las reglas, entidades y flujos específicos del contexto peruano en paquetes propios.
3. **Compatibilidad explícita:** validar cualquier dato que se intercambie con el formato y esquema de dotBEP. No asumir que el campo `extensions` del esquema es un mecanismo de plugins.
4. **Integración desacoplada:** conectar herramientas mediante adaptadores; una integración no debe convertirse en dependencia de todos los módulos.
5. **Trazabilidad:** registrar actor, fecha, objeto, versión, acción, resultado y evidencia.
6. **Segregación de funciones:** separar producción, revisión y aprobación; impedir la autoaprobación cuando corresponda.
7. **Automatización controlada:** las reglas automáticas generan resultados y observaciones; las decisiones técnicas y administrativas corresponden a responsables autorizados.
8. **Evolución incremental:** comenzar con un monolito modular y procesos worker; evaluar microservicios solo cuando exista una necesidad operativa demostrable.

## 3. Vista lógica

```text
Usuarios y roles institucionales
            |
            v
Aplicación web (React + TypeScript)
            |
            v
API y servicios de aplicación (Node.js + TypeScript)
            |
            +---- Núcleo dotBEP (@dotbep/core, versionado)
            |
            +---- Dominio peruano
            |       +-- Proyectos e inversiones
            |       +-- Normativa y aplicabilidad
            |       +-- Requisitos OIR / AIR / PIR / EIR
            |       +-- BEP y planificación MIDP / TIDP
            |       +-- Entregables y revisiones
            |       +-- QA/QC y gestión de incidencias
            |       +-- Trazabilidad, aprobaciones y reportes
            |
            +---- Persistencia PostgreSQL
            |
            +---- Adaptadores e integraciones
                    +-- ACC / Autodesk Platform Services
                    +-- Revit
                    +-- Civil 3D
                    +-- IFC
                    +-- QGIS
                    +-- Almacenamiento documental

Workers Python
    +-- IfcOpenShell
    +-- IfcTester / IDS
    +-- Validaciones y procesamiento de archivos
```

## 4. Componentes y responsabilidades

### 4.1 Aplicación web

Interfaz para configurar proyectos, consultar requisitos, gestionar BEP, planificar entregables, revisar resultados QA/QC, atender observaciones y consultar reportes. La interfaz aplicará permisos recibidos del backend; no será la autoridad final de autorización.

### 4.2 API y servicios de aplicación

Expondrá operaciones autenticadas, validará entradas, aplicará reglas de negocio, verificará permisos y coordinará transacciones, workflows y trabajos asíncronos. La API será la frontera de seguridad del sistema.

### 4.3 Núcleo dotBEP

Se consumirá como dependencia con versión fijada y pruebas de compatibilidad. Antes de ampliar su modelo se inspeccionarán sus tipos, validadores, normalizadores, API pública y comportamiento de apertura/guardado de paquetes `.bep`.

Los datos propios de Perú no se añadirán arbitrariamente a la raíz del BEP si el esquema original la restringe. Se definirá un mapeo documentado y validado, utilizando los mecanismos de extensión de datos que realmente admita el núcleo y, cuando corresponda, entidades relacionales externas.

### 4.4 Dominio peruano

Contendrá el modelo de proyectos e inversiones, referencias normativas y su aplicabilidad, requisitos de información, planificación, entregables, revisiones, aprobaciones, incidencias y reportes. Las reglas normativas tendrán fuente, versión, vigencia, ámbito de aplicación y responsable de validación.

### 4.5 Persistencia y evidencias

PostgreSQL almacenará entidades de negocio, relaciones, permisos, estados, metadatos y registros de auditoría. Los archivos pesados (RVT, DWG, IFC, nubes de puntos, PDF) permanecerán en ACC u otro repositorio documental institucional. La plataforma guardará identificadores, URI, versión, huella/hash cuando sea posible, metadatos y evidencias de revisión.

El historial del paquete BEP no se considerará por sí solo un registro de auditoría institucional inmutable. Se implementará un registro de eventos separado, protegido contra modificación ordinaria y con políticas de retención.

### 4.6 Workers BIM

Los workers Python ejecutarán tareas asíncronas: lectura de IFC, validación IDS, extracción de propiedades, controles geométricos seleccionados y generación de informes. Cada ejecución registrará versión de reglas, herramientas, parámetros, archivo de entrada y resultado para permitir reproducibilidad.

## 5. Módulos funcionales iniciales

| Módulo | Responsabilidad principal |
|---|---|
| Gestión de proyectos | Identificación, CUI y datos del proyecto, entidad y fase |
| Normativa | Fuentes, vigencia, ámbito y matriz de aplicabilidad |
| Requisitos de información | OIR, AIR, PIR y EIR |
| BEP | Configuración, versiones, acuerdos y entregas |
| Planificación | Responsables, RACI, MIDP y TIDP |
| Entregables | Paquetes, estados, versiones y fechas |
| QA/QC | Reglas, resultados, incidencias y excepciones |
| Revisiones y aprobaciones | Flujos, segregación de funciones y decisiones |
| Integraciones | ACC, Revit, Civil 3D, IFC y QGIS |
| Reportes y auditoría | Indicadores, evidencias y trazabilidad |

Los módulos se activarán de acuerdo con el alcance contractual y la aplicabilidad normativa del proyecto; no todas las inversiones se presumirán sujetas a las mismas obligaciones BIM.

## 6. Flujos principales

1. Configuración del proyecto y determinación de aplicabilidad.
2. Definición y aprobación de requisitos de información.
3. Elaboración y revisión del BEP.
4. Planificación de entregables y responsabilidades.
5. Producción de modelos y documentos en las herramientas especializadas.
6. Publicación o referencia de versiones en el CDE.
7. Validaciones automáticas y revisión interdisciplinaria.
8. Atención de observaciones, excepciones y nueva entrega.
9. Revisión técnica y aprobación por responsables autorizados.
10. Consolidación y cierre del expediente técnico.

## 7. Seguridad, roles y control

Se aplicará control de acceso por rol y por proyecto, con permisos específicos por acción y estado del flujo. Como mínimo se distinguirán productor, coordinador BIM, revisor especialista, responsable de aprobación y administrador.

La asignación concreta de responsabilidades deberá corresponder a la organización, contrato y normativa aplicables. La Contraloría no se configurará como aprobador genérico del expediente técnico.

## 8. Despliegue inicial

Se propone un monolito modular para la API, una aplicación web separada y workers Python ejecutados como procesos independientes. Docker facilitará entornos reproducibles. PostgreSQL será el repositorio transaccional; ACC o el repositorio institucional mantendrá los archivos de trabajo.

## 9. Decisiones pendientes de validar

- Estrategia de autenticación e identidad institucional.
- Versión de Node.js, React, TypeScript y PostgreSQL.
- Versión y contrato de integración de `@dotbep/core`.
- Modelo de datos peruano y correspondencia con el esquema BEP.
- Proveedor de almacenamiento documental y política de retención.
- Alcance real de integración con ACC y Autodesk Platform Services.
- Reglas QA/QC por disciplina y entregable.
- Requisitos de seguridad, alojamiento, respaldo y recuperación.

## 10. Criterios de aceptación de esta arquitectura

- El núcleo dotBEP puede actualizarse sin reescribir el dominio peruano.
- Los datos del proyecto y sus entregables tienen identificadores y relaciones consistentes.
- Cada revisión y aprobación puede reconstruirse a partir de registros y evidencias.
- Los archivos BIM se referencian por versión sin duplicar innecesariamente su almacenamiento.
- Las validaciones registran reglas y versiones utilizadas.
- La plataforma no confunde una validación automática o aceptación BIM con la aprobación administrativa del expediente.
