SET QUOTED_IDENTIFIER ON;
GO
/* =====================================================================
   01_schema.sql · Esquema COMPLETO y actualizado de SIMADB (instalación limpia)

   - Es el estado final de la BD. Lo ejecuta Docker automáticamente al levantar el proyecto.
   - Idempotente: se puede correr varias veces; solo crea lo que falta.
   - Se ejecuta con sqlcmd (por eso usa GO). Orden de ejecución: 00 → 01 → 02.
   - NO es para tu BD vieja ya existente: para esa usa backend/sql/01_migracion_simadb.sql.

   REGLA DEL EQUIPO: si cambias la estructura de la BD, actualiza este archivo
   (para instalaciones nuevas) y agrega un script de migración numerado (para BDs existentes).
   ===================================================================== */
USE SIMADB;
GO

/* ---------- Usuarios (clientes) ---------- */
IF OBJECT_ID(N'dbo.Usuarios', N'U') IS NULL
CREATE TABLE dbo.Usuarios (
    id_usuario   INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Usuarios PRIMARY KEY,
    nombre       NVARCHAR(60)  NOT NULL,
    apellidos    NVARCHAR(80)  NOT NULL CONSTRAINT DF_Usuarios_apellidos DEFAULT N'',
    telefono     NVARCHAR(20)  NOT NULL,
    correo       NVARCHAR(150) NULL,          -- NULL = cliente sin cuenta (cita exprés)
    contrasena   NVARCHAR(255) NULL,          -- hash bcrypt, nunca texto plano
    tiene_cuenta BIT NOT NULL CONSTRAINT DF_Usuarios_tiene_cuenta DEFAULT 1
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_Usuarios_correo' AND object_id = OBJECT_ID('dbo.Usuarios'))
    CREATE UNIQUE INDEX UX_Usuarios_correo ON dbo.Usuarios (correo) WHERE correo IS NOT NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Usuarios_telefono' AND object_id = OBJECT_ID('dbo.Usuarios'))
    CREATE INDEX IX_Usuarios_telefono ON dbo.Usuarios (telefono);
GO

/* ---------- Empleados (personal del taller) ---------- */
IF OBJECT_ID(N'dbo.Empleados', N'U') IS NULL
CREATE TABLE dbo.Empleados (
    id_empleado   INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Empleados PRIMARY KEY,
    nombre        NVARCHAR(60)  NOT NULL,
    apellidos     NVARCHAR(80)  NOT NULL CONSTRAINT DF_Empleados_apellidos DEFAULT N'',
    puesto        NVARCHAR(60)  NULL,
    correo        NVARCHAR(150) NOT NULL,
    password_hash NVARCHAR(255) NULL,
    rol           NVARCHAR(20)  NOT NULL CONSTRAINT DF_Empleados_rol DEFAULT N'mecanico'
                  CONSTRAINT CK_Empleados_rol CHECK (rol IN (N'admin', N'mecanico'))
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_Empleados_correo' AND object_id = OBJECT_ID('dbo.Empleados'))
    CREATE UNIQUE INDEX UX_Empleados_correo ON dbo.Empleados (correo);
GO

/* ---------- Servicios (catálogo) ---------- */
IF OBJECT_ID(N'dbo.Servicios', N'U') IS NULL
CREATE TABLE dbo.Servicios (
    id_servicio     INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Servicios PRIMARY KEY,
    nombre          NVARCHAR(100) NOT NULL,
    descripcion     NVARCHAR(300) NULL,
    precio_estimado DECIMAL(12,2) NOT NULL CONSTRAINT CK_Servicios_precio CHECK (precio_estimado >= 0),
    activo          BIT NOT NULL CONSTRAINT DF_Servicios_activo DEFAULT 1,
    categoria       NVARCHAR(30)  NOT NULL CONSTRAINT DF_Servicios_categoria DEFAULT N'Preventivo'
                    CONSTRAINT CK_Servicios_categoria CHECK (categoria IN (N'Preventivo', N'Correctivo')),
    duracion_horas  DECIMAL(4,1)  NOT NULL CONSTRAINT DF_Servicios_duracion DEFAULT 1,
    garantia_meses  INT           NOT NULL CONSTRAINT DF_Servicios_garantia DEFAULT 1
);
GO

/* ---------- Vehiculos ---------- */
IF OBJECT_ID(N'dbo.Vehiculos', N'U') IS NULL
CREATE TABLE dbo.Vehiculos (
    id_vehiculo INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Vehiculos PRIMARY KEY,
    id_usuario  INT NOT NULL CONSTRAINT FK_Vehiculos_Usuario REFERENCES dbo.Usuarios (id_usuario),
    marca       NVARCHAR(40) NOT NULL,
    modelo      NVARCHAR(40) NOT NULL,
    anio        INT NOT NULL,
    placas      NVARCHAR(12) NOT NULL
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Vehiculos_usuario' AND object_id = OBJECT_ID('dbo.Vehiculos'))
    CREATE INDEX IX_Vehiculos_usuario ON dbo.Vehiculos (id_usuario);
GO

/* ---------- Citas ---------- */
IF OBJECT_ID(N'dbo.Citas', N'U') IS NULL
CREATE TABLE dbo.Citas (
    id_cita        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Citas PRIMARY KEY,
    id_usuario     INT NOT NULL CONSTRAINT FK_Citas_Usuario  REFERENCES dbo.Usuarios  (id_usuario),
    id_vehiculo    INT NOT NULL CONSTRAINT FK_Citas_Vehiculo REFERENCES dbo.Vehiculos (id_vehiculo),
    id_servicio    INT NULL     CONSTRAINT FK_Citas_Servicio REFERENCES dbo.Servicios (id_servicio),
    fecha          DATE    NOT NULL,
    hora           TIME(0) NOT NULL,
    estado         NVARCHAR(15) NOT NULL CONSTRAINT DF_Citas_estado DEFAULT N'Solicitada'
                   CONSTRAINT CK_Citas_estado CHECK (estado IN (N'Solicitada', N'Confirmada', N'Rechazada', N'Cancelada')),
    motivo_rechazo NVARCHAR(200) NULL,
    es_expres      BIT NOT NULL CONSTRAINT DF_Citas_es_expres DEFAULT 0
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Citas_usuario' AND object_id = OBJECT_ID('dbo.Citas'))
    CREATE INDEX IX_Citas_usuario ON dbo.Citas (id_usuario);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Citas_fecha' AND object_id = OBJECT_ID('dbo.Citas'))
    CREATE INDEX IX_Citas_fecha ON dbo.Citas (fecha, hora);
GO

/* ---------- OrdenesTrabajo ---------- */
IF OBJECT_ID(N'dbo.OrdenesTrabajo', N'U') IS NULL
CREATE TABLE dbo.OrdenesTrabajo (
    id_orden           INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_OrdenesTrabajo PRIMARY KEY,
    folio              NVARCHAR(20) NOT NULL,
    id_cita            INT NULL CONSTRAINT FK_Ordenes_Cita     REFERENCES dbo.Citas     (id_cita),
    id_usuario         INT NOT NULL CONSTRAINT FK_Ordenes_Usuario  REFERENCES dbo.Usuarios  (id_usuario),
    id_vehiculo        INT NOT NULL CONSTRAINT FK_Ordenes_Vehiculo REFERENCES dbo.Vehiculos (id_vehiculo),
    id_empleado        INT NULL CONSTRAINT FK_Ordenes_Empleado REFERENCES dbo.Empleados (id_empleado),
    id_servicio        INT NULL CONSTRAINT FK_Ordenes_Servicio REFERENCES dbo.Servicios (id_servicio),
    fecha_ingreso      DATETIME2(0) NOT NULL CONSTRAINT DF_Ordenes_fecha DEFAULT SYSDATETIME(),
    diagnostico        NVARCHAR(2000) NOT NULL CONSTRAINT DF_Ordenes_diagnostico DEFAULT N'',
    estado             NVARCHAR(15) NOT NULL CONSTRAINT DF_Ordenes_estado DEFAULT N'Recibida'
                       CONSTRAINT CK_Ordenes_estado CHECK (estado IN (N'Recibida', N'En diagnóstico', N'Cotizada', N'Autorizada',
                                                                       N'En reparación', N'Lista', N'Entregada')),
    total              DECIMAL(14,2) NOT NULL CONSTRAINT DF_Ordenes_total DEFAULT 0,   -- IVA incluido
    kilometraje        INT NULL,
    notas_recepcion    NVARCHAR(500) NULL,
    autorizacion       NVARCHAR(15) NOT NULL CONSTRAINT DF_Ordenes_autorizacion DEFAULT N'Pendiente'
                       CONSTRAINT CK_Ordenes_autorizacion CHECK (autorizacion IN (N'Pendiente', N'Autorizada', N'Rechazada')),
    cotizacion_enviada BIT NOT NULL CONSTRAINT DF_Ordenes_cotizacion_enviada DEFAULT 0
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_Ordenes_folio' AND object_id = OBJECT_ID('dbo.OrdenesTrabajo'))
    CREATE UNIQUE INDEX UX_Ordenes_folio ON dbo.OrdenesTrabajo (folio);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Ordenes_estado' AND object_id = OBJECT_ID('dbo.OrdenesTrabajo'))
    CREATE INDEX IX_Ordenes_estado ON dbo.OrdenesTrabajo (estado);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Ordenes_usuario' AND object_id = OBJECT_ID('dbo.OrdenesTrabajo'))
    CREATE INDEX IX_Ordenes_usuario ON dbo.OrdenesTrabajo (id_usuario);
GO

/* ---------- Ordenes_Servicios (líneas de la cotización) ---------- */
IF OBJECT_ID(N'dbo.Ordenes_Servicios', N'U') IS NULL
CREATE TABLE dbo.Ordenes_Servicios (
    id_detalle      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Ordenes_Servicios PRIMARY KEY,
    id_orden        INT NOT NULL CONSTRAINT FK_OrdSrv_Orden REFERENCES dbo.OrdenesTrabajo (id_orden) ON DELETE CASCADE,
    id_servicio     INT NULL     CONSTRAINT FK_OrdSrv_Servicio REFERENCES dbo.Servicios (id_servicio),
    concepto        NVARCHAR(150) NOT NULL,
    tipo            NVARCHAR(15)  NOT NULL CONSTRAINT DF_OrdSrv_tipo DEFAULT N'Labor'
                    CONSTRAINT CK_OrdSrv_tipo CHECK (tipo IN (N'Refacción', N'Tornería', N'Labor')),
    cantidad        DECIMAL(8,2)  NOT NULL CONSTRAINT CK_OrdSrv_cantidad CHECK (cantidad > 0),
    precio_unitario DECIMAL(12,2) NOT NULL CONSTRAINT CK_OrdSrv_precio CHECK (precio_unitario >= 0),
    subtotal        AS (CAST(cantidad * precio_unitario AS DECIMAL(14,2))) PERSISTED
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_OrdSrv_orden' AND object_id = OBJECT_ID('dbo.Ordenes_Servicios'))
    CREATE INDEX IX_OrdSrv_orden ON dbo.Ordenes_Servicios (id_orden);
GO

/* ---------- Notificaciones ---------- */
IF OBJECT_ID(N'dbo.Notificaciones', N'U') IS NULL
CREATE TABLE dbo.Notificaciones (
    id_notificacion INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Notificaciones PRIMARY KEY,
    audiencia       NVARCHAR(10)  NOT NULL CONSTRAINT CK_Notif_audiencia CHECK (audiencia IN (N'personal', N'cliente')),
    id_usuario      INT NULL CONSTRAINT FK_Notif_Usuario REFERENCES dbo.Usuarios (id_usuario) ON DELETE CASCADE,
    tipo            NVARCHAR(12)  NOT NULL CONSTRAINT CK_Notif_tipo CHECK (tipo IN (N'cita', N'orden', N'cotizacion')),
    tono            NVARCHAR(6)   NOT NULL CONSTRAINT DF_Notif_tono DEFAULT N'slate'
                    CONSTRAINT CK_Notif_tono CHECK (tono IN (N'amber', N'green', N'red', N'slate')),
    titulo          NVARCHAR(100) NOT NULL,
    detalle         NVARCHAR(300) NOT NULL,
    leida           BIT NOT NULL CONSTRAINT DF_Notif_leida DEFAULT 0,
    fecha           DATETIME2(0) NOT NULL CONSTRAINT DF_Notif_fecha DEFAULT SYSDATETIME(),
    ref_tipo        NVARCHAR(10)  NULL CONSTRAINT CK_Notif_ref_tipo CHECK (ref_tipo IN (N'cita', N'orden')),
    ref_id          INT NULL
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Notif_destino' AND object_id = OBJECT_ID('dbo.Notificaciones'))
    CREATE INDEX IX_Notif_destino ON dbo.Notificaciones (audiencia, id_usuario, leida, fecha DESC);
GO

/* ---------- Folios consecutivos OT-1001, OT-1002... ---------- */
IF OBJECT_ID(N'dbo.seq_folio_orden', N'SO') IS NULL
    CREATE SEQUENCE dbo.seq_folio_orden AS INT START WITH 1001 INCREMENT BY 1;
GO
