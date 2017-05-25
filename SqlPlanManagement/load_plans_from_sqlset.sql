select * from dba_hist_snapshot
where dbid = (select dbid from v$database)
order by snap_id desc
;
select dbid from v$database;

select * from   table (dbms_sqltune.select_workload_repository
                      (begin_snap        => 230593
                      ,end_snap          => 230594
                      --,basic_filter      => 'module = ''PKG_LEDGER_AVB_SUMMARY'''  --
                      ,basic_filter      => 'sql_id = ''bjvr26s4g5ktv'''
                      ,object_filter     => NULL
                      ,ranking_measure1  => NULL --'buffer_gets'
                      ,ranking_measure2  => NULL
                      ,ranking_measure3  => NULL
                      ,result_percentage => NULL --0.8
                      ,result_limit      => NULL
                      ,attribute_list    => NULL ---'ALL'
                    ));

--10g
select * from   table (sys.dbms_sqltune.select_workload_repository(20,21,null,null,'buffer_gets',null,null,null,10,'TYPICAL') );

select * from dba_sqlset order by created desc;
select * from DBA_HIST_SNAPSHOT order by snap_id desc;

-- Create a SQL Tuning Set and load it from AWR
declare
  l_cursor  dbms_sqltune.sqlset_cursor;
begin
  dbms_sqltune.create_sqlset (
    sqlset_name  => '&sqlset_name',
    description  => 'Using attribute_list ALL ')
    ;
  open l_cursor for
    select value(p)
    from   table (dbms_sqltune.select_workload_repository
                      (begin_snap        => 230593
                      ,end_snap          => 230594
                      ,basic_filter      => 'sql_id = ''bjvr26s4g5ktv'''
                      ,object_filter     => NULL
                      ,ranking_measure1  => NULL
                      ,ranking_measure2  => NULL
                      ,ranking_measure3  => NULL
                      ,result_percentage => NULL
                      ,result_limit      => NULL
                      ,attribute_list    => 'TYPICAL'
                    )
                  ) p;

  dbms_sqltune.load_sqlset (
    sqlset_name     => '&sqlset_name',
    populate_cursor => l_cursor);
end;
/

select * from dba_sqlset order by created desc;

select * from dba_sqlset_statements
where sqlset_name = '&sqlset_name'
--and  sql_text like 'UPDATE%'
--and   parsing_schema_name = 'SYSTEM'
;
select * from table (dbms_xplan.display_sqlset( '&sqlset_name','&sql_id'));

declare
   t_rc pls_integer;
begin
   t_rc := dbms_spm.load_plans_from_sqlset
      (sqlset_name      => '&sqlset_name'
      ,sqlset_owner     => 'SYSTEM'
      ,basic_filter     => 'sql_id = ''bjvr26s4g5ktv''' --'parsing_schema_name = ''SYSTEM'''
      ,fixed            => 'NO'
      ,enabled          => 'YES'
      );
   dbms_output.put_line(to_char(t_rc));
end;
/

declare
   t_rc  pls_integer;
begin
   t_rc := dbms_spm.alter_sql_plan_baseline
         (sql_handle      => 'SQL_58507a35d5a52b90'
         ,plan_name       => 'SQL_PLAN_5hn3u6rauaawhacd2f02f'
         ,attribute_name  => 'enabled'
         ,attribute_value => 'YES'
         );
   dbms_output.put_line(t_rc);
end;
/

select * from dba_sql_plan_baselines spb where created > sysdate - 1/24;
select * from table(dbms_xplan.display_sql_plan_baseline(sql_handle => '&sql_handle', format => 'basic'));

alter system set statistics_level = 'ALL' scope=BOTH;

declare
   t_rc pls_integer;
begin
   for r_sql in (select sql_id, plan_hash_value
                 from dba_sqlset_statements
                 where sqlset_name = '&sqlset_name'
                 and   parsing_schema_name = '&parsing_schema_name'
                )
   loop
      if r_sql.plan_hash_value = 0
      then
         t_rc := dbms_spm.load_plans_from_cursor_cache(sql_id => r_sql.sql_id);
      else
         t_rc := dbms_spm.load_plans_from_cursor_cache(sql_id => r_sql.sql_id, plan_hash_value => r_sql.plan_hash_value);
      end if;
   end loop;
end;
/
