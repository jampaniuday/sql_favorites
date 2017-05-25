select * from dba_sql_plan_baselines spb
where sql_handle in (select sql_handle from dba_sql_plan_baselines spb where accepted = 'NO')
order by sql_handle, created desc;

select spb.*,  round(spb.buffer_gets/greatest(spb.executions,1)) "lio/ex" from dba_sql_plan_baselines spb
where plan_name = '&plan_name'
order by created desc;

select * from table(dbms_xplan.display_sql_plan_baseline(sql_handle => '&sql_handle', format => 'basic'));

declare
  t_report clob;
begin
  t_report := dbms_spm.evolve_sql_plan_baseline
                 (sql_handle  => '&sql_handle' -- NULL for all non-accepted plans
                 --,plan_name    IN VARCHAR2 := NULL,
                 --,time_limit   IN INTEGER  := DBMS_SPM.AUTO_LIMIT,
                 ,verify      => 'YES'
                 ,commit      => 'NO'
                 );
  dbms_output.put_line(t_report);
end;
/
