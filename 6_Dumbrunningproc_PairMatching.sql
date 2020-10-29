USE FOO2;
GO
CREATE OR ALTER PROCEDURE DBO.DUMBRUNNINGPROC @WAITFOR INT = 1
AS

IF @WAITFOR = 1
BEGIN
	WAITFOR DELAY '00:00:10'
	SELECT NAME, VALUE FROM SYS.CONFIGURATIONS
	WHERE NAME = 'max server memory (MB)'
	RETURN
END

ELSE
	BEGIN
	WAITFOR DELAY '00:00:30'
	
	SELECT NAME, VALUE FROM SYS.CONFIGURATIONS
	WHERE NAME = 'max server memory (MB)'
	RETURN
END

GO

SELECT oBJECT_ID('DBO.DUMBRUNNINGPROC')

CREATE EVENT SESSION [PM_DUMBRUNNINGPROC] ON SERVER 
ADD EVENT sqlserver.sp_statement_completed(SET collect_statement=(0)
    ACTION(sqlserver.session_id)
    WHERE ([object_id]=(18099105) AND [source_database_id]=(13))),
ADD EVENT sqlserver.sp_statement_starting(SET collect_statement=(0)
    ACTION(sqlserver.session_id)
    WHERE ([object_id]=(18099105) AND [source_database_id]=(13)))
ADD TARGET package0.pair_matching(SET begin_event=N'sqlserver.sp_statement_starting',begin_matching_actions=N'sqlserver.session_id',end_event=N'sqlserver.sp_statement_completed',end_matching_actions=N'sqlserver.session_id',respond_to_memory_pressure=(1))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=5 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=OFF)
GO



EXEC Foo2.DBO.DUMBRUNNINGPROC 7


