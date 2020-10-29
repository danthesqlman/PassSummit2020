--AS many may have sp_whoisactive 
--I recommend having sp_humanevents
--erikdarlingdata.com/sp_humanevents/

EXEC dbo.sp_HumanEvents @event_type = 'query', @query_duration_ms = 100, @seconds_sample = 60

EXEC dbo.sp_HumanEvents @event_type = 'query', @query_duration_ms = 1000, @seconds_sample = 20, @requested_memory_mb = 1024;

EXEC dbo.sp_HumanEvents @event_type = 'compilations', @client_app_name = N'GL00SNIF?', @session_id = 'sample', @sample_divisor = 3;

EXEC dbo.sp_HumanEvents @event_type = 'waits', @wait_duration_ms = 10, @seconds_sample = 100, @wait_type = N'all';