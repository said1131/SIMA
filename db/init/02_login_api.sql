/* =====================================================================
   02_login_api.sql · Usuario de SQL Server exclusivo para la API (mínimos permisos)
   La contraseña llega desde docker-compose como variable de sqlcmd: $(API_PASSWORD)
   ===================================================================== */
USE master;
GO
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'sima_api')
    CREATE LOGIN sima_api WITH PASSWORD = N'$(API_PASSWORD)', CHECK_POLICY = OFF;
ELSE
    ALTER LOGIN sima_api WITH PASSWORD = N'$(API_PASSWORD)';   -- por si cambias la clave en .env
GO

USE SIMADB;
GO
IF USER_ID(N'sima_api') IS NULL
    CREATE USER sima_api FOR LOGIN sima_api;
GO
ALTER ROLE db_datareader ADD MEMBER sima_api;
ALTER ROLE db_datawriter ADD MEMBER sima_api;
GRANT UPDATE ON OBJECT::dbo.seq_folio_orden TO sima_api;   -- necesario para generar folios
GO
