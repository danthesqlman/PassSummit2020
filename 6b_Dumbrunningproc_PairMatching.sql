

-- Create XML variable to hold Target Data
DECLARE @target_data XML;
SELECT @target_data = CAST(target_data AS XML)
FROM sys.dm_xe_sessions AS s
    JOIN sys.dm_xe_session_targets AS t
        ON t.event_session_address = s.address
WHERE s.name = 'PM_DUMBRUNNINGPROC'
      AND t.target_name = 'pair_matching';
	  --1 for beginning
	  --3 for completed....good question.....why?....


-- Query XML variable to get Target Execution information
SELECT @target_data.value('(PairingTarget/@orphanCount)[1]', 'int') AS orphanCount,
       @target_data.value('(PairingTarget/@matchedCount)[1]', 'int') AS matchedCount,
       @target_data.value('(PairingTarget/@memoryPressureDroppedCount)[1]', 'int') AS memoryPressureDroppedCount;

-- Query the XML variable to get the Target Data
SELECT n.value('(event/@name)[1]', 'varchar(50)') AS event_name,
       n.value('(event/@package)[1]', 'varchar(50)') AS package_name,
       n.value('(event/@id)[1]', 'int') AS id,
       n.value('(event/@version)[1]', 'int') AS version,
       DATEADD(hh, DATEDIFF(hh, GETUTCDATE(), CURRENT_TIMESTAMP), n.value('(event/@timestamp)[1]', 'datetime2')) AS [timestamp],
       n.value('(event/data[@name="source_database_id"]/value)[1]', 'int') AS [source_database_id],
       n.value('(event/data[@name="object_id"]/value)[1]', 'int') AS [object_id],
       n.value('(event/data[@name="object_type"]/value)[1]', 'varchar(60)') AS [object_type],
       n.value('(event/data[@name="state"]/text)[1]', 'varchar(50)') AS [state],
       n.value('(event/data[@name="offset"]/value)[1]', 'int') AS [offset],
       n.value('(event/data[@name="offset_end"]/value)[1]', 'int') AS [offset_end],
       n.value('(event/data[@name="nest_level"]/value)[1]', 'int') AS [nest_level],
       n.value('(event/action[@name="session_id"]/value)[1]', 'int') AS session_id,
       n.value('(event/action[@name="tsql_stack"]/value)[1]', 'varchar(max)') AS tsql_stack,
       n.value('(event/action[@name="attach_activity_id"]/value)[1]', 'varchar(50)') AS activity_id
FROM
(
    SELECT td.query('.') AS n
    FROM @target_data.nodes('PairingTarget/event') AS q(td)
) AS tab
ORDER BY session_id,
         activity_id;