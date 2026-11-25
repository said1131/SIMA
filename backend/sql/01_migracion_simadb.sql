/* =====================================================================
   SIMA · Migración de SIMADB (SQL Server)
   Archivo: 01_migracion_simadb.sql

   CÓMO EJECUTARLO (DBeaver):
     1. Conéctate a localhost:1433 y abre este archivo en un editor SQL.
     2. Ejecuta TODO el script con "Ejecutar script" (Alt+X), no con Ctrl+Enter.
     3. Si algo falla, todo se revierte (es una sola transacción). Corrige y vuelve a correrlo.

   - Es idempotente: se puede ejecutar varias veces sin duplicar nada.
   - NO usa "GO", así que funciona igual en DBeaver, SSMS y Azure Data Studio.
   - Haz un respaldo antes:  BACKUP DATABASE SIMADB TO DISK = 'SIMADB_antes.bak';
   ===================================================================== */

USE SIMADB;
SET XACT_ABORT ON;   -- cualquier error revierte la transacción completa
SET NOCOUNT ON;

BEGIN TRANSACTION;

DECLARE @sql NVARCHAR(MAX);

/* ---------------------------------------------------------------------
   1. EMPLEADOS  ·  login del personal (web)
   --------------------------------------------------------------------- */
IF COL_LENGTH('dbo.Empleados', 'password_hash') IS NULL
    ALTER TABLE dbo.Empleados ADD password_hash NVARCHAR(255) NULL;

IF COL_LENGTH('dbo.Empleados', 'rol') IS NULL
    ALTER TABLE dbo.Empleados ADD rol NVARCHAR(20) NOT NULL
        CONSTRAINT DF_Empleados_rol DEFAULT 'mecanico';

IF OBJECT_ID(N'dbo.CK_Empleados_rol', N'C') IS NULL
    EXEC (N'ALTER TABLE dbo.Empleados ADD CONSTRAINT CK_Empleados_rol
            CHECK (rol IN (N''admin'', N''mecanico''))');

-- Un correo de empleado no se puede repetir (si ya hay duplicados, aquí se detiene).
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'UX_Empleados_correo' AND object_id = OBJECT_ID('dbo.Empleados'))
    CREATE UNIQUE INDEX UX_Empleados_correo ON dbo.Empleados (correo) WHERE correo IS NOT NULL;

/* ---------------------------------------------------------------------
   2. USUARIOS (clientes)  ·  permitir "cliente sin cuenta" (cita exprés)
      - correo y contrasena pasan a aceptar NULL
      - contrasena guarda el HASH bcrypt (60 caracteres), no la clave en texto
   --------------------------------------------------------------------- */
-- Quita índices/constraints UNIQUE viejos sobre correo para poder cambiar la columna
-- (se vuelve a crear uno compatible con NULL más abajo).
SET @sql = N'';
SELECT @sql += CASE WHEN kc.object_id IS NOT NULL
        THEN N'ALTER TABLE dbo.Usuarios DROP CONSTRAINT ' + QUOTENAME(i.name) + N';'
        ELSE N'DROP INDEX ' + QUOTENAME(i.name) + N' ON dbo.Usuarios;' END
FROM sys.indexes i
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns c        ON c.object_id = ic.object_id AND c.column_id = ic.column_id
LEFT JOIN sys.key_constraints kc
       ON kc.parent_object_id = i.object_id AND kc.unique_index_id = i.index_id AND kc.type = 'UQ'
WHERE i.object_id = OBJECT_ID('dbo.Usuarios')
  AND c.name = 'correo'
  AND i.is_primary_key = 0
  AND i.name <> 'UX_Usuarios_correo';
IF LEN(@sql) > 0 EXEC sp_executesql @sql;

ALTER TABLE dbo.Usuarios ALTER COLUMN correo      NVARCHAR(150) NULL;
ALTER TABLE dbo.Usuarios ALTER COLUMN contrasena  NVARCHAR(255) NULL;

IF COL_LENGTH('dbo.Usuarios', 'tiene_cuenta') IS NULL
    ALTER TABLE dbo.Usuarios ADD tiene_cuenta BIT NOT NULL
        CONSTRAINT DF_Usuarios_tiene_cuenta DEFAULT 1;

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'UX_Usuarios_correo' AND object_id = OBJECT_ID('dbo.Usuarios'))
    CREATE UNIQUE INDEX UX_Usuarios_correo ON dbo.Usuarios (correo) WHERE correo IS NOT NULL;

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_Usuarios_telefono' AND object_id = OBJECT_ID('dbo.Usuarios'))
    CREATE INDEX IX_Usuarios_telefono ON dbo.Usuarios (telefono);

/* ---------------------------------------------------------------------
   3. VEHICULOS
   --------------------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_Vehiculos_usuario' AND object_id = OBJECT_ID('dbo.Vehiculos'))
    CREATE INDEX IX_Vehiculos_usuario ON dbo.Vehiculos (id_usuario);

/* ---------------------------------------------------------------------
   4. SERVICIOS (catálogo)  ·  categoría, duración y garantía
      Nota: la columna "activo" se deja como está (BIT o INT, ambos sirven).
   --------------------------------------------------------------------- */
IF COL_LENGTH('dbo.Servicios', 'categoria') IS NULL
    ALTER TABLE dbo.Servicios ADD categoria NVARCHAR(30) NOT NULL
        CONSTRAINT DF_Servicios_categoria DEFAULT N'Preventivo';

IF COL_LENGTH('dbo.Servicios', 'duracion_horas') IS NULL
    ALTER TABLE dbo.Servicios ADD duracion_horas DECIMAL(4,1) NOT NULL
        CONSTRAINT DF_Servicios_duracion DEFAULT 1;

IF COL_LENGTH('dbo.Servicios', 'garantia_meses') IS NULL
    ALTER TABLE dbo.Servicios ADD garantia_meses INT NOT NULL
        CONSTRAINT DF_Servicios_garantia DEFAULT 1;

IF OBJECT_ID(N'dbo.CK_Servicios_categoria', N'C') IS NOT NULL
    ALTER TABLE dbo.Servicios DROP CONSTRAINT CK_Servicios_categoria;

UPDATE dbo.Servicios
SET categoria = N'Correctivo'
WHERE categoria <> N'Preventivo' OR categoria IS NULL;

EXEC (N'ALTER TABLE dbo.Servicios ADD CONSTRAINT CK_Servicios_categoria
        CHECK (categoria IN (N''Preventivo'', N''Correctivo''))');
        
/* ---------------------------------------------------------------------
   5. CITAS  ·  motivo de rechazo, cita exprés y estados válidos
   --------------------------------------------------------------------- */
IF COL_LENGTH('dbo.Citas', 'motivo_rechazo') IS NULL
    ALTER TABLE dbo.Citas ADD motivo_rechazo NVARCHAR(200) NULL;

IF COL_LENGTH('dbo.Citas', 'es_expres') IS NULL
    ALTER TABLE dbo.Citas ADD es_expres BIT NOT NULL CONSTRAINT DF_Citas_es_expres DEFAULT 0;

-- WITH NOCHECK: no valida filas viejas (revisa el diagnóstico del final), sí valida las nuevas.
IF OBJECT_ID(N'dbo.CK_Citas_estado', N'C') IS NULL
    EXEC (N'ALTER TABLE dbo.Citas WITH NOCHECK ADD CONSTRAINT CK_Citas_estado
            CHECK (estado IN (N''Solicitada'', N''Confirmada'', N''Rechazada'', N''Cancelada''))');

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_Citas_usuario' AND object_id = OBJECT_ID('dbo.Citas'))
    CREATE INDEX IX_Citas_usuario ON dbo.Citas (id_usuario);

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_Citas_fecha' AND object_id = OBJECT_ID('dbo.Citas'))
    CREATE INDEX IX_Citas_fecha ON dbo.Citas (fecha, hora);

/* ---------------------------------------------------------------------
   6. ORDENESTRABAJO  ·  recepción, autorización de cotización, servicio, folio
   --------------------------------------------------------------------- */
IF COL_LENGTH('dbo.OrdenesTrabajo', 'kilometraje') IS NULL
    ALTER TABLE dbo.OrdenesTrabajo ADD kilometraje INT NULL;

IF COL_LENGTH('dbo.OrdenesTrabajo', 'notas_recepcion') IS NULL
    ALTER TABLE dbo.OrdenesTrabajo ADD notas_recepcion NVARCHAR(500) NULL;

IF COL_LENGTH('dbo.OrdenesTrabajo', 'autorizacion') IS NULL
    ALTER TABLE dbo.OrdenesTrabajo ADD autorizacion NVARCHAR(15) NOT NULL
        CONSTRAINT DF_Ordenes_autorizacion DEFAULT N'Pendiente';

IF COL_LENGTH('dbo.OrdenesTrabajo', 'cotizacion_enviada') IS NULL
    ALTER TABLE dbo.OrdenesTrabajo ADD cotizacion_enviada BIT NOT NULL
        CONSTRAINT DF_Ordenes_cotizacion_enviada DEFAULT 0;

-- Servicio solicitado en la recepción (el de la pantalla "Nueva orden")
IF COL_LENGTH('dbo.OrdenesTrabajo', 'id_servicio') IS NULL
    ALTER TABLE dbo.OrdenesTrabajo ADD id_servicio INT NULL
        CONSTRAINT FK_Ordenes_Servicio REFERENCES dbo.Servicios (id_servicio);

-- Una orden puede crearse sin cita previa (llegó directo al taller)
IF EXISTS (SELECT 1 FROM sys.columns
           WHERE object_id = OBJECT_ID('dbo.OrdenesTrabajo') AND name = 'id_cita' AND is_nullable = 0)
    ALTER TABLE dbo.OrdenesTrabajo ALTER COLUMN id_cita INT NULL;

-- Rellena datos de órdenes que ya existían (todo en EXEC porque usa columnas recién creadas)
EXEC (N'UPDATE o SET o.id_servicio = c.id_servicio
        FROM dbo.OrdenesTrabajo o JOIN dbo.Citas c ON c.id_cita = o.id_cita
        WHERE o.id_servicio IS NULL');

EXEC (N'UPDATE dbo.OrdenesTrabajo
        SET autorizacion = N''Autorizada'', cotizacion_enviada = 1
        WHERE estado IN (N''Autorizada'', N''En reparación'', N''Lista'', N''Entregada'')
          AND autorizacion = N''Pendiente''');

EXEC (N'UPDATE dbo.OrdenesTrabajo SET cotizacion_enviada = 1
        WHERE estado = N''Cotizada'' AND cotizacion_enviada = 0');

IF OBJECT_ID(N'dbo.CK_Ordenes_estado', N'C') IS NULL
    EXEC (N'ALTER TABLE dbo.OrdenesTrabajo WITH NOCHECK ADD CONSTRAINT CK_Ordenes_estado
            CHECK (estado IN (N''Recibida'', N''En diagnóstico'', N''Cotizada'', N''Autorizada'',
                              N''En reparación'', N''Lista'', N''Entregada''))');

IF OBJECT_ID(N'dbo.CK_Ordenes_autorizacion', N'C') IS NULL
    EXEC (N'ALTER TABLE dbo.OrdenesTrabajo ADD CONSTRAINT CK_Ordenes_autorizacion
            CHECK (autorizacion IN (N''Pendiente'', N''Autorizada'', N''Rechazada''))');

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'UX_Ordenes_folio' AND object_id = OBJECT_ID('dbo.OrdenesTrabajo'))
    CREATE UNIQUE INDEX UX_Ordenes_folio ON dbo.OrdenesTrabajo (folio) WHERE folio IS NOT NULL;

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_Ordenes_estado' AND object_id = OBJECT_ID('dbo.OrdenesTrabajo'))
    CREATE INDEX IX_Ordenes_estado ON dbo.OrdenesTrabajo (estado);

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_Ordenes_usuario' AND object_id = OBJECT_ID('dbo.OrdenesTrabajo'))
    CREATE INDEX IX_Ordenes_usuario ON dbo.OrdenesTrabajo (id_usuario);

-- Folios consecutivos OT-1001, OT-1002... (arranca después del último folio existente)
IF OBJECT_ID(N'dbo.seq_folio_orden', N'SO') IS NULL
BEGIN
    DECLARE @siguiente INT;
    SELECT @siguiente = ISNULL(MAX(TRY_CAST(SUBSTRING(folio, 4, 20) AS INT)), 1000) + 1
    FROM dbo.OrdenesTrabajo WHERE folio LIKE 'OT-%';

    SET @sql = N'CREATE SEQUENCE dbo.seq_folio_orden AS INT START WITH '
             + CAST(@siguiente AS NVARCHAR(12)) + N' INCREMENT BY 1;';
    EXEC sp_executesql @sql;
END

/* ---------------------------------------------------------------------
   7. ORDENES_SERVICIOS  ·  líneas de la cotización
      La PK era (id_orden, id_servicio), lo que impedía conceptos libres
      (refacciones, tornería, mano de obra). Se recrea con PK propia
      id_detalle, id_servicio opcional, concepto y tipo. Los datos se copian.
   --------------------------------------------------------------------- */
IF COL_LENGTH('dbo.Ordenes_Servicios', 'id_detalle') IS NULL
BEGIN
    EXEC (N'
    CREATE TABLE dbo.Ordenes_Servicios_nuevo (
        id_detalle      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Ordenes_Servicios PRIMARY KEY,
        id_orden        INT NOT NULL CONSTRAINT FK_OrdSrv_Orden
                            REFERENCES dbo.OrdenesTrabajo (id_orden) ON DELETE CASCADE,
        id_servicio     INT NULL CONSTRAINT FK_OrdSrv_Servicio
                            REFERENCES dbo.Servicios (id_servicio),
        concepto        NVARCHAR(150) NOT NULL,
        tipo            NVARCHAR(15)  NOT NULL CONSTRAINT DF_OrdSrv_tipo DEFAULT N''Labor''
                            CONSTRAINT CK_OrdSrv_tipo CHECK (tipo IN (N''Refacción'', N''Tornería'', N''Labor'')),
        cantidad        DECIMAL(8,2)  NOT NULL CONSTRAINT CK_OrdSrv_cantidad CHECK (cantidad > 0),
        precio_unitario DECIMAL(12,2) NOT NULL CONSTRAINT CK_OrdSrv_precio CHECK (precio_unitario >= 0),
        subtotal        AS (CAST(cantidad * precio_unitario AS DECIMAL(14,2))) PERSISTED
    );');

    EXEC (N'
    INSERT INTO dbo.Ordenes_Servicios_nuevo (id_orden, id_servicio, concepto, tipo, cantidad, precio_unitario)
    SELECT os.id_orden, os.id_servicio, s.nombre, N''Labor'', os.cantidad, os.precio_unitario
    FROM dbo.Ordenes_Servicios os
    JOIN dbo.Servicios s ON s.id_servicio = os.id_servicio;');

    DROP TABLE dbo.Ordenes_Servicios;
    EXEC sp_rename N'dbo.Ordenes_Servicios_nuevo', N'Ordenes_Servicios';

    EXEC (N'CREATE INDEX IX_OrdSrv_orden ON dbo.Ordenes_Servicios (id_orden);');
END

/* ---------------------------------------------------------------------
   8. NOTIFICACIONES (tabla nueva)
      audiencia 'personal' -> avisos para el taller (id_usuario NULL)
      audiencia 'cliente'  -> avisos para un cliente (id_usuario = destinatario)
   --------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.Notificaciones', N'U') IS NULL
BEGIN
    EXEC (N'
    CREATE TABLE dbo.Notificaciones (
        id_notificacion INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Notificaciones PRIMARY KEY,
        audiencia       NVARCHAR(10)  NOT NULL
                            CONSTRAINT CK_Notif_audiencia CHECK (audiencia IN (N''personal'', N''cliente'')),
        id_usuario      INT NULL CONSTRAINT FK_Notif_Usuario
                            REFERENCES dbo.Usuarios (id_usuario) ON DELETE CASCADE,
        tipo            NVARCHAR(12)  NOT NULL
                            CONSTRAINT CK_Notif_tipo CHECK (tipo IN (N''cita'', N''orden'', N''cotizacion'')),
        tono            NVARCHAR(6)   NOT NULL CONSTRAINT DF_Notif_tono DEFAULT N''slate''
                            CONSTRAINT CK_Notif_tono CHECK (tono IN (N''amber'', N''green'', N''red'', N''slate'')),
        titulo          NVARCHAR(100) NOT NULL,
        detalle         NVARCHAR(300) NOT NULL,
        leida           BIT           NOT NULL CONSTRAINT DF_Notif_leida DEFAULT 0,
        fecha           DATETIME2(0)  NOT NULL CONSTRAINT DF_Notif_fecha DEFAULT SYSDATETIME(),
        ref_tipo        NVARCHAR(10)  NULL
                            CONSTRAINT CK_Notif_ref_tipo CHECK (ref_tipo IN (N''cita'', N''orden'')),
        ref_id          INT NULL
    );');

    EXEC (N'CREATE INDEX IX_Notif_destino
            ON dbo.Notificaciones (audiencia, id_usuario, leida, fecha DESC);');
END

/* ---------------------------------------------------------------------
   9. DIAGNÓSTICO: filas viejas con valores que el sistema no reconoce
      (si salen resultados, corrígelos con UPDATE para que coincidan)
   --------------------------------------------------------------------- */
SELECT 'Citas con estado no válido' AS revisar, id_cita AS id, estado
FROM dbo.Citas
WHERE estado NOT IN (N'Solicitada', N'Confirmada', N'Rechazada', N'Cancelada') OR estado IS NULL;

SELECT 'Órdenes con estado no válido' AS revisar, id_orden AS id, estado
FROM dbo.OrdenesTrabajo
WHERE estado NOT IN (N'Recibida', N'En diagnóstico', N'Cotizada', N'Autorizada',
                     N'En reparación', N'Lista', N'Entregada') OR estado IS NULL;

SELECT 'Usuarios con contraseña sin cifrar (no es bcrypt): deben restablecerla' AS revisar,
       COUNT(*) AS total
FROM dbo.Usuarios
WHERE contrasena IS NOT NULL AND LEN(contrasena) <> 60;

COMMIT TRANSACTION;
PRINT 'Migración SIMA aplicada correctamente.';

/* =====================================================================
   OPCIONAL · Usuario de SQL Server exclusivo para la API (recomendado)
   Ejecútalo aparte, descomentando, y usa estos datos en backend/.env
   ---------------------------------------------------------------------
   USE master;
   CREATE LOGIN sima_api WITH PASSWORD = 'Cambia_Esta_Clave_123!', CHECK_POLICY = OFF;
   USE SIMADB;
   CREATE USER sima_api FOR LOGIN sima_api;
   ALTER ROLE db_datareader ADD MEMBER sima_api;
   ALTER ROLE db_datawriter ADD MEMBER sima_api;
   GRANT UPDATE ON OBJECT::dbo.seq_folio_orden TO sima_api;   -- necesario para generar folios
   ===================================================================== */
