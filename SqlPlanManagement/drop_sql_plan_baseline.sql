select distinct parsing_schema_name from dba_sql_plan_baselines spb;

select round(spb.buffer_gets/greatest(spb.executions,1)) "lio/ex"
,      to_char(floor(((elapsed_time/case when executions > 0 then executions else 1 end)/1000000)/3600),'fm9900')||':'||
        to_char(floor(mod(((elapsed_time/case when executions > 0 then executions else 1 end)/1000000),3600)/60),'fm00')||':'||
        to_char(floor(mod(mod(((elapsed_time/case when executions > 0 then executions else 1 end)/1000000),3600),60)),'fm00') ||'.'||
        to_char(round(mod((elapsed_time/case when executions > 0 then executions else 1 end),1000000)/1000000,3)*1000,'fm000')  "Elapsed/exec"
,      spb.*
from dba_sql_plan_baselines spb
--where created > sysdate - 14/24
--where created between to_date('01/20/2013 08:00:00','mm/dd/yyyy hh24:mi:ss')
--                  and to_date('01/20/2013 15:00:00','mm/dd/yyyy hh24:mi:ss')
--and   action   like 'PRC_PURGE%'
--and module = 'PKG_LEDGER_AVB_SUMMARY'
order by created desc
;

select * from dba_sql_plan_baselines spb
where created > sysdate - 1
order by created desc
;

select spb.*,  round(spb.buffer_gets/greatest(spb.executions,1)) "lio/ex" from dba_sql_plan_baselines spb
where sql_handle = '&sql_handle'
order by created desc;

declare
   t_rc  pls_integer := 0;
begin
   t_rc := dbms_spm.drop_sql_plan_baseline(sql_handle => '&sql_handle');
end;
/

declare
   t_rc  pls_integer := 0;
begin
   t_rc := dbms_spm.drop_sql_plan_baseline(sql_handle => '&sql_handle', plan_name => '&plan_name');
end;
/

select * from dba_sql_plan_baselines spb
where parsing_schema_name in ('SYS','SYSTEM','DBSNMP')
;

declare
   t_rc  pls_integer := 0;
   t_num pls_integer := 0;
   t_err pls_integer := 0;
   --
   sql_handle_notfound exception;
   PRAGMA EXCEPTION_INIT(sql_handle_notfound, -38131);
begin
   for r_sql in (select distinct spb.sql_handle
                 from   dba_sql_plan_baselines spb
                 --where  spb.parsing_schema_name in ('SYS','SYSTEM','DBSNMP')
                )
   loop
      begin
         t_rc := dbms_spm.drop_sql_plan_baseline(sql_handle => r_sql.sql_handle);
         t_num := t_num + t_rc;
      exception
      when sql_handle_notfound then t_err := t_err + 1;
      end;
   end loop;
   dbms_output.put_line('Baselines dropped: '||to_char(t_num,'fm99990'));
   dbms_output.put_line('Errors           : '||to_char(t_err,'fm99990'));
end;
/
/*
Running single statement at cursor.
ORA-38131: specified SQL handle SYS_SQL_6d8acc04ce888582 does not exist
ORA-06512: at "SYS.DBMS_SPM", line 2444
ORA-06512: at line 10
*/

select distinct spb.sql_handle, 'dbms_spm.drop_sql_plan_baseline(sql_handle => '||spb.sql_handle||');' ddl
from   dba_sql_plan_baselines spb
where  sql_text like 'SELECT M.MANUFACTURER FROM PWRLINE.LSMDPHYSICALMETER P, PWRLINE.LSMDPHYSMTRTYPE T, PWRLINE.LSMDMTRMANUFACTURER M, PWRLINE.LSMDMTRREADSYSHIST H, PWRLINE.LSMDMTRREADSYSTEM S WHERE P.UIDMETERMANUFACTURER = M.UIDMTRMANUFACTURER AND P.UIDPHYSMTRTYPE = T.UIDPHYSMTRTYPE AND T.PHYSMETERTYPE = ''ELECTRIC'' AND H.UIDPHYSICALMETER = P.UIDPHYSICALMETER AND H.STARTTIME <= SYSDATE AND (H.STOPTIME IS NULL OR H.STOPTIME >= SYSDATE) AND S.UIDMTRREADSYSTEM = H.UIDMTRREADSYSTEM AND S.METERREADSYSTEM =%'
and    sql_text not like '%:%'
and    last_executed < to_date('03/24/2012','mm/dd/yyyy')
;
