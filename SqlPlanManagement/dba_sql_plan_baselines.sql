select count(*), min(created), max(created) from dba_sql_plan_baselines spb;
select * from dba_sql_plan_baselines spb order by sql_handle, created;

select trunc(created) create_day, count(*) from dba_sql_plan_baselines spb
group by trunc(created)
order by trunc(created)
;


select spb.*,  round(spb.buffer_gets/greatest(spb.executions,1)) "lio/ex" from dba_sql_plan_baselines spb
order by created desc;

select spb.*,  round(spb.buffer_gets/greatest(spb.executions,1)) "lio/ex" from dba_sql_plan_baselines spb
order by sql_handle, created desc;

select round(spb.buffer_gets/greatest(spb.executions,1)) "lio/ex"
,      to_char(floor(((elapsed_time/case when executions > 0 then executions else 1 end)/1000000)/3600),'fm9900')||':'||
        to_char(floor(mod(((elapsed_time/case when executions > 0 then executions else 1 end)/1000000),3600)/60),'fm00')||':'||
        to_char(floor(mod(mod(((elapsed_time/case when executions > 0 then executions else 1 end)/1000000),3600),60)),'fm00') ||'.'||
        to_char(round(mod((elapsed_time/case when executions > 0 then executions else 1 end),1000000)/1000000,3)*1000,'fm000')  "Elapsed/exec"
,      spb.*
from dba_sql_plan_baselines spb
--where created > trunc(sysdate) -- 24
where created > sysdate - 1--/24
--where created between to_date('01/20/2013 08:00:00','mm/dd/yyyy hh24:mi:ss')
--                  and to_date('01/20/2013 15:00:00','mm/dd/yyyy hh24:mi:ss')
--and   action   like 'PRC_PURGE%'
--and module = 'PKG_LEDGER_AVB_SUMMARY'
--and creator = 'RPT_MONITOR'
order by created desc;

select spb.*,  round(spb.buffer_gets/greatest(spb.executions,1)) "lio/ex" from dba_sql_plan_baselines spb
where accepted = 'NO'
order by created desc;

select spb.*,  round(spb.buffer_gets/greatest(spb.executions,1)) "lio/ex" from dba_sql_plan_baselines spb
where sql_handle = '&sql_handle'
order by created desc;

select spb.*,  round(spb.buffer_gets/greatest(spb.executions,1)) "lio/ex" from dba_sql_plan_baselines spb
where plan_name = '&plan_name'
order by created desc;

select spb.*,  round(spb.buffer_gets/greatest(spb.executions,1)) "lio/ex" from dba_sql_plan_baselines spb
where signature = &signature
order by created desc;

select spb.*,  round(spb.buffer_gets/greatest(spb.executions,1)) "lio/ex" from dba_sql_plan_baselines spb
where sql_text like 'INSERT%INTO "MDMRPT"."UNBL_USG_MV" SELECT * FROM unbl_usg_vw%'
--and   action   like 'PRC_PURGE%'
order by created desc;

select spb.*,  round(spb.buffer_gets/greatest(spb.executions,1)) "lio/ex" from dba_sql_plan_baselines spb
where sql_text like '%TBL_JOURNAL_DETAIL%'
order by created desc;

select spb.*,  round(spb.buffer_gets/greatest(spb.executions,1)) "lio/ex" from dba_sql_plan_baselines spb
where creator = 'SYS'
order by created desc;

select spb.*,  round(spb.buffer_gets/greatest(spb.executions,1)) "lio/ex" from dba_sql_plan_baselines spb
where parsing_schema_name = 'SYS'
order by created desc;

select spb.*,  round(spb.buffer_gets/greatest(spb.executions,1)) "lio/ex" from dba_sql_plan_baselines spb
where sql_handle in (select sql_handle from dba_sql_plan_baselines spb where accepted = 'NO')
order by sql_handle, created desc;

select * from table(dbms_xplan.display_sql_plan_baseline(sql_handle => '&sql_handle', format => 'basic'));

select spb.*,  round(spb.buffer_gets/greatest(spb.executions,1)) "lio/ex" from dba_sql_plan_baselines spb
--where upper(sql_text) like upper('UPDATE PC_PROJECT_ESTIMATE_HISTORY SET ESTIMATE_AMT%')
--where parsing_schema_name = 'ESPID'
order by dbms_lob.substr(sql_text,100,1)
;

select parsing_schema_name, count(*)
from dba_sql_plan_baselines spb
group by rollup(parsing_schema_name)
order by 2 desc
;

-- baselines created manually
select sql_handle, creator, origin, parsing_schema_name, enabled, accepted, fixed, reproduced, created
, last_modified, last_executed, executions, sql_text, module
from dba_sql_plan_baselines spb
where sql_handle in (select distinct sql_handle
                     from dba_sql_plan_baselines spb
                     where origin = 'MANUAL-LOAD'
                    )
order by sql_handle, created desc
;

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

select st.sql_handle
,      decode(ad.origin, 1, 'MANUAL-LOAD',
                         2, 'AUTO-CAPTURE',
                         3, 'MANUAL-SQLTUNE',
                         4, 'AUTO-SQLTUNE',
                            'UNKNOWN')                    origin
,      to_char(so.last_executed, 'mm/dd/yyyy hh24:mi:ss') last_executed
,      ad.executions
,      to_char(ad.last_verified, 'mm/dd/yyyy hh24:mi:ss') last_verified
,      decode(Bitand(so.flags, 1), 1, 'YES', 'NO')        enabled
,      decode(Bitand(so.flags, 2), 2, 'YES', 'NO')        accepted
,      decode(Bitand(so.flags, 4), 4, 'YES', 'NO')        fixed
,      st.sql_text
,      sod.comp_data
,      sod.plan_id
,      so.name plan_name
,      so.signature
from   sys.sqlobj$        so
,      sys.sqlobj$auxdata ad
,      sys.sqlobj$data    sod
,      sys.sql$text       st
where  so.signature = st.signature
and    ad.signature = st.signature
and    so.signature = ad.signature
and    so.signature = sod.signature
and    so.plan_id   = ad.plan_id
and    so.plan_id   = sod.plan_id
and    so.obj_type  = 2
and    ad.obj_type  = 2
and    st.sql_handle = '&sql_handle'
--and    so.signature = &signature
;

select * from dba_sql_management_config;

with inst as (select (sysdate - startup_time)*24*60*60 as secs_running from v$instance)
select sql_id
,      child_number "Child"
,      plan_hash_value
,      buffer_gets "Lio"
,      first_load_time
,      parse_calls "Parse"
,      executions  "Exec"
,      command_type
,      round(buffer_gets/greatest(executions,1))    "lio/ex"
,      disk_reads "Pio"
,      case when command_type = 3
            then case when executions > 0 then round(rows_processed/executions) end
       end "rw/ex"
,      case when command_type = 3
            then case when fetches > 0    then round(rows_processed/fetches) end
       end "rw/ftch"
,      sql_text
,      hash_value
,      elapsed_time   "Elapsed"
,      rows_processed "Rows"
,      case when elapsed_time = 0 then 0 else trunc(rows_processed/(elapsed_time/1000000)) end "rows/sec"
,      round(executions/secs_running, 2) "ex/sec"
,      to_char(floor((elapsed_time/1000000)/3600),'fm9900')||':'||
        to_char(floor(mod((elapsed_time/1000000),3600)/60),'fm00')||':'||
        to_char(floor(mod(mod((elapsed_time/1000000),3600),60)),'fm00') ||'.'||
        to_char(round(mod(elapsed_time,1000000)/1000000,3)*1000,'fm000')  "Elapsed hh:mi:ss"
,      to_char(floor(((elapsed_time/case when executions > 0 then executions else 1 end)/1000000)/3600),'fm9900')||':'||
        to_char(floor(mod(((elapsed_time/case when executions > 0 then executions else 1 end)/1000000),3600)/60),'fm00')||':'||
        to_char(floor(mod(mod(((elapsed_time/case when executions > 0 then executions else 1 end)/1000000),3600),60)),'fm00') ||'.'||
        to_char(round(mod((elapsed_time/case when executions > 0 then executions else 1 end),1000000)/1000000,3)*1000,'fm000')  "Elapsed/exec"
,      to_char(floor((cpu_time/1000000)/3600),'fm9900')||':'||
        to_char(floor(mod((cpu_time/1000000),3600)/60),'fm00')||':'||
        to_char(floor(mod(mod((cpu_time/1000000),3600),60)),'fm00') ||'.'||
        to_char(round(mod(cpu_time,1000000)/1000000,3)*1000,'fm000')  "CPU hh:mi:ss"
,      to_char(floor(((cpu_time/case when executions > 0 then executions else 1 end)/1000000)/3600),'fm9900')||':'||
        to_char(floor(mod(((cpu_time/case when executions > 0 then executions else 1 end)/1000000),3600)/60),'fm00')||':'||
        to_char(floor(mod(mod(((cpu_time/case when executions > 0 then executions else 1 end)/1000000),3600),60)),'fm00') ||'.'||
        to_char(round(mod((cpu_time/case when executions > 0 then executions else 1 end),1000000)/1000000,3)*1000,'fm000')  "CPU/exec"
,      optimizer_mode
,      last_load_time
,      last_active_time
,      sql_profile
,      sql_plan_baseline
,     (select username from all_users where user_id = parsing_schema_id) parsing_schema
--,      s.*
from gv$sql s
,      inst i
where sql_plan_baseline is not null
order by s.first_load_time desc, child_number
;

select * from sys.sqlobj$        where signature = &signature;
select * from sys.sqlobj$auxdata where signature = &signature;
select * from sys.sqlobj$data    where signature = &signature;
select * from sys.sql$text       where signature = &signature;
select * from sys.sql$           where signature = &signature;
select * from sys.sqllog$        where signature = &signature; --> this is the table spm uses to track sql


select count(*) from dba_sql_plan_baselines spb where sql_text not like '%:%';
select parsing_schema_name, count(*)
from dba_sql_plan_baselines spb
where sql_text not like '%:%'
group by rollup(parsing_schema_name)
order by 2 desc
;
