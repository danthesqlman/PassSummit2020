

CREATE EVENT SESSION [LinkedServerOLEDBRead] ON SERVER 
ADD EVENT sqlserver.oledb_data_read(
    ACTION(sqlserver.client_app_name,sqlserver.nt_username,sqlserver.sql_text,sqlserver.tsql_stack,sqlserver.username)),
ADD EVENT sqlserver.oledb_query_interface(
    ACTION(sqlserver.client_app_name,sqlserver.nt_username,sqlserver.sql_text,sqlserver.tsql_stack,sqlserver.username))
ADD TARGET package0.event_file(SET filename=N'c:\temp\LinkedServerOLEDBRead',max_file_size=(256)),

ADD TARGET package0.histogram(SET filtering_event_name=N'sqlserver.oledb_data_read',slots=(10000),source=N'sqlserver.tsql_stack')

WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=5 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
GO



		ALTER EVENT SESSION LinkedServerOLEDBRead
		ON SERVER
		STATE=START;

GO
SELECT symbol as 'Password', * from [deadpool\sql2019_2].seacrawladventures.dbo.Character;
GO
SELECT symbol as 'Symbol', * from [deadpool\sql2019_2].seacrawladventures.dbo.Character;

EXEC [deadpool\sql2019_2].master.dbo.sp_who2




--Pulls the filepath out of the system, and applies to the sys.fn_xe_file_target_read_file 
DECLARE @FileName NVARCHAR(4000)

SELECT 	TOP 1 @FileName = target_data.value('(EventFileTarget/File/@name)[1]', 'NVARCHAR(4000)')
FROM 
	(SELECT CAST(target_data AS XML) target_data
	FROM sys.dm_xe_sessions AS s
		INNER JOIN sys.dm_xe_session_targets t
		ON s.address = t.event_session_address
	WHERE s.name = N'LinkedServerOLEDBRead'
	) AS ft
WHERE
	target_data.value('(EventFileTarget/File/@name)[1]', 'NVARCHAR(4000)') IS NOT NULL
;WITH CTE AS
(
SELECT  StartTime = d.value(N'(/event/@timestamp)[1]', N'datetime'),
		Error_Reported = d.value(N'(/event/data[@name="message"]/value)[1]', N'varchar(max)'),
		UserNAme = d.value(N'(/event/action[@name="username"]/value)[1]', N'varchar(128)'),
		NTUserNAme = d.value(N'(/event/action[@name="nt_username"]/value)[1]', N'varchar(128)'),
		SQL_Text = ISNULL(d.value(N'(/event/action[@name="sql_text"]/value)[1]', N'varchar(max)'),'No SQL Text for this error'),
		ClientApplication = d.value(N'(/event/action[@name="client_app_name"]/value)[1]',N'varchar(128)'),
		[ERROR_NUMBER] = d.value(N'(/event/data[@name="error_number"]/value)[1]',N'int'),
		[Severity] = d.value(N'(/event/data[@name="severity"]/value)[1]',N'int'),
		[State] = d.value(N'(/event/data[@name="state"]/value)[1]',N'int'),
		[Database_name] = d.value(N'(/event/action[@name="database_name"]/value)[1]', N'varchar(128)')
FROM
(
    SELECT CONVERT(XML, event_data) 
    FROM sys.fn_xe_file_target_read_file(@FileName,NULL,NULL,NULL)
) AS x(d)
)
SELECT * FROM CTE;

GO




SELECT tab2.handle,
       tab2.slotcount,
       st.dbid,
       st.objectid,
       st.number,
       st.text,
       st.encrypted
FROM
(
    SELECT xed.slot_data.value('xs:hexBinary(substring((value/frames/frame/@handle)[1], 3))', 'varbinary(max)') AS [handle],
           xed.slot_data.value('(@count)[1]', 'varchar(256)') AS slotcount
    FROM
    (
        SELECT CAST(xet.target_data AS XML) AS target_data
        FROM sys.dm_xe_session_targets AS xet
            JOIN sys.dm_xe_sessions AS xe
                ON (xe.address = xet.event_session_address)
        WHERE xe.name = 'LinkedServerOLEDBRead'
              AND target_name = 'histogram'
    ) AS t
        CROSS APPLY t.target_data.nodes('//HistogramTarget/Slot') AS xed(slot_data)
) tab2
    CROSS APPLY sys.dm_exec_sql_text(tab2.handle) AS st;
