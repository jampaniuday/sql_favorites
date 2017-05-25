select /*+ INC000025773476 */ 25773476  as setticketid from dual;

-- load plan for sql_id/plan_hash_value into SPB
declare
   t_rc  pls_integer;
begin
   t_rc := dbms_spm.load_plans_from_cursor_cache
              (sql_id          => '&sql_id'
              --,plan_hash_value => &plan_hash_value
              ,fixed           => 'NO'
              ,enabled         => 'NO'
              );
   dbms_output.put_line(t_rc);
end;
/

select * from dba_sql_plan_baselines spb
where created > sysdate - 11 --2/1440
order by created desc
;
select * from dba_sql_plan_baselines spb where sql_handle = '&sql_handle' ;
select * from dba_sql_plan_baselines spb where signature = &signature;
select * from table(dbms_xplan.display_sql_plan_baseline(sql_handle => '&sql_handle', format => 'basic'));

-- load plan for sql_id/plan_hash_value into SPB for sql with sql_handle
-- then set enabled to 'NO' for original (bad) plan
declare
   t_rc  pls_integer;
begin
   t_rc := dbms_spm.load_plans_from_cursor_cache
              (sql_id          => '&sql_id'            --> tuned sql
              ,plan_hash_value => &plan_hash_value     --> tuned sql
              ,sql_handle      => '&sql_handle'        --> original sql
              ,fixed           => 'NO'
              ,enabled         => 'YES'
              );
   dbms_output.put_line(t_rc);
end;
/

declare
   t_rc  pls_integer;
begin
   t_rc := dbms_spm.alter_sql_plan_baseline
         (sql_handle      => '&sql_handle'
         ,plan_name       => '&plan_name'
         ,attribute_name  => 'enabled'
         ,attribute_value => 'NO'
         );
   dbms_output.put_line(t_rc);
end;
/

declare
   t_rc  pls_integer;
begin
   t_rc := dbms_spm.alter_sql_plan_baseline
              (sql_handle       => '&sql_handle'
              ,plan_name        => '&plan_name'
              ,attribute_name   => 'fixed'
              ,attribute_value  => 'YES'
              );
end;
/

declare
   t_rc  pls_integer;
begin
   t_rc := dbms_spm.drop_sql_plan_baseline
              (sql_handle       => '&sql_handle'
              ,plan_name        => '&plan_name'
              );
end;
/

select spb.sql_handle
,      spb.plan_name
,      spb.sql_text
,      spb.enabled
,      spb.accepted
,      spb.fixed
,      to_char(spb.last_executed,'dd-mon-yy HH24:MI') last_executed
from dba_sql_plan_baselines spb
--where spb.sql_text like nvl('%'||'&sql_text'||'%',spb.sql_text)
--and spb.sql_handle like nvl('&name',spb.sql_handle)
--and spb.plan_name like nvl('&plan_name',spb.plan_name)
;



select * from dba_sqlset_statements
where sqlset_name = '&sqlset_name'
--and  sql_text like 'UPDATE%'
and   parsing_schema_name = 'FINDW'
;
