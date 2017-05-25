exec dbms_spm.configure('spm_tracing',1); -- on
exec dbms_spm.configure('spm_tracing',0); -- off
-- Verify tracing is enabled
select parameter_name, parameter_value from sys.smb$config;

alter session set events 'trace [sql_planmanagement.*]';    -- 11.1
alter session set events 'trace off';

alter session set events 'trace [sql_plan_management.*]';   -- 11.2
