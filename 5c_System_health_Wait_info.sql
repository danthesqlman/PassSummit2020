
--Run this on two separate windows while talking about other stuff


BEGIN TRAN
UPDATE Foo2.dbo.foo
SET name = 'Ben&Jerry'
WHERE ID = 1;


rollback tran




DECLARE @path NVARCHAR(260);
--to retrieve the local path of system_health files 
SELECT @path = dosdlc.path
FROM sys.dm_os_server_diagnostics_log_configurations AS dosdlc;

SELECT @path = @path + N'system_health_*';

SELECT CAST(fx.event_data AS XML) AS Event_Data,
       fx.object_name
FROM sys.fn_xe_file_target_read_file(@path,
                                     NULL,
                                     NULL,
                                     NULL) AS fx
WHERE fx.object_name = 'wait_info';