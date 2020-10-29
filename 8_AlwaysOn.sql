CREATE EVENT SESSION [AlwaysOn_health] ON SERVER 
ADD EVENT sqlserver.alwayson_ddl_executed,
ADD EVENT sqlserver.availability_group_lease_expired,
ADD EVENT sqlserver.availability_replica_automatic_failover_validation,
ADD EVENT sqlserver.availability_replica_manager_state_change,
ADD EVENT sqlserver.availability_replica_state,
ADD EVENT sqlserver.availability_replica_state_change,
ADD EVENT sqlserver.error_reported(
    WHERE ([error_number]=(9691) OR [error_number]=(35204) OR [error_number]=(9693) OR [error_number]=(26024) OR [error_number]=(28047) OR [error_number]=(26023) OR [error_number]=(9692) OR [error_number]=(28034) OR [error_number]=(28036) OR [error_number]=(28048) OR [error_number]=(28080) OR [error_number]=(28091) OR [error_number]=(26022) OR [error_number]=(9642) OR [error_number]=(35201) OR [error_number]=(35202) OR [error_number]=(35206) OR [error_number]=(35207) OR [error_number]=(26069) OR [error_number]=(26070) OR [error_number]>(41047) AND [error_number]<(41056) OR [error_number]=(41142) OR [error_number]=(41144) OR [error_number]=(1480) OR [error_number]=(823) OR [error_number]=(824) OR [error_number]=(829) OR [error_number]=(35264) OR [error_number]=(35265) OR [error_number]=(41188) OR [error_number]=(41189))),
ADD EVENT sqlserver.hadr_db_partner_set_sync_state,
ADD EVENT sqlserver.lock_redo_blocked
ADD TARGET package0.event_file(SET filename=N'AlwaysOn_health.xel',max_file_size=(5),max_rollover_files=(4))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO







DECLARE @FileName NVARCHAR(4000)
SELECT @FileName = target_data.value('(EventFileTarget/File/@name)[1]','nvarchar(4000)')
FROM (
SELECT
CAST(target_data AS XML) target_data
FROM sys.dm_xe_sessions s
JOIN sys.dm_xe_session_targets t
ON s.address = t.event_session_address
WHERE s.name = N'AlwaysOn_health'
) ft
 SET @filename = 'C:\Program Files\Microsoft SQL Server\MSSQL15.SQL2019\MSSQL\LOG\AlwaysOn*.xel'
SELECT 
XEData.value('(event/@timestamp)[1]','datetime2(3)') AS event_timestamp,
XEData.value('(event/data[@name="previous_state"]/text)[1]', 'varchar(255)') AS previous_state,
XEData.value('(event/data[@name="current_state"]/text)[1]', 'varchar(255)') AS current_state,
XEData.value('(event/data[@name="availability_replica_name"]/value)[1]', 'varchar(255)') AS availability_replica_name,
XEData.value('(event/data[@name="availability_group_name"]/value)[1]', 'varchar(255)') AS availability_group_name
FROM (
SELECT CAST(event_data AS XML) XEData
FROM sys.fn_xe_file_target_read_file(@FileName, NULL, NULL, NULL)
WHERE object_name = 'availability_replica_state_change'
) event_data
--WHERE XEData.value('(event/data[@name="current_state"]/text)[1]', 'varchar(255)') = 'PRIMARY_NORMAL'
ORDER BY event_timestamp DESC;



