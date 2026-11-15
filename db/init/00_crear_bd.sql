/* 00_crear_bd.sql · Crea la base de datos SIMADB si no existe (instalación limpia / Docker) */
IF DB_ID(N'SIMADB') IS NULL
BEGIN
    CREATE DATABASE SIMADB;
END
GO
