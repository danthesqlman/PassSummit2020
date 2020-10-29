
--Here are three deprecated XE, the first one is similar to one I saw from Pinal Dave,  
--The next is one that just uses the histogram target and more lightweight.  
--The first will be one you could also see the sql_text and a bit heavier on the run,
-- while the 2nd is just to find what deprecated announcements are present with a count, and not where they are called. 
--The histogram will only be stored in memory though, and not a file target, so if the server reboots you will lose the data. 


-- --file target-- code defaults it to errorlog location, can set different if you want. 

CREATE EVENT SESSION [Deprecated_and_Discontinued] ON SERVER 
ADD EVENT sqlserver.deprecation_announcement,
ADD EVENT sqlserver.deprecation_final_support(
    ACTION(sqlserver.client_app_name,sqlserver.database_id,sqlserver.sql_text))
ADD TARGET package0.event_file(SET filename=N'Deprecated_and_Discontinued',max_file_size=(20))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=5 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
GO


--Pulls the filepath out of the system, and applies to the sys.fn_xe_file_target_read_file 
DECLARE @FileName NVARCHAR(4000)

SELECT 	TOP 1 @FileName = target_data.value('(EventFileTarget/File/@name)[1]', 'NVARCHAR(4000)')
FROM 
	(SELECT CAST(target_data AS XML) target_data
	FROM sys.dm_xe_sessions AS s
		INNER JOIN sys.dm_xe_session_targets t
		ON s.address = t.event_session_address
	WHERE s.name = N'Deprecated_and_Discontinued'
	) AS ft

;WITH CTE
AS(

SELECT 
  StartTime = d.value(N'(/event/@timestamp)[1]', N'datetime'),
  ClientApplication = d.value(N'(/event/action[@name="client_app_name"]/value)[1]',N'varchar(128)') ,
  TextData = d.value(N'(/event/data[@name="message"]/value)[1]', N'varchar(max)'),
  Database_id = d.value(N'(/event/action[@name="database_id"]/value)[1]', N'int'),
  SQL_Text = d.value(N'(/event/action[@name="sql_text"]/value)[1]', N'varchar(max)'),
  Feature = d.value(N'(/event/data[@name="feature"]/value)[1]',N'varchar(128)')
  FROM
(
  SELECT CONVERT(XML, event_data) 
    FROM sys.fn_xe_file_target_read_file(@FileName,NULL, NULL, NULL)
) AS x(d)
)
SELECT * FROM CTE;






CREATE EVENT SESSION [Deprecation] ON SERVER 
ADD EVENT sqlserver.deprecation_announcement(
    ACTION(sqlserver.client_app_name,sqlserver.database_id,sqlserver.sql_text))
ADD TARGET package0.histogram(SET filtering_event_name=N'sqlserver.deprecation_announcement',source=N'message',source_type=(0))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
GO



CREATE EVENT SESSION [Deprecation_Final_Announcement] ON SERVER 
ADD EVENT sqlserver.deprecation_final_support(
    ACTION(sqlserver.client_app_name,sqlserver.database_id,sqlserver.sql_text))
ADD TARGET package0.histogram(SET filtering_event_name=N'sqlserver.deprecation_final_support',source=N'message',source_type=(0))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
GO


GO
--Query FOR Bucketizer/HISTOGRAM 

SELECT 
    (n.value(N'(value)[1]', N'varchar(500)')) AS Event,
    n.value(N'(@count)[1]', N'int') AS EventCount
    
FROM
(SELECT CAST(target_data as XML) target_data
FROM sys.dm_xe_sessions AS s 
JOIN sys.dm_xe_session_targets t
    ON s.address = t.event_session_address
WHERE s.name = N'Deprecation'
  AND t.target_name = N'histogram') as tab
CROSS APPLY target_data.nodes(N'HistogramTarget/Slot') as q(n)

GO





--For querying Deprecation_Final_Announcement
SELECT 
    (n.value(N'(value)[1]', N'varchar(500)')) AS Event,
    n.value(N'(@count)[1]', N'int') AS EventCount
    
FROM
(SELECT CAST(target_data as XML) target_data
FROM sys.dm_xe_sessions AS s 
JOIN sys.dm_xe_session_targets t
    ON s.address = t.event_session_address
WHERE s.name = N'Deprecation_Final_Announcement'
  AND t.target_name = N'histogram') as tab
CROSS APPLY target_data.nodes(N'HistogramTarget/Slot') as q(n)


















/*
Here are the ones for 2008/2008r2

*/


CREATE EVENT SESSION [Deprecated_and_Discontinued] ON SERVER
ADD EVENT sqlserver.deprecation_announcement(
ACTION(sqlserver.client_app_name,sqlserver.database_id, sqlserver.sql_text)),
ADD EVENT sqlserver.deprecation_final_support(
ACTION(sqlserver.client_app_name,sqlserver.database_id, sqlserver.sql_text))
ADD TARGET package0.asynchronous_file_target(SET filename=N'c:\temp\Deprecated_and_Discontinued.xel',max_file_size=(500),max_rollover_files=(10))
WITH (STARTUP_STATE=ON)
GO
ALTER EVENT SESSION [Deprecated_and_Discontinued] ON SERVER  STATE = START
--DROP EVENT SESSION [Deprecation] ON server


GO
--Histogram -- very lightweight. in memory only. 
CREATE EVENT SESSION [Deprecation] ON SERVER
ADD EVENT sqlserver.deprecation_announcement
ADD TARGET package0.asynchronous_bucketizer(SET filtering_event_name=N'sqlserver.deprecation_announcement',source=N'message',source_type=(0))
WITH(STARTUP_STATE=ON)

GO

CREATE EVENT SESSION [Deprecation_Final_Announcement] ON SERVER
ADD EVENT sqlserver.deprecation_final_support
ADD TARGET package0.asynchronous_bucketizer(SET filtering_event_name=N'sqlserver.deprecation_final_support',source=N'message',source_type=(0))
WITH(STARTUP_STATE=ON)


ALTER EVENT SESSION [Deprecation_Final_Announcement] ON SERVER STATE = START


GO
--Put in the Location of the XEL and XEM files, this script has them in C:\temp
--Query for event_file/asynchronous_file_target
DECLARE @xelpath VARCHAR(MAX)
DECLARE @xempath VARCHAR(MAX)
SET @xelpath = 'C:\Temp\Deprecated_and_Discontinued*.xel'
SET @xempath = 'C:\Temp\Deprecated_and_Discontinued*.xem'


;WITH CTE
AS(

SELECT 
  StartTime = d.value(N'(/event/@timestamp)[1]', N'datetime'),
  ClientApplication = d.value(N'(/event/action[@name="client_app_name"]/value)[1]',N'varchar(128)') ,
  TextData = d.value(N'(/event/data[@name="message"]/value)[1]', N'varchar(max)'),
  Database_id = d.value(N'(/event/action[@name="database_id"]/value)[1]', N'int'),
  SQL_Text = d.value(N'(/event/action[@name="sql_text"]/value)[1]', N'varchar(max)'),
  Feature = d.value(N'(/event/data[@name="feature"]/value)[1]',N'varchar(128)')
  FROM
(
  SELECT CONVERT(XML, event_data) 
    FROM sys.fn_xe_file_target_read_file(@xelpath,@xempath, NULL, NULL)
) AS x(d)
)
SELECT * FROM CTE
--WHERE sql_text <> 'Unable to retrieve SQL text' OR Sql_text = ''
GROUP BY SQL_text
ORDER BY COUNT(*) DESC;




GO
--Query FOR Bucketizer/HISTOGRAM 

SELECT 
    (n.value(N'(value)[1]', N'varchar(500)')) AS Event,
    n.value(N'(@count)[1]', N'int') AS EventCount
    
FROM
(SELECT CAST(target_data as XML) target_data
FROM sys.dm_xe_sessions AS s 
JOIN sys.dm_xe_session_targets t
    ON s.address = t.event_session_address
WHERE s.name = N'Deprecation'
  AND t.target_name = N'asynchronous_bucketizer') as tab
CROSS APPLY target_data.nodes(N'BucketizerTarget/Slot') as q(n)

GO
--For querying Deprecation_Final_Announcement
SELECT 
    (n.value(N'(value)[1]', N'varchar(500)')) AS Event,
    n.value(N'(@count)[1]', N'int') AS EventCount
    
FROM
(SELECT CAST(target_data as XML) target_data
FROM sys.dm_xe_sessions AS s 
JOIN sys.dm_xe_session_targets t
    ON s.address = t.event_session_address
WHERE s.name = N'Deprecation_Final_Announcement'
  AND t.target_name = N'asynchronous_bucketizer') as tab
CROSS APPLY target_data.nodes(N'BucketizerTarget/Slot') as q(n)
