with slo as (select sid, sql_id, serial#, target, opname, time_remaining, sql_exec_id, inst_id from gv$session_longops sl where time_remaining > 0)
select /* rule */
     to_char(floor(s.last_call_et/3600/24),'fm9999')||'d:'||
      to_char(floor(mod(s.last_call_et,86400)/3600),'fm00')||':'||
       to_char(floor(mod(s.last_call_et,3600)/60),'fm00')||':'||
       to_char(mod(mod(s.last_call_et,3600),60),'fm00') "Idle"
,     to_char(floor(s.seconds_in_wait/3600/24),'fm9999')||'d:'||
      to_char(floor(mod(s.seconds_in_wait,86400)/3600),'fm00')||':'||
       to_char(floor(mod(s.seconds_in_wait,3600)/60),'fm00')||':'||
       to_char(mod(mod(s.seconds_in_wait,3600),60),'fm00') "Wait"
,    rpad(substr(s.username,1,13),13) "User"
,    substr(case when substr(s.program,-1) = ')'
            then
               case when substr(s.program,-6,1) = '('
                    then substr(s.program,-6) ||' '||s.module
                    else substr(s.program,1, instr(s.program,'(',-1)-1) --substr(s.program,1,7)
               end
            else nvl(substr(s.program,instr(s.program,'/',-1)+1), substr(s.module,instr(s.module,'/',-1)+1,15)  )
            end
           ,1,16) "program/mod"
,    case s.state when 'WAITING' then substr(s.event,1,31)
                else case s.status when 'INACTIVE' then substr(s.event,1,31)
                                                   else 'on cpu/runqueue'
                end
     end event
--,    s.event event2
--,    case
--          when s.wait_time = 0 then s.state
--          when s.wait_time < 0 then case when s.command = 0 then 'WAITING' else 'On CPU ' end
--          when s.wait_time > 0 then case when s.status = 'INACTIVE' then 'WAITING' else 'On CPU ' end
--                                         --||to_char(s.seconds_in_wait-(s.wait_time/100),'fm90.00')
--     end  as state
,    case s.status
          when 'ACTIVE'
          then case s.state when 'WAITING'
                            then 'WAITING'
                            else 'CPU/RQ'
               end
          else 'WAITING'
     end state
--,    s.state stateR
--, s.wait_time, s.command--, s.seconds_in_wait
,    s.status
,    q.disk_reads  pio
,    q.buffer_gets lio
,    round(q.buffer_gets/nullif(q.executions,0))    "lio/ex"
,    q.parse_calls prs
,    q.executions  exe
--,    round(q.parse_calls/nullif(q.executions,0),1)  "prs/ex"
,    round(q.rows_processed/nullif(q.executions,0)) "rw/ex"
,    round(p.pga_alloc_mem/1024/1024) "pga (Mb)"
--,    s.p3
--,    decode(s.sql_trace,'ENABLED','Y','') tr
,    q.rows_processed "rows"
,    case q.command_type
          when 2 then case when q.executions > 0 then round(q.rows_processed/q.executions)  end -- insert
          when 3 then case when q.fetches    > 1 then round(q.rows_processed/(q.fetches-1)) end -- select
          when 6 then case when q.executions > 0 then round(q.rows_processed/q.executions)  end -- update
          when 7 then case when q.executions > 0 then round(q.rows_processed/q.executions)  end -- delete
          else null
     end "array"
--,    ss.value  commits
--,    to_char(ss.value / (nullif(sysdate - s.logon_time,0)*86400) ,'fm9990') "tps"
,    to_char(q.rows_processed / (nullif(sysdate - s.sql_exec_start,0)*86400) ,'fm999999990') "rps"
--,    s.sid||nvl2(blocking_session,'/'||blocking_session,null)||nvl2(final_blocking_session,'/'||final_blocking_session,null) "Sid(/bl)"
,    s.sid||'/'||s.inst_id||nvl2(s.blocking_session,'('||s.blocking_session||'/'||s.blocking_instance||')',null) "Sid (bl)"
--,    rsi.current_active_time/1000 as cur_act_sec
,    rsi.consumed_cpu_time/1000   as cons_cpu_sec
--,    rsi.state
,    case when sl.opname is not null then sl.opname||': '||sl.time_remaining else ' ' end as opname
,    q.sql_text
,    nvl2(sql_exec_start,
      to_char(trunc(sysdate-sql_exec_start),'fm9990') ||'d '||
       to_char(trunc(mod((sysdate-sql_exec_start)*24, 24 ) ),'fm00') ||':'||
       to_char(trunc(mod((sysdate-sql_exec_start)*24*60, 60 ) ),'fm00')  ||':'||
       to_char(trunc(mod((sysdate-sql_exec_start)*24*60*60, 60 ) ),'fm00')
      , null) "Running"
,      to_char(floor(((q.elapsed_time/case when q.executions > 0 then q.executions else 1 end)/1000000)/3600),'fm9900')||':'||
        to_char(floor(mod(((q.elapsed_time/case when q.executions > 0 then q.executions else 1 end)/1000000),3600)/60),'fm00')||':'||
        to_char(floor(mod(mod(((q.elapsed_time/case when q.executions > 0 then q.executions else 1 end)/1000000),3600),60)),'fm00') ||'.'||
        to_char(round(mod((q.elapsed_time/case when q.executions > 0 then q.executions else 1 end),1000000)/1000000,6)*1000000,'fm000000')  "Elapsed/exec"
,    q.hash_value
,    s.sql_id
,    s.sql_child_number childno
,    q.sql_profile
,    q.sql_plan_baseline
,    sl.target
,    s.p1
,    case p1text when 'name|mode' then chr(bitand(s.p1,-16777216)/16777215)  || chr(bitand(s.p1, 16711680)/65535) end bl_Type
,    mod(s.p1,16) bl_lmode
--,    decode(aa.name,'UNKNOWN','',lower(aa.name)) cmd
,    s.*
,    'alter system kill session '''||s.sid||','||s.serial#||',@'||s.inst_id||''' immediate;'  as kill_session
,    'sys.dbms_system.set_ev('||s.sid||','||s.serial#||',10046,12,'''');' as trace_session
,    'exec dbms_monitor.session_trace_enable('||s.sid||','||s.serial#||',waits=>true, binds=>false);'  traceon
,    'exec dbms_monitor.session_trace_disable('||s.sid||','||s.serial#||');'                           traceoff
,    p.pid
,    p.spid "OS pid"
,    to_char((p.pga_used_mem /1024)/1024, '999G999G990D00') pga_used_mem
,    to_char((p.pga_alloc_mem /1024)/1024, '999G999G990D00') pga_alloc_mem
,    to_char((p.pga_max_mem /1024)/1024, '999G999G990D00') pga_max_mem
,    case when s.p2text = 'object #' then (select object_name from dba_objects where object_id = s.p2) end as object_name
,    case when s.row_wait_obj# > 0   then (select object_name from dba_objects where object_id = s.row_wait_obj#) end as object_name2
,    case when q.elapsed_time = 0 then 0 else trunc(q.rows_processed/(q.elapsed_time/1000000)) end "rows/sec"
from  gv$process         p
,     gv$session         s
,     gv$sql             q
,     gv$rsrc_session_info rsi
,     slo               sl
--,     audit_actions     aa
--,     v$sesstat         ss
where q.sql_id(+)       = decode(s.sql_id,null,s.prev_sql_id,s.sql_id)
and   q.child_number(+) = decode(s.sql_id,null,s.prev_child_number,s.sql_child_number)
and   q.inst_id(+)      = s.inst_id
and   s.paddr           = p.addr(+)
and   s.inst_id         = p.inst_id(+)
and   rsi.sid     (+)   = s.sid
and   rsi.inst_id (+)   = s.inst_id
and   sl.sid    (+)     = s.sid
and   sl.serial#(+)     = s.serial#
--and   sl.sql_id(+)      = decode(s.sql_id,null,s.prev_sql_id,s.sql_id)
and   sl.sql_exec_id(+) = s.sql_exec_id
and   sl.inst_id(+)     = s.inst_id
--and   not (s.username = 'SYSTEM' and (substr(s.program,-6) = '(PZ99)' or substr(s.program,-6) = '(PPA7)'))
--and   q.is_obsolete  = 'N'
--and   s.command         = aa.action (+)
--and   ss.sid            = s.sid
--and   ss.statistic#     = 4 -- (select sn.statistic# from v$statname sn where sn.name = 'user commits')
--and osuser         = 'PMG9532'
--and s.username         in ('IVRBATP','SYSTEM','ADWILL2','MRM9523','RPT_MONITOR')
--and s.terminal         = 'IMADCMDMRMP4'
--and s.sid         in (874)
--and sw.event  not in ('SQL*Net message from client','rdbms ipc message') and s.username is not null
--and s.status       = 'ACTIVE'
--and s.username    = 'CISUSER'
--and s.inst_id = 2
--and s.aschemaname  != 'SYS'
--and client_info like '%PSQRYSRV%'
--and client_identifier like 'FMISRUN'
--and s.program     in ('Golden6.exe')
--and s.module       = 'PSAE.D_GL_JO1_RPT.21889030'
--and service_name   = 'SYS$BACKGROUND'
--and q.sql_text like 'UPDATE ORADBSS.OSDDSAUD%'
--and   q.parse_calls >= q.executions
--and s.sql_id = '88cyk4475htjz'
--and p.spid in (36438510,29294874,20185346,36307306,18285062,19792286,11207086,52101380,31719854,43516236)
order by decode(s.blocking_session,null, -1, s.last_call_et) desc
, case s.status when 'ACTIVE'
                then case s.state when 'WAITING'
                                  then 999999999
                                  else s.seconds_in_wait
                                  end
--                when 'KILLED'
--                then s.seconds_in_wait
                else 999999999
                end
,decode(s.username,null,99,0)
--,case substr(s.program,-6) when '(PZ98)'    then 1  else 0 end
,case substr(s.module,1,9) when 'Data Pump' then 0  else decode(s.type,'BACKGROUND',99,0) end
--, case s.username when 'SYS' then case s.state when 'WAITING' then 98 else 0 end else 99 end
, 6, s.status, decode(s.status,'ACTIVE',s.last_call_et,s.last_call_et*-1) desc, s.inst_id, s.username, s.sid
;
