with sysauxkb as (select sum(ddf.bytes)/1024 Kbytes
                  from   dba_data_files  ddf
                  where  ddf.tablespace_name = 'SYSAUX'
                  group by ddf.tablespace_name
                 )
select so.occupant_name, so.occupant_desc, so.schema_name
, round(so.space_usage_kbytes/1024) "Space Used (MB)"
, round(so.space_usage_kbytes/kb.kbytes*100,2) "Used %"
from v$sysaux_occupants so
,    sysauxkb           kb
order by space_usage_kbytes desc
;

select * from dba_sql_management_config;

begin
   dbms_spm.configure ('space_budget_percent',20);
end;
/

begin
   dbms_spm.configure ('plan_retention_weeks',60);
end;
/
