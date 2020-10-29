USE DRMDB;
GO
--EXEC sp_HumanEvents @event_type = N'compiles', @keep_alive = 1;
--EXEC sp_HumanEvents @event_type = N'recompiles', @keep_alive = 1;
--EXEC sp_HumanEvents @event_type = N'query', @keep_alive = 1;
--EXEC sp_HumanEvents @event_type = N'waits', @keep_alive = 1;
--EXEC sp_HumanEvents @event_type = N'blocking', @keep_alive = 1;
/*Queries*/
SELECT TOP 1000 * FROM dbo.HumanEvents_Queries;
/*Waits*/
SELECT TOP 1000 * FROM dbo.HumanEvents_WaitsByQueryAndDatabase;
SELECT TOP 1000 * FROM dbo.HumanEvents_WaitsByDatabase;
SELECT TOP 1000 * FROM dbo.HumanEvents_WaitsTotal;
/*Blocking*/
SELECT TOP 1000 * FROM dbo.HumanEvents_Blocking;
/*Compiles, only on newer versions of SQL Server*/
SELECT TOP 1000 * FROM dbo.HumanEvents_CompilesByDatabaseAndObject;
SELECT TOP 1000 * FROM dbo.HumanEvents_CompilesByQuery;
SELECT TOP 1000 * FROM dbo.HumanEvents_CompilesByDuration;
/*Parameterization data, if available (comes along with compiles)*/
SELECT TOP 1000 * FROM dbo.HumanEvents_Parameterization;
/*Recompiles, only on newer versions of SQL Server*/
SELECT TOP 1000 * FROM dbo.HumanEvents_RecompilesByDatabaseAndObject;
SELECT TOP 1000 * FROM dbo.HumanEvents_RecompilesByQuery;
SELECT TOP 1000 * FROM dbo.HumanEvents_RecompilesByDuration;



EXEC master.dbo.sp_HumanEvents @output_database_name = N'DRMDB', @output_schema_name = N'dbo';