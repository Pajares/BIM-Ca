# Matriz de reutilización del núcleo dotBEP para dotBEP-PE

**Estado:** evaluación técnica preliminar basada en inspección del repositorio original  
**Proyecto destino:** `Pajares/BIM-Ca`  
**Rama destino:** `develop`

## 1. Objetivo

Determinar qué capacidades de `HoyosJuan/dotbep` pueden reutilizarse, cuáles requieren adaptación y cuáles deben implementarse en dotBEP-PE. Esta matriz no afirma que los módulos peruanos estén implementados.

La inspección previa fue principalmente estática (lectura de README, esquema JSON y código fuente). No se han ejecutado instalación, compilación, pruebas automatizadas ni pruebas de integración.

## 2. Matriz de capacidades

| Capacidad | Soporte observado en dotBEP | Tratamiento en dotBEP-PE | Verificación pendiente |
|---|---|---|---|
| Paquete BEP `.bep` | Apertura y creación mediante ZIP y `bep.json` | Reutilizar formato y API pública | Pruebas de ida y vuelta y preservación de datos |
| Esquema BEP | Esquema JSON Schema draft 2020-12 | Reutilizar como contrato del núcleo | Compatibilidad de versiones y validadores |
| Roles, miembros y equipos | Entidades presentes en el modelo BEP | Mapear roles del proyecto y responsabilidades | Reglas de autorización institucional |
| Disciplinas | Entidad `disciplines` | Reutilizar y ampliar catálogos mediante modelo compatible | Catálogo piloto y códigos contractuales |
| Entregables | Entidad `deliverables` | Reutilizar como referencia de planificación y entrega | Versiones, archivos externos y ciclo de revisión |
| Hitos y fases | Entidades `milestones` y `phases` | Mapear fases del trabajo BIM | Correspondencia con ciclo de inversión y expediente |
| Usos BIM y objetivos | Entidades `bimUses` y `objectives` | Reutilizar y relacionar con requisitos de información | Modelo de requisitos verificables |
| LOD / LOI / LOIN | Entidades de LOD, LOI y LOIN | Reutilizar donde la semántica sea compatible | Alineación con EIR y especificaciones del proyecto |
| Workflows | Motor de workflows y automatizaciones | Reutilizar motor cuando encaje; implementar políticas externas | Persistencia, concurrencia, permisos y fallos |
| Historial BEP | Historial basado en JSON Patch, baselines y commits | Reutilizar para cambios del paquete BEP | Integridad, autoría y comportamiento ante conflictos |
| Reportes y memorias | Gestión propia del núcleo | Reutilizar selectivamente | Ciclo de vida, exportación y versionado |
| Estándares y guías | Entidades de standards y guides | Reutilizar como referencias del BEP | Gestión de fuentes normativas peruanas y vigencia |
| Automatizaciones | Entidades y runtime de automations | Integrar tareas compatibles; mantener workers BIM externos | Contratos, reintentos, seguridad y observabilidad |
| Persistencia de instancias | Store intercambiable; memoria por defecto | Implementar adaptador persistente o servicio propio | Recuperación tras reinicio y consistencia transaccional |
| Requisitos OIR/AIR/PIR/EIR | No se ha confirmado un módulo completo con semántica ISO 19650 | Desarrollar dominio peruano y mapeos | Definiciones, relaciones y aprobaciones |
| MIDP/TIDP | No se ha confirmado implementación completa | Desarrollar planificación detallada | Asignaciones, dependencias, fechas y revisiones |
| Invierte.pe / CUI | No se ha confirmado soporte específico | Desarrollar módulo de proyecto e inversión | Identificadores, fases, entidades y fuentes oficiales |
| Aplicabilidad normativa peruana | No se ha confirmado motor específico | Desarrollar matriz de aplicabilidad | Reglas versionadas, vigencia y evidencia |
| QA/QC de modelos IFC | El núcleo no realiza por sí mismo validación BIM interna | Workers Python independientes | IDS, reglas geométricas y reportes reproducibles |
| Revisión técnica y aprobación institucional | No se ha confirmado segregación institucional completa | Desarrollar flujo con autorización y evidencia | Roles, no autoaprobación y delegaciones |
| Auditoría institucional | El historial BEP no equivale a un log inmutable de toda la aplicación | Desarrollar registro append-only separado | Retención, acceso, respaldo y protección contra alteración |
| Conector ACC | No se ha confirmado conector institucional listo para el piloto | Desarrollar adaptador desacoplado | APS, OAuth, permisos, versiones y webhooks |
| Integraciones Revit/Civil 3D/QGIS | No se ha confirmado integración completa | Desarrollar conectores según casos de uso | API disponible, formatos y estrategia de sincronización |

## 3. Hallazgos técnicos que condicionan el diseño

### 3.1 El esquema BEP tiene una raíz cerrada

El esquema observado utiliza `additionalProperties: false` en la raíz del BEP y requiere un conjunto amplio de propiedades. Por tanto, agregar una propiedad peruana arbitraria en la raíz puede romper la validación.

**Decisión:** no añadir `pe` ni otros campos raíz hasta demostrar que el esquema y el runtime aceptan esa extensión. El modelo peruano tendrá contratos y persistencia propios, con un mapeo explícito al paquete BEP.

### 3.2 `extensions` no es un registro de plugins

En el esquema original, `extensions` representa formatos de archivo admitidos y se relaciona con tipos de activos. No debe utilizarse para registrar módulos funcionales, plugins o integraciones.

**Decisión:** las integraciones se implementarán como adaptadores de la aplicación, fuera de esa propiedad.

### 3.3 El historial del BEP no sustituye la auditoría institucional

El historial observado utiliza diferencias JSON Patch, baselines y commits para versionar el contenido BEP. Los reportes y memorias tienen tratamiento separado. No se debe asumir que cada acceso, aprobación, exportación, cambio de permiso o decisión institucional queda registrado como evento inmutable.

**Decisión:** mantener historial del paquete BEP y auditoría de aplicación como dos mecanismos distintos, relacionados mediante identificadores y versiones.

### 3.4 Los workflows requieren una capa de autorización

El motor dispone de operaciones para crear, emitir, consultar, cancelar y reintentar instancias. La operación de cancelación registra un actor, pero la autorización efectiva debe implementarla el consumidor. La opción `skipRaci` se destina a pruebas locales.

**Decisión:** no exponer operaciones del motor directamente a usuarios. La API de dotBEP-PE debe validar rol, proyecto, estado, segregación de funciones y política de transición antes de invocarlas.

### 3.5 La persistencia debe ser verificada

El runtime admite un `InstanceStore` intercambiable y utiliza almacenamiento en memoria por defecto.

**Decisión:** no considerar el motor listo para producción hasta demostrar persistencia duradera, recuperación de instancias, consistencia y comportamiento concurrente.

## 4. Arquitectura de integración recomendada

```text
Aplicación dotBEP-PE
  |
  +-- Dominio peruano y políticas institucionales
  |     +-- Proyectos / Invierte.pe
  |     +-- Normativa y aplicabilidad
  |     +-- Requisitos / BEP / MIDP / TIDP
  |     +-- Revisiones / aprobaciones / auditoría
  |
  +-- Adaptador dotBEP
  |     +-- @dotbep/core (versión fijada)
  |     +-- Conversión y validación de datos
  |     +-- Apertura / creación / exportación .bep
  |
  +-- Servicios externos
        +-- PostgreSQL
        +-- Workers BIM
        +-- ACC / almacenamiento documental
        +-- Revit / Civil 3D / QGIS
```

El adaptador será la única capa que conozca directamente los detalles de integración con `@dotbep/core`. Los módulos peruanos no deberán depender de clases internas del núcleo.

## 5. Pruebas obligatorias antes de adoptar el núcleo en producción

1. Crear un BEP de prueba, guardarlo, abrirlo y comparar el contenido lógico.
2. Abrir paquetes existentes de distintas versiones y registrar compatibilidad.
3. Comprobar qué ocurre con propiedades desconocidas y archivos adicionales dentro del ZIP.
4. Verificar qué elementos incluye y excluye el historial.
5. Reiniciar el proceso y comprobar recuperación de workflows con almacenamiento persistente.
6. Ejecutar transiciones concurrentes y probar reintentos y cancelaciones.
7. Verificar que las políticas de autorización bloqueen autoaprobaciones y operaciones no permitidas.
8. Comprobar que un BEP exportado pueda abrirse con el núcleo original sin pérdida de datos esenciales.

## 6. Riesgos y controles

| Riesgo | Control propuesto |
|---|---|
| Acoplamiento excesivo al núcleo | Adaptador y pruebas de contrato |
| Pérdida de datos al exportar `.bep` | Pruebas de ida y vuelta y esquema versionado |
| Confundir historial con auditoría | Registro institucional independiente |
| Workflows sin autorización suficiente | Políticas en API y pruebas negativas |
| Pérdida de instancias por almacenamiento en memoria | Persistencia duradera antes de producción |
| Cambios incompatibles del núcleo | Fijar versión y actualizar mediante pruebas |
| Normativa mal aplicada | Fuente, vigencia, ámbito, justificación y revisión responsable |

## 7. Decisión técnica preliminar

**Reutilizar:** formato `.bep`, modelo y esquema del núcleo, entidades BEP compatibles, motor de workflows y mecanismo de historial, sujeto a pruebas.

**Adaptar:** roles, disciplinas, entregables, hitos, fases, estándares, guías, automatizaciones y persistencia.

**Desarrollar en dotBEP-PE:** Invierte.pe, aplicabilidad normativa peruana, requisitos OIR/AIR/PIR/EIR, MIDP/TIDP, QA/QC BIM, aprobaciones institucionales, auditoría integral y conectores ACC/CAD/BIM/SIG.

## 8. Límites de esta auditoría

La matriz es una evaluación de diseño basada en la inspección estática previa de archivos del repositorio original, incluyendo README, `package.json`, `src/index.ts`, `src/runtime/Engine.ts`, `src/base/history.ts` y `bep.schema.json`.

No es una certificación de compatibilidad, conformidad ISO 19650 ni aptitud para producción. La siguiente fase debe ejecutar pruebas técnicas sobre una versión concreta del núcleo y documentar resultados reproducibles.
