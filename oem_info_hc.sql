declare
   /*
		Metric Extension			  Column														    Deployed
		ME$maximum_PGA_allocated_mb   'maximum PGA allocated (MB)'									    Y
		ME$pga_aggregate_target_mb	  'pga_aggregate_target (MB)' 									    Y
		ME$total_sga_allocated_mb	  'total SGA allocated (MB)'  									    Y
		ME$sga_target_advice		  'STA_Minimum_Size','STA_Current_Size','STA_Difference'			N
		ME$memory_target_advice		  'MTA_Minimum_Size','MTA_Current_Size','MTA_Difference'			N
   */
   -- Constants
   c_crlf     CONSTANT        varchar2(1):= chr(10);
   --
   i_host_cluster_name        varchar2(50) := lower('&host_or_cluster_name')||'%';
   i_days                     pls_integer  := &days;
   i_verbose                  boolean      := (&verbose = 1);

   t_target_type              varchar2(128);
   t_asm_storage_unalloc_gb   number := 0;
   t_asm_tot_dat_free         pls_integer := 0;
   t_asm_tot_fra_free         pls_integer := 0;
   t_avg_avg_instance_cpu     number := 0;
   t_avg_avg_active_sessions  number := 0;
   t_avg_pga_cache_hit        number := 0;
   t_avg_soft_parse_perc      number := 0;
   t_avg_tps                  number := 0;
   t_avg_mem_sort_perc        number := 0;
   t_category_prop_1          varchar2(128);
   t_category_prop_2          varchar2(128);
   t_clu_count_databases      pls_integer := 0;
   t_clu_min_online_memory    number := 9999999999;
   t_clu_def_oracle_alloc     number := 0;
   t_clu_max_oracle_alloc     pls_integer := 0;
   t_count_databases          pls_integer := 0;
   t_cpu_count                number := 0;
   t_cpu_user_avg             number := 0;
   t_cpu_user_max             number := 0;
   t_cpu_util_avg             number := 0;
   t_cpu_util_max             number := 0;
   t_db_cpu_user_avg          number := 0;
   t_db_cpu_user_max          number := 0;
   t_def_oracle_alloc         pls_integer := 0;
   t_host_free_mem_perc       number := 0;
   t_host_processes           pls_integer := 0;
   t_linux_active_mem_kb      number := 0;
   t_linux_mem_util_perc      number := 0;
   t_num_asm                  pls_integer := 0;
   t_num_databases            pls_integer := 0;
   t_max_avg_active_sessions  number := 0;
   t_max_avg_instance_cpu     number := 0;
   t_max_host_memory          number := 0;
   t_max_oracle_alloc         pls_integer := 0;
   t_max_pga_alloc            number := 0;
   t_max_phys_cpu             number := 0;
   t_max_tps                  number := 0;
   t_max_used_space           number := 0;
   t_max_virt_cpu             number := 0;
   t_mem_free                 number := 0;
   t_mem_tot_difference       number := 0; -- sum of mta+sga
   t_mta_current_size         number := 0;
   t_mta_mimimum_size         number := 0;
   t_mta_difference           number := 0;
   t_online_cpu               pls_integer := 0;
   t_online_memory            pls_integer := 0;
   t_pages_paged_in_avg       number := 0;
   t_pages_paged_in_max       number := 0;
   t_pages_paged_out_avg      number := 0;
   t_pages_paged_out_max      number := 0;
   t_pga_agg_target           number := 0;
   t_run_q_len_15min_max      number := 0;
   t_run_q_len_15min_avg      number := 0;
   t_sga_alloc                number := 0;
   t_sta_current_size         number := 0;
   t_sta_mimimum_size         number := 0;
   t_sta_difference           number := 0;
   t_sum_avg_instance_cpu     number := 0;
   t_swap_util_avg            number := 0;
   t_swap_util_max            number := 0;
   t_tot_mem_usage            number := 0;
   t_total_io_sec_avg         number := 0;
   t_total_io_sec_max         number := 0;
   --
   type tp_num_table is table of number index by varchar2(60);

   t_dg_disk_count        tp_num_table;
   t_dg_free              tp_num_table;
   t_dg_usable            tp_num_table;
   t_dg_usable_free       tp_num_table;
   t_dg_used              tp_num_table;
   t_dg_size              tp_num_table;
   t_dg_used_sf           tp_num_table;
   t_dg_rd_resp_tim       tp_num_table;
   t_dg_wr_resp_tim       tp_num_table;
   t_dg_reads             tp_num_table;
   t_dg_writes            tp_num_table;
   t_dg_read_time         tp_num_table;
   t_dg_write_time        tp_num_table;

   t_ca_report            clob;

   procedure log_line(i_rpt_line in varchar2)
   is

   begin
     t_ca_report := t_ca_report || i_rpt_line || c_crlf;
   end;

   procedure print_host_info(i_host_name in varchar2)
   is
      t_first_drr  boolean := true;
      t_first_srr  boolean := true;
      t_drr_mem    number  := 0;
      t_drr_dat    number  := 0;
      t_drr_fra    number  := 0;
   begin
      log_line('Host Info '||i_host_name);
      if t_category_prop_1 = 'Linux'
      then
 	     log_line('OS/Version                       : '||t_category_prop_2);
      else
 	     log_line('OS/Version                       : '||t_category_prop_1||' '||t_category_prop_2);
      end if;
	    log_line('Online CPU/cpu_count             : '||t_online_cpu||' / '||t_cpu_count);
	    log_line('Max phys/virtual CPU             : '||t_max_phys_cpu||' / '||t_max_virt_cpu);
      log_line('Sum of processes                 : '||t_host_processes);
	    log_line('Sum of Avg DB CPU                : '||t_sum_avg_instance_cpu);
  	  log_line('CPU Utilization Host avg/max     : '||t_cpu_util_avg||' / '||t_cpu_util_max);
	    log_line('CPU Utilization Host User avg/max: '||t_cpu_user_avg||' / '||t_cpu_user_max);
	    log_line('Swap Util avg/max                : '||t_swap_util_avg||' / '||t_swap_util_max);
	    log_line('Run Queue Length (15 min)        : '||t_run_q_len_15min_avg||' / '||t_run_q_len_15min_max);
	    log_line('Pages paged in (sec) avg/max     : '||t_pages_paged_in_avg||' / '||t_pages_paged_in_max);
	    log_line('Pages paged out (sec) avg/max    : '||t_pages_paged_out_avg||' / '||t_pages_paged_out_max);
	    log_line('Total I/O (sec) avg/max          : '||t_total_io_sec_avg||' / '||t_total_io_sec_max);
	    if t_num_asm > 0
	    then
	       log_line('ASM Instances                    : '||t_num_asm );
	       log_line('ASM storage unallocated (Gb)     : '||t_asm_storage_unalloc_gb );
      end if;
	    log_line('Databases                        : '||greatest(t_num_databases,t_count_databases) );
	    log_line('Host memory (Mb/Gb)              : '||t_online_memory ||'/'|| round(t_online_memory/1024));
	    log_line('Total Oracle Defined (Mb/Gb)     : '||t_def_oracle_alloc ||'/'|| round(t_def_oracle_alloc/1024));

	    if t_online_memory > 0
	    then
		     t_mem_free := t_online_memory - t_def_oracle_alloc;
		     if t_mem_free > 0
    		 then
		        log_line('Host memory free (Mb/Gb/%)       : '||t_mem_free ||'/'|| round(t_mem_free/1024) ||'/'|| round((t_mem_free/t_online_memory)*100)||'%');
		     else
		        log_line('Overallocated (Mb/Gb/%)          : '||t_mem_free*-1 ||'/'|| round((t_mem_free*-1)/1024) ||'/'|| round((t_mem_free*-1/t_online_memory)*100)||'%');
         end if;

		     if t_clu_max_oracle_alloc > 0
		     then
	          log_line('Max Oracle Allocated (Mb/Gb)     : '||t_max_oracle_alloc ||'/'|| round(t_max_oracle_alloc/1024));
			      t_mem_free := t_online_memory - t_max_oracle_alloc;

            if t_mem_free > 0
			      then
			         log_line('Host memory free (@max alloc)    : '||t_mem_free ||'/'|| round(t_mem_free/1024) ||'/'|| round((t_mem_free/t_online_memory)*100)||'%');
            else
			         log_line('Overallocated (@max alloc)       : '||t_mem_free*-1 ||'/'|| round((t_mem_free*-1)/1024) ||'/'|| round((t_mem_free*-1/t_online_memory)*100)||'%');
			      end if;
	       end if;
	    else
	      log_line('Host memory free (%)             : '||t_host_free_mem_perc);
	    end if;

	    if t_mem_tot_difference > 0
	    then
         log_line('After Memory_Target/SGA_Target resize');
 	       log_line('   Memory saved                  : '||t_mem_tot_difference ||', '||round((t_mem_tot_difference/t_def_oracle_alloc)*100)||'%');
 	       log_line('   Total Oracle Defined (Mb/Gb)  : '||(t_def_oracle_alloc - t_mem_tot_difference) ||'/'|| round((t_def_oracle_alloc - t_mem_tot_difference)/1024) );
		     if t_online_memory > 0
		     then
		        t_mem_free := t_online_memory - t_def_oracle_alloc + t_mem_tot_difference;
		        if t_mem_free > 0
            then
		           log_line('   Host memory free              : '||round((t_mem_free/t_online_memory)*100)||'%');
    		    else
		           log_line('   Overallocated                 : '||round((t_mem_free*-1/t_online_memory)*100)||'%');
		        end if;

	-- not sure if this makes sense to keep
	--	         log_line('   Max Oracle Allocated (Mb)    : '||(t_max_oracle_alloc - t_mem_tot_difference) );
	--			 t_mem_free := t_online_memory - t_max_oracle_alloc + t_mem_tot_difference;
	--
	--			 if t_mem_free > 0
	--			 then
	--			    log_line('   Host memory free (@max alloc): '||round((t_mem_free/t_online_memory)*100)||'%');
	--			 else
	--			    log_line('   Overallocated (@max alloc)   : '||round((t_mem_free*-1/t_online_memory)*100)||'%');
	--			 end if;
		      end if;
	    end if;

      -- check DRRs for the host
	    for r_drr in (
	 	        select drr.req_id, drr.project, drr.drr_status, drr.comments
	 	        ,      nvl(drr.sga_size,0)     sga_size
	 	        ,      nvl(drr.pga_size_max,0) pga_size_max
	 	        ,      nvl(drr.data_space,0)   data_space
	 	        ,      nvl(drr.temp_space,0)   temp_space
	 	        ,      nvl(drr.index_space,0)  index_space
	 	        ,      drr.db_name
	          from cfgadm.database_res_request drr
	          where lower(substr(i_host_name,1,instr(i_host_name,'.')-1)) = lower(drr.requested_cluster)
	          and   drr.drr_status in ('OPEN', 'PLANNED', 'IN PROGRESS')
	          order by drr.req_id
	          )
	    loop
	       log_line(' ');
         if t_first_drr
	       then
	          t_first_drr := false;
            log_line('DRRs for host');
	       end if;
	       log_line('Request/Status/Project: '||r_drr.req_id ||'/'|| r_drr.drr_status||'/'|| r_drr.project);
         log_line('DB Name                          : '||r_drr.db_name);
		     --log_line('...SGA/PGA Size                 : '||r_drr.sga_size ||'/'|| case when r_drr.pga_size_max > 100 then 1 else r_drr.pga_size_max end);
         log_line('...SGA/PGA Size(Gb)              : '||r_drr.sga_size ||'/'|| r_drr.pga_size_max);
         log_line('...Data/FRA                      : '||r_drr.data_space ||'/'|| r_drr.temp_space);
		     --
		     --t_drr_mem := t_drr_mem + r_drr.sga_size + case when r_drr.pga_size_max > 100 then 1 else r_drr.pga_size_max end;
		     t_drr_mem := t_drr_mem + r_drr.sga_size + r_drr.pga_size_max;
	       t_drr_dat := t_drr_dat + r_drr.data_space;
	       t_drr_fra := t_drr_fra + r_drr.temp_space;
      end loop;

      if not t_first_drr
  	  then
         log_line(' ');
	       log_line('Total');
		     log_line('...SGA/PGA Size                  : '||t_drr_mem);

		     t_def_oracle_alloc := t_def_oracle_alloc + (t_drr_mem * 1024);
	       log_line('...New Total Oracle Defined (Mb) : '||t_def_oracle_alloc);

		     if t_online_memory > 0
		     then
		        t_mem_free := t_online_memory - t_def_oracle_alloc;
		        if t_mem_free > 0
		        then
		           log_line('...New Host memory free          : '||round((t_mem_free/t_online_memory)*100)||'%');
            else
			         log_line('...New Overallocated             : '||round((t_mem_free*-1/t_online_memory)*100)||'%');
            end if;
		     end if;
         log_line('...Data/FRA                      : '||t_drr_dat||'/'||t_drr_fra);
	  	   log_line('...New ASM Total Free(Gb)        : '
	  	                        || to_char(  (t_asm_tot_dat_free/1024) - t_drr_dat, 'fm99999' )
	  	                        || '/'|| to_char(  (t_asm_tot_fra_free/1024) - t_drr_fra, 'fm99999' )
	  	                         );

	    end if;

	    -- check SRRs for the host
	    for r_srr in (
	 	        select m.mch_nm, m.mch_dns_nm, srr.*
	          from cfgadm.srr     srr
	          ,    cfgadm.machine m
	          where srr.mch_id = m.mch_id
	          and   srr.srr_status in ('OPEN', 'PLANNED', 'IN PROGRESS')
	          and   lower(substr(i_host_name,1,instr(i_host_name,'.')-1)) = lower(m.mch_nm)
	          order by srr_id
	          )
	    loop
	 	     log_line(' ');
	       if t_first_srr
	       then
	          t_first_srr := false;
	  	      log_line('SRRs for host');
	       end if;
		     log_line('Request/Status: '||r_srr.srr_id ||'/'|| r_srr.srr_status);
		     log_line('Comments      : '||r_srr.comments);
	    end loop;

      log_line(' ');
      -- save cluster-wide values
      if t_online_memory < t_clu_min_online_memory
	    then
	       t_clu_min_online_memory := t_online_memory;
      end if;

      t_asm_storage_unalloc_gb  := 0;
      t_count_databases         := 0;
	    t_def_oracle_alloc        := 0;
	    t_category_prop_1         := null;
	    t_category_prop_2         := null;
      t_cpu_util_avg            := 0;
	    t_cpu_util_max            := 0;
	    t_cpu_user_avg            := 0;
      t_cpu_user_max            := 0;
      t_host_processes          := 0;
      t_swap_util_avg           := 0;
      t_swap_util_max           := 0;
	    t_linux_active_mem_kb     := 0;
	    t_linux_mem_util_perc     := 0;
      t_max_host_memory         := 0;
	    t_max_oracle_alloc        := 0;
	    t_mem_tot_difference      := 0;
	    t_num_databases           := 0;
	    t_online_cpu              := 0;
	    t_online_memory           := 0;
      t_pages_paged_in_avg      := 0;
      t_pages_paged_in_max      := 0;
      t_pages_paged_out_avg     := 0;
      t_pages_paged_out_max     := 0;
	    t_run_q_len_15min_max     := 0;
	    t_run_q_len_15min_avg     := 0;
	    t_sum_avg_instance_cpu    := 0;
   end;

   procedure print_asm_info(i_asm_name in varchar2)
   is
      t_dg             varchar2(60);
      t_asm_tot_free   pls_integer := 0;
      t_asm_tot_size   pls_integer := 0;
      t_asm_tot_used   number      := 0;
      t_read_time_ms   pls_integer := 0;
      t_write_time_ms  pls_integer := 0;
   begin
      t_asm_tot_dat_free := 0;
      t_asm_tot_fra_free := 0;

      log_line('ASM name    : '||i_asm_name);
      if t_dg_free.count > 0
      then
	      log_line('Disk Group name       Size(Gb)     %Used       Free(Gb)  Disks   Avg rd/wr response time(ms)');

	      t_dg := t_dg_free.first;

	      while t_dg is not null
	      loop
	         if substr(t_dg,1,3) = 'DAT'
	         then
	            t_asm_tot_dat_free := t_asm_tot_dat_free + t_dg_free(t_dg);
	            --
	         elsif substr(t_dg,1,3) = 'FRA'
	         then
	            t_asm_tot_fra_free := t_asm_tot_fra_free + t_dg_free(t_dg);
	         end if;
	         t_asm_tot_size := t_asm_tot_size + t_dg_size(t_dg);
	         t_asm_tot_free := t_asm_tot_free + t_dg_free(t_dg);
	         --
  	         if t_dg_rd_resp_tim.exists(t_dg)
		     then
		        t_read_time_ms :=  t_dg_wr_resp_tim(t_dg);
		     else
		        t_read_time_ms :=  t_dg_read_time(t_dg) / t_dg_reads(t_dg);
		     end if;

  	         if t_dg_wr_resp_tim.exists(t_dg)
		     then
		        t_write_time_ms :=  t_dg_wr_resp_tim(t_dg);
		     else
		        t_write_time_ms :=  t_dg_write_time(t_dg) / t_dg_writes(t_dg);
		     end if;

	         log_line
	             (  rpad(t_dg,15)
	             || lpad(to_char(round(t_dg_size(t_dg)/1024),'99,999,999,990'),15)
	             || lpad(to_char(t_dg_used(t_dg),'990.00'),10)
	             || lpad(to_char(round(t_dg_free(t_dg)/1024),'99,999,999,990'),15)
	             || lpad(to_char(t_dg_disk_count(t_dg),'990'),7)
	             || lpad(to_char(t_read_time_ms,'99990.0'),10)
	             || ' / '
	             || ltrim(to_char(t_write_time_ms,'99990.0'))
	             );
	         t_dg := t_dg_free.next(t_dg);
	      end loop;

	      t_dg := t_dg_free.first;
	      while t_dg is not null
	      loop
			 t_dg_free.delete(t_dg);
			 t_dg_usable.delete(t_dg);
			 t_dg_usable_free.delete(t_dg);
			 t_dg_used.delete(t_dg);
			 t_dg_size.delete(t_dg);
			 t_dg_used_sf.delete(t_dg);
			 t_dg_rd_resp_tim.delete(t_dg);
			 t_dg_wr_resp_tim.delete(t_dg);
			 t_dg_read_time.delete(t_dg);
			 t_dg_reads.delete(t_dg);
			 t_dg_write_time.delete(t_dg);
			 t_dg_writes.delete(t_dg);
	         t_dg := t_dg_free.next(t_dg);
	      end loop;
	      --
	      t_asm_tot_used := 100 - (t_asm_tot_free / t_asm_tot_size * 100);
	      log_line('--------------- --------------   ------- --------------');
	      log_line(rpad(' ',15)
		             || lpad(to_char(round(t_asm_tot_size/1024),'99,999,999,990'),15)
		             || lpad(to_char(t_asm_tot_used,'990.00'),10)
		             || lpad(to_char(round(t_asm_tot_free/1024),'99,999,999,990'),15)
		             );
      end if;
      log_line(' ');
   end;


   procedure get_asm_info(i_asm_name in varchar2)
   is
   begin
  	  for r_asm in (
					select target_name
					,      case when key_value2 is null then key_value
					            when key_value2 =  ' '  then key_value
					            else key_value2
					       end kv
					,      column_label
					,      avg(average) value_average
					,      min(minimum) value_minimum
					,      max(maximum) value_maximum
					from sysman.mgmt$metric_daily@oem_db
					where target_name = i_asm_name
					and   metric_name in ('DiskGroup_Usage','Instance_Disk_Performance','Instance_Diskgroup_Performance','diskgroup_imbalance')
					--and rollup_timestamp >= trunc(sysdate) - 1
					and   rollup_timestamp = (select max(rollup_timestamp)
					                          from sysman.mgmt$metric_daily@oem_db
 					                          where target_name = i_asm_name
					                          and   metric_name in ('DiskGroup_Usage','Instance_Disk_Performance','Instance_Diskgroup_Performance','diskgroup_imbalance')
					                         )
					group by target_name, case when key_value2 is null then key_value when key_value2 =  ' '  then key_value else key_value2 end, column_label
					order by target_name, case when key_value2 is null then key_value when key_value2 =  ' '  then key_value else key_value2 end, column_label
				)
      loop
		     if r_asm.column_label = 'Disk Group Free (MB)'
		     then
		        t_dg_free(r_asm.kv)  := r_asm.value_minimum;
		        --
		     elsif r_asm.column_label = 'Disk Group Usable (MB)'
		     then
		        t_dg_usable(r_asm.kv)  := r_asm.value_minimum;
		        --
		     elsif r_asm.column_label = 'Disk Group Usable Free (MB)'
		     then
		        t_dg_usable_free(r_asm.kv)  := r_asm.value_minimum;
		        --
		     elsif r_asm.column_label = 'Disk Group Used %'
		     then
		        t_dg_used(r_asm.kv)  := r_asm.value_maximum;
		        --
		     elsif r_asm.column_label = 'Disk Count'
		     then
		        t_dg_disk_count(r_asm.kv)  := r_asm.value_maximum;
		        --
		     elsif r_asm.column_label = 'Size (MB)'
		     then
		        t_dg_size(r_asm.kv)  := r_asm.value_maximum;
		        --
		     elsif r_asm.column_label = 'Used % of Safely Usable'
		     then
		        t_dg_used_sf(r_asm.kv)  := r_asm.value_minimum;
		        --
		     elsif r_asm.column_label = 'Read Response Time (MS)'
		     then
		        t_dg_rd_resp_tim(r_asm.kv)  := r_asm.value_average;
		        --
		     elsif r_asm.column_label = 'Read Time (MS)'
		     then
                t_dg_read_time(r_asm.kv)  := r_asm.value_average;
		        --
		     elsif r_asm.column_label = 'Reads'
		     then
		        t_dg_reads(r_asm.kv)  := r_asm.value_average;
		        --
		     elsif r_asm.column_label = 'Write Response Time (MS)'
		     then
		        t_dg_wr_resp_tim(r_asm.kv)  := r_asm.value_average;
		     ---
		     elsif r_asm.column_label = 'Write Time (MS)'
		     then
  		        t_dg_write_time(r_asm.kv)  := r_asm.value_average;
		     ---
		     elsif r_asm.column_label = 'Writes'
		     then
		        t_dg_writes(r_asm.kv)  := r_asm.value_average;
		        --
		     end if;
      end loop;

   end;

   procedure process_asm(i_host_name in varchar2)
   is
   begin
  	  for r_asm_target in (
			    select target_name
                from sysman.mgmt_targets@oem_db
                where host_name = i_host_name
                and   target_type in ('osm_cluster','osm_instance')
                order by target_name
				)
      loop
	     get_asm_info(r_asm_target.target_name);
         print_asm_info(r_asm_target.target_name);
         t_num_asm := t_num_asm + 1;
	  end loop;
   end;

   procedure calc_db_info(i_database_name in varchar2)
   is
      t_dbversion            varchar2(50);
      t_instance_number      number := 0;
      t_max_db_alloc         number := 0;
      t_memory_target        number := 0;
      t_memory_max_target    number := 0;
      t_oracle_alloc         number := 0;
      t_pga_aggregate_target number := 0;
      t_processes            pls_integer := 0;
      t_sga_target           number := 0;
      t_sga_max_size         number := 0;
   begin
      t_cpu_count       := 0;
	    t_count_databases := t_count_databases + 1;
      --
      for r_param in (select ip.name
                      ,      to_number(ip.value)/1024/1024 value_mb
                      ,      to_number(ip.value) value_num
                      from sysman.mgmt_db_init_params_ecm@oem_db ip
                      ,    sysman.mgmt$ecm_current_snapshots@oem_db sn
                      where ip.ecm_snapshot_id     = sn.ecm_snapshot_id
                      and   sn.display_target_name = i_database_name
                      and   sn.snapshot_type       = 'oracle_dbconfig'
                      and   ip.name in ('cpu_count'
                                       ,'instance_number'
                                       ,'memory_target','memory_max_target'
                                       ,'pga_aggregate_target'
                                       ,'processes'
                                       ,'sga_target','sga_max_size'
                                       )
                     )
      loop
	     if r_param.name = 'cpu_count'
	     then
	        t_cpu_count := r_param.value_num;
	      --
	     elsif r_param.name = 'instance_number'
	     then
	        t_instance_number := r_param.value_num;
	      --
	     elsif r_param.name = 'memory_target'
	     then
	        t_memory_target  := r_param.value_mb;
	      --
	     elsif r_param.name = 'memory_max_target'
	     then
	        t_memory_max_target  := r_param.value_mb;
	      --
	     elsif r_param.name = 'pga_aggregate_target'
	     then
	        t_pga_aggregate_target := r_param.value_mb;
	      --
	     elsif r_param.name = 'processes'
	     then
	        t_processes := r_param.value_num;
	      --
	     elsif r_param.name = 'sga_target'
	     then
	        t_sga_target := r_param.value_mb;
	     --
	     elsif r_param.name = 'sga_max_size'
	     then
	        t_sga_max_size := r_param.value_mb;
	     end if;
      end loop;
      --
      if t_sga_target > 0
      then
         t_sga_alloc := t_sga_target;
      else
         t_sga_alloc := t_sga_max_size;
      end if;
      --
	  if t_memory_target = 0
	  then
		 t_oracle_alloc := t_sga_alloc + t_pga_aggregate_target;
	  else
		 t_oracle_alloc := t_memory_target;
	  end if;
	  t_def_oracle_alloc := t_def_oracle_alloc + t_oracle_alloc;

	  if t_sga_alloc = 0
	  then
	     t_max_db_alloc := t_memory_target;
	     if t_max_pga_alloc > greatest(t_pga_agg_target,t_pga_aggregate_target)
		 then
		    t_max_db_alloc := t_max_db_alloc + (t_max_pga_alloc - greatest(t_pga_agg_target,t_pga_aggregate_target) );
		 end if;
	  else
	     t_max_db_alloc := t_sga_alloc + t_max_pga_alloc;
	  end if;

	  if t_max_db_alloc = 0
	  then
	     t_max_db_alloc := t_memory_target;
	  end if;

      t_max_oracle_alloc := t_max_oracle_alloc + t_tot_mem_usage; --t_max_db_alloc;
      t_mta_difference   := t_mta_current_size - t_mta_mimimum_size;

      if t_mta_difference > 0
      then
         -- if memory_target is used, use those numbers in preference of sga_target
         t_mem_tot_difference := t_mem_tot_difference + t_mta_difference;
      --
      elsif t_sta_difference > 0
      then
         t_mem_tot_difference := t_mem_tot_difference + t_sta_difference;
      end if;

	  if i_verbose
	  then
         log_line('Database name          : '||i_database_name);

         begin
		     select mtp.property_value
		     into   t_dbversion
	         from   sysman.mgmt_target_properties@oem_db mtp
	         ,      sysman.mgmt_targets@oem_db           mt
		     where  mtp.property_name = 'DBVersion'
		     and    mtp.target_guid   = mt.target_guid
		     and    mt.target_type    = 'oracle_database'
	   		 and    mt.target_name    = i_database_name
		     ;
		     exception
		     when no_data_found
		     then
		        t_dbversion := 'unknown';
		     end;

         log_line('Version                : '||t_dbversion);
         log_line('Processes              : '||t_processes);
         t_host_processes := t_host_processes + t_processes;

         if t_avg_avg_instance_cpu > 0
         or t_max_avg_instance_cpu > 0
         then
            log_line('Average Instance CPU % : '||to_char(t_avg_avg_instance_cpu,'fm990.00') || ' / '||to_char(t_max_avg_instance_cpu,'fm990.00') );
         end if;

         if t_avg_tps > 0
         or t_max_tps > 0
         then
            log_line('Transactions per Second: '||to_char(t_avg_tps,'fm990.00') || ' / '||to_char(t_max_tps,'fm990.00'));
         end if;

         if t_avg_avg_active_sessions > 0
         or t_max_avg_active_sessions > 0
         then
            log_line('Average Active Sessions: '||to_char(t_avg_avg_active_sessions,'fm990.00') || ' / '||to_char(t_max_avg_active_sessions,'fm990.00'));
         end if;

         if t_avg_soft_parse_perc > 0
         or t_avg_mem_sort_perc   > 0
         then
            log_line('Soft Parse/Mem Sort %  : '||to_char(t_avg_soft_parse_perc,'fm990.00') || ' / '||to_char(t_avg_mem_sort_perc,'fm990.00'));
         end if;

         log_line('t_pga_agg_target/par   : '||t_pga_agg_target ||' / '||t_pga_aggregate_target);
         log_line('t_max_pga_alloc/hit%   : '||t_max_pga_alloc  ||' / '||to_char(t_avg_pga_cache_hit,'fm990.00'));
         log_line('t_sga_target           : '||t_sga_target);
         log_line('t_sga_alloc/max_size   : '||t_sga_alloc ||' / '||t_sga_max_size);
         log_line('t_memory_target/max    : '||t_memory_target || ' / '||t_memory_max_target);
         --log_line('t_max_db_alloc         : '||t_max_db_alloc); -- use t_tot_mem_usage instead
         log_line('t_tot_mem_usage        : '||t_tot_mem_usage);
         log_line('t_max_used_space (gb)  : '||t_max_used_space);
         if t_mta_difference > 0
         then
            -- if memory_target is used, use those numbers in preference of sga_target
            log_line('Memory Target Advice, estd_db_time_factor < 1.1');
            log_line('...Current/mimimum/diff: '||t_mta_current_size||' / '||t_mta_mimimum_size|| ' / '||t_mta_difference);
         --
         elsif t_sta_difference > 0
         then
            log_line('SGA Target Advice, estd_db_time_factor < 1.1');
            log_line('...Current/mimimum/diff: '||t_sta_current_size||' / '||t_sta_mimimum_size|| ' / '||t_sta_difference);
         end if;

         log_line(' ');
	  end if;

      if t_instance_number < 2
      then
         -- only add for first instance in a RAC cluster
         t_clu_count_databases     := t_clu_count_databases  + 1;
         t_clu_def_oracle_alloc    := t_clu_def_oracle_alloc + t_oracle_alloc;
         t_clu_max_oracle_alloc    := t_clu_max_oracle_alloc + t_tot_mem_usage;
      end if;

      t_max_pga_alloc            := 0;
      t_pga_agg_target           := 0;
      t_sga_alloc                := 0;
      t_max_db_alloc             := 0;
      t_mta_current_size         := 0;
      t_mta_mimimum_size         := 0;
      t_mta_difference           := 0;
      t_processes                := 0;
      t_tot_mem_usage            := 0;
      t_sta_current_size         := 0;
      t_sta_mimimum_size         := 0;
      t_sta_difference           := 0;
      t_avg_avg_instance_cpu     := 0;
      t_max_avg_instance_cpu     := 0;
      t_avg_avg_active_sessions  := 0;
      t_max_avg_active_sessions  := 0;
      t_avg_soft_parse_perc      := 0;
      t_avg_tps                  := 0;
      t_max_tps                  := 0;
      t_avg_mem_sort_perc        := 0;
      t_max_used_space           := 0;
      t_avg_pga_cache_hit        := 0;
   end;

   procedure process_database(i_database_name in varchar2)
   is
      b_first_dbrec boolean := true;
   begin
  	  for r_dbs in (
		with mm as (select distinct metric_guid, lower(column_label) column_label
		            from sysman.mgmt_metrics@oem_db
		            where target_type = 'oracle_database'
		            and lower(column_label) in
		                ('average instance cpu (%)'
						,'average active sessions'
						,'database time spent waiting (%)'
						,'host cpu utilization (%)'
		                ,'maximum pga allocated (mb)'
		                ,'mta_minimum_size','mta_current_size','mta_difference'
		                ,'pga_aggregate_target (mb)'
		                ,'pga cache hit (%)'
						,'soft parse (%)', 'sorts in memory (%)'
		                ,'sta_minimum_size','sta_current_size','sta_difference'
		                ,'total memory usage (mb)'
		                ,'total sga allocated (mb)'
		                ,'used space(gb)'
		                ,'user-defined numeric metric' -- old version
						,'number of transactions (per second)'
		                )
		            )
		select mm1d.rollup_timestamp
		, mt.target_name as database_name
        , lead(mt.target_name) over (order by mm1d.rollup_timestamp, mt.host_name, mt.target_name, mm1d.key_value)
		, lower(decode(mm.column_label
		        ,'user-defined numeric metric', mm1d.key_value
		        ,mm.column_label
		        )) label
		, mm1d.value_minimum, mm1d.value_maximum, mm1d.value_average
		, 2 sortcol
		from sysman.mgmt_metrics_1day@oem_db   mm1d
		,    sysman.mgmt_targets@oem_db        mt
		,    mm
		where mm1d.target_guid      = mt.target_guid
		and   mt.target_type        = 'oracle_database'
		and   mt.target_name        = i_database_name
		and   mm1d.metric_guid      = mm.metric_guid
		and   mm1d.rollup_timestamp = (select max(mm1d.rollup_timestamp)
                                       from sysman.mgmt_metrics_1day@oem_db   mm1d
                                       ,    sysman.mgmt_targets@oem_db        mt
                                       where mm1d.target_guid      = mt.target_guid
                                       and   mt.target_type        = 'oracle_database'
                                       and   mt.target_name        = i_database_name
		                              )
		order by rollup_timestamp, database_name, label
	)
	loop
	   if r_dbs.label = 'average active sessions'
	   then
	      t_avg_avg_active_sessions := r_dbs.value_average;
	      t_max_avg_active_sessions := r_dbs.value_maximum;
	      --
	   elsif r_dbs.label = 'average instance cpu (%)'
	   then
	      t_sum_avg_instance_cpu := t_sum_avg_instance_cpu + r_dbs.value_maximum;
	      t_avg_avg_instance_cpu := r_dbs.value_average;
	      t_max_avg_instance_cpu := r_dbs.value_maximum;
	      --
	   elsif r_dbs.label = 'maximum pga allocated (mb)'
	   then
	      t_max_pga_alloc  := r_dbs.value_maximum;
	      --
	   elsif r_dbs.label = 'pga_aggregate_target (mb)'
	   then
	      t_pga_agg_target := r_dbs.value_maximum;
	      --
	   elsif r_dbs.label = 'pga cache hit (%)'
	   then
	      t_avg_pga_cache_hit := r_dbs.value_average;
	      --
	   elsif r_dbs.label = 'soft parse (%)'
	   then
	      t_avg_soft_parse_perc := r_dbs.value_average;
	      --
	   elsif r_dbs.label = 'sorts in memory (%)'
	   then
	      t_avg_mem_sort_perc := r_dbs.value_average;
	      --
	   elsif r_dbs.label = 'used space(gb)'
	   then
	      t_max_used_space := r_dbs.value_maximum;
	      --
	   elsif r_dbs.label = 'total sga allocated (mb)'
	   then
	      t_sga_alloc      := r_dbs.value_maximum;
	      --
	   elsif r_dbs.label = 'total memory usage (mb)'
	   then
	      t_tot_mem_usage  := r_dbs.value_maximum;
	      --
	   elsif r_dbs.label = 'number of transactions (per second)'
	   then
	      t_avg_tps := r_dbs.value_average;
	      t_max_tps := r_dbs.value_maximum;
	      --
	   elsif r_dbs.label = 'mta_minimum_size'
	   then
	      t_mta_mimimum_size  := r_dbs.value_maximum;
	      --
	   elsif r_dbs.label = 'mta_current_size'
	   then
	      t_mta_current_size  := r_dbs.value_maximum;
	      --
--	   elsif r_dbs.label = 'mta_difference'
--	   then
--	      t_mta_difference  := r_dbs.value_maximum;
	      --
	   elsif r_dbs.label = 'sta_minimum_size'
	   then
	      t_sta_mimimum_size  := r_dbs.value_maximum;
	      --
	   elsif r_dbs.label = 'sta_current_size'
	   then
	      t_sta_current_size  := r_dbs.value_maximum;
	      --
	   elsif r_dbs.label = 'sta_difference'
	   then
	      t_sta_difference  := r_dbs.value_maximum;
	      --
	   end if;

	end loop;

    calc_db_info(i_database_name);

   end;

   procedure process_databases(i_host_name in varchar2)
   is
      b_first_dbrec boolean := true;
   begin
      for r_database in (select target_name
                         from sysman.mgmt_targets@oem_db
                         where target_type = 'oracle_database'
                         and   target_name not like '%duke-energy.com' -- should be removed
                         and host_name = i_host_name
                         order by target_name)
      loop
         process_database(r_database.target_name);
      end loop;
   end;

   procedure process_host(i_host_name in varchar2)
   is
   begin
   for r_host in (
        -- info seems to be sourced from "lparstat -i"
		with mm as (select distinct metric_guid, column_label
		            from sysman.mgmt_metrics@oem_db
		            where target_type = 'host'
		            and column_label in (-- AIX, metrics group "LPAR Statistics on AIX""
		                                 'Online Virtual CPUs'
		                                ,'Maximum Physical CPUs in system'
		                                ,'Maximum Virtual CPUs'
		                                ,'Online Memory (MB)'
		                                ,'Maximum Memory (MB)'
		                                ,'Number of ASM Instances Summarized'
		                                ,'Number of Databases Summarized'
		                                ,'CPU Utilization (%)'
		                                ,'CPU in User Mode (%)'
		                                ,'Swap Utilization (%)'
		                                ,'User %'
		                                ,'Total I/O (per second)'
		                                ,'Pages Paged-in (per second)'
                                        ,'Pages Paged-out (per second)'
                                        ,'Run Queue Length (15 minute average)'
                                        ,'Free Memory (%)'
                                        ,'ASM Storage Unallocated (GB)'
                                        -- Linux, metrics group "Load"
                                        ,'Active Memory, Kilobytes'
                                        ,'Memory Utilization (%)'
                                        -- Any
                                        ,'Run Queue Length (15 minute average,per core)'
                                        ,'Total Disk I/O made across all disks (per second)'
		                                )
		            )
		select mt.target_name host_name
		, mm.column_label
		, round(avg(mm1d.value_average),2) value_average
		, round(max(mm1d.value_maximum),2) value_maximum
		from sysman.mgmt_metrics_1day@oem_db   mm1d
		,    sysman.mgmt_targets@oem_db        mt
		,    mm
		where mm1d.target_guid       = mt.target_guid
		and   mt.target_type         = 'host'
		and   mt.target_guid         = (select target_guid from sysman.mgmt_targets@oem_db where target_type = 'host' and target_name = i_host_name)
		and   mm1d.metric_guid       = mm.metric_guid
		and   mm1d.rollup_timestamp >= trunc(sysdate) - i_days
		group by mt.target_name, mm.column_label
		order by mt.target_name, mm.column_label
        )
   loop
	   if r_host.column_label = 'CPU Utilization (%)'
	   then
	      t_cpu_util_max := r_host.value_maximum;
	      t_cpu_util_avg := r_host.value_average;
	      --
	   elsif r_host.column_label in ('CPU in User Mode (%)')
	   then
	      t_cpu_user_max := r_host.value_maximum;
	      t_cpu_user_avg := r_host.value_average;
	      --
	   elsif r_host.column_label = 'Maximum Memory (MB)'
	   then
	      t_max_host_memory := r_host.value_maximum;
	      --
	   elsif r_host.column_label = 'Maximum Physical CPUs in system'
	   then
	      t_max_phys_cpu := r_host.value_maximum;
	      --
	   elsif r_host.column_label = 'Maximum Virtual CPUs'
	   then
	      t_max_virt_cpu := r_host.value_maximum;
	      --
	   elsif r_host.column_label in ('Number of Databases Summarized','Number of ASM Instances Summarized')
	   then
	      t_num_databases := r_host.value_maximum;
	      --
	   elsif r_host.column_label = 'Online Memory (MB)'
	   then
	      t_online_memory := r_host.value_maximum;
	      --
	   elsif r_host.column_label = 'Online Virtual CPUs'
	   then
	      t_online_cpu := r_host.value_maximum;
	      --
	   elsif r_host.column_label = 'Pages Paged-in (per second)'
	   then
	      t_pages_paged_in_max := r_host.value_maximum;
	      t_pages_paged_in_avg := r_host.value_average;
	      --
	   elsif r_host.column_label = 'Pages Paged-out (per second)'
	   then
	      t_pages_paged_out_max := r_host.value_maximum;
	      t_pages_paged_out_avg := r_host.value_average;
	      --
	   elsif r_host.column_label in ('Run Queue Length (15 minute average)','Run Queue Length (15 minute average,per core)')
	   then
	      t_run_q_len_15min_max := r_host.value_maximum;
	      t_run_q_len_15min_avg := r_host.value_average;
	      --
	   elsif r_host.column_label = 'Swap Utilization (%)'
	   then
	      t_swap_util_max := r_host.value_maximum;
	      t_swap_util_avg := r_host.value_average;
	      --
	   elsif r_host.column_label in ('Total I/O (per second)','Total Disk I/O made across all disks (per second)')
	   then
	      t_total_io_sec_max := r_host.value_maximum;
	      t_total_io_sec_avg := r_host.value_average;
	      --
	   elsif r_host.column_label = 'User %'
	   then
	      t_db_cpu_user_max := r_host.value_maximum;
	      t_db_cpu_user_avg := r_host.value_average;
	      --
	   elsif r_host.column_label = 'Free Memory (%)'
	   then
	      t_host_free_mem_perc := r_host.value_maximum;
	      --
	   elsif r_host.column_label = 'ASM Storage Unallocated (GB)'
	   then
	      t_asm_storage_unalloc_gb := r_host.value_maximum;
	      --
	   elsif r_host.column_label = 'Active Memory, Kilobytes'
	   then
	      t_linux_active_mem_kb := r_host.value_maximum;
	      --
	   elsif r_host.column_label = 'Memory Utilization (%)'
	   then
	      t_linux_mem_util_perc := r_host.value_maximum;
	      --
	   end if;

   end loop;

   if t_online_memory = 0
   then
     -- not AIX, so calculate
      t_online_memory :=  round((t_linux_active_mem_kb / nullif(t_linux_mem_util_perc,0) * 100) / 1024);
   end if;

   log_line('--------------'||rpad('-',length(i_host_name),'-') );
   log_line('Host name   : '||i_host_name);
   log_line('--------------'||rpad('-',length(i_host_name),'-') );
   process_asm(i_host_name);
   process_databases(i_host_name);
   print_host_info(i_host_name);

   end;

   procedure process_cluster(i_cluster_name in varchar2)
   is
      t_first_drr boolean := true;
      t_num_hosts pls_integer := 0;
   begin
      log_line('--------------'||rpad('-',length(i_cluster_name),'-') );
      log_line('Cluster name: '||i_cluster_name);

      for r_hosts in (
--          select mt.target_name, mt.category_prop_1, mt.category_prop_2
--			from sysman.mgmt_targets@oem_db        mt
--			,    sysman.mgmt_target_assocs@oem_db  mta
--			,    sysman.mgmt_targets@oem_db        mt_assoc
--			where mt.target_type        = 'host'
--			and   mta.assoc_target_guid = (select target_guid from sysman.mgmt_targets@oem_db where target_type = 'cluster' and target_name = i_cluster_name)
--			and   mt.target_guid        = mta.source_target_guid
--			and   mta.assoc_guid        = (select assoc_guid from sysman.mgmt_target_assoc_defs@oem_db where assoc_def_name = 'cluster_instance' and source_target_type = 'host')
--			and   mt_assoc.target_guid  = mta.assoc_target_guid
--   OEM13c:
			select target_host.target_name
            ,      target_host.category_prop_1
            ,      target_host.category_prop_2
            from   sysman.mgmt_targets@oem_db          target_cluster
            ,      sysman.mgmt_targets@oem_db          target_host
            ,      sysman.mgmt_assoc_instances@oem_db  assoc
            where target_cluster.target_type = 'cluster'
            and   target_cluster.target_name = i_cluster_name
            and   assoc.assoc_type           = 'cluster_contains'
            and   assoc.source_me_guid       = target_cluster.target_guid
            and   target_host.target_type    = 'host'
            and   target_host.target_guid    = assoc.dest_me_guid
            order by target_host.target_name
           )
      loop
         t_category_prop_1 := r_hosts.category_prop_1;
	     t_category_prop_2 := r_hosts.category_prop_2;
         process_host(r_hosts.target_name);
         t_num_hosts := t_num_hosts + 1;
      end loop;

	  log_line('--------------');
	  log_line('Cluster Totals');
	  log_line('--------------');
	  log_line('Hosts                           : '||t_num_hosts );
	  log_line('Databases                       : '||t_clu_count_databases );
	  log_line('Minimum Cluster Host memory (Gb): '||round(t_clu_min_online_memory/1024));
	  log_line('Total Oracle Defined (Gb)       : '||round(t_clu_def_oracle_alloc/1024));

	  if t_clu_min_online_memory > 0
	  then
		 t_mem_free := t_clu_min_online_memory - t_clu_def_oracle_alloc;
		 if t_mem_free > 0
		 then
		    log_line('Host memory free (Gb/%)         : '||round(t_mem_free/1024) ||'/'|| round((t_mem_free/t_clu_min_online_memory)*100)||'%');
		 else
		    log_line('Overallocated (Gb/%)            : '||round((t_mem_free*-1)/1024) ||'/'|| round((t_mem_free*-1/t_clu_min_online_memory)*100)||'%');
		 end if;

		 if t_clu_max_oracle_alloc > 0
		 then
	     log_line('Max Oracle Allocated (Gb)       : '||round(t_clu_max_oracle_alloc/1024));
			 t_mem_free := t_clu_min_online_memory - t_clu_max_oracle_alloc;

			 if t_mem_free > 0
			 then
			    log_line('Host memory free (@max alloc)   : '||round(t_mem_free/1024) ||'/'|| round((t_mem_free/t_clu_min_online_memory)*100)||'%');
			 else
			    log_line('Overallocated (@max alloc)      : '||round((t_mem_free*-1)/1024) ||'/'|| round((t_mem_free*-1/t_clu_min_online_memory)*100)||'%');
			 end if;
		 end if;
	  end if;

    -- check DRRs for the cluster
    for r_drr in (
 	        select drr.requested_cluster, drr.req_id, drr.project, drr.db_name
          from cfgadm.database_res_request drr
          where drr_status in ('OPEN', 'PLANNED', 'IN PROGRESS')
          and   lower(drr.requested_cluster) = lower(i_cluster_name)
          order by drr.req_id
          )
    loop
       if t_first_drr
       then
          t_first_drr := false;
          log_line(' ');
  	      log_line('DRRs for cluster');
  	      log_line('----------------');
       end if;
	     log_line('Request/Project: '||r_drr.req_id ||'/'|| r_drr.project ||'/'|| lower(r_drr.db_name));
    end loop;

	  log_line(' ');
    t_clu_count_databases   := 0;
    t_clu_min_online_memory := 9999999999;
    t_clu_def_oracle_alloc  := 0;
    t_clu_max_oracle_alloc  := 0;

   end;

   procedure process_hosts(i_host_name in varchar2)
   is
   begin
	   for r_host in (select target_name, category_prop_1, category_prop_2
	                  from sysman.mgmt_targets@oem_db
	                  where target_type = 'host'
	                  and target_name like i_host_name
	                  order by target_name
	                 )
	   loop
	      t_category_prop_1 := r_host.category_prop_1;
	      t_category_prop_2 := r_host.category_prop_2;
	      process_host(r_host.target_name);
	   end loop;
   end;

   procedure process_clusters(i_cluster_name in varchar2)
   is
   begin
	   for r_cluster in (
				select target_guid, target_name
				from  sysman.mgmt_targets@oem_db
				where target_type    = 'cluster'
				and   target_name like i_cluster_name
				order by target_name
				)
	   loop
	      process_cluster(r_cluster.target_name);
	   end loop;

   end;

begin
   log_line('cfgadm.cluster_analysis_pkg v4.0');
   log_line(' ');
   log_line('Host/Cluster name: '||i_host_cluster_name);
   log_line('Days             : '||i_days);
   log_line('Verbose          : '||case when i_verbose then 'TRUE' else 'FALSE' end );
   log_line(' ');

   -- determine if input is host or cluster, with cluster given preference
	 select max(target_type)
	 into t_target_type
	 from (
	  select target_type
	  from  sysman.mgmt_targets@oem_db
	  where target_type in ('host','cluster')
	  and   target_name like i_host_cluster_name
	  order by target_type
	  )
	 where rownum = 1
	 ;

   if t_target_type = 'cluster'
   then
      -- process clusters
      process_clusters(i_host_cluster_name);
   elsif t_target_type = 'host'
   then
      -- process hosts
      process_hosts(i_host_cluster_name);
   else
      log_line('No host or cluster found.');
   end if;

   dbms_output.put_line(t_ca_report);
end;
/
