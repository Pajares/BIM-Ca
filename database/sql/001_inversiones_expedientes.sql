/*
  dotBEP-PE - SQL Server 2025
  001_inversiones_expedientes.sql

  Alcance:
  - Catálogos y entidades institucionales.
  - Inversiones PI / IOARR y detalles específicos.
  - Fases e historial.
  - Ubicaciones y componentes.
  - Expedientes principales/complementarios, relaciones, etapas y versiones.

  Ejecutar en una base de datos de desarrollo previamente seleccionada.
  No crea la base de datos ni configura usuarios/permisos.
  Revisar y respaldar antes de ejecutar en cualquier entorno persistente.
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF SCHEMA_ID(N'proyectos') IS NULL EXEC(N'CREATE SCHEMA proyectos');
IF SCHEMA_ID(N'bim') IS NULL EXEC(N'CREATE SCHEMA bim');
GO

BEGIN TRANSACTION;
GO

CREATE TABLE proyectos.TipoInversion (
    TipoInversionId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TipoInversion PRIMARY KEY,
    Codigo NVARCHAR(30) NOT NULL,
    Nombre NVARCHAR(150) NOT NULL,
    Descripcion NVARCHAR(500) NULL,
    Activo BIT NOT NULL CONSTRAINT DF_TipoInversion_Activo DEFAULT (1),
    EsSistema BIT NOT NULL CONSTRAINT DF_TipoInversion_EsSistema DEFAULT (0),
    CONSTRAINT UQ_TipoInversion_Codigo UNIQUE (Codigo)
);

INSERT INTO proyectos.TipoInversion (Codigo, Nombre, Descripcion, EsSistema)
VALUES
(N'PI', N'Proyecto de inversión', N'Proyecto de inversión en el marco de Invierte.pe.', 1),
(N'IOARR', N'IOARR', N'Inversiones de optimización, ampliación marginal, reposición y rehabilitación.', 1),
(N'OTRO', N'Otra modalidad', N'Modalidad extensible sujeta a configuración y reglas propias.', 1);

CREATE TABLE proyectos.Entidad (
    EntidadId UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Entidad_Id DEFAULT NEWSEQUENTIALID(),
    CodigoEntidad NVARCHAR(30) NOT NULL,
    Nombre NVARCHAR(250) NOT NULL,
    RUC CHAR(11) NULL,
    TipoEntidad NVARCHAR(50) NOT NULL,
    Activo BIT NOT NULL CONSTRAINT DF_Entidad_Activo DEFAULT (1),
    FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Entidad_Fecha DEFAULT SYSUTCDATETIME(),
    VersionFila ROWVERSION NOT NULL,
    CONSTRAINT PK_Entidad PRIMARY KEY (EntidadId),
    CONSTRAINT UQ_Entidad_Codigo UNIQUE (CodigoEntidad),
    CONSTRAINT CK_Entidad_RUC CHECK (RUC IS NULL OR RUC NOT LIKE '%[^0-9]%')
);

CREATE TABLE proyectos.UnidadEjecutora (
    UnidadEjecutoraId UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_UnidadEjecutora_Id DEFAULT NEWSEQUENTIALID(),
    EntidadId UNIQUEIDENTIFIER NOT NULL,
    Codigo NVARCHAR(30) NOT NULL,
    Nombre NVARCHAR(250) NOT NULL,
    Activo BIT NOT NULL CONSTRAINT DF_UnidadEjecutora_Activo DEFAULT (1),
    CONSTRAINT PK_UnidadEjecutora PRIMARY KEY (UnidadEjecutoraId),
    CONSTRAINT FK_UnidadEjecutora_Entidad FOREIGN KEY (EntidadId) REFERENCES proyectos.Entidad(EntidadId),
    CONSTRAINT UQ_UnidadEjecutora_Entidad_Codigo UNIQUE (EntidadId, Codigo),
    CONSTRAINT UQ_UnidadEjecutora_Id_Entidad UNIQUE (UnidadEjecutoraId, EntidadId)
);

CREATE TABLE proyectos.Inversion (
    InversionId UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Inversion_Id DEFAULT NEWSEQUENTIALID(),
    CodigoInterno NVARCHAR(30) NOT NULL,
    TipoInversionId INT NOT NULL,
    CUI NVARCHAR(20) NULL,
    Nombre NVARCHAR(300) NOT NULL,
    Descripcion NVARCHAR(MAX) NULL,
    EntidadId UNIQUEIDENTIFIER NOT NULL,
    UnidadEjecutoraId UNIQUEIDENTIFIER NULL,
    Estado NVARCHAR(30) NOT NULL CONSTRAINT DF_Inversion_Estado DEFAULT (N'EnRegistro'),
    FechaRegistro DATETIME2(0) NOT NULL CONSTRAINT DF_Inversion_FechaRegistro DEFAULT SYSUTCDATETIME(),
    FechaModificacion DATETIME2(0) NULL,
    VersionFila ROWVERSION NOT NULL,
    CONSTRAINT PK_Inversion PRIMARY KEY (InversionId),
    CONSTRAINT UQ_Inversion_CodigoInterno UNIQUE (CodigoInterno),
    CONSTRAINT FK_Inversion_Tipo FOREIGN KEY (TipoInversionId) REFERENCES proyectos.TipoInversion(TipoInversionId),
    CONSTRAINT FK_Inversion_Entidad FOREIGN KEY (EntidadId) REFERENCES proyectos.Entidad(EntidadId),
    CONSTRAINT FK_Inversion_UnidadEjecutora_Entidad FOREIGN KEY (UnidadEjecutoraId, EntidadId)
        REFERENCES proyectos.UnidadEjecutora(UnidadEjecutoraId, EntidadId),
    CONSTRAINT CK_Inversion_Estado CHECK (Estado IN (N'EnRegistro',N'Activa',N'Suspendida',N'Cerrada',N'Cancelada'))
);
CREATE UNIQUE INDEX UX_Inversion_CUI ON proyectos.Inversion(CUI) WHERE CUI IS NOT NULL;
CREATE INDEX IX_Inversion_Entidad_Estado ON proyectos.Inversion(EntidadId, Estado);

CREATE TABLE proyectos.DetalleProyectoInversion (
    InversionId UNIQUEIDENTIFIER NOT NULL,
    TipoDocumentoFormulacion NVARCHAR(80) NULL,
    FechaViabilidad DATE NULL,
    UnidadProductoraReferencia NVARCHAR(200) NULL,
    DatosEspecificos NVARCHAR(MAX) NULL,
    CONSTRAINT PK_DetalleProyectoInversion PRIMARY KEY (InversionId),
    CONSTRAINT FK_DetallePI_Inversion FOREIGN KEY (InversionId) REFERENCES proyectos.Inversion(InversionId),
    CONSTRAINT CK_DetallePI_JSON CHECK (DatosEspecificos IS NULL OR ISJSON(DatosEspecificos) = 1)
);

CREATE TABLE proyectos.TipoIOARR (
    TipoIOARRId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TipoIOARR PRIMARY KEY,
    Codigo NVARCHAR(10) NOT NULL,
    Nombre NVARCHAR(100) NOT NULL,
    Activo BIT NOT NULL CONSTRAINT DF_TipoIOARR_Activo DEFAULT (1),
    CONSTRAINT UQ_TipoIOARR_Codigo UNIQUE (Codigo)
);
INSERT INTO proyectos.TipoIOARR (Codigo, Nombre)
VALUES (N'OPT',N'Optimización'),(N'AM',N'Ampliación marginal'),
       (N'REP',N'Reposición'),(N'REH',N'Rehabilitación');

CREATE TABLE proyectos.DetalleIOARR (
    InversionId UNIQUEIDENTIFIER NOT NULL,
    TipoIOARRId INT NOT NULL,
    UnidadProductoraReferencia NVARCHAR(200) NULL,
    DatosEspecificos NVARCHAR(MAX) NULL,
    CONSTRAINT PK_DetalleIOARR PRIMARY KEY (InversionId),
    CONSTRAINT FK_DetalleIOARR_Inversion FOREIGN KEY (InversionId) REFERENCES proyectos.Inversion(InversionId),
    CONSTRAINT FK_DetalleIOARR_Tipo FOREIGN KEY (TipoIOARRId) REFERENCES proyectos.TipoIOARR(TipoIOARRId),
    CONSTRAINT CK_DetalleIOARR_JSON CHECK (DatosEspecificos IS NULL OR ISJSON(DatosEspecificos) = 1)
);

CREATE TABLE proyectos.FaseInversion (
    FaseInversionId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_FaseInversion PRIMARY KEY,
    Codigo NVARCHAR(30) NOT NULL,
    Nombre NVARCHAR(120) NOT NULL,
    Orden TINYINT NOT NULL,
    Activo BIT NOT NULL CONSTRAINT DF_Fase_Activo DEFAULT (1),
    CONSTRAINT UQ_Fase_Codigo UNIQUE (Codigo),
    CONSTRAINT UQ_Fase_Orden UNIQUE (Orden)
);
INSERT INTO proyectos.FaseInversion (Codigo, Nombre, Orden)
VALUES (N'PROGRAMACION',N'Programación multianual',1),
       (N'FORMULACION',N'Formulación y evaluación',2),
       (N'EJECUCION',N'Ejecución',3),
       (N'FUNCIONAMIENTO',N'Funcionamiento',4);

CREATE TABLE proyectos.HistorialFase (
    HistorialFaseId UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_HistorialFase_Id DEFAULT NEWSEQUENTIALID(),
    InversionId UNIQUEIDENTIFIER NOT NULL,
    FaseAnteriorId INT NULL,
    FaseNuevaId INT NOT NULL,
    FechaCambio DATETIME2(0) NOT NULL CONSTRAINT DF_HistorialFase_Fecha DEFAULT SYSUTCDATETIME(),
    UsuarioExternoId NVARCHAR(150) NULL,
    ReferenciaExterna NVARCHAR(500) NULL,
    Observacion NVARCHAR(1000) NULL,
    CONSTRAINT PK_HistorialFase PRIMARY KEY (HistorialFaseId),
    CONSTRAINT FK_HistorialFase_Inversion FOREIGN KEY (InversionId) REFERENCES proyectos.Inversion(InversionId),
    CONSTRAINT FK_HistorialFase_Anterior FOREIGN KEY (FaseAnteriorId) REFERENCES proyectos.FaseInversion(FaseInversionId),
    CONSTRAINT FK_HistorialFase_Nueva FOREIGN KEY (FaseNuevaId) REFERENCES proyectos.FaseInversion(FaseInversionId)
);
CREATE INDEX IX_HistorialFase_Inversion_Fecha ON proyectos.HistorialFase(InversionId, FechaCambio DESC);

CREATE TABLE proyectos.Ubicacion (
    UbicacionId UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Ubicacion_Id DEFAULT NEWSEQUENTIALID(),
    Departamento NVARCHAR(100) NOT NULL,
    Provincia NVARCHAR(100) NOT NULL,
    Distrito NVARCHAR(100) NOT NULL,
    CoordenadaEste DECIMAL(18,3) NULL,
    CoordenadaNorte DECIMAL(18,3) NULL,
    SistemaCoordenadas NVARCHAR(80) NULL,
    ZonaUTM TINYINT NULL,
    CONSTRAINT PK_Ubicacion PRIMARY KEY (UbicacionId),
    CONSTRAINT CK_Ubicacion_ZonaUTM CHECK (ZonaUTM IS NULL OR ZonaUTM BETWEEN 1 AND 60)
);

CREATE TABLE proyectos.InversionUbicacion (
    InversionId UNIQUEIDENTIFIER NOT NULL,
    UbicacionId UNIQUEIDENTIFIER NOT NULL,
    EsPrincipal BIT NOT NULL CONSTRAINT DF_InversionUbicacion_Principal DEFAULT (0),
    Referencia NVARCHAR(300) NULL,
    CONSTRAINT PK_InversionUbicacion PRIMARY KEY (InversionId, UbicacionId),
    CONSTRAINT FK_InversionUbicacion_Inversion FOREIGN KEY (InversionId) REFERENCES proyectos.Inversion(InversionId),
    CONSTRAINT FK_InversionUbicacion_Ubicacion FOREIGN KEY (UbicacionId) REFERENCES proyectos.Ubicacion(UbicacionId)
);
CREATE UNIQUE INDEX UX_InversionUbicacion_Principal ON proyectos.InversionUbicacion(InversionId) WHERE EsPrincipal = 1;

CREATE TABLE bim.TipoExpediente (
    TipoExpedienteId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TipoExpediente PRIMARY KEY,
    Codigo NVARCHAR(30) NOT NULL,
    Nombre NVARCHAR(150) NOT NULL,
    Activo BIT NOT NULL CONSTRAINT DF_TipoExpediente_Activo DEFAULT (1),
    CONSTRAINT UQ_TipoExpediente_Codigo UNIQUE (Codigo)
);
INSERT INTO bim.TipoExpediente (Codigo, Nombre)
VALUES (N'PRINCIPAL',N'Expediente técnico principal'),
       (N'COMPLEMENTARIO',N'Expediente técnico complementario'),
       (N'EQUIVALENTE',N'Documento equivalente'),
       (N'OTRO',N'Otro tipo de expediente');

CREATE TABLE bim.ExpedienteTecnico (
    ExpedienteId UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Expediente_Id DEFAULT NEWSEQUENTIALID(),
    InversionId UNIQUEIDENTIFIER NOT NULL,
    TipoExpedienteId INT NOT NULL,
    CodigoExpediente NVARCHAR(40) NOT NULL,
    Nombre NVARCHAR(300) NOT NULL,
    Descripcion NVARCHAR(MAX) NULL,
    EsPrincipal BIT NOT NULL CONSTRAINT DF_Expediente_Principal DEFAULT (0),
    Estado NVARCHAR(30) NOT NULL CONSTRAINT DF_Expediente_Estado DEFAULT (N'EnPreparacion'),
    FechaInicio DATE NULL,
    FechaFinPrevista DATE NULL,
    FechaRegistro DATETIME2(0) NOT NULL CONSTRAINT DF_Expediente_Fecha DEFAULT SYSUTCDATETIME(),
    VersionFila ROWVERSION NOT NULL,
    CONSTRAINT PK_ExpedienteTecnico PRIMARY KEY (ExpedienteId),
    CONSTRAINT FK_Expediente_Inversion FOREIGN KEY (InversionId) REFERENCES proyectos.Inversion(InversionId),
    CONSTRAINT FK_Expediente_Tipo FOREIGN KEY (TipoExpedienteId) REFERENCES bim.TipoExpediente(TipoExpedienteId),
    CONSTRAINT UQ_Expediente_Inversion_Codigo UNIQUE (InversionId, CodigoExpediente),
    CONSTRAINT CK_Expediente_Estado CHECK (Estado IN (N'EnPreparacion',N'EnRevision',N'Observado',N'Aprobado',N'Cerrado',N'Anulado')),
    CONSTRAINT CK_Expediente_Fechas CHECK (FechaFinPrevista IS NULL OR FechaInicio IS NULL OR FechaFinPrevista >= FechaInicio),
    CONSTRAINT UQ_Expediente_Id_Inversion UNIQUE (ExpedienteId, InversionId)
);
CREATE UNIQUE INDEX UX_Expediente_Principal ON bim.ExpedienteTecnico(InversionId) WHERE EsPrincipal = 1;
CREATE INDEX IX_Expediente_Inversion_Estado ON bim.ExpedienteTecnico(InversionId, Estado);

CREATE TABLE bim.RelacionExpediente (
    RelacionExpedienteId UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_RelacionExpediente_Id DEFAULT NEWSEQUENTIALID(),
    InversionId UNIQUEIDENTIFIER NOT NULL,
    ExpedientePadreId UNIQUEIDENTIFIER NOT NULL,
    ExpedienteHijoId UNIQUEIDENTIFIER NOT NULL,
    TipoRelacion NVARCHAR(30) NOT NULL,
    Justificacion NVARCHAR(1000) NULL,
    FechaRegistro DATETIME2(0) NOT NULL CONSTRAINT DF_RelacionExpediente_Fecha DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_RelacionExpediente PRIMARY KEY (RelacionExpedienteId),
    CONSTRAINT FK_RelacionExpediente_Padre FOREIGN KEY (ExpedientePadreId, InversionId)
        REFERENCES bim.ExpedienteTecnico(ExpedienteId, InversionId),
    CONSTRAINT FK_RelacionExpediente_Hijo FOREIGN KEY (ExpedienteHijoId, InversionId)
        REFERENCES bim.ExpedienteTecnico(ExpedienteId, InversionId),
    CONSTRAINT CK_RelacionExpediente_Distintos CHECK (ExpedientePadreId <> ExpedienteHijoId),
    CONSTRAINT CK_RelacionExpediente_Tipo CHECK (TipoRelacion IN (N'COMPLEMENTARIO',N'DERIVADO',N'ASOCIADO')),
    CONSTRAINT UQ_RelacionExpediente UNIQUE (ExpedientePadreId, ExpedienteHijoId, TipoRelacion)
);

CREATE TABLE bim.Componente (
    ComponenteId UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Componente_Id DEFAULT NEWSEQUENTIALID(),
    InversionId UNIQUEIDENTIFIER NOT NULL,
    ComponentePadreId UNIQUEIDENTIFIER NULL,
    Codigo NVARCHAR(40) NOT NULL,
    Nombre NVARCHAR(250) NOT NULL,
    Descripcion NVARCHAR(1000) NULL,
    Estado NVARCHAR(30) NOT NULL CONSTRAINT DF_Componente_Estado DEFAULT (N'Activo'),
    CONSTRAINT PK_Componente PRIMARY KEY (ComponenteId),
    CONSTRAINT FK_Componente_Inversion FOREIGN KEY (InversionId) REFERENCES proyectos.Inversion(InversionId),
    CONSTRAINT FK_Componente_Padre FOREIGN KEY (ComponentePadreId) REFERENCES bim.Componente(ComponenteId),
    CONSTRAINT UQ_Componente_Inversion_Codigo UNIQUE (InversionId, Codigo),
    CONSTRAINT UQ_Componente_Id_Inversion UNIQUE (ComponenteId, InversionId),
    CONSTRAINT CK_Componente_NoAutopadre CHECK (ComponentePadreId IS NULL OR ComponentePadreId <> ComponenteId)
);

CREATE TABLE bim.ExpedienteComponente (
    ExpedienteId UNIQUEIDENTIFIER NOT NULL,
    ComponenteId UNIQUEIDENTIFIER NOT NULL,
    InversionId UNIQUEIDENTIFIER NOT NULL,
    Alcance NVARCHAR(1000) NULL,
    EsPrincipal BIT NOT NULL CONSTRAINT DF_ExpedienteComponente_Principal DEFAULT (0),
    Estado NVARCHAR(30) NOT NULL CONSTRAINT DF_ExpedienteComponente_Estado DEFAULT (N'Activo'),
    CONSTRAINT PK_ExpedienteComponente PRIMARY KEY (ExpedienteId, ComponenteId),
    CONSTRAINT FK_ExpedienteComponente_Expediente FOREIGN KEY (ExpedienteId, InversionId)
        REFERENCES bim.ExpedienteTecnico(ExpedienteId, InversionId),
    CONSTRAINT FK_ExpedienteComponente_Componente FOREIGN KEY (ComponenteId, InversionId)
        REFERENCES bim.Componente(ComponenteId, InversionId)
);

CREATE TABLE bim.Etapa (
    EtapaId UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Etapa_Id DEFAULT NEWSEQUENTIALID(),
    InversionId UNIQUEIDENTIFIER NOT NULL,
    EtapaPadreId UNIQUEIDENTIFIER NULL,
    Codigo NVARCHAR(40) NOT NULL,
    Nombre NVARCHAR(200) NOT NULL,
    Orden SMALLINT NOT NULL,
    Descripcion NVARCHAR(1000) NULL,
    Estado NVARCHAR(30) NOT NULL CONSTRAINT DF_Etapa_Estado DEFAULT (N'Planificada'),
    CONSTRAINT PK_Etapa PRIMARY KEY (EtapaId),
    CONSTRAINT FK_Etapa_Inversion FOREIGN KEY (InversionId) REFERENCES proyectos.Inversion(InversionId),
    CONSTRAINT FK_Etapa_Padre FOREIGN KEY (EtapaPadreId) REFERENCES bim.Etapa(EtapaId),
    CONSTRAINT UQ_Etapa_Inversion_Codigo UNIQUE (InversionId, Codigo),
    CONSTRAINT UQ_Etapa_Id_Inversion UNIQUE (EtapaId, InversionId),
    CONSTRAINT CK_Etapa_NoAutopadre CHECK (EtapaPadreId IS NULL OR EtapaPadreId <> EtapaId)
);

CREATE TABLE bim.ExpedienteEtapa (
    ExpedienteId UNIQUEIDENTIFIER NOT NULL,
    EtapaId UNIQUEIDENTIFIER NOT NULL,
    InversionId UNIQUEIDENTIFIER NOT NULL,
    FechaInicio DATE NULL,
    FechaFinPrevista DATE NULL,
    FechaFinReal DATE NULL,
    Estado NVARCHAR(30) NOT NULL CONSTRAINT DF_ExpedienteEtapa_Estado DEFAULT (N'Planificada'),
    Observaciones NVARCHAR(1000) NULL,
    CONSTRAINT PK_ExpedienteEtapa PRIMARY KEY (ExpedienteId, EtapaId),
    CONSTRAINT FK_ExpedienteEtapa_Expediente FOREIGN KEY (ExpedienteId, InversionId)
        REFERENCES bim.ExpedienteTecnico(ExpedienteId, InversionId),
    CONSTRAINT FK_ExpedienteEtapa_Etapa FOREIGN KEY (EtapaId, InversionId)
        REFERENCES bim.Etapa(EtapaId, InversionId),
    CONSTRAINT CK_ExpedienteEtapa_Fechas CHECK (
        (FechaFinPrevista IS NULL OR FechaInicio IS NULL OR FechaFinPrevista >= FechaInicio)
        AND (FechaFinReal IS NULL OR FechaInicio IS NULL OR FechaFinReal >= FechaInicio)
    )
);

CREATE TABLE bim.VersionExpediente (
    VersionExpedienteId UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_VersionExpediente_Id DEFAULT NEWSEQUENTIALID(),
    ExpedienteId UNIQUEIDENTIFIER NOT NULL,
    NumeroVersion NVARCHAR(30) NOT NULL,
    Estado NVARCHAR(30) NOT NULL CONSTRAINT DF_VersionExpediente_Estado DEFAULT (N'Borrador'),
    FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_VersionExpediente_Fecha DEFAULT SYSUTCDATETIME(),
    CreadoPorExternoId NVARCHAR(150) NULL,
    ReferenciaPaqueteBEP NVARCHAR(1000) NULL,
    Observaciones NVARCHAR(1000) NULL,
    CONSTRAINT PK_VersionExpediente PRIMARY KEY (VersionExpedienteId),
    CONSTRAINT FK_VersionExpediente_Expediente FOREIGN KEY (ExpedienteId) REFERENCES bim.ExpedienteTecnico(ExpedienteId),
    CONSTRAINT UQ_VersionExpediente_Numero UNIQUE (ExpedienteId, NumeroVersion),
    CONSTRAINT UQ_VersionExpediente_Id_Expediente UNIQUE (VersionExpedienteId, ExpedienteId)
);

COMMIT TRANSACTION;
GO

PRINT N'Esquema inicial de inversiones y expedientes creado correctamente.';
GO
