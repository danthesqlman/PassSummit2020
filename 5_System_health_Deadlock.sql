
---Two global temp tables with sample data for demo purposes.
CREATE TABLE ##People (
    PersonId INT IDENTITY,
    Name VARCHAR(16),
    Digits VARCHAR(16)
)
GO

INSERT INTO ##People (Name, Digits)
VALUES ('Mary', '800-555-1234'), ('Jenny', '800-867-5309')
GO

CREATE TABLE ##Music(
    MusicID INT IDENTITY,
    MusicianName VARCHAR(64),
    Digits VARCHAR(16)
)
GO

INSERT INTO ##Music (MusicianName, Digits)
VALUES ('LoudMusic', '877-555-5656'), ('JazzEmporium', '800-777-3232')
GO



--run first
BEGIN TRAN;                 
UPDATE ##People
SET Name = 'Mary'
WHERE PersonID = 1

--Run third

UPDATE ##Music
SET Digits = N'555-1212'
WHERE MusicID = 1

rollback tran


SELECT XEvent.query('(event/data/value/deadlock)[1]') AS DeadlockGraph
FROM (
    SELECT XEvent.query('.') AS XEvent
    FROM (
        SELECT CAST(target_data AS XML) AS TargetData
        FROM sys.dm_xe_session_targets st
        INNER JOIN sys.dm_xe_sessions s 
ON s.address = st.event_session_address
        WHERE s.NAME = 'system_health'
            AND st.target_name = 'ring_buffer'
        ) AS Data
CROSS APPLY TargetData.nodes('RingBufferTarget/event[@name="xml_deadlock_report"]') AS XEventData(XEvent)
) AS source;




--
--  Author:        Ben Harding
--  Date:          20/04/2018
--  Purpose:       Output deadlock information stored in the 'system_health' session.
--                 Attempts to get the filename from the 'live' session. If the session is not currently running, then assume XE data is in same location as error log.
-- 
--                 SAVE DEADLOCK GRAPH OUTPUT AS .XDL FILE, THEN CAN OPEN IN SSMS FOR THE PICTURE
--
--  Version:       0.1.0 
--  Disclaimer:    This script is provided "as is" in accordance with the projects license
-- https://raw.githubusercontent.com/microsoft/DataInsightsAsia/4c280c0446aff95f719e6aa4a4b4fcad9db7cd69/Scripts/QueryPerformance/ExtendedEvents_Get_DeadLocksFromSystemHealth_SingleServer.sql
--  History
--  When        Version     Who         What
--  -----------------------------------------------------------------
--  20/04/2018  0.1.0       behardin     Initial coding
--  -----------------------------------------------------------------
--

SET NOCOUNT ON
DECLARE @FileName NVARCHAR(4000)

SELECT 
	TOP 1 @FileName = target_data.value('(EventFileTarget/File/@name)[1]', 'NVARCHAR(4000)')
FROM 
	(
	SELECT 
		CAST(target_data AS XML) target_data
	FROM 
		sys.dm_xe_sessions AS s
		INNER JOIN sys.dm_xe_session_targets t
		ON s.address = t.event_session_address
	WHERE
		s.name = N'system_health'
	) AS ft
WHERE
	target_data.value('(EventFileTarget/File/@name)[1]', 'NVARCHAR(4000)') IS NOT NULL

IF @FileName IS NULL
BEGIN
	PRINT 'Couldn''t get file location from live XE session (probably because it is not running). Getting from (and assuming) default log location'
	SET @FileName = REPLACE(CAST(SERVERPROPERTY('ErrorLogFileName') AS NVARCHAR(512)), 'ERRORLOG','') + N'system_health_*.xel'
END
ELSE
BEGIN
	SELECT	@FileName= LEFT(@FileName, LEN(@FileName)-CHARINDEX('\', REVERSE(@FileName))) + N'\system_health_*.xel'
END

;WITH system_health_data AS 
	(
		SELECT 
			XEData.value('(event/@timestamp)[1]', 'DATETIME') AS event_timestamp
			, XEData
		FROM 
		(
			SELECT 
				CAST(event_data AS XML) XEData
				, *
			FROM 
				sys.fn_xe_file_target_read_file(@FileName, NULL, NULL, NULL)
			WHERE
				object_name = 'xml_deadlock_report'
		) event_data
	)

    SELECT 
		DATEADD(HOUR, DATEDIFF(HOUR, GETUTCDATE(), GETDATE()), event_timestamp)
		, XEventData.XEvent.query('(data/value/deadlock)[1]') AS DeadLockGraph
	FROM 
		system_health_data
		CROSS APPLY XEData.nodes('//event') AS XEventData (XEvent)
