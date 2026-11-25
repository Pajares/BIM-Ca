# Modelo de dominio y datos inicial de dotBEP-PE

**Estado:** diseño preliminar para revisión  
**Repositorio:** `Pajares/BIM-Ca`  
**Rama:** `develop`

Este documento define un primer mapa conceptual. No constituye todavía un esquema SQL definitivo ni afirma que estas entidades ya existan en `@dotbep/core`.

## 1. Criterios de modelado

- Separar el modelo de negocio peruano del formato de intercambio BEP.
- Usar identificadores internos estables (UUID/ULID) y conservar identificadores externos como CUI, IDs ACC y GUID IFC en campos específicos.
- Mantener relaciones explícitas entre proyecto, requisitos, entregables, archivos, revisiones, incidencias y decisiones.
- Versionar requisitos, reglas y entregables; no sobrescribir evidencia histórica.
- Registrar fechas en UTC y presentar fechas según la zona horaria configurada para el proyecto.
- Definir catálogos configurables para disciplinas, tipos de entregable, estados y severidades.
- No asumir que todos los proyectos tienen los mismos requisitos BIM ni las mismas disciplinas.

## 2. Entidades principales

### 2.1 Proyecto e inversión

**Project**
- id
- code
- name
- description
- investment_cui (nullable; identificador oficial, no clave primaria)
- investment_type
- public_entity_id
- executing_unit
- government_level
- location
- project_phase
- technical_stage
- applicability_status
- created_at / updated_at

**Organization**
- id
- legal_name
- organization_type
- official_identifier (nullable)

**ProjectMembership**
- project_id
- user_id
- role_id
- valid_from / valid_until
- status

La plataforma mantendrá referencias y evidencias de datos oficiales; no sustituirá los sistemas oficiales de Invierte.pe.

### 2.2 Normativa y aplicabilidad

**RegulatorySource**
- id
- title
- source_type
- issuing_authority
- publication_reference
- publication_date
- effective_from / effective_until
- official_uri
- version
- status

**ApplicabilityRule**
- id
- regulatory_source_id
- rule_code
- description
- conditions (estructuradas y versionadas)
- effective_from / effective_until

**ProjectApplicability**
- id
- project_id
- applicability_rule_id
- determination (applies / does_not_apply / pending / exception)
- rationale
- evidence_reference
- determined_by
- determined_at
- reviewed_by
- reviewed_at

La determinación de aplicabilidad debe poder revisarse y justificarse. No inferir obligatoriedad BIM solo por tratarse de una obra pública.

### 2.3 Requisitos de información

**InformationRequirement**
- id
- project_id
- requirement_type (OIR / AIR / PIR / EIR)
- code
- title
- description
- version
- status
- owner_role_id
- approved_at

**RequirementItem**
- id
- information_requirement_id
- code
- description
- discipline_id (nullable)
- delivery_stage
- verification_method
- acceptance_criteria
- priority

**RequirementMapping**
- id
- requirement_item_id
- bep_id
- deliverable_type_id
- ids_specification_uri (nullable)
- mapping_status

Los requisitos deben ser verificables y trazables hasta uno o más entregables y criterios de aceptación.

### 2.4 BEP y planificación

**BepRecord**
- id
- project_id
- package_uri / package_reference
- package_version
- core_version
- status
- submitted_by
- submitted_at
- approved_by
- approved_at

**BimUse**
- id
- project_id
- code
- name
- description
- applicable_stage
- status

**DeliveryPlan**
- id
- project_id
- plan_type (MIDP / TIDP)
- version
- status
- approved_at

**PlannedDelivery**
- id
- delivery_plan_id
- deliverable_type_id
- discipline_id
- responsible_role_id
- planned_date
- acceptance_criteria_id
- status

RACI puede representarse mediante asignaciones de responsabilidades ligadas a actividades, roles y entregables, evitando codificar una matriz fija para todos los contratos.

### 2.5 Entregables y archivos

**Deliverable**
- id
- project_id
- planned_delivery_id (nullable)
- code
- title
- discipline_id
- deliverable_type_id
- status
- current_version_id

**DeliverableVersion**
- id
- deliverable_id
- version_label
- file_reference_id
- submitted_by
- submitted_at
- supersedes_version_id (nullable)
- checksum (nullable)
- status

**FileReference**
- id
- storage_provider
- container_or_project_id
- external_file_id
- uri
- filename
- media_type
- file_size
- checksum
- created_at

Los binarios se conservarán en ACC o en el repositorio documental aprobado. La base de datos guardará referencias, metadatos y relaciones; no asumirá que todos los archivos se cargan directamente a PostgreSQL.

### 2.6 QA/QC, revisiones e incidencias

**ValidationRule**
- id
- code
- title
- validation_level (documental / información / geométrico / técnico-normativo)
- discipline_id (nullable)
- rule_version
- severity_default
- executable_reference
- status

**ValidationRun**
- id
- deliverable_version_id
- rule_set_version
- tool_name
- tool_version
- parameters
- started_at / completed_at
- execution_status
- summary

**ValidationFinding**
- id
- validation_run_id
- rule_id
- severity
- result_status
- message
- object_reference (nullable; por ejemplo GUID IFC)
- evidence_reference (nullable)

**Review**
- id
- deliverable_version_id
- reviewer_id
- review_type
- decision
- comments
- reviewed_at

**Issue**
- id
- project_id
- deliverable_version_id
- finding_id (nullable)
- title
- description
- severity
- status
- assigned_to
- due_date
- resolved_at

**ExceptionRecord**
- id
- project_id
- related_requirement_id (nullable)
- related_finding_id (nullable)
- justification
- requested_by
- authorized_by
- decision
- decided_at
- expiry_date (nullable)

Una validación aprobada por regla automática no equivale a una revisión técnica favorable. Las excepciones deben registrar justificación, autoridad, alcance y vigencia.

### 2.7 Workflows, aprobaciones y auditoría

**WorkflowDefinition**
- id
- code
- version
- project_type
- configuration
- status

**WorkflowInstance**
- id
- project_id
- definition_id
- subject_type
- subject_id
- current_state
- started_at
- completed_at

**WorkflowAction**
- id
- workflow_instance_id
- action
- actor_id
- from_state
- to_state
- occurred_at
- comment
- evidence_reference

**Approval**
- id
- subject_type
- subject_id
- approval_stage
- decision
- approver_id
- decided_at
- rationale

**AuditEvent**
- id
- project_id
- actor_id
- action
- entity_type
- entity_id
- entity_version
- occurred_at
- correlation_id
- before_hash (nullable)
- after_hash (nullable)
- metadata

AuditEvent debe ser append-only desde la aplicación ordinaria, con controles de acceso, respaldo y política de retención. Para garantías fuertes de inmutabilidad se requerirá almacenamiento o mecanismo externo apropiado.

## 3. Relaciones conceptuales

```text
Organization 1---N Project
Project 1---N ProjectMembership
Project 1---N ProjectApplicability
RegulatorySource 1---N ApplicabilityRule
Project 1---N InformationRequirement
InformationRequirement 1---N RequirementItem
RequirementItem N---N DeliverableType (mediante RequirementMapping)
Project 1---N BepRecord
Project 1---N DeliveryPlan
DeliveryPlan 1---N PlannedDelivery
PlannedDelivery 1---N Deliverable
Deliverable 1---N DeliverableVersion
DeliverableVersion N---1 FileReference
DeliverableVersion 1---N ValidationRun
ValidationRun 1---N ValidationFinding
DeliverableVersion 1---N Review
Project 1---N Issue
Project 1---N WorkflowInstance
WorkflowInstance 1---N WorkflowAction
Project 1---N AuditEvent
```

## 4. Estados y catálogos

Los estados deben definirse mediante transiciones permitidas, no como texto libre. Como punto de partida:

- Entregable: planned, in_preparation, submitted, under_review, observations, accepted, rejected, superseded.
- Incidencia: open, assigned, in_progress, resolved, verified, closed, reopened.
- Requisito: draft, under_review, approved, superseded, withdrawn.
- Aplicabilidad: pending, applies, does_not_apply, exception.

Los nombres definitivos y traducciones se validarán con los procesos institucionales y contractuales del piloto.

## 5. Reglas de integridad críticas

1. Un CUI no reemplaza el identificador interno del proyecto.
2. No se permite aprobar una versión que no haya sido presentada y revisada conforme al flujo definido.
3. El productor no puede aprobar su propia entrega cuando exista segregación de funciones.
4. Toda decisión debe identificar actor, fecha, objeto y versión.
5. Una nueva versión no elimina la anterior ni sus observaciones.
6. Un resultado QA/QC debe conservar la versión de reglas y herramientas utilizadas.
7. Un entregable aceptado no equivale por sí solo a aprobación administrativa del expediente técnico.
8. Los requisitos deben poder rastrearse hasta entregables, revisiones y evidencias.
9. La aplicabilidad normativa debe conservar fuente, vigencia, razonamiento y responsable.
10. Los accesos a archivos externos deben verificarse; una URI no demuestra que el usuario tenga permisos para abrirla.

## 6. Próximas validaciones antes del esquema SQL

- Contrastar entidades con los tipos reales y la API pública de `@dotbep/core`.
- Determinar qué información se conserva dentro del paquete `.bep` y qué queda en PostgreSQL.
- Definir catálogo de disciplinas y entregables del piloto de edificaciones públicas.
- Definir el modelo de usuarios, organizaciones, contratos y permisos.
- Confirmar el flujo institucional de revisión y aprobación del expediente.
- Definir estrategia de versionado, retención y evidencia documental.
- Probar exportación, apertura y preservación de metadatos en paquetes BEP.
