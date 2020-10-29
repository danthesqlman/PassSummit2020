/*
Database file found at
https://gallery.technet.microsoft.com/SQL-Server-game-31c25d1d
Author: Daniel Janik 
*/
IF EXISTS (SELECT * FROM SYS.SERVER_EVENT_SESSIONS WHERE name = 'Delete_Map_trigger')
	BEGIN
		DROP EVENT SESSION  Delete_Map_trigger ON SERVER
	END
USE MASTER;
GO
ALTER DATABASE SeaCrawlAdventures SET OFFLINE WITH ROLLBACK IMMEDIATE;
go
RESTORE database seacrawlAdventures FROM Disk = N'C:\Backup\Deadpool$SQL2019\SeacrawlAdventures\FULL\Deadpool$SQL2019_SeacrawlAdventures_FULL_20201024_213842.bak'
WITH REPLACE, STATS = 5
GO

USE SeaCrawlAdventures;
GO
--Set text output
EXEC dbo.do 'new'

--SORRY FOR PLAYING GAMES DURING MY DEMO, I'LL QUIT!
EXEC dbo.do 'retire'

--OH WERE YOU ALL INTERESTED? 
go
EXEC dbo.do 'new'

SELECT * FROM DBO.MAP

USE MASTER;
go
ALTER DATABASE SeaCrawlAdventures SET OFFLINE WITH ROLLBACK IMMEDIATE;
GO
RESTORE DATABASE seacrawlAdventures FROM Disk = N'C:\Backup\Deadpool$SQL2019\SeacrawlAdventures\FULL\Deadpool$SQL2019_SeacrawlAdventures_FULL_20201024_213842.bak'
WITH replace, stats = 5
GO
USE SeaCrawlAdventures;
go
CREATE TRIGGER dbo.Delete_Map_trigger ON dbo.map
INSTEAD OF DELETE
AS
	RETURN


GO
DECLARE @Object_id int
DECLARE @SQL nvarchar(MAX)
SET @Object_id = Object_id('dbo.Delete_Map_trigger')
IF @Object_id IS NOT NULL 
	BEGIN
		SET @SQL = 'CREATE EVENT SESSION Delete_Map_trigger
			ON SERVER 
			ADD EVENT sqlserver.module_start(
				ACTION(sqlserver.tsql_stack)
				WHERE ([object_id]= ' + CAST(@object_id AS NVARCHAR(16))+ ')) 
			ADD TARGET package0.ring_buffer
			WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=1 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=ON)'
		
		EXEC sp_executesql @stmt = @sql
		
		ALTER EVENT SESSION Delete_Map_trigger
		ON SERVER
		STATE=START;

	END
	ELSE
		BEGIN
			RAISERROR('Object id is invalid',10,1) WITH NOWAIT;
		END

GO
--Lets run our statement to cause some damage

EXEC dbo.do  'new'

EXEC dbo.do 'retire'

EXEC dbo.do  'new'
--And the data is changed....


GO
-- What's executing the trigger
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	event_id,
	level,
	handle,
	line,
	offset_start,
	offset_end,
	st.dbid,
	st.objectid,
	OBJECT_NAME(st.objectid, st.dbid) AS ObjectName,
    SUBSTRING(st.text, (offset_start/2)+1, 
        ((CASE offset_end
          WHEN -1 THEN DATALENGTH(st.text)
         ELSE offset_end
         END - offset_start)/2) + 1) AS stmt

FROM
(
	SELECT 
		tab.event_id,
		frame.value('(@level)[1]', 'int') AS [level],
		frame.value('xs:hexBinary(substring((@handle)[1], 3))', 'varbinary(max)') AS [handle],
		frame.value('(@line)[1]', 'int') AS [line],
		frame.value('(@offsetStart)[1]', 'int') AS [offset_start],
		frame.value('(@offsetEnd)[1]', 'int') AS [offset_end]
	FROM
	(
		SELECT 
			ROW_NUMBER() OVER (ORDER BY XEvent.value('(event/@timestamp)[1]', 'datetime2')) AS event_id,
			XEvent.query('(action[@name="tsql_stack"]/value/frames)[1]') AS [tsql_stack]
		FROM 
		(    -- Cast the target_data to XML 
			SELECT CAST(target_data AS XML) AS TargetData 
			FROM sys.dm_xe_session_targets st 
			JOIN sys.dm_xe_sessions s 
				ON s.address = st.event_session_address 
			WHERE s.name = N'Delete_Map_trigger' 
				AND st.target_name = N'ring_buffer'
		) AS Data 
		-- Split out the Event Nodes 
		CROSS APPLY TargetData.nodes ('RingBufferTarget/event') AS XEventData (XEvent)
	) AS tab 
	CROSS APPLY tsql_stack.nodes ('(frames/frame)') AS stack(frame)
) AS tab2
CROSS APPLY sys.dm_exec_sql_text(tab2.handle) AS st
GO