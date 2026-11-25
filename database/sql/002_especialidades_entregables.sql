/*
  dotBEP-PE - SQL Server 2025
  002_especialidades_entregables.sql

  Alcance:
  - Catálogo configurable de especialidades BIM y roles.
  - Asignación de especialidades y responsables por expediente.
  - Entregables generales, por componente y transversales.
  - Asociación de entregables con varias especialidades y componentes.
  - Versionado de entregables y referencias a repositorios externos.

  Requisitos:
  - Ejecutar sobre una base de datos que ya tenga aplicada 001_inversiones_expedientes.sql.
  - Seleccionar explícitamente la base de datos de destino antes de ejecutar.
  - No crea la base de datos ni configura usuarios/permisos.
  - No almacena archivos binarios en SQL Server.
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID(N'bim.ExpedienteTecnico', N'U') IS NULL
    THROW 51000, N'No existe bim.ExpedienteTecnico. Ejecute primero 001_inversiones_expedientes.sql.', 1;
IF OBJECT_ID(N'bim.ExpedienteComponente', N'U') IS NULL
    THROW 51000, N'No existe bim.ExpedienteComponente. Ejecute primero 001_inversiones_expedientes.sql.', 1;
IF OBJECT_ID(N'bim.Especialidad', N'U') IS NOT NULL
    THROW 51000, N'La migración 002 parece estar aplicada: ya existe bim.Especialidad.', 1;
GO

BEGIN TRANSACTION;
GO

CREATE TABLE bim.Especialidad (
    EspecialidadId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Especialidad PRIMARY KEY,
    Codigo NVARCHAR(20) NOT NULL,
    Nombre NVARCHAR(150) NOT NULL,
    Descripcion NVARCHAR(500) NULL,
    Activo BIT NOT NULL CONSTRAINT DF_Especialidad_Activo DEFAULT (1),
    EsSistema BIT NOT NULL CONSTRAINT DF_Especialidad_EsSistema DEFAULT (0),
    FechaRegistro DATETIME2(0) NOT NULL CONSTRAINT DF_Especialidad_Fecha DEFAULT SYSUTCDATETIME(),
    CONSTRAINT UQ_Especialidad_Codigo UNIQUE (Codigo)
);

INSERT INTO bim.Especialidad (Codigo, Nombre, Descripcion, EsSistema)
VALUES
(N'ARQ', N'Arquitectura', N'Diseño arquitectónico y espacios.', 1),
(N'EST', N'Estructuras', N'Diseño y documentación estructural.', 1),
(N'SAN', N'Instalaciones sanitarias', N'Agua, desagüe y drenaje.', 1),
(N'ELE', N'Instalaciones eléctricas', N'Instalaciones eléctricas y alumbrado.', 1),
(N'MEC', N'Instalaciones mecánicas', N'Climatización y sistemas mecánicos.', 1),
(N'COM', N'Comunicaciones', N'Datos, telecomunicaciones y sistemas de comunicación.', 1),
(N'PCI', N'Protección contra incendios', N'Sistemas de detección y protección contra incendios.', 1),
(N'TOPO', N'Topografía', N'Levantamientos y control topográfico.', 1),
(N'GEO', N'Geotecnia', N'Estudios y diseño geotécnico.', 1),
(N'EXT', N'Obras exteriores', N'Urbanización, accesos y obras exteriores.', 1);

CREATE TABLE bim.ExpedienteEspecialidad (
    ExpedienteId UNIQUEIDENTIFIER NOT NULL,
    EspecialidadId INT NOT NULL,
    Alcance NVARCHAR(1000) NULL,
    EsEspecialidadPrincipal BIT NOT NULL CONSTRAINT DF_ExpedienteEspecialidad_Principal DEFAULT (0),
    Estado NVARCHAR(20) NOT NULL CONSTRAINT DF_ExpedienteEspecialidad_Estado DEFAULT (N'ACTIVA'),
    FechaAsignacion DATETIME2(0) NOT NULL CONSTRAINT DF_ExpedienteEspecialidad_Fecha DEFAULT SYSUTCDATETIME(),
    FechaCierre DATETIME2(0) NULL,
    CONSTRAINT PK_ExpedienteEspecialidad PRIMARY KEY (ExpedienteId, EspecialidadId),
    CONSTRAINT FK_ExpedienteEspecialidad_Expediente FOREIGN KEY (ExpedienteId)
        REFERENCES bim.ExpedienteTecnico(ExpedienteId),
    CONSTRAINT FK_ExpedienteEspecialidad_Especialidad FOREIGN KEY (EspecialidadId)
        REFERENCES bim.Especialidad(EspecialidadId),
    CONSTRAINT CK_ExpedienteEspecialidad_Estado CHECK (Estado IN (N'ACTIVA',N'SUSPENDIDA',N'CERRADA')),
    CONSTRAINT CK_ExpedienteEspecialidad_Fechas CHECK (FechaCierre IS NULL OR FechaCierre >= CONVERT(DATE, FechaAsignacion))
);

CREATE UNIQUE INDEX UX_ExpedienteEspecialidad_Principal
    ON bim.ExpedienteEspecialidad(ExpedienteId)
    WHERE EsEspecialidadPrincipal = 1 AND Estado = N'ACTIVA';

CREATE INDEX IX_ExpedienteEspecialidad_Especialidad
    ON bim.ExpedienteEspecialidad(EspecialidadId, ExpedienteId);

CREATE TABLE bim.RolEspecialidad (
    RolEspecialidadId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_RolEspecialidad PRIMARY KEY,
    Codigo NVARCHAR(30) NOT NULL,
    Nombre NVARCHAR(100) NOT NULL,
    Descripcion NVARCHAR(300) NULL,
    Activo BIT NOT NULL CONSTRAINT DF_RolEspecialidad_Activo DEFAULT (1),
    EsSistema BIT NOT NULL CONSTRAINT DF_RolEspecialidad_EsSistema DEFAULT (0),
    CONSTRAINT UQ_RolEspecialidad_Codigo UNIQUE (Codigo)
);

INSERT INTO bim.RolEspecialidad (Codigo, Nombre, Descripcion, EsSistema)
VALUES
(N'RESPONSABLE', N'Responsable de especialidad', N'Responsable técnico de la especialidad.', 1),
(N'COORDINADOR', N'Coordinador', N'Coordina la producción e integración de información.', 1),
(N'MODELADOR', N'Modelador BIM', N'Produce o actualiza modelos y documentación BIM.', 1),
(N'REVISOR', N'Revisor', N'Revisa entregables y registra observaciones.', 1),
(N'APROBADOR', N'Aprobador', N'Tiene atribución para aprobar según el flujo autorizado.', 1),
(N'APOYO', N'Participante de apoyo', N'Participa en actividades de la especialidad.', 1);

CREATE TABLE bim.ResponsableEspecialidad (
    ResponsableEspecialidadId UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_ResponsableEspecialidad_Id DEFAULT NEWSEQUENTIALID(),
    ExpedienteId UNIQUEIDENTIFIER NOT NULL,
    EspecialidadId INT NOT NULL,
    RolEspecialidadId INT NOT NULL,
    UsuarioExternoId NVARCHAR(150) NOT NULL,
    NombreReferencia NVARCHAR(200) NULL,
    OrganizacionReferencia NVARCHAR(200) NULL,
    FechaInicio DATE NOT NULL CONSTRAINT DF_ResponsableEspecialidad_Inicio DEFAULT CONVERT(DATE, SYSUTCDATETIME()),
    FechaFin DATE NULL,
    Estado NVARCHAR(20) NOT NULL CONSTRAINT DF_ResponsableEspecialidad_Estado DEFAULT (N'ACTIVO'),
    AsignadoPorExternoId NVARCHAR(150) NULL,
    Observaciones NVARCHAR(1000) NULL,
    CONSTRAINT PK_ResponsableEspecialidad PRIMARY KEY (ResponsableEspecialidadId),
    CONSTRAINT FK_ResponsableEspecialidad_ExpedienteEspecialidad
        FOREIGN KEY (ExpedienteId, EspecialidadId)
        REFERENCES bim.ExpedienteEspecialidad(ExpedienteId, EspecialidadId),
    CONSTRAINT FK_ResponsableEspecialidad_Rol FOREIGN KEY (RolEspecialidadId)
        REFERENCES bim.RolEspecialidad(RolEspecialidadId),
    CONSTRAINT CK_ResponsableEspecialidad_Estado CHECK (Estado IN (N'ACTIVO',N'INACTIVO')),
    CONSTRAINT CK_ResponsableEspecialidad_Fechas CHECK (FechaFin IS NULL OR FechaFin >= FechaInicio)
);

CREATE INDEX IX_ResponsableEspecialidad_Expediente
    ON bim.ResponsableEspecialidad(ExpedienteId, EspecialidadId, Estado);

CREATE INDEX IX_ResponsableEspecialidad_Usuario
    ON bim.ResponsableEspecialidad(UsuarioExternoId, Estado);

CREATE TABLE bim.TipoEntregable (
    TipoEntregableId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TipoEntregable PRIMARY KEY,
    Codigo NVARCHAR(30) NOT NULL,
    Nombre NVARCHAR(120) NOT NULL,
    Descripcion NVARCHAR(400) NULL,
    Activo BIT NOT NULL CONSTRAINT DF_TipoEntregable_Activo DEFAULT (1),
    EsSistema BIT NOT NULL CONSTRAINT DF_TipoEntregable_EsSistema DEFAULT (0),
    CONSTRAINT UQ_TipoEntregable_Codigo UNIQUE (Codigo)
);

INSERT INTO bim.TipoEntregable (Codigo, Nombre, Descripcion, EsSistema)
VALUES
(N'MODELO_BIM', N'Modelo BIM', N'Modelo nativo o de intercambio, por ejemplo RVT o IFC.', 1),
(N'PLANO', N'Plano', N'Planos y láminas técnicas.', 1),
(N'MEMORIA', N'Memoria', N'Memorias descriptivas, de cálculo u otras.', 1),
(N'ESPECIFICACION', N'Especificación técnica', N'Especificaciones y requisitos técnicos.', 1),
(N'METRADO', N'Metrado', N'Metrados y cuantificaciones.', 1),
(N'PRESUPUESTO', N'Presupuesto', N'Presupuestos, análisis y documentos asociados.', 1),
(N'INFORME', N'Informe', N'Informes técnicos y de revisión.', 1),
(N'OTRO', N'Otro entregable', N'Tipo configurable para otros productos de información.', 1);

CREATE TABLE bim.Entregable (
    EntregableId UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Entregable_Id DEFAULT NEWSEQUENTIALID(),
    ExpedienteId UNIQUEIDENTIFIER NOT NULL,
    InversionId UNIQUEIDENTIFIER NOT NULL,
    TipoEntregableId INT NOT NULL,
    Codigo NVARCHAR(50) NOT NULL,
    Nombre NVARCHAR(250) NOT NULL,
    Descripcion NVARCHAR(1500) NULL,
    Estado NVARCHAR(20) NOT NULL CONSTRAINT DF_Entregable_Estado DEFAULT (N'PLANIFICADO'),
    RequiereAprobacion BIT NOT NULL CONSTRAINT DF_Entregable_Aprobacion DEFAULT (1),
    FechaObjetivo DATE NULL,
    FechaRegistro DATETIME2(0) NOT NULL CONSTRAINT DF_Entregable_Fecha DEFAULT SYSUTCDATETIME(),
    CreadoPorExternoId NVARCHAR(150) NULL,
    VersionFila ROWVERSION NOT NULL,
    CONSTRAINT PK_Entregable PRIMARY KEY (EntregableId),
    CONSTRAINT FK_Entregable_Expediente FOREIGN KEY (ExpedienteId, InversionId)
        REFERENCES bim.ExpedienteTecnico(ExpedienteId, InversionId),
    CONSTRAINT FK_Entregable_Tipo FOREIGN KEY (TipoEntregableId)
        REFERENCES bim.TipoEntregable(TipoEntregableId),
    CONSTRAINT UQ_Entregable_Expediente_Codigo UNIQUE (ExpedienteId, Codigo),
    CONSTRAINT UQ_Entregable_Id_Expediente UNIQUE (EntregableId, ExpedienteId),
    CONSTRAINT CK_Entregable_Estado CHECK (Estado IN (N'PLANIFICADO',N'EN_PRODUCCION',N'EN_REVISION',N'OBSERVADO',N'ACEPTADO',N'CERRADO',N'CANCELADO'))
);

CREATE INDEX IX_Entregable_Expediente_Estado
    ON bim.Entregable(ExpedienteId, Estado);

CREATE INDEX IX_Entregable_Tipo
    ON bim.Entregable(TipoEntregableId, ExpedienteId);

CREATE TABLE bim.EntregableEspecialidad (
    EntregableId UNIQUEIDENTIFIER NOT NULL,
    ExpedienteId UNIQUEIDENTIFIER NOT NULL,
    EspecialidadId INT NOT NULL,
    EsResponsablePrincipal BIT NOT NULL CONSTRAINT DF_EntregableEspecialidad_Principal DEFAULT (0),
    Observaciones NVARCHAR(500) NULL,
    CONSTRAINT PK_EntregableEspecialidad PRIMARY KEY (EntregableId, EspecialidadId),
    CONSTRAINT FK_EntregableEspecialidad_Entregable FOREIGN KEY (EntregableId, ExpedienteId)
        REFERENCES bim.Entregable(EntregableId, ExpedienteId),
    CONSTRAINT FK_EntregableEspecialidad_ExpedienteEspecialidad FOREIGN KEY (ExpedienteId, EspecialidadId)
        REFERENCES bim.ExpedienteEspecialidad(ExpedienteId, EspecialidadId)
);

CREATE UNIQUE INDEX UX_EntregableEspecialidad_Principal
    ON bim.EntregableEspecialidad(EntregableId)
    WHERE EsResponsablePrincipal = 1;

CREATE INDEX IX_EntregableEspecialidad_Especialidad
    ON bim.EntregableEspecialidad(ExpedienteId, EspecialidadId, EntregableId);

CREATE TABLE bim.EntregableComponente (
    EntregableId UNIQUEIDENTIFIER NOT NULL,
    ExpedienteId UNIQUEIDENTIFIER NOT NULL,
    ComponenteId UNIQUEIDENTIFIER NOT NULL,
    Alcance NVARCHAR(500) NULL,
    CONSTRAINT PK_EntregableComponente PRIMARY KEY (EntregableId, ComponenteId),
    CONSTRAINT FK_EntregableComponente_Entregable FOREIGN KEY (EntregableId, ExpedienteId)
        REFERENCES bim.Entregable(EntregableId, ExpedienteId),
    CONSTRAINT FK_EntregableComponente_ExpedienteComponente FOREIGN KEY (ExpedienteId, ComponenteId)
        REFERENCES bim.ExpedienteComponente(ExpedienteId, ComponenteId)
);

CREATE INDEX IX_EntregableComponente_Componente
    ON bim.EntregableComponente(ExpedienteId, ComponenteId, EntregableId);

CREATE TABLE bim.EntregableVersion (
    EntregableVersionId UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_EntregableVersion_Id DEFAULT NEWSEQUENTIALID(),
    EntregableId UNIQUEIDENTIFIER NOT NULL,
    NumeroVersion NVARCHAR(30) NOT NULL,
    Estado NVARCHAR(20) NOT NULL CONSTRAINT DF_EntregableVersion_Estado DEFAULT (N'BORRADOR'),
    EsVersionVigente BIT NOT NULL CONSTRAINT DF_EntregableVersion_Vigente DEFAULT (0),
    NombreArchivo NVARCHAR(260) NULL,
    Extension NVARCHAR(20) NULL,
    TipoContenido NVARCHAR(150) NULL,
    TamanoBytes BIGINT NULL,
    Repositorio NVARCHAR(50) NULL,
    UbicacionExterna NVARCHAR(2000) NULL,
    IdentificadorExterno NVARCHAR(500) NULL,
    HashSHA256 CHAR(64) NULL,
    FechaRegistro DATETIME2(0) NOT NULL CONSTRAINT DF_EntregableVersion_Fecha DEFAULT SYSUTCDATETIME(),
    FechaEnvio DATETIME2(0) NULL,
    CreadoPorExternoId NVARCHAR(150) NULL,
    Observaciones NVARCHAR(1500) NULL,
    VersionFila ROWVERSION NOT NULL,
    CONSTRAINT PK_EntregableVersion PRIMARY KEY (EntregableVersionId),
    CONSTRAINT FK_EntregableVersion_Entregable FOREIGN KEY (EntregableId)
        REFERENCES bim.Entregable(EntregableId),
    CONSTRAINT UQ_EntregableVersion_Numero UNIQUE (EntregableId, NumeroVersion),
    CONSTRAINT CK_EntregableVersion_Estado CHECK (Estado IN (N'BORRADOR',N'ENVIADA',N'EN_REVISION',N'OBSERVADA',N'ACEPTADA',N'RECHAZADA',N'SUPERADA')),
    CONSTRAINT CK_EntregableVersion_Tamano CHECK (TamanoBytes IS NULL OR TamanoBytes >= 0),
    CONSTRAINT CK_EntregableVersion_Hash CHECK (HashSHA256 IS NULL OR (LEN(HashSHA256) = 64 AND HashSHA256 NOT LIKE '%[^0-9A-Fa-f]%'))
);

CREATE UNIQUE INDEX UX_EntregableVersion_Vigente
    ON bim.EntregableVersion(EntregableId)
    WHERE EsVersionVigente = 1;

CREATE INDEX IX_EntregableVersion_Entregable_Fecha
    ON bim.EntregableVersion(EntregableId, FechaRegistro DESC);

COMMIT TRANSACTION;
GO

PRINT N'Migración 002 de especialidades y entregables creada correctamente.';
GO
