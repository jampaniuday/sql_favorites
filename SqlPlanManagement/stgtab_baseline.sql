--drop table system.stgtab_baseline;
begin
   dbms_spm.create_stgtab_baseline(table_name      => 'stgtab_baseline'
                                  ,table_owner     => 'SYSTEM'
                                  ,tablespace_name => 'USERS'
                                  --performance testing
                                  );
end;
/

select count(*) from stgtab_baseline;

select parsing_schema_name, count(*)
from stgtab_baseline spb
group by rollup(parsing_schema_name)
order by 2 desc
;

truncate table stgtab_baseline;

-- export all baselines
declare
   t_rc pls_integer;
begin
   t_rc := dbms_spm.pack_stgtab_baseline
             (table_name   => 'stgtab_baseline'
             ,table_owner  => 'SYSTEM'
             --performance testing
             );
   dbms_output.put_line(to_char(t_rc));
end;
/

-- export some baselines
declare
   t_rc pls_integer;
begin
   t_rc := dbms_spm.pack_stgtab_baseline  --CRQ000020194607
             (table_name   => 'stgtab_baseline'
             ,table_owner  => 'SYSTEM'
             ,sql_handle   => 'SQL_e98c7e9c257ff91e'
--             ,plan_name    => NULL
--             ,sql_text     => NULL
--             ,creator      => NULL
--             ,origin       => NULL
--             ,enabled      => NULL
             ,accepted     => 'YES'
--             ,fixed        => NULL
--             ,module       => 'Golden6.exe'
--             ,action       => NULL
             );
   dbms_output.put_line(to_char(t_rc));
end;
/

select * from stgtab_baseline;

declare
   t_rc pls_integer;
begin
   t_rc := dbms_spm.unpack_stgtab_baseline
             (table_name   => 'stgtab_baseline'
             ,table_owner  => 'SYSTEM'
             ,sql_handle   => 'SQL_e98c7e9c257ff91e'
             );
   dbms_output.put_line(to_char(t_rc));
end;
/

desc stgtab_baseline
