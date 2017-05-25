select s.sql_id
,      s.inst_id
,      s.child_number
,      s.plan_hash_value
,      s.first_load_time
,      s.parse_calls
,      s.executions
,      round(s.buffer_gets/greatest(s.executions,1))   "lio/ex"
,      round(s.disk_reads/greatest(executions,1))      "pio/ex"
,      case when s.command_type in (2,3,6,7)
            then case when s.executions > 0 then round(s.rows_processed/s.executions) end
       end "rows/ex"
,      case when s.command_type in (2,3,6)
            then case when s.executions > 0 then round(s.rows_processed/nullif(s.fetches,0)) end
       end "rows/fetch"
,      to_char(floor(((s.elapsed_time/case when s.executions > 0 then s.executions else 1 end)/1000000)/3600),'fm9900')||':'||
        to_char(floor(mod(((s.elapsed_time/case when s.executions > 0 then s.executions else 1 end)/1000000),3600)/60),'fm00')||':'||
        to_char(floor(mod(mod(((s.elapsed_time/case when s.executions > 0 then s.executions else 1 end)/1000000),3600),60)),'fm00') ||'.'||
        to_char(round(mod((s.elapsed_time/case when s.executions > 0 then s.executions else 1 end),1000000)/1000000,5)*100000,'fm00000')  "Elapsed/exec"
,      case when s.executions > 0 then round(s.cpu_time/s.executions)   end/1000000 "cpu/ex"
,      case when s.executions > 0 then round(s.application_wait_time/s.executions)   end/1000000 "apw/ex"
,      case when s.executions > 0 then round(s.concurrency_wait_time/s.executions)   end/1000000 "concw/ex"
,      case when s.executions > 0 then round(s.cluster_wait_time/s.executions)   end/1000000 "clw/ex"
,      case when s.executions > 0 then round(s.user_io_wait_time/s.executions)   end/1000000 "useriow/ex"
,      case when s.executions > 0 then round(s.plsql_exec_time/s.executions)   end/1000000 "plsqlw/ex"
,      case when s.executions > 0 then round(s.java_exec_time/s.executions)   end/1000000 "javaw/ex"
,      rows_processed "Rows"
,      case when s.elapsed_time = 0 then 0 else trunc(s.rows_processed/(nullif(s.elapsed_time,0)/1000000)) end "rows/sec"
,      case when s.executions > 0 then round((s.cpu_time/nullif(s.elapsed_time,0))*100,2) end "%cpu"
,      case when s.executions > 0 then round((s.application_wait_time/nullif(s.elapsed_time,0))*100,2) end "%apw"
,      case when s.executions > 0 then round((s.concurrency_wait_time/nullif(s.elapsed_time,0))*100,2) end "%concw"
,      case when s.executions > 0 then round((s.cluster_wait_time/nullif(s.elapsed_time,0))*100,2) end "%clw"
,      case when s.executions > 0 then round((s.user_io_wait_time/nullif(s.elapsed_time,0))*100,2) end "%userio"
,      case when s.executions > 0 then round((s.plsql_exec_time/nullif(s.elapsed_time,0))*100,2) end "%plsql"
,      case when s.executions > 0 then round((s.java_exec_time/nullif(s.elapsed_time,0))*100,2) end "%java"
,      to_char(floor((s.elapsed_time/1000000)/3600),'fm9900')||':'||
        to_char(floor(mod((s.elapsed_time/1000000),3600)/60),'fm00')||':'||
        to_char(floor(mod(mod((s.elapsed_time/1000000),3600),60)),'fm00') ||'.'||
        to_char(round(mod(s.elapsed_time,1000000)/1000000,5)*100000,'fm00000')  "Elapsed hh:mi:ss"
,      s.*
,     (select username from all_users where user_id = s.parsing_schema_id) parsing_schema
--,      sc.bind_mismatch
--,      sc.use_feedback_stats
--,      sc.*
from gv$sql                s
,    gv$sql_shared_cursor  sc
where s.sql_id       = '&sqlid'
and   s.sql_id       = sc.sql_id
and   s.child_number = sc.child_number
and   s.inst_id      = sc.inst_id
order by s.inst_id, s.first_load_time desc, s.child_number
;

select * from table(dbms_xplan.display_cursor('&sqlid'));
select * from table(dbms_xplan.display_cursor('&sqlid','&child_number','ALLSTATS LAST REMOTE PEEKED_BINDS'));
select * from table(dbms_xplan.display_cursor('&sqlid','&child_number','ALLSTATS ALL REMOTE PEEKED_BINDS'));
select * from table(dbms_xplan.display_cursor('&sqlid','&child_number','ADVANCED'));
select * from table(dbms_xplan.display_awr('&sqlid',null,null,'ALL'));

select * from gv$sql_monitor sm where sm.sql_id = '&sqlid';
select dbms_sqltune.report_sql_monitor(sql_id=>'&sqlid',report_level=>'TYPICAL', type=>'TEXT') sqlmon from dual;
select dbms_sqltune.report_sql_monitor(sql_id=>'&sqlid',report_level=>'TYPICAL', type=>'HTML') sqlmon from dual;
select dbms_sqltune.report_sql_monitor(sql_id=>'&sqlid',report_level=>'ALL', type=>'HTML') sqlmon from dual;
select dbms_sqltune.report_sql_monitor(sql_id=>'&sqlid',sql_exec_id=>&sql_exec_id, report_level=>'TYPICAL', type=>'TEXT') sqlmon from dual;

select dbms_sqltune.report_sql_monitor_list(sql_id=>'&sqlid',report_level=>'TYPICAL', type=>'TEXT') sqlmonlist from dual;
select dbms_sqltune.report_sql_detail(sql_id=>'&sqlid',report_level=>'TYPICAL') sqldetail from dual;

select dbms_sql_monitor.report_sql_monitor(type=>'active') from dual;

with inst as (select (sysdate - startup_time)*24*60*60 as secs_running from v$instance)
select sql_id
,      child_number "Child"
,      inst_id
,      plan_hash_value
,      buffer_gets "Lio"
,      first_load_time
,      parse_calls "Parse"
,      executions  "Exec"
,      command_type
,      round(buffer_gets/greatest(executions,1))   "lio/ex"
--,      disk_reads "pio"
,      round(disk_reads/greatest(executions,1))    "pio/ex"
,      case when command_type in (2,3,6,7)
            then case when executions > 0 then round(rows_processed/executions) end
       end "rw/ex"
,      case when command_type = 3
            then case when fetches > 0    then round(rows_processed/fetches) end
       end "rw/ftch"
,      to_char(floor(((elapsed_time/case when executions > 0 then executions else 1 end)/1000000)/3600),'fm9900')||':'||
        to_char(floor(mod(((elapsed_time/case when executions > 0 then executions else 1 end)/1000000),3600)/60),'fm00')||':'||
        to_char(floor(mod(mod(((elapsed_time/case when executions > 0 then executions else 1 end)/1000000),3600),60)),'fm00') ||'.'||
        to_char(round(mod((elapsed_time/case when executions > 0 then executions else 1 end),1000000)/1000000,5)*100000,'fm00000')  "Elapsed/exec"
,      to_char(floor((elapsed_time/1000000)/3600),'fm9900')||':'||
        to_char(floor(mod((elapsed_time/1000000),3600)/60),'fm00')||':'||
        to_char(floor(mod(mod((elapsed_time/1000000),3600),60)),'fm00') ||'.'||
        to_char(round(mod(elapsed_time,1000000)/1000000,3)*1000,'fm000')  "Elapsed hh:mi:ss"
,      sql_text
,      hash_value
,      elapsed_time   "Elapsed"
,      rows_processed "Rows"
,      case when elapsed_time = 0 then 0 else trunc(rows_processed/(elapsed_time/1000000)) end "rows/sec"
,      round(executions/secs_running, 2) "ex/sec"
,      to_char(floor((cpu_time/1000000)/3600),'fm9900')||':'||
        to_char(floor(mod((cpu_time/1000000),3600)/60),'fm00')||':'||
        to_char(floor(mod(mod((cpu_time/1000000),3600),60)),'fm00') ||'.'||
        to_char(round(mod(cpu_time,1000000)/1000000,3)*1000,'fm000')  "CPU hh:mi:ss"
,      to_char(floor(((cpu_time/case when executions > 0 then executions else 1 end)/1000000)/3600),'fm9900')||':'||
        to_char(floor(mod(((cpu_time/case when executions > 0 then executions else 1 end)/1000000),3600)/60),'fm00')||':'||
        to_char(floor(mod(mod(((cpu_time/case when executions > 0 then executions else 1 end)/1000000),3600),60)),'fm00') ||'.'||
        to_char(round(mod((cpu_time/case when executions > 0 then executions else 1 end),1000000)/1000000,5)*100000,'fm00000')  "CPU/exec"
,      optimizer_mode
,      last_load_time
,      last_active_time
,      sql_profile
--,      sql_plan_baseline
,      exact_matching_signature
--,      is_bind_aware
--,      is_bind_sensitive
,     (select username from all_users where user_id = parsing_schema_id) parsing_schema
--,      s.*
from gv$sql s
,      inst i
--where upper(sql_fulltext) like upper('SELECT%AND  FINANCES.GL_PROCESS.GL_PROCESS  NOT IN  (''PPUTJRL'')%AND  FINANCES.GL_PRODUCT.GL_PRODUCT  NOT IN  (''PPUTJR'')%AND  FIN_INTERNAL.FI_CODEBLOCK_BUSINESS_RULE.RULE_YEAR  =  2016%AND  FIN_INTERNAL.FI_CODEBLOCK_BUSINESS_RULE.ENT_FUNCTION  =  ''Delivery Operations - FL''%AND  FIN_INTERNAL.FI_CODEBLOCK_BUSINESS_RULE.ENT_SEGMENT  =  ''Regulated Utilities''%')
where upper(sql_fulltext) like upper('select%to_timestamp(to_char(decode(umc.time_variant,''Y'', tv.begin_date%')
--where sql_id = '&sqlid'
--where exact_matching_signature = '&signature'
--where sql_plan_baseline = 'SQL_PLAN_cf928gt9uhxvnc1713651'
--and parsing_user_id = 227
order by s.first_load_time desc, inst_id, child_number;


select s.sql_id, s.sql_fulltext
from gv$sql s
where upper(s.sql_fulltext) like upper('SELECT * FROM ( SELECT ROW_. *, ROWNUM ROWNUM_ FROM ( SELECT APPLICATIO1_.NAME AS COL_0_0_, MANAGEDATT0_.ATTRIBUTE AS COL_1_0_, MANAGEDATT0_.DISPLAYABLE_NAME AS COL_2_0_, MANAGEDATT0_.VALUE AS COL_3_0_, MANAGEDATT0_.TYPE AS COL_4_0_, MANAGEDATT0_.ATTRIBUTES AS COL_5_0_, IDENTITY2_.DISPLAY_NAME AS COL_6_0_, MANAGEDATT0_.REQUESTABLE AS COL_7_0_, MANAGEDATT0_.MODIFIED AS COL_8_0_, MANAGEDATT0_.ID AS COL_9_0_ FROM SPT_MANAGED_ATTRIBUTE MANAGEDATT0_ LEFT OUTER JOIN SPT_APPLICATION APPLICATIO1_ ON MANAGEDATT0_.APPLICATION = APPLICATIO1_.ID LEFT OUTER JOIN SPT_IDENTITY IDENTITY2_ ON MANAGEDATT0_.OWNER = IDENTITY2_.ID WHERE (MANAGEDATT0_.ASSIGNED_SCOPE_PATH LIKE%')
or    upper(s.sql_fulltext) like upper('SELECT COUNT (IDENTITY0_.ID) AS COL_0_0_ FROM SPT_IDENTITY IDENTITY0_ WHERE (IDENTITY0_.ASSIGNED_SCOPE_PATH LIKE%')
or    upper(s.sql_fulltext) like upper('SELECT * FROM ( SELECT ROW_. *, ROWNUM ROWNUM_ FROM (SELECT DISTINCT IDENTITY0_.ID AS COL_0_0_, IDENTITY0_.NAME AS COL_1_0_, IDENTITY0_.FIRSTNAME AS COL_2_0_, IDENTITY0_.LASTNAME AS COL_3_0_, IDENTITY0_.EMAIL AS COL_4_0_, IDENTITY0_.WORKGROUP AS COL_5_0_, IDENTITY0_.DISPLAY_NAME AS COL_6_0_ FROM SPT_IDENTITY IDENTITY0_ WHERE (IDENTITY0_.ASSIGNED_SCOPE_PATH LIKE%')
or    upper(s.sql_fulltext) like upper('SELECT DISTINCT COUNT (DISTINCT IDENTITY0_.ID) AS COL_0_0_ FROM SPT_IDENTITY IDENTITY0_ WHERE (IDENTITY0_.ASSIGNED_SCOPE_PATH LIKE%')
or    upper(s.sql_fulltext) like upper('SELECT * FROM ( SELECT DISTINCT IDENTITY0_.ID AS COL_0_0_, IDENTITY0_.NAME AS COL_1_0_, IDENTITY0_.FIRSTNAME AS COL_2_0_, IDENTITY0_.LASTNAME AS COL_3_0_, IDENTITY0_.EMAIL AS COL_4_0_, IDENTITY0_.WORKGROUP AS COL_5_0_, IDENTITY0_.DISPLAY_NAME AS COL_6_0_ FROM SPT_IDENTITY IDENTITY0_ WHERE (IDENTITY0_.ASSIGNED_SCOPE_PATH LIKE%')
or    upper(s.sql_fulltext) like upper('SELECT * FROM ( SELECT DISTINCT IDENTITY0_.ID AS COL_0_0_, IDENTITY0_.NAME AS COL_1_0_, IDENTITY0_.DISPLAY_NAME AS COL_2_0_, IDENTITY0_.FIRSTNAME AS COL_3_0_, IDENTITY0_.LASTNAME AS COL_4_0_, IDENTITY0_.EMAIL AS COL_5_0_, IDENTITY0_.WORKGROUP AS COL_6_0_, IDENTITY0_.MANAGER_STATUS AS COL_7_0_ FROM SPT_IDENTITY IDENTITY0_ WHERE (IDENTITY0_.ASSIGNED_SCOPE_PATH LIKE ? OR IDENTITY0_.ASSIGNED_SCOPE_PATH LIKE%')

--or    upper(s.sql_fulltext) like upper('select * from ( select row_.*, rownum rownum_ from ( select distinct identity0_.id as col_0_0_, identity0_.name as col_1_0_, identity0_.firstname as col_2_0_, identity0_.lastname as col_3_0_, identity0_.name as col_4_0_, identity0_.lan_id as col_5_0_, identity0_.domain as col_6_0_, identity0_.department_id as col_7_0_ from spt_identity identity0_ where identity0_.id<>%')
order by 1
;



/* need statistics_level=all for this, or use gather_plan_statistics hint */
select id
,      parent_id
    -- ,last_cr_buffer_gets
     --,children_cr_buffer_gets
     --,children_cr_buffer_gets2
,      operation
,      last_starts          "Starts"
,      last_output_rows     "Rows (total)"
,      case when last_starts = 0 then 0 else ceil(last_output_rows/last_starts) end "Rows (real)"
,      cardinality          "Rows"
,      case when id = 1 then last_cr_buffer_gets else last_cr_buffer_gets - nvl(children_cr_buffer_gets,0)   end "Cr gets"
,      case when id = 1 then last_cu_buffer_gets else last_cu_buffer_gets - nvl(children_cu_buffer_gets,0)   end "Cu gets"
,      case when id = 1 then last_disk_reads     else last_disk_reads     - nvl(children_last_disk_reads,0)  end "Reads"
,      case when id = 1 then last_disk_writes    else last_disk_writes    - nvl(children_last_disk_writes,0) end "Writes"
,      case when last_elapsed_time - nvl(children_elapsed_time,0) < 0
            then 0 -- just in case something messed up with last_elapsed_time
            else last_elapsed_time - nvl(children_elapsed_time,0)
       end "Self Elapsed (ms)"
,      case when last_elapsed_time - nvl(children_elapsed_time,0) < 0
            then '   0.0'
            else to_char(round(100 * ratio_to_report(last_elapsed_time - nvl(children_elapsed_time,0) ) over () ,1),'990.0')
       end  "Self %"
,      last_elapsed_time                                      "Elapsed (ms)"
,      case when max_elapsed_time > 0 then to_char(round(100 * (last_elapsed_time/max_elapsed_time),1),'900.0') end "%"
,      case when last_elapsed_time - nvl(children_elapsed_time,0) < 0
            then '00:00:00.000'
            else
              to_char(floor(((last_elapsed_time - nvl(children_elapsed_time,0))/1000000)/3600),'fm9900')||':'||
               to_char(floor(mod(((last_elapsed_time - nvl(children_elapsed_time,0))/1000000),3600)/60),'fm00')||':'||
               to_char(floor(mod(mod(((last_elapsed_time - nvl(children_elapsed_time,0))/1000000),3600),60)),'fm00') ||'.'||
               to_char(round(mod((last_elapsed_time - nvl(children_elapsed_time,0)),1000000)/1000000,6)*1000000,'fm000000')
       end "Duration of self"
,      to_char(floor((last_elapsed_time/1000000)/3600),'fm9900')||':'||
        to_char(floor(mod((last_elapsed_time/1000000),3600)/60),'fm00')||':'||
        to_char(floor(mod(mod((last_elapsed_time/1000000),3600),60)),'fm00') ||'.'||
        to_char(round(mod(last_elapsed_time,1000000)/1000000,6)*1000000,'fm000000')  "Elapsed hh:mi:ss"
,      cost
,      cpu_cost
,      io_cost
,      access_predicates
,      filter_predicates
,      last_memory_used
,      optimal_mem
,      onepass_mem
,      opt_one_mul "O/1/M"
,      last_execution
,      last_degree
,      address
,      child_number
,      optimizer
,     (select username from all_users where user_id = parsing_schema_id) parsing_schema
from
(
select p.id
,      p.parent_id
,      lpad(' ',1*(p.depth-1))||p.operation||' '||p.options||' '
       || case when p.object_owner is null
          then null
          else p.object_owner||'.'||p.object_name
          end
       || decode(p.partition_start,null,' ',':')||translate(p.partition_start,'nrumbe','(nr')
       || decode(p.partition_stop,null,' ','-')||translate(p.partition_stop,'nrumbe','(nr')
       as operation
,      s.last_output_rows
,      p.cardinality
,      p.cost
,      p.cpu_cost
,      p.io_cost
,      s.last_starts
,      s.last_cr_buffer_gets
--,      sum(s.last_cr_buffer_gets) over (partition by p.id)  children_cr_buffer_gets2
,      (select sum(si.last_cr_buffer_gets)
        from  v$sql_plan_statistics_all si
        where si.sql_id       = p.sql_id
        and   si.child_number = p.child_number
        and   si.parent_id    = p.id
       ) children_cr_buffer_gets
,      s.last_cu_buffer_gets
,      (select sum(si.last_cu_buffer_gets)
        from  v$sql_plan_statistics_all si
        where si.sql_id       = p.sql_id
        and   si.child_number = p.child_number
        and   si.parent_id    = p.id
       ) children_cu_buffer_gets
,      s.last_disk_reads
,      (select sum(si.last_disk_reads)
        from  v$sql_plan_statistics_all si
        where si.sql_id       = p.sql_id
        and   si.child_number = p.child_number
        and   si.parent_id    = p.id
       ) children_last_disk_reads
,      s.last_disk_writes
,      (select sum(si.last_disk_writes)
        from  v$sql_plan_statistics_all si
        where si.sql_id       = p.sql_id
        and   si.child_number = p.child_number
        and   si.parent_id    = p.id
       ) children_last_disk_writes
,      max(s.last_elapsed_time) over () max_elapsed_time
,      s.last_elapsed_time
,      (select sum(si.last_elapsed_time)
        from  v$sql_plan_statistics_all si
        where si.sql_id       = p.sql_id
        and   si.child_number = p.child_number
        and   si.parent_id    = p.id
       ) children_elapsed_time
,      p.access_predicates
,      p.filter_predicates
,      p.address
,      p.child_number
,      p.hash_value
,      case when p.parent_id is null
           then (select parsing_schema_id from v$sql s where s.hash_value = p.hash_value and s.address = p.address and s.child_number = p.child_number)
       end as parsing_schema_id
,      s.last_memory_used
,      s.last_execution
,      trunc(s.estimated_optimal_size/1024) optimal_mem
,      trunc(s.estimated_onepass_size/1024) onepass_mem
,      decode(s.optimal_executions, null, null, s.optimal_executions||'/'||s.onepass_executions||'/'||s.multipasses_executions) opt_one_mul
,      s.last_degree
,      p.optimizer
from v$sql_plan            p
,    v$sql_plan_statistics_all s
where p.sql_id       = '&sqlid'
and   p.child_number = nvl(&child_number,0)
and   s.address      (+) = p.address
and   s.id           (+) = p.id
and   s.child_number (+) = p.child_number
)
order by hash_value, child_number, id
;


-- **************** tmsprod thresher: 3q2pkud4y15bz
select snap.snap_id
,      snap.end_interval_time
,      stat.instance_number        inst
,	     stat.plan_hash_value        phv
,      sum(stat.parse_calls_delta) prs
,      sum(stat.executions_delta)  exe
,      sum(stat.buffer_gets_delta) lio
,      sum(stat.disk_reads_delta) pio
--,      sum(stat.elapsed_time_total)/1000000 ela_tot1
--,      to_char(floor(sum(stat.elapsed_time_total)/1000000/3600),'fm9900')||':'||
--        to_char(floor(mod(sum(stat.elapsed_time_total)/1000000,3600)/60),'fm00')||':'||
--        to_char(floor(mod(mod(sum(stat.elapsed_time_total)/1000000,3600),60)),'fm00')||'.' ||
--        to_char(round(mod(sum(stat.elapsed_time_total),1000000)/1000000,6)*1000000,'fm000000') ela_tot
,      to_char(floor(sum(stat.elapsed_time_delta)/1000000/3600),'fm9900')||':'||
        to_char(floor(mod(sum(stat.elapsed_time_delta)/1000000,3600)/60),'fm00')||':'||
        to_char(floor(mod(mod(sum(stat.elapsed_time_delta)/1000000,3600),60)),'fm00')||'.' ||
        to_char(round(mod(sum(stat.elapsed_time_delta),1000000)/1000000,6)*1000000,'fm000000') ela_delta
,      sum(case when stat.executions_delta > 0 then round(stat.buffer_gets_delta/stat.executions_delta)    end) "lio/ex"
,      sum(case when stat.executions_delta > 0 then round(stat.disk_reads_delta/stat.executions_delta)     end) "pio/ex"
,      round(( sum(stat.disk_reads_delta) / nullif(sum(stat.buffer_gets_delta),0) ) * 100,2) "%pio"
,      sum(case when stat.executions_delta > 0 then round(stat.rows_processed_delta/stat.executions_delta) end) "rows/ex"
,      sum(case when stat.executions_delta > 0 then round(stat.elapsed_time_delta/stat.executions_delta)   end)/1000000 "ela/ex"
,      sum(case when stat.executions_delta > 0 then round(stat.cpu_time_delta/stat.executions_delta)   end)/1000000 "cpu/ex"
,      sum(case when stat.executions_delta > 0 then round(stat.iowait_delta/stat.executions_delta)   end)/1000000 "iow/ex"
,      sum(case when stat.executions_delta > 0 then round(stat.clwait_delta/stat.executions_delta)   end)/1000000 "clw/ex"
,      sum(case when stat.executions_delta > 0 then round(stat.ccwait_delta/stat.executions_delta)   end)/1000000 "cc/ex"
,      sum(case when stat.executions_delta > 0 then round((stat.elapsed_time_delta-stat.clwait_delta)/stat.executions_delta)   end)/1000000 "ela-clus/ex"
,      round((sum(stat.cpu_time_delta) / nullif(sum(stat.elapsed_time_delta),0) ) * 100,2) "%cpu"
,      round((sum(stat.iowait_delta) / nullif(sum(stat.elapsed_time_delta),0) ) * 100,2) "%iowait"
,      round((sum(stat.clwait_delta) / nullif(sum(stat.elapsed_time_delta),0) ) * 100,2) "%clwait"
,      round((sum(stat.ccwait_delta) / nullif(sum(stat.elapsed_time_delta),0) ) * 100,2) "%ccwait"
,      round((sum(stat.apwait_delta) / nullif(sum(stat.elapsed_time_delta),0) ) * 100,2) "%apwait"
,      to_char(floor(sum(stat.cpu_time_delta)/1000000/3600),'fm9900')||':'||
        to_char(floor(mod(sum(stat.cpu_time_delta)/1000000,3600)/60),'fm00')||':'||
        to_char(floor(mod(mod(sum(stat.cpu_time_delta)/1000000,3600),60)),'fm00')||'.' ||
        to_char(round(mod(sum(stat.cpu_time_delta),1000000)/1000000,6)*1000000,'fm000000') cpu_time_delta
,      to_char(floor(sum(stat.iowait_delta)/1000000/3600),'fm9900')||':'||
        to_char(floor(mod(sum(stat.iowait_delta)/1000000,3600)/60),'fm00')||':'||
        to_char(floor(mod(mod(sum(stat.iowait_delta)/1000000,3600),60)),'fm00')||'.' ||
        to_char(round(mod(sum(stat.iowait_delta),1000000)/1000000,6)*1000000,'fm000000') iowait_delta
,      to_char(floor(sum(stat.clwait_delta)/1000000/3600),'fm9900')||':'||
        to_char(floor(mod(sum(stat.clwait_delta)/1000000,3600)/60),'fm00')||':'||
        to_char(floor(mod(mod(sum(stat.clwait_delta)/1000000,3600),60)),'fm00')||'.' ||
        to_char(round(mod(sum(stat.clwait_delta),1000000)/1000000,6)*1000000,'fm000000') clusterwait_delta
,      to_char(floor(sum(stat.ccwait_delta)/1000000/3600),'fm9900')||':'||
        to_char(floor(mod(sum(stat.ccwait_delta)/1000000,3600)/60),'fm00')||':'||
        to_char(floor(mod(mod(sum(stat.ccwait_delta)/1000000,3600),60)),'fm00')||'.' ||
        to_char(round(mod(sum(stat.ccwait_delta),1000000)/1000000,6)*1000000,'fm000000') ccwait_delta
,      to_char(floor(sum(stat.apwait_delta)/1000000/3600),'fm9900')||':'||
        to_char(floor(mod(sum(stat.apwait_delta)/1000000,3600)/60),'fm00')||':'||
        to_char(floor(mod(mod(sum(stat.apwait_delta)/1000000,3600),60)),'fm00')||'.' ||
        to_char(round(mod(sum(stat.apwait_delta),1000000)/1000000,6)*1000000,'fm000000') apwait_delta
,      sum(stat.rows_processed_delta)     sum_rows_proc
,      sum(stat.fetches_delta)            sum_fetches
,      sum(case when stat.executions_delta > 0 then round(stat.fetches_delta/stat.executions_delta)   end) "ftch/ex"
,      min(stat.force_matching_signature) force_matching_signature
,      min(stat.sql_id) sql_id
from   dba_hist_sqlstat  stat
,      dba_hist_snapshot snap
where  stat.sql_id = '&sqlid'
--and    plan_hash_value != 3953216635
and    snap.snap_id         = stat.snap_id
and    snap.dbid            = stat.dbid
and    snap.instance_number = stat.instance_number
and    snap.dbid            = (select dbid from v$database)
group by snap.snap_id, snap.end_interval_time, stat.instance_number, stat.plan_hash_value
--having sum(stat.parse_calls_delta) > 0
having sum(stat.executions_delta) > 0
order by snap.snap_id desc, stat.instance_number
;

--summed per day/instance
select trunc(snap.end_interval_time) eit
,      stat.instance_number        inst
,	     stat.plan_hash_value        phv
,      sum(stat.parse_calls_delta) prs
,      sum(stat.executions_delta)  exe
,      sum(buffer_gets_delta) lio
,      sum(disk_reads_delta) pio
,      round(( sum(stat.disk_reads_delta) / nullif(sum(stat.buffer_gets_delta),0) ) * 100,2) "%pio"
,      sum(elapsed_time_total) ela_tot
,      sum(case when stat.executions_delta > 0 then round(stat.buffer_gets_delta/stat.executions_delta)    end) "lio/ex"
,      sum(case when stat.executions_delta > 0 then round(stat.rows_processed_delta/stat.executions_delta) end) "rows/ex"
,      round(sum(case when stat.executions_delta > 0 then round(stat.elapsed_time_delta/stat.executions_delta)   end)/1000000,2) "ela/ex"
,      sum(elapsed_time_delta) ela_delta
,      sum(iowait_delta) iowait_delta
,      sum(apwait_delta) apwait_delta
,      round((sum(iowait_delta) / nullif(sum(elapsed_time_delta),0) ) * 100,2) "%iowait"
,      round((sum(apwait_delta) / nullif(sum(elapsed_time_delta),0) ) * 100,2) "%apwait"
--,      sum(clwait_delta) clwait_delta
--,      sum(apwait_delta) apwait_delta
--,      sum(ccwait_delta) ccwait_delta
,      sum(stat.rows_processed_delta)     sum_rows_proc
,      min(stat.force_matching_signature) force_matching_signature
,      min(stat.sql_id) sql_id
from   dba_hist_sqlstat  stat
,      dba_hist_snapshot snap
where  stat.sql_id = '&sqlid'
--and    plan_hash_value != 3953216635
and    snap.snap_id         = stat.snap_id
and    snap.dbid            = stat.dbid
and    snap.instance_number = stat.instance_number
group by trunc(snap.end_interval_time), stat.instance_number, stat.plan_hash_value
--having sum(stat.parse_calls_delta) > 0
--having sum(stat.executions_delta) > 0
order by trunc(snap.end_interval_time) desc, stat.instance_number
;

--summed per day/phv
select to_char(snap.end_interval_time,'yyyy/mm/dd') interval_date
,	     stat.plan_hash_value        phv
,      sum(stat.parse_calls_delta) prs
,      sum(stat.executions_delta)  exe
,      sum(stat.buffer_gets_delta) lio
,      sum(stat.disk_reads_delta) pio
--,      sum(stat.elapsed_time_total)/1000000 ela_tot1
--,      to_char(floor(sum(stat.elapsed_time_total)/1000000/3600),'fm9900')||':'||
--        to_char(floor(mod(sum(stat.elapsed_time_total)/1000000,3600)/60),'fm00')||':'||
--        to_char(floor(mod(mod(sum(stat.elapsed_time_total)/1000000,3600),60)),'fm00')||'.' ||
--        to_char(round(mod(sum(stat.elapsed_time_total),1000000)/1000000,6)*1000000,'fm000000') ela_tot
,      to_char(floor(sum(stat.elapsed_time_delta)/1000000/3600),'fm9900')||':'||
        to_char(floor(mod(sum(stat.elapsed_time_delta)/1000000,3600)/60),'fm00')||':'||
        to_char(floor(mod(mod(sum(stat.elapsed_time_delta)/1000000,3600),60)),'fm00')||'.' ||
        to_char(round(mod(sum(stat.elapsed_time_delta),1000000)/1000000,6)*1000000,'fm000000') ela_delta
,      sum(case when stat.executions_delta > 0 then round(stat.buffer_gets_delta/stat.executions_delta)    end) "lio/ex"
,      sum(case when stat.executions_delta > 0 then round(stat.disk_reads_delta/stat.executions_delta)     end) "pio/ex"
,      round(( sum(stat.disk_reads_delta) / nullif(sum(stat.buffer_gets_delta),0) ) * 100,2) "%pio"
,      sum(case when stat.executions_delta > 0 then round(stat.rows_processed_delta/stat.executions_delta) end) "rows/ex"
,      sum(case when stat.executions_delta > 0 then round(stat.elapsed_time_delta/stat.executions_delta)   end)/1000000 "ela/ex"
,      sum(case when stat.executions_delta > 0 then round(stat.cpu_time_delta/stat.executions_delta)   end)/1000000 "cpu/ex"
,      sum(case when stat.executions_delta > 0 then round(stat.iowait_delta/stat.executions_delta)   end)/1000000 "iow/ex"
,      sum(case when stat.executions_delta > 0 then round(stat.clwait_delta/stat.executions_delta)   end)/1000000 "clw/ex"
,      sum(case when stat.executions_delta > 0 then round((stat.elapsed_time_delta-stat.clwait_delta)/stat.executions_delta)   end)/1000000 "ela-clus/ex"
,      round((sum(stat.cpu_time_delta) / nullif(sum(stat.elapsed_time_delta),0) ) * 100,2) "%cpu"
,      round((sum(stat.iowait_delta) / nullif(sum(stat.elapsed_time_delta),0) ) * 100,2) "%iowait"
,      round((sum(stat.clwait_delta) / nullif(sum(stat.elapsed_time_delta),0) ) * 100,2) "%clwait"
,      round((sum(stat.ccwait_delta) / nullif(sum(stat.elapsed_time_delta),0) ) * 100,2) "%ccwait"
,      round((sum(stat.apwait_delta) / nullif(sum(stat.elapsed_time_delta),0) ) * 100,2) "%apwait"
,      to_char(floor(sum(stat.cpu_time_delta)/1000000/3600),'fm9900')||':'||
        to_char(floor(mod(sum(stat.cpu_time_delta)/1000000,3600)/60),'fm00')||':'||
        to_char(floor(mod(mod(sum(stat.cpu_time_delta)/1000000,3600),60)),'fm00')||'.' ||
        to_char(round(mod(sum(stat.cpu_time_delta),1000000)/1000000,6)*1000000,'fm000000') cpu_time_delta
,      to_char(floor(sum(stat.iowait_delta)/1000000/3600),'fm9900')||':'||
        to_char(floor(mod(sum(stat.iowait_delta)/1000000,3600)/60),'fm00')||':'||
        to_char(floor(mod(mod(sum(stat.iowait_delta)/1000000,3600),60)),'fm00')||'.' ||
        to_char(round(mod(sum(stat.iowait_delta),1000000)/1000000,6)*1000000,'fm000000') iowait_delta
,      to_char(floor(sum(stat.clwait_delta)/1000000/3600),'fm9900')||':'||
        to_char(floor(mod(sum(stat.clwait_delta)/1000000,3600)/60),'fm00')||':'||
        to_char(floor(mod(mod(sum(stat.clwait_delta)/1000000,3600),60)),'fm00')||'.' ||
        to_char(round(mod(sum(stat.clwait_delta),1000000)/1000000,6)*1000000,'fm000000') clusterwait_delta
,      to_char(floor(sum(stat.ccwait_delta)/1000000/3600),'fm9900')||':'||
        to_char(floor(mod(sum(stat.ccwait_delta)/1000000,3600)/60),'fm00')||':'||
        to_char(floor(mod(mod(sum(stat.ccwait_delta)/1000000,3600),60)),'fm00')||'.' ||
        to_char(round(mod(sum(stat.ccwait_delta),1000000)/1000000,6)*1000000,'fm000000') ccwait_delta
,      to_char(floor(sum(stat.apwait_delta)/1000000/3600),'fm9900')||':'||
        to_char(floor(mod(sum(stat.apwait_delta)/1000000,3600)/60),'fm00')||':'||
        to_char(floor(mod(mod(sum(stat.apwait_delta)/1000000,3600),60)),'fm00')||'.' ||
        to_char(round(mod(sum(stat.apwait_delta),1000000)/1000000,6)*1000000,'fm000000') apwait_delta
,      sum(stat.rows_processed_delta)     sum_rows_proc
,      sum(stat.fetches_delta)            sum_fetches
,      sum(case when stat.executions_delta > 0 then round(stat.fetches_delta/stat.executions_delta)   end) "ftch/ex"
,      min(stat.force_matching_signature) force_matching_signature
,      min(stat.sql_id) sql_id
from   dba_hist_sqlstat  stat
,      dba_hist_snapshot snap
where  stat.sql_id = '&sqlid'
--and    plan_hash_value != 3953216635
and    snap.snap_id         = stat.snap_id
and    snap.dbid            = stat.dbid
and    snap.instance_number = stat.instance_number
and    snap.dbid            = (select dbid from v$database)
group by to_char(snap.end_interval_time,'yyyy/mm/dd'), stat.plan_hash_value
--having sum(stat.parse_calls_delta) > 0
--having sum(stat.executions_delta) > 0
order by to_char(snap.end_interval_time,'yyyy/mm/dd') desc, stat.plan_hash_value
;


--summed per day
select trunc(snap.end_interval_time) eit
,	     stat.plan_hash_value        phv
,      sum(stat.parse_calls_delta) prs
,      sum(stat.executions_delta)  exe
,      sum(stat.buffer_gets_delta) lio
,      sum(stat.disk_reads_delta) pio
,      round(( sum(stat.disk_reads_delta) / nullif(sum(stat.buffer_gets_delta),0) ) * 100,2) "%pio"
--,      sum(elapsed_time_total) ela_tot
,      sum(case when stat.executions_delta > 0 then round(stat.buffer_gets_delta/stat.executions_delta)    end) "lio/ex"
,      sum(case when stat.executions_delta > 0 then round(stat.disk_reads_delta/stat.executions_delta)    end) "pio/ex"
,      sum(case when stat.executions_delta > 0 then round(stat.rows_processed_delta/stat.executions_delta) end) "rows/ex"
,      round(sum(case when stat.executions_delta > 0 then round(stat.elapsed_time_delta/stat.executions_delta)   end)/1000000,2) "ela/ex"
--,      sum(elapsed_time_delta) ela_delta
,      sum(iowait_delta) iowait_delta
,      sum(apwait_delta) apwait_delta
,      round((sum(iowait_delta) / nullif(sum(elapsed_time_delta),0) ) * 100,2) "%iowait"
,      round((sum(apwait_delta) / nullif(sum(elapsed_time_delta),0) ) * 100,2) "%apwait"
,      round((sum(clwait_delta) / nullif(sum(elapsed_time_delta),0) ) * 100,2) "%clwait"
--,      sum(clwait_delta) clwait_delta
--,      sum(apwait_delta) apwait_delta
--,      sum(ccwait_delta) ccwait_delta
,      sum(stat.rows_processed_delta)     sum_rows_proc
,      min(stat.force_matching_signature) force_matching_signature
,      min(stat.sql_id) sql_id
from   dba_hist_sqlstat  stat
,      dba_hist_snapshot snap
where  stat.sql_id = '&sqlid'
--and    plan_hash_value != 3953216635
and    snap.snap_id         = stat.snap_id
and    snap.dbid            = stat.dbid
and    snap.instance_number = stat.instance_number
group by trunc(snap.end_interval_time), stat.plan_hash_value
--having sum(stat.parse_calls_delta) > 0
having sum(stat.executions_delta) > 0
order by trunc(snap.end_interval_time) desc
;


select *
from   dba_hist_sqlstat  stat
,      dba_hist_snapshot snap
where  stat.sql_id = '&sqlid'
--and    plan_hash_value != 3953216635
and    snap.snap_id         = stat.snap_id
and    snap.dbid            = stat.dbid
and    snap.instance_number = stat.instance_number
order by snap.end_interval_time desc, stat.instance_number
;

select plan_hash_value, execs, elap, round(elap/execs/1000000,2) "ela/exe"
from (
	select plan_hash_value, sum(executions_total) execs, sum(elapsed_time_total) elap
	from dba_hist_sqlstat q,
	    (
	    select /*+ no_merge */ min(snap_id) min_snap, max(snap_id) max_snap
	    from dba_hist_snapshot ss
	    --where ss.begin_interval_time between trunc(sysdate - 0) and sysdate
	    where ss.begin_interval_time between (sysdate - 120/1440) and sysdate
	    ) s
	where q.snap_id between s.min_snap and s.max_snap
	  and q.sql_id in ( '&sqlid' )
	  --and q.plan_hash_value not in (1948013680)
	group by plan_hash_value
    )
order by 4 desc
;


select sql_id, child_number "Child"
,      buffer_gets "Lio"
,      first_load_time
,      parse_calls "Parse"
,      executions  "Exec"
,      round(buffer_gets/greatest(executions,1))    "lio/ex"
,      disk_reads "Pio"
,      case when command_type = 3
            then case when fetches > 0    then round(rows_processed/fetches) end
            else case when executions > 0 then round(rows_processed/executions) end
       end "rw/ex"
,      sql_text
,      hash_value
,      rows_processed "Rows"
,      elapsed_time   "Elapsed"
,      case when elapsed_time = 0 then 0 else trunc(rows_processed/(elapsed_time/1000000)) end "rows/sec"
,      to_char(floor((elapsed_time/1000000)/3600),'fm9900')||':'||
        to_char(floor(mod((elapsed_time/1000000),3600)/60),'fm00')||':'||
        to_char(floor(mod(mod((elapsed_time/1000000),3600),60)),'fm00') ||'.'||
        to_char(round(mod(elapsed_time,1000000)/1000000,3)*1000,'fm000')  "Elapsed hh:mi:ss"
,      to_char(floor(((elapsed_time/case when executions > 0 then executions else 1 end)/1000000)/3600),'fm9900')||':'||
        to_char(floor(mod(((elapsed_time/case when executions > 0 then executions else 1 end)/1000000),3600)/60),'fm00')||':'||
        to_char(floor(mod(mod(((elapsed_time/case when executions > 0 then executions else 1 end)/1000000),3600),60)),'fm00') ||'.'||
        to_char(round(mod((elapsed_time/case when executions > 0 then executions else 1 end),1000000)/1000000,3)*1000,'fm000')  "Elapsed/exec"
,      optimizer_mode
,      plan_hash_value
,     (select username from all_users where user_id = parsing_schema_id) parsing_schema
,     users_executing
from gv$sql
where sql_id = '&sqlid'
order by first_load_time desc, child_number;


select sp.sql_id, sp.operation, sp.options, sp.object_owner, sp.object_name, sp.object_type, sp.access_predicates, sp.filter_predicates
,    q.sql_text
,    q.disk_reads  pio
,    q.buffer_gets lio
,    q.parse_calls prs
,    q.executions  exe
,    round(q.buffer_gets/greatest(q.executions,1))    "lio/ex"
,    case when q.command_type = 3
          then case when q.fetches > 0    then round(q.rows_processed/q.fetches) end
          else case when q.executions > 0 then round(q.rows_processed/q.executions) end
     end "array"
,    q.rows_processed
from v$sql_plan sp
,    v$sql      q
where sp.object_name = upper('Fnd_Concurrent_Requests')
and   sp.sql_id      = q.sql_id
--and   options     = 'FULL'
;

select * from table(dbms_xplan.display_cursor('&sqlid',0,'TYPICAL'));
select * from table(dbms_xplan.display_cursor('&sqlid',0,'ALLSTATS LAST +PEEKED_BINDS'));
select * from table(dbms_xplan.display_cursor('&sqlid',0,'ALL'));
select * from table(dbms_xplan.display_cursor('&sqlid',0,'TYPICAL +PEEKED_BINDS')) ;
select * from table(dbms_xplan.display_cursor('&sqlid',0,'TYPICAL +PARTITION'));
select * from table(dbms_xplan.display_awr('&sqlid',null,null,'ALL'));
select * from table(dbms_xplan.display_awr('&sqlid',null,null,'TYPICAL ADVANCED'));

select stat.*
,      dhst.sql_text
from   (
		select stat.sql_id
		,      stat.plan_hash_value
		,      sum(stat.executions_delta)     execs
		,      sum(stat.buffer_gets_delta)    lio
		,      sum(stat.rows_processed_delta) rows_proc
		,      sum(stat.elapsed_time_delta)   ela
		,      round(sum(case when stat.executions_delta > 0 then round(stat.elapsed_time_delta/stat.executions_delta)   end)/1000000,2) "ela/ex"
		,	   max(stat.parsing_schema_name)  schema_name
		--,	   max(stat.parsing_user_id)      user_id
		from dba_hist_sqlstat stat
		where stat.module = 'MSQRY32.EXE'
		group by stat.sql_id, stat.plan_hash_value
		) stat
,     dba_hist_sqltext  dhst
where stat.sql_id = dhst.sql_id
order by 7 desc --stat.sql_id, stat.plan_hash_value
;

select dhsp.*
,      dhst.sql_text
from   dba_hist_sql_plan dhsp
,      dba_hist_sqltext  dhst
where  dhst.sql_text like upper('WITH TMP1 AS%')
and    dhst.sql_id = dhsp.sql_id
and    dhst.dbid   = dhsp.dbid
order by dhsp.sql_id, dhsp.plan_hash_value,dhsp.id
;

select dhsp.*
,      dhst.sql_text
from   dba_hist_sql_plan dhsp
,      dba_hist_sqltext  dhst
where  1=1
and    dhsp.operation    = 'INDEX'
--and    dhsp.options      = 'FULL'
--and    dhsp.object_owner = 'FIN_BASE'
and    dhsp.object_name  like 'MESSAGE_IX%'
and    dhst.sql_id = dhsp.sql_id
and    dhst.dbid   = dhsp.dbid
order by dhsp.sql_id, dhsp.plan_hash_value,dhsp.id
;

desc dba_hist_sqltext
select /*+ parallel(dhst, 8) */ sql_id, dhst.sql_text
from   dba_hist_sqltext  dhst
where  upper(dhst.sql_text) like upper('select to_timestamp(to_char(decode(umc.time_variant,''Y'', tv.begin_date%')
--and    dhst.sql_text not like ('%dbms_stats%')
;

select sql_id, dhst.sql_text
from   dba_hist_sqltext  dhst
where  dhst.sql_id = '&sqlid'
;


with sqll as (select /*+ materialize */ sql_id, to_char(substr(dhst.sql_text,1,4000)) sql_text
              from   dba_hist_sqltext  dhst
              where  dhst.sql_text like upper('select%tbl_ap_subledger%')
             )
select max_bit last_execute
,      sql_id
,      parsing_schema_name
,      (select sqll.sql_text from sqll where sqll.sql_id = msql.sql_id) sqltext
from (select max(snap.begin_interval_time) max_bit
     ,       max(stat.parsing_schema_name) parsing_schema_name
     ,       stat.sql_id
	 from   dba_hist_sqlstat  stat
	 ,      dba_hist_snapshot snap
	 ,      sqll
	 where  stat.sql_id   = sqll.sql_id
	 and    snap.snap_id  = stat.snap_id
	 and    snap.dbid     = stat.dbid
	 group by stat.sql_id
	) msql
order by max_bit desc
;

select snap.begin_interval_time, dhst.sql_id, dhst.sql_text, stat.*
from   dba_hist_sqltext  dhst
,      dba_hist_sqlstat  stat
,      dba_hist_snapshot snap
where  dhst.sql_text like upper('Update trd_term_shipment%')
and    dhst.sql_id = stat.sql_id
and    dhst.dbid   = stat.dbid
and    snap.snap_id = stat.snap_id
and    snap.dbid    = stat.dbid
order by snap.begin_interval_time desc
;

select snap.snap_id
,      snap.begin_interval_time
,      stat.executions_delta
,      dhst.sql_id
,      dhst.sql_text
,      stat.*
,      case when executions_delta > 0 then round(buffer_gets_delta/executions_delta)    end "lio/ex"
,      case when executions_delta > 0 then round(rows_processed_delta/executions_delta) end "rows/ex"
from   dba_hist_sqltext  dhst
,      dba_hist_sqlstat  stat
,      dba_hist_snapshot snap
where  dhst.sql_id = '&sqlid'
--and    plan_hash_value != 3953216635
and    dhst.sql_id = stat.sql_id
and    dhst.dbid   = stat.dbid
and    snap.snap_id = stat.snap_id
and    snap.dbid    = stat.dbid
order by snap.begin_interval_time desc
;

select snap.snap_id
,      snap.begin_interval_time
,      sum(stat.executions_delta) exe
,      sum(buffer_gets_delta) lio
,      sum(case when stat.executions_delta > 0 then round(stat.buffer_gets_delta/stat.executions_delta)    end) "lio/ex"
,      sum(case when stat.executions_delta > 0 then round(stat.rows_processed_delta/stat.executions_delta) end) "rows/ex"
from   dba_hist_sqlstat  stat
,      dba_hist_snapshot snap
where  stat.sql_id = '&sqlid'
--and    plan_hash_value != 3953216635
and    snap.snap_id = stat.snap_id
and    snap.dbid    = stat.dbid
group by snap.snap_id, snap.begin_interval_time
order by snap.begin_interval_time desc
;

select snap.snap_id
,      snap.end_interval_time
,	   max(stat.plan_hash_value) phv
,      sum(stat.executions_delta) exe
,      sum(buffer_gets_delta) lio
,      sum(disk_reads_delta) pio
--,      sum(elapsed_time_total) ela_tot
,      sum(elapsed_time_delta) ela_delta
,      sum(iowait_delta) iowait_delta
,      round((sum(iowait_delta) / sum(elapsed_time_delta) ) * 100,2) "%iowait"
--,      sum(clwait_delta) clwait_delta
--,      sum(apwait_delta) apwait_delta
--,      sum(ccwait_delta) ccwait_delta
,      sum(case when stat.executions_delta > 0 then round(stat.buffer_gets_delta/stat.executions_delta)    end) "lio/ex"
,      sum(case when stat.executions_delta > 0 then round(stat.rows_processed_delta/stat.executions_delta) end) "rows/ex"
from   dba_hist_sqlstat  stat
,      dba_hist_snapshot snap
where  stat.sql_id = '&sqlid'
--and    plan_hash_value != 3953216635
and    snap.snap_id = stat.snap_id
and    snap.dbid    = stat.dbid
and    to_number(to_char(snap.end_interval_time,'hh24')) = 3
group by snap.snap_id, snap.end_interval_time
order by snap.end_interval_time desc
;

select * from dba_hist_sql_plan dhsp
where  dhsp.sql_id = '&sqlid'
order by sql_id, plan_hash_value, id
;

select * from v$sqlarea
where parsing_user_id = 5 ;

select * from histograms;
select * from v$sql where hash_value = '3564974892'; --and address = 'C0000000483F9E60';
select * from v$sql_plan_statistics s where hash_value = '3564974892' order by child_number, operation_id;
select * from v$sql_plan_statistics s where address = '' and operation_id =;
select * from v$sql_plan_statistics_all s where hash_value = '921899235' order by child_number, id;
select * from v$sql_plan where hash_value = '3564974892';
select * from v$sql where (hash_value , address ) in
(select distinct hash_value, address from v$sql_plan where address in (select address from v$sql_plan where id = 0 and cost is not null)
                         and   address in (select address from v$sql_plan where object_owner = 'CONFIRMS')
);

select * from gv$sql where sql_id = '&sqlid';
select * from gv$sqltext where sql_id = '&sqlid' and inst_id = 1 order by address, piece;
select * from gv$sqltext_with_newlines where sql_id = '&sqlid' and inst_id = 1 order by address, piece;
select * from v$sql_bind_capture where sql_id = '&sqlid' order by child_number,child_address,position;
select child_number, name,value_string, datatype_string from v$sql_bind_capture where sql_id = '&sqlid' order by child_number,child_address,position;

--alter system set statistics_level=all;
--alter system set statistics_level=typical;

alter session set statistics_level=all;

select * from v$sql_optimizer_env where sql_id = '&sqlid' order by name, child_number;
select * from v$sql_shared_memory where sql_id = '&sqlid';
select * from v$sql_shared_cursor where sql_id = '&sqlid' order by child_number desc;
select * from dba_tab_columns where owner = 'OMH' and table_name = 'OMH_PROPERTY' order by column_name;

/*
og	Optimizer goal: 1=All_Rows, 2=First_Rows, 3=Rule, 4=Choose
*/

select * from gv$sql where sql_id = '&sqlid';




select sql_id, child_number, inst_id, buffer_gets, first_load_time, parse_calls, executions
,      round(buffer_gets/greatest(executions,1))    "lio/ex"
,      case when command_type = 3
            then case when fetches > 0    then round(rows_processed/fetches) end
            else case when executions > 0 then round(rows_processed/executions) end
       end "rw/ex"
,      sql_text
,      hash_value
,      rows_processed
,      disk_reads
,      elapsed_time
,      to_char(floor((elapsed_time/1000000)/3600),'fm9900')||':'||
        to_char(floor(mod((elapsed_time/1000000),3600)/60),'fm00')||':'||
        to_char(floor(mod(mod((elapsed_time/1000000),3600),60)),'fm00') ||'.'||
        to_char(round(mod(elapsed_time,1000000)/1000000,3)*1000,'fm000')  "Elapsed hh:mi:ss"
,      to_char(floor(((elapsed_time/case when executions > 0 then executions else 1 end)/1000000)/3600),'fm9900')||':'||
        to_char(floor(mod(((elapsed_time/case when executions > 0 then executions else 1 end)/1000000),3600)/60),'fm00')||':'||
        to_char(floor(mod(mod(((elapsed_time/case when executions > 0 then executions else 1 end)/1000000),3600),60)),'fm00') ||'.'||
        to_char(round(mod((elapsed_time/case when executions > 0 then executions else 1 end),1000000)/1000000,3)*1000,'fm000')  "Elapsed/ex hh:mi:ss"
,      to_char(floor((concurrency_wait_time/1000000)/3600),'fm9900')||':'||
        to_char(floor(mod((concurrency_wait_time/1000000),3600)/60),'fm00')||':'||
        to_char(floor(mod(mod((concurrency_wait_time/1000000),3600),60)),'fm00') ||'.'||
        to_char(round(mod(concurrency_wait_time,1000000)/1000000,3)*1000,'fm000')  "concurrency_wait_time"
,     (select username from all_users where user_id = parsing_schema_id) parsing_schema
,      optimizer_mode
,      invalidations
from gv$sql
--where plan_hash_value = 2444883895
where parsing_schema_id = (select user_id from all_users where username = 'ORABPEL')
order by parse_calls desc, child_number;

select sql_id
,      child_address
,      max(decode( name, ':1', datatype_string, null )) c1
,      max(decode( name, ':2', datatype_string, null )) c2
,      max(decode( name, ':3', datatype_string, null )) c3
,      max(decode( name, ':4', datatype_string, null )) c4
,      max(decode( name, ':5', datatype_string, null )) c5
,      max(decode( name, ':6', datatype_string, null )) c6
,      max(decode( name, ':7', datatype_string, null )) c7
,      max(decode( name, ':8', datatype_string, null )) c8
,      max(decode( name, ':9', datatype_string, null )) c9
,      max(decode( name, ':10', datatype_string, null )) c10
,      max(decode( name, ':11', datatype_string, null )) c11
,      max(decode( name, ':12', datatype_string, null )) c12
,      max(decode( name, ':13', datatype_string, null )) c13
,      max(decode( name, ':14', datatype_string, null )) c14
,      max(decode( name, ':15', datatype_string, null )) c15
,      max(decode( name, ':16', datatype_string, null )) c16
,      max(decode( name, ':17', datatype_string, null )) c17
,      max(decode( name, ':18', datatype_string, null )) c18
,      max(decode( name, ':19', datatype_string, null )) c19
,      max(decode( name, ':20', datatype_string, null )) c20
,      max(decode( name, ':21', datatype_string, null )) c21
,      max(decode( name, ':22', datatype_string, null )) c22
,      max(decode( name, ':23', datatype_string, null )) c23
,      max(decode( name, ':24', datatype_string, null )) c24
,      max(decode( name, ':25', datatype_string, null )) c25
,      max(decode( name, ':26', datatype_string, null )) c26
,      max(decode( name, ':27', datatype_string, null )) c27
,      max(decode( name, ':28', datatype_string, null )) c28
,      max(decode( name, ':29', datatype_string, null )) c29
,      max(decode( name, ':30', datatype_string, null )) c30
,      max(decode( name, ':31', datatype_string, null )) c31
,      max(decode( name, ':32', datatype_string, null )) c32
,      max(decode( name, ':33', datatype_string, null )) c33
,      max(decode( name, ':34', datatype_string, null )) c34
,      max(decode( name, ':35', datatype_string, null )) c35
,      max(decode( name, ':36', datatype_string, null )) c36
,      max(decode( name, ':37', datatype_string, null )) c37
,      max(decode( name, ':38', datatype_string, null )) c38
,      max(decode( name, ':39', datatype_string, null )) c39
,      max(decode( name, ':40', datatype_string, null )) c40
,      max(decode( name, ':41', datatype_string, null )) c41
,      max(decode( name, ':42', datatype_string, null )) c42
,      max(decode( name, ':43', datatype_string, null )) c43
,      max(decode( name, ':44', datatype_string, null )) c44
,      max(decode( name, ':45', datatype_string, null )) c45
,      max(decode( name, ':46', datatype_string, null )) c46
,      max(decode( name, ':47', datatype_string, null )) c47
,      max(decode( name, ':48', datatype_string, null )) c48
,      max(decode( name, ':49', datatype_string, null )) c49
,      max(decode( name, ':50', datatype_string, null )) c50
,      max(decode( name, ':51', datatype_string, null )) c51
,      max(decode( name, ':52', datatype_string, null )) c52
,      max(decode( name, ':53', datatype_string, null )) c53
,      max(decode( name, ':54', datatype_string, null )) c54
,      max(decode( name, ':55', datatype_string, null )) c55
,      max(decode( name, ':56', datatype_string, null )) c56
,      max(decode( name, ':57', datatype_string, null )) c57
,      max(decode( name, ':58', datatype_string, null )) c58
,      max(decode( name, ':59', datatype_string, null )) c59
from v$sql_bind_capture
where sql_id = '&sqlid'
group by sql_id, child_address
order by c1,c2,c3,c4,c5,c6,c7,c8,c9
       ,c10,c11,c12,c13,c14,c15,c16,c17,c18,c19
       ,c20,c21,c22,c23,c24,c25,c26,c27,c28,c29
       ,c30,c31,c32,c33,c34,c35,c36,c37,c38,c39
       ,c40,c41,c42,c43,c44,c45,c46,c47,c48,c49
       ,c50,c51,c52,c53,c54,c55,c56,c57,c58,c59
       ,child_address
/

select sql_id
,      child_address
,      max(decode( name, ':SYS_B_0', datatype_string, null )) c1
,      max(decode( name, ':SYS_B_1', datatype_string, null )) c2
,      max(decode( name, ':SYS_B_2', datatype_string, null )) c3
,      max(decode( name, ':SYS_B_3', datatype_string, null )) c4
,      max(decode( name, ':SYS_B_4', datatype_string, null )) c5
,      max(decode( name, ':SYS_B_5', datatype_string, null )) c6
,      max(decode( name, ':SYS_B_6', datatype_string, null )) c7
,      max(decode( name, ':SYS_B_7', datatype_string, null )) c8
,      max(decode( name, ':SYS_B_8', datatype_string, null )) c9
,      max(decode( name, ':SYS_B_9', datatype_string, null )) c10
,      max(decode( name, ':SYS_B_10', datatype_string, null )) c11
from v$sql_bind_capture
where sql_id = '&sqlid'
group by sql_id, child_address
order by c1,c2,c3,c4,c5,c6,c7,c8,c9,c10
       ,child_address
/

select child_address, name,value_string, datatype_string from v$sql_bind_capture where sql_id = '&sqlid' order by child_number,position;
select child_address, name,value_string, datatype_string from v$sql_bind_capture where sql_id = '&sqlid' and name = ':2' order by child_number,position;
select child_address, name,value_string, datatype_string from v$sql_bind_capture where sql_id = '&sqlid' and child_address = '0000000492906130' order by child_number,position;

select * from
	(select sql_id
	 ,      version_count
	 ,      executions
	 ,      sql_text
	 ,      hash_value
	 ,      address
	 from v$sqlarea
	 where version_count > 20
	 order by version_count desc
	)
where rownum <= 100
;
select * from v$sql_shared_cursor where sql_id = '&sqlid' order by child_number;
select * from gv$sqltext where sql_id = '&sqlid' and inst_id = 1 order by address, piece;
select sql_id, child_number, sql_fulltext from gv$sql where sql_id = '&sqlid';
select * from gv$sql_optimizer_env where sql_id = '&sqlid' and child_number= &child_number order by name, child_number;

select child_number, name,value_string, datatype_string from v$sql_bind_capture where sql_id = '&sqlid' order by child_number,child_address,position;

select sql_id, child_number, child_address, 'var  ' || substr(name,2) || ' '    || datatype_string || ';' var
,      'exec ' || name || ' := '
               || nvl2(value_string, case substr(datatype_string,1,8) when 'VARCHAR2' then '''' when 'DATE' then '''' else null end, null)
               || nvl(value_string,'null')
               || nvl2(value_string, case substr(datatype_string,1,8) when 'VARCHAR2' then '''' when 'DATE' then '''' else null end, null)
               || ';' val
from gv$sql_bind_capture
where sql_id = '&sqlid'
order by child_number,child_address,position;

select *
from dba_hist_sqlbind
where sql_id = '&sqlid'
order by snap_id desc, position
;

select snap_id
,      'var  ' || substr(name,2) || ' '    || datatype_string || ';'
,      'exec ' || name || ' := '
               || nvl2(value_string, case substr(datatype_string,1,8) when 'VARCHAR2' then '''' when 'DATE' then '''' else null end, null)
               || nvl(value_string,'null')
               || nvl2(value_string, case substr(datatype_string,1,8) when 'VARCHAR2' then '''' when 'DATE' then '''' else null end, null)
               || ';'
from dba_hist_sqlbind
where sql_id = '&sqlid'
order by snap_id desc, instance_number, position;

desc dba_hist_sqlbind;

select * from v$sql_shared_cursor where use_feedback_stats = 'Y' order by sql_id, child_number;
