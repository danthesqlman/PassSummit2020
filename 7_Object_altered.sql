--Not as secure as Audit, but can help track when Alterations are occuring on the server. 
--Can be chatty depending on environment. 


CREATE EVENT SESSION object_altered ON SERVER 
ADD EVENT sqlserver.object_altered(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.nt_username,sqlserver.server_principal_name,sqlserver.sql_text,sqlserver.username))
ADD TARGET package0.ring_buffer
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO

ALTER EVENT SESSION object_altered ON SERVER STATE = START;


ALTER DATABASE foo2 SET RECOVERY BULK_LOGGED;
GO
ALTER DATABASE foo2 SET RECOVERY FULL;
GO
ALTER DATABASE foo2 SET RECOVERY SIMPLE;
GO


SELECT StartTime = d.value(N'(/event/@timestamp)[1]', N'datetime'),
       Object_type = d.value(N'(/event/data[@name="object_type"]/value)[1]', N'varchar(100)'),
       Object_text = d.value(N'(/event/data[@name="object_type"]/text)[1]', N'varchar(100)'),
       UserNAme = d.value(N'(/event/action[@name="username"]/value)[1]', N'varchar(128)'),
       NTUserNAme = d.value(N'(/event/action[@name="nt_username"]/value)[1]', N'varchar(128)'),
       SQL_Text = ISNULL(
                            d.value(N'(/event/action[@name="sql_text"]/value)[1]', N'varchar(max)'),
                            'No SQL Text for this error'
                        ),
       ClientApplication = d.value(N'(/event/action[@name="client_app_name"]/value)[1]', N'varchar(128)'),
       [Database_id] = DB_NAME(d.value(N'(/event/data[@name="database_id"]/value)[1]', N'varchar(128)')),
       ddl_phase = d.value(N'(/event/data[@name="ddl_phase"]/value)[1]', N'varchar(128)')
FROM
(
    SELECT XEvent.query('.') AS d
    FROM
    ( -- Cast the target_data to XML 
        SELECT CAST(st.target_data AS XML) AS TargetData
        FROM sys.dm_xe_session_targets st
            JOIN sys.dm_xe_sessions s
                ON s.address = st.event_session_address
        WHERE s.name = N'object_altered'
              AND st.target_name = N'ring_buffer'
    ) AS Data
        CROSS APPLY targetdata.nodes('/RingBufferTarget/event') AS XEventData(Xevent)
) AS tab(d);