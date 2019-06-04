create or replace package body utl.pkg_logger as
--------------------------------------------------------------------------
--------------------------------------------------------------------------
--  Write log information (e.g. errors and events) to a log_mesage table
------------------------------------------------------------------------

-- PUBLIC FUNCTIONS

  -- writes a standard debug message to the log with optional additional text
  procedure log_debug(p_message_text in varchar2 default null) as
    c_proc_name         constant varchar2(100) := pc_schema||'.'||pc_package||'.log_debug';
  begin
    dbms_application_info.set_module(c_proc_name,null);
    -- log with the program name set to the caller of log_debug
    log(gc_log_message_debug,
        systimestamp || ' ' || p_message_text,
        null,
        null,
        null,
        get_program_name(dbms_utility.format_call_stack));

    dbms_application_info.set_module(null,null);
  exception
    when others then
      pkg_errorhandler.handle;
      raise;
  end log_debug;

  -- extracts the calling procedures name and line number where the call was made from the call stack
  -- ignores the first entry in the callstack as this would generally be the logging procedure
  function get_program_name(p_callstack in varchar2) return varchar2 as
    c_proc_name         constant varchar2(100) := pc_schema||'.'||pc_package||'.get_program_name';
    v_name    varchar2(2000) := '';
    v_index   number;
    v_endline number;

    v_split   dbms_sql.varchar2s;
  begin
    dbms_application_info.set_module(c_proc_name,null);
    v_index := instr(p_callstack, 'name') + 5;                       -- skip to the start of the call info
    v_index := instr(p_callstack, pkg_constants.gc_cr, v_index) + 1; -- skip the first call in the stack as this will be the error handler itself
    v_endline := instr(p_callstack, pkg_constants.gc_cr, v_index);
    v_name := substr(p_callstack, v_index, v_endline - v_index);
    v_name := ltrim(v_name);
    v_name := substr(v_name, length(substr(v_name, 1, instr(v_name, ' '))) + 1);
    v_name := ltrim(v_name);
    IF (instr(v_name,'package body') <> 0)
    then
      v_split := utl.pkg_string.string2list(v_name, utl.pkg_string.gc_space);
      v_name := v_split(5) || ' (' || v_split(1) || ')';
    end IF;

    dbms_application_info.set_module(null,null);
    return v_name;
  exception
    when others then
      pkg_errorhandler.handle;
      raise;
  end get_program_name;

  
  -- procedure to write a log message
  --
  -- p_message_type defines the level of the log message (event, error, info, debug)
  -- p_program_name is an optional field to define the logging program (if null then the calling pl/sql subprogram is used)
  -- p_message_text is the text to be logged
  -- p_parent_table is the optional table of which p_parent_id is a primary key value
  -- p_parent_id is an optional identifier of a parent of the log message
  -- p_sqlcode is the oracle error code (if this is an error log message)
  procedure log(p_message_type in log_message.message_type%type:=null,
                p_message_text in log_message.message_text%type:=null,
                p_parent_table in log_message.parent_table%type default null,
                p_parent_id    in log_message.parent_id%type default null,
                p_sqlcode      in log_message.error_code%type default null,
                p_program_name in log_message.program_name%type default null)
  is
    pragma autonomous_transaction;
    c_proc_name         constant varchar2(100) := pc_schema||'.'||pc_package||'.log';
    v_err_code          log_message.error_code%type:=nvl(p_sqlcode,sqlcode);
    c_chunk_size        constant number := 4000;
    v_retcode           global.t_error_code;
    v_sysdate           timestamp:=systimestamp;
    v_user              varchar2(30):=user;
    v_program_name      log_message.program_name%type;
    v_message_text      varchar2(32760);
    v_message           varchar2(32760);
    v_explanation       error_codes.explanation%type;
    v_error_message     error_codes.message%type;
    l_line              dbms_sql.varchar2s;
    v_index             pls_integer;  -- current line index
    

  begin
    dbms_application_info.set_module(c_proc_name,null);

    -- Collect message text and explanation for a known error code
    v_retcode:=pkg_errorhandler.code2desc(v_err_code,v_error_message,v_explanation);
    -- Add error message if not supplied
    if(p_message_text is null)then
      v_message_text:=v_error_message;
    else
      v_message_text:=p_message_text;
    end if;
    
    -- Substitute format characters %1, %2, etc., with details in the order 
    -- of p_parent_table, p_parent_id
    declare
      v_pos               pls_integer;
      v_parent_table  boolean:=false;
      v_parent_id     boolean:=false;
    begin
      v_index:=1;
      loop
        v_pos:=instr(v_error_message,'%'||v_index);
        exit when v_pos=0;
        if(p_parent_table is not null and v_parent_table=false)then
          v_message_text:=substr(v_message_text,1,v_pos-1)||p_parent_table||substr(v_message_text,v_pos);
          v_parent_table:=true;
        end if;
        if(p_parent_id is not null and v_parent_id=false)then
          v_message_text:=substr(v_message_text,1,v_pos-1)||p_parent_id||substr(v_message_text,v_pos+length(v_index)+1);
          v_parent_id:=true;
        end if;
        v_index:=v_index+1;
      end loop;
    end;

    if(instr(gc_log_types,upper(nvl(p_message_type,gc_log_message_event)))<>0)then
      -- Log to table
      if(instr(gc_log_target_types, gc_log_target_table)<>0)then
        begin
          v_program_name := nvl(p_program_name,get_program_name(dbms_utility.format_call_stack));
          for i in 1 .. ceil(length(v_message_text) / c_chunk_size) loop
            v_message := nvl(substr(v_message_text, ((i-1)*c_chunk_size)+1, c_chunk_size),'');
            insert into log_message
              (program_name,
               message_type,
               log_date,
               log_user,
               message_text,
               sequence_id,
               error_code,
               parent_table,
               parent_id)
            values
              (v_program_name,
               nvl(p_message_type,gc_log_message_event),
               v_sysdate,
               v_user,
               v_message,
               sq_log_message.nextval,
               v_err_code,
               p_parent_table,
               p_parent_id);
          end loop;
          commit;
        exception
          when others then
            raise;
        end;
      end if;
    end if;

    -- Make up maximum line width of 168 chars
    declare
      l_message       dbms_sql.varchar2s;
      v_lines         pls_integer;
      c_linesize      constant pls_integer:=60;
    begin
      v_index:=0;
      -- Event Header:              date                                          event_type                            error code inc. -
      l_line(v_index):='['||to_char(v_sysdate,gc_log_date_format)||'] ['||nvl(p_message_type,gc_log_message_event)||'] ['||lpad(v_err_code,6,'0')||']';
      v_index:=v_index+1;
      -- Message:
      v_retcode:=pkg_string.break_string(v_message_text,l_message,v_lines,'',c_linesize);
      if(v_lines>0)then
        pkg_string.chomp(l_message(v_lines));
        for i in l_message.first..l_message.last loop
          if(i=1)then
            l_line(v_index):= '  Msg:  ('||lpad(i,4,0)||') '||l_message(i);
            v_index:=v_index+1;
          else
            l_line(v_index):= '        ('||lpad(i,4,0)||') '||l_message(i);
            v_index:=v_index+1;
          end if;
        end loop;
      end if;
      -- Explanation:
      v_lines:=0;
      l_message.delete;
      if(gc_loglevel>=gc_loglevel_debug and v_explanation is not null and v_err_code<>0)then
        v_retcode:=pkg_string.break_string(v_explanation,l_message,v_lines,'',c_linesize);
        if(v_lines>0)then
          pkg_string.chomp(l_message(v_lines));
          for i in l_message.first..l_message.last loop
            if(i=1)then
              l_line(v_index):= '  Explanation: '||l_message(i);
              v_index:=v_index+1;
            else
              l_line(v_index):= '               '||l_message(i);
              v_index:=v_index+1;
            end if;
          end loop;
        end if;
      end if;

      if(gc_loglevel>=gc_loglevel_vebose)then
        -- Get source load run description
        if(p_parent_id is not null)then
          if(lower(p_parent_table)='source_load_run')then
            l_line(v_index):= '  Source Load: '||vcr.pkg_source_load_run.get_description(p_parent_id);
            v_index:=v_index+1;
          else
            l_line(v_index):= '  Task Id:     '||p_parent_id;
            v_index:=v_index+1;
          end if;
        end if;
        -- Some smaller details
        if(p_parent_table is not null)then
          l_line(v_index):=   '  Details:     '||p_parent_table;
          v_index:=v_index+1;
        end if;
        -- Environment
        l_line(v_index):=     '  User:        '||v_user;
        v_index:=v_index+1;
        l_line(v_index):=     '  Program:     '||v_program_name;
        v_index:=v_index+1;
      end if;
    end;

    -- Output to DBMS_OUTPUT. In Oracle 8i and 9i, too much of this output and the whole
    -- database slows down to a grind. Event setting the server output size to 1000000
    -- will not help, since Oracle writes other things to this buffer. So use with care.
    -- 10g has no limitation on the dbms_output buffer size, so this may not be a problem any more.   
    -- You would only use this facility if you are using a console session.
    -- Remember to do this:
    -- SQL> set serveroutput on format wrapped
    -- or the leading spaces will be truncated.
    if(instr(gc_log_target_types, gc_log_target_output)<>0)then
      for v_index in l_line.first..l_line.last loop
        dbms_output.put_line(l_line(v_index));
      end loop;
    end if;

    -- Get a global lock so that
    -- 1. in the case of file writes, events do not get lost
    -- 2. in the case of pipe writes, events do not get jumbled
    -- Get around this by soft-locking. We go ahead and write after 
    -- 1 seconds' worth of attempts to get a lock.
    -- If we fail, then nothing is written to the file and some 
    -- jumbled info may be written to the pipes. C'est la vie!
    if(dbms_lock.request(gc_log_lock_id,1,1)<>0)then    -- Try for 1 sec to get lock...
      dbms_lock.sleep(1);                               -- Failed, so we need to put own own wait here
      v_retcode:=dbms_lock.request(gc_log_lock_id,1,1); -- Final attempt for 1 sec. 
    end if;   
    -- logging to file is cheap
    if(instr(gc_log_target_types, gc_log_target_file)<>0)then
      declare
        v_fid           utl_file.file_type;
      begin
        v_fid := utl_file.fopen(gc_log_dir,gc_log_file,'A');
        for v_index in l_line.first..l_line.last loop
          utl_file.put_line(v_fid, l_line(v_index));
        end loop;
        utl_file.fflush(v_fid);
        utl_file.fclose(v_fid);
      exception
        when others then
          utl_file.fclose(v_fid);
          -- No need to raise further
      end;
    end if;    
    -- Release lock even if this session did not own the lock
    v_retcode:=dbms_lock.release(gc_log_lock_id);
    
    dbms_application_info.set_module(null,null);
  exception
    when others then      
      pkg_errorhandler.handle;
      raise;
  end log;

  procedure error(p_sqlcode      in log_message.error_code%type default null) is
  begin
    utl.pkg_logger.log(p_message_type=>utl.pkg_logger.gc_log_message_error,p_sqlcode=>p_sqlcode);
  end error;
  procedure warn (p_sqlcode      in log_message.error_code%type default null) is
  begin
    utl.pkg_logger.log(p_message_type=>utl.pkg_logger.gc_log_message_warn,p_sqlcode=>p_sqlcode);
  end warn;
    procedure info (p_sqlcode      in log_message.error_code%type default null) is
  begin
    utl.pkg_logger.log(p_message_type=>utl.pkg_logger.gc_log_message_info,p_sqlcode=>p_sqlcode);
  end info;
  procedure debug(p_sqlcode      in log_message.error_code%type default null) is
  begin
    utl.pkg_logger.log(p_message_type=>utl.pkg_logger.gc_log_message_debug,p_sqlcode=>p_sqlcode);
  end debug;

  -- procedure to purge the log table
  procedure purge(p_log_user in log_message.log_user%type default '%')
  is
    c_proc_name         constant varchar2(100) := pc_schema||'.'||pc_package||'.log';
  begin
    dbms_application_info.set_module(c_proc_name,null);

    delete from log_message
    where  log_date <
           to_date(to_char(add_months(sysdate, -1 * gc_log_months_retained),
                           'dd-MON-yyyy'),
                   'dd-MON-yyyy')
    and    log_user like p_log_user;

    log(gc_log_message_event,
        'Purged ' || SQL%ROWCOUNT || ' log entries older than ' ||
        to_char(add_months(sysdate, -1 * gc_log_months_retained), 'dd-MON-yyyy'));
    commit;

    dbms_application_info.set_module(null,null);
  exception
    when others then
      pkg_errorhandler.handle;
      pkg_errorhandler.log_sqlerror;

      raise;
  end purge;

begin
  -- Get all configution setting ONCE per session
  gc_log_target_types     :=nvl(upper(utl.pkg_config.get_variable_string(gc_log_target_types_cfg_key)),gc_log_target_table);
  gc_log_types            :=nvl(upper(pkg_config.get_variable_string(gc_log_types_cfg_key)),gc_log_message_error);
  gc_log_months_retained  :=nvl(pkg_config.get_variable_int(gc_log_months_retained_cfg_key),gc_default_months_retained);
  gc_log_dir              :=utl.pkg_config.get_variable_string(gc_log_dir_cfg_key);
  gc_log_file             :=nvl(utl.pkg_config.get_variable_string(gc_log_file_cfg_key),'events');
  gc_loglevel             :=nvl(utl.pkg_config.get_variable_int(gc_loglevel_cfg_key),gc_loglevel_basic);
  gc_log_date_format      :=nvl(utl.pkg_config.get_variable_string(gc_log_date_fmt_cfg_key),'YYYY/MM/DD HH24:MI:SS');
end pkg_logger;
/
