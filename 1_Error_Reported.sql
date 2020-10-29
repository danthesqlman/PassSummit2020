/*
Error_Reported event

This helps show various events on the system that would show as errors that may or may not cause problems for the system. 
Some can just be fat fingered DBA quries....I mean queries. 

The selection below was started as I was helping find what permissions people were having trouble with...End users don't always know what they need, but this helped to find what was being denied. Later adding the full severity 16+ I was able to leverage to find issues when I would migrate systems, and helping developers with issues. 


*/

--All messages in system for us_english

SELECT m.message_id, m.severity,m.text FROM sys.messages m
INNER JOIN syslanguages l ON l.lcid = m.language_id
WHERE l.name = 'us_english' --Modify here if you have a different language on your system
--SQL2019 CU8 - 14,093
select @@version



SELECT * FROM sys.messages where severity >= 16
and language_id = 1033 --10,810

SELECT * FROM sys.messages WHERE text like '%denied%'
and language_id = 1033 and severity < 16

CREATE EVENT SESSION [Error_reported]
ON SERVER
    ADD EVENT sqlserver.error_reported
    (ACTION
     (
         sqlserver.client_app_name,
         sqlserver.nt_username,
         sqlserver.sql_text,
         sqlserver.username
     )
     WHERE (
               [package0].[greater_than_equal_int64]([severity], (16))
               OR [error_number] = (6004)
               OR [error_number] = (15469)
			   OR [error_number] = (15470)
			   OR [error_number] = (15472)
			   OR [error_number] = (15562)
			   OR [error_number] = (15622)
			   OR [error_number] = (3701)
			   OR [error_number] = (15388)
			   OR [error_number] = (229)
			   OR [error_number] = (230)
			   OR [error_number] = (300)
			   OR [error_number] = (2104)
           )
    )
    ADD TARGET package0.event_file
    (SET filename = N'c:\temp\Error_reported') -- change file location here if needed. 
WITH
(
    MAX_MEMORY = 4096KB,
    EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY = 5 SECONDS,
    MAX_EVENT_SIZE = 0KB,
    MEMORY_PARTITION_MODE = NONE,
    TRACK_CAUSALITY = OFF,
    STARTUP_STATE = ON
);
GO

ALTER EVENT SESSION [Error_Reported] ON SERVER STATE = START;
GO

DECLARE @FileName NVARCHAR(4000)
SELECT @FileName = target_data.value('(EventFileTarget/File/@name)[1]','nvarchar(4000)')
FROM (
SELECT
CAST(target_data AS XML) target_data
FROM sys.dm_xe_sessions s
JOIN sys.dm_xe_session_targets t
ON s.address = t.event_session_address
WHERE s.name = N'Error_reported'
) ft
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