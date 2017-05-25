BEGIN
sys.dbms_scheduler.create_job(
job_name => '"SYSTEM"."DROP_NON_APP_BASELINES"',
job_type => 'PLSQL_BLOCK',
job_action => 'declare
   t_rc  pls_integer := 0;
   t_num pls_integer := 0;
   t_err pls_integer := 0;
   --
   sql_handle_notfound exception;
   PRAGMA EXCEPTION_INIT(sql_handle_notfound, -38131);
begin
   for r_sql in (select spb.sql_handle
                 from   dba_sql_plan_baselines spb
                 where  spb.parsing_schema_name in (''SYS'',''SYSTEM'',''DBSNMP'')
                )
   loop
      begin
         t_rc := dbms_spm.drop_sql_plan_baseline(sql_handle => r_sql.sql_handle);
         t_num := t_num + t_rc;
      exception
      when sql_handle_notfound then t_err := t_err + 1;
      end;
   end loop;
   dbms_output.put_line(''Baselines dropped: ''||to_char(t_num,''fm99990''));
   dbms_output.put_line(''Errors           : ''||to_char(t_err,''fm99990''));
end;
',
repeat_interval => 'FREQ=DAILY;BYHOUR=19',
start_date => systimestamp at time zone 'America/New_York',
job_class => '"DEFAULT_JOB_CLASS"',
comments => 'Drop baselines from the SPB ',
auto_drop => FALSE,
enabled => FALSE);
sys.dbms_scheduler.set_attribute( name => '"SYSTEM"."DROP_NON_APP_BASELINES"', attribute => 'logging_level', value => DBMS_SCHEDULER.LOGGING_FULL);
sys.dbms_scheduler.enable( '"SYSTEM"."DROP_NON_APP_BASELINES"' );
END;
/
