create or replace package body
------------------------------------------------------------------------
------------------------------------------------------------------------
--  System functions: Database Analysis and Repair and Diagnostics
------------------------------------------------------------------------
 utl.pkg_system as

------  DO NOT "BEAUTifY" THis CODE !!!!!  ------------------

  ------------------------------------------------------------------------
  -- Build Operations
  ------------------------------------------------------------------------

  -- Build Operation
  -- Recompiles all packages/procedures/functions and views in the schema list
  -- until it there is no change in the over all compilation status.
  -- Based on code by Solomon Yakobson:
  --    Objects are recompiled based on object dependencies and
  --    therefore compiling  all requested objects in one path.
  --    Recompile Utility skips every object which is either of
  --    unsupported object type or depends on INVALID object(s)
  --    outside of current request (which means we know upfront
  --    compilation will fail anyway).  If object recompilation
  --    is not successful, Recompile Utility continues with the
  --    next object.
  --
  --  Use in 10g scheduler as follows:
  --  begin
  --    dbms_scheduler.create_job(
  --      job_name        =>'Recompile',
  --      job_type        =>'PLSQL_BLOCK',
  --      job_action      =>'utl.system.compile_all;',
  --      start_date      => systimestamp,
  --      repeat_interval =>'FREQ=MINUTELY; INTERVAL = 30;',
  --      comments        =>'Recompile code base every 30 minutes'
  --    );
  --  end;
  --  /
  procedure compile_all(p_schemas IN varchar2 := NULL) is
    --v_schemas           tb_config.string_value%type;
    --v_schema_list       dbms_sql.varchar2s;
    --v_old_hash          number(38) := 0;
    --v_new_hash          number(38) := 0;
    --v_count             integer;
    o_owner  varchar2(100) := p_schemas;
    o_name   varchar2(10) := '%';
    o_type   varchar2(10) := '%';
    o_status varchar2(12) := 'INVALID';

    -- exceptions
    success_with_error exception;
    PRAGMA exception_INIT(success_with_error, -24344);
    -- return Codes
    invalid_type   constant integer := 1;
    invalid_parent constant integer := 2;
    compile_errors constant integer := 4;
    cnt              NUMBER;
    dyncur           integer;
    type_status      integer := 0;
    parent_status    integer := 0;
    recompile_status integer := 0;
    object_status    varchar2(30);

    cursor invalid_parent_cursor(oowner varchar2, oname varchar2, otype varchar2, ostatus varchar2, OID NUMBER) is
      select /*+ RULE */
       o.object_id
      from   public_dependency d, all_objects o
      where  d.object_id = OID
      AND    o.object_id = d.referenced_object_id
      AND    o.status != 'VALID'
      MINUS
      select /*+ RULE */
       object_id
      from   all_objects
      where  owner LIKE upper(oowner)
      AND    object_name LIKE upper(oname)
      AND    object_type LIKE upper(otype)
      AND    status LIKE upper(ostatus);

    cursor recompile_cursor(OID NUMBER) is
      select /*+ RULE */
       'ALTER ' || decode(object_type,
                          'PACKAGE BODY',
                          'PACKAGE',
                          'type BODY',
                          'type',
                          object_type) || ' ' || owner || '.' ||
       object_name || ' COMPILE ' ||
       decode(object_type,
              'PACKAGE BODY',
              ' BODY',
              'type BODY',
              'BODY',
              'type',
              'SPECifICATION',
              '') stmt,
       object_type,
       owner,
       object_name
      from   all_objects
      where  object_id = OID;

    recompile_record recompile_cursor%ROWtype;

    cursor obj_cursor(oowner varchar2, oname varchar2, otype varchar2, ostatus varchar2) is
      select /*+ RULE */
       MAX(LEVEL) dlevel, object_id
      from   sys.public_dependency
      START  WITH object_id IN
                  (select object_id
                   from   all_objects
                   where  owner LIKE upper(oowner)
                   AND    object_name LIKE upper(oname)
                   AND    object_type LIKE upper(otype)
                   AND    status LIKE upper(ostatus))
      CONNECT BY object_id = PRIOR referenced_object_id
      GROUP  BY object_id
      HAVING MIN(LEVEL) = 1
      UNION ALL
      select 1 dlevel, object_id
      from   all_objects o
      where  owner LIKE upper(oowner)
      AND    object_name LIKE upper(oname)
      AND    object_type LIKE upper(otype)
      AND    status LIKE upper(ostatus)
      AND    NOT EXisTS (select 1
              from   sys.public_dependency d
              where  d.object_id = o.object_id)
      ORDER  BY 1 DESC;

    cursor status_cursor(OID NUMBER) is
      select /*+ RULE */
       status
      from   all_objects
      where  object_id = OID;

  begin
    dbms_application_info.set_module('utl.pkg_system.compile_all',null);

    if (o_owner is NULL)
    then
      o_owner := pkg_config.get_variable_string('Schemas');
    end if;
    if (o_owner is NULL)
    then
      o_owner := USER;
    end if;

    utl.pkg_logger.log(utl.pkg_logger.gc_log_message_event,
                       'Starting compilation of objects in schema ' ||
                       o_owner);

    -- Recompile requested objects based on their dependency levels.
    dyncur := dbms_sql.open_cursor;

    FOR obj_record IN obj_cursor(o_owner, o_name, o_type, o_status)
    loop
      OPEN recompile_cursor(obj_record.object_id);
      fetch recompile_cursor
        into recompile_record;
      close recompile_cursor;

      -- We can recompile only functions, Packages, Package Bodies,
      -- procedures, Triggers, Views, Types and Type Bodies.
      if recompile_record.object_type IN
         ('function', 'PACKAGE', 'PACKAGE BODY', 'procedure', 'TRIGGER',
          'VIEW', 'type', 'type BODY')
      then
        -- There is no sense to recompile an object that depends on
        -- invalid objects outside of the current recompile request.
        OPEN invalid_parent_cursor(o_owner,
                                   o_name,
                                   o_type,
                                   o_status,
                                   obj_record.object_id);
        fetch invalid_parent_cursor
          into cnt;

        if invalid_parent_cursor%NOTFOUND
        then
          -- Recompile object.
          begin
            dbms_sql.parse(dyncur, recompile_record.stmt, dbms_sql.native);

            utl.pkg_logger.log(utl.pkg_logger.gc_log_message_event,
                               recompile_record.stmt ||
                               ' completed without errors');
          exception
            when success_with_error then
              utl.pkg_errorhandler.log_error(utl.pkg_exceptions.gc_compilation_err,
                                             recompile_record.stmt ||
                                             ' completed with errors');
          end;

          OPEN status_cursor(obj_record.object_id);
          fetch status_cursor
            into object_status;
          close status_cursor;

          if object_status <> 'VALID'
          then
            recompile_status := compile_errors;
          end if;
        ELSE
          parent_status := invalid_parent;
        end if;

        close invalid_parent_cursor;
      ELSE
        type_status := invalid_type;
      end if;
    end loop;

    utl.pkg_logger.log(utl.pkg_logger.gc_log_message_event,
                       'Completed compilation of objects in schema ' ||
                       o_owner);

    dbms_sql.close_cursor(dyncur);

    dbms_application_info.set_module(null,null);
  exception
    when others then

      if obj_cursor%isOPEN
      then
        close obj_cursor;
      end if;
      if recompile_cursor%isOPEN
      then
        close recompile_cursor;
      end if;
      if invalid_parent_cursor%isOPEN
      then
        close invalid_parent_cursor;
      end if;
      if status_cursor%isOPEN
      then
        close status_cursor;
      end if;
      if dbms_sql.is_open(dyncur)
      then
        dbms_sql.close_cursor(dyncur);
      end if;

      utl.pkg_errorhandler.handle;
      utl.pkg_errorhandler.log_sqlerror;
      raise;
  end compile_all;

  ------------------------------------------------------------------------
  -- Maintenance Operations
  ------------------------------------------------------------------------

  -- Maintenance Operation
  -- Analyzes all schemas specified in system variable "Schemas".
  procedure analyze_schemas(p_schemas IN varchar2) is
    v_schemas     config.string_value%type;
    v_schema_list dbms_sql.varchar2s;
    v_frequency   integer;

    -- Get tables for a schema
    cursor cur_tables(p_schema sys.all_tables.owner%type, p_frequency integer) is
      select table_name
      from   sys.all_tables
      where  owner = p_schema
      and    partitioned = 'NO'
      AND    (last_analyzed is NULL OR
            last_analyzed < SYSDATE - p_frequency);

  begin
    dbms_application_info.set_module('utl.pkg_system.analyze_schemas',null);

    v_frequency := nvl(pkg_config.get_variable_int('AnalyzeFrequency'),gc_analyze_frequency);
    -- Get schemas
    -- use parameter schemas, or config schema or current user in that order of precedence
    v_schemas := nvl(p_schemas, nvl(utl.pkg_config.get_variable_string('Schemas'), USER));

    -- Parse list out into array
    v_schema_list := utl.pkg_string.string2list(v_schemas);
    FOR i IN 1 .. v_schema_list.COUNT
    loop
      utl.pkg_logger.log(utl.pkg_logger.gc_log_message_event,
                         'Starting analyze of schema ' || v_schema_list(i));
      -- Analyse tables in this schema
      FOR ct IN cur_tables(v_schema_list(i),v_frequency)
      loop
        utl.pkg_logger.log(utl.pkg_logger.gc_log_message_event,
                           'Gathering statistics for ' || v_schema_list(i) || '.' ||
                           ct.table_name);

        -- Now do tables, for a hash bucket size of 100
        dbms_stats.gather_table_stats(v_schema_list(i),
                                      ct.table_name,
                                      NULL,
                                      dbms_stats.auto_sample_size,
                                      FALSE,
                                      'FOR ALL INDEXED COLUMNS SIZE SKEWONLY',
                                      NULL,
                                      'DEFAULT',
                                      TRUE,
                                      NULL,
                                      NULL,
                                      NULL,
                                      FALSE);
      end loop;

      utl.pkg_logger.log(utl.pkg_logger.gc_log_message_event,
                         'Completed analyze of schema ' || v_schema_list(i));
    end loop;

    dbms_application_info.set_module(null,null);
  exception
    when others then
      utl.pkg_errorhandler.handle;
      utl.pkg_errorhandler.log_sqlerror;
      raise;
  end analyze_schemas;

  -- Maintenance Operation
  -- Coalesces all tablespaces specified in system variable "Tables Spaces".
  procedure coalesce_tablespaces is
    v_tablespaces     config.string_value%type;
    v_tablespace_list dbms_sql.varchar2s;
  begin
    -- Get schemas
    v_tablespaces := pkg_config.get_variable_string('Schemas');
    if (v_tablespaces is NULL)
    then
      -- Parse list out into array
      v_tablespace_list := utl.pkg_string.string2list(v_tablespaces);
      FOR i IN 1 .. v_tablespace_list.COUNT
      loop
        EXECUTE IMMEDIATE 'alter tablespace ' || v_tablespace_list(i) ||
                          ' coalesce';
      end loop;
    end if;
  exception
    when others then
      utl.pkg_errorhandler.handle;
      utl.pkg_errorhandler.log_sqlerror;
      raise;
  end coalesce_tablespaces;

  -- Removes Duplicate records from a table
  -- This procedure requires full table scans, so care must be taken
  -- when using this procedure on very large tables.
  -- It also assumes that ROWID is consistently generated from the content of the row.
  -- This is not a valid assumption, and therefore this function will not always work.
  -- Which makes the function somewhat useless, actually.
  /*
  To dedupe on a column 'Id'
  delete
    from crm_load.st_customer_details a
   where  rowid < (
          select max(rowid)
            from crm_load.st_customer_details b
           where b.Id = a.Id )
  */

  procedure remove_dup_records(p_table_name IN varchar2 -- Table name, optionally including schema name
                               ) is
    v_dup_sql  varchar2(100) := 'select  t.*, t.rowid from [table_name] t order by  t.rowid';
    v_dist_sql varchar2(100) := 'select  distinct t.*, t.rowid from [table_name] t order by  t.rowid';

    v_dist_count integer := 1;
    v_dup_count  integer := 1;
    v_duplicates integer := 0;
    v_rowcount   integer := 0;

    type listrowid is TABLE OF ROWID INDEX BY BINARY_integer;
    v_dup_list  listrowid;
    v_dist_list listrowid;

    type t_dup is REF cursor;
    v_dup t_dup;

  begin
    -- Get number of items in cursors to ease algorithm:
    v_dup_sql := REPLACE(v_dup_sql, '[table_name]', p_table_name);
    OPEN v_dup FOR v_dup_sql;
    loop
      fetch v_dup
        into v_dup_list(v_dup_count);
      exit when v_dup%NOTFOUND;
      v_dup_count := v_dup_count + 1;
    end loop;
    close v_dup;

    -- Distinct recordset - full table scan required here!
    v_dist_sql := REPLACE(v_dist_sql, '[table_name]', p_table_name);
    OPEN v_dup FOR v_dist_sql;
    loop
      fetch v_dup
        into v_dist_list(v_dist_count);
      exit when v_dup%NOTFOUND;
      v_dist_count := v_dist_count + 1;
    end loop;
    close v_dup;

    -- Get total number of duplicates
    v_duplicates := v_dup_count - v_dist_count;
    -- Only bother if there are duplicates:
    if (v_duplicates > 0)
    then
      begin
        -- Compare against reference list of rowid's
        FOR i IN 1 .. v_dup_count
        loop
          -- compare rowid's of the two cursors, with refer to data of the same order.
          -- if they are not the same, then the current record in c_dup
          -- is a duplicate of the previous record, and must be deleted
          if (v_dup_list(i) <> v_dist_list(i))
          then
            EXECUTE IMMEDIATE 'delete ' || p_table_name || ' m ' ||
                              'where m.rowid = :dup_item_rowid'
              USING v_dup_list(i);
            v_rowcount   := v_rowcount + SQL%ROWCOUNT;
            v_duplicates := v_duplicates - 1;
            -- No more remaining duplicates:
            exit when v_duplicates = 0;
          end if;
        end loop;
        pkg_system.safe_commit;
      end;
    end if;
  exception
    when others then
      utl.pkg_errorhandler.handle;
      utl.pkg_errorhandler.log_sqlerror;
      raise;
  end remove_dup_records;

  ------------------------------------------------------------------------
  -- DDL Operations
  ------------------------------------------------------------------------

  -- Truncate table p_schema.p_table
  procedure truncate_table(p_schema IN all_tables.owner%type,
                           p_table  IN all_tables.table_name%type) is
  begin
    -- truncate_table
    dbms_utility.exec_ddl_statement('TRUNCATE TABLE ' || rtrim(p_schema) || '.' ||
                                    rtrim(p_table));
  end truncate_table;

  -- Disable all foreign key constraints where p_ref_schema.p_ref_constraint
  -- is the referenced entity
  procedure disable_fk(p_ref_schema     IN sys.all_constraints.r_owner%type,
                       p_ref_constraint IN sys.all_constraints.r_constraint_name%type) is
    -- Generate the "alter constraint...disable..." for foreign key constraints
    cursor cur_all_constraints is
      select 'alter table ' || owner || '.' || table_name ||
             ' disable constraint ' || constraint_name
      from   all_constraints
      where  r_owner = p_ref_schema
      AND    r_constraint_name = p_ref_constraint
      AND    status <> 'disabled'
      AND    constraint_type = 'r';
    v_ddl_command varchar2(1000);
  begin
    OPEN cur_all_constraints;
    loop
      fetch cur_all_constraints
        into v_ddl_command;
      exit when cur_all_constraints%NOTFOUND OR cur_all_constraints%NOTFOUND is NULL;
      dbms_utility.exec_ddl_statement(v_ddl_command);
    end loop;
    close cur_all_constraints;
  exception
    when others then
      if cur_all_constraints%isOPEN
      then
        close cur_all_constraints;
      end if;
      utl.pkg_errorhandler.handle;
      utl.pkg_errorhandler.log_sqlerror;
      raise;
  end disable_fk;

  -- Disable all foreign key constraints where p_ref_schema.p_ref_constraint
  -- is the referenced entity.
  procedure enable_fk(p_ref_schema     IN all_constraints.r_owner%type,
                      p_ref_constraint IN all_constraints.r_constraint_name%type) is
    -- Generates the "alter constraint...disable..." for foreign key constraints.
    cursor cur_all_constraints is
      select 'alter table ' || owner || '.' || table_name ||
             ' enable constraint ' || constraint_name
      from   all_constraints
      where  r_owner = p_ref_schema
      AND    r_constraint_name = p_ref_constraint
      AND    status <> 'enabled'
      AND    constraint_type = 'r';
    v_ddl_command varchar2(1000);
  begin
    -- enable_fk
    OPEN cur_all_constraints;
    loop
      fetch cur_all_constraints
        into v_ddl_command;
      exit when cur_all_constraints%NOTFOUND OR cur_all_constraints%NOTFOUND is NULL;
      dbms_utility.exec_ddl_statement(v_ddl_command);
    end loop;
    close cur_all_constraints;
  exception
    when others then
      if cur_all_constraints%isOPEN
      then
        close cur_all_constraints;
      end if;
      utl.pkg_errorhandler.handle;
      utl.pkg_errorhandler.log_sqlerror;
      raise;
  end enable_fk;

  -- Attempts to commit a number to times before abandoning the attempt.
  -- This is probably a mythical scenario from pre-version 8..?
  procedure safe_commit(p_max_retry IN pls_integer := 10) is
    v_committed   boolean := FALSE;
    v_retry_count pls_integer := 0;
  begin
    while (NOT v_committed)
    loop
      begin
        COMMIT;
        v_committed := TRUE;
      exception
        when others then
          v_committed   := FALSE;
          v_retry_count := v_retry_count + 1;
          if (v_retry_count >= p_max_retry)
          then
            raise;
          ELSE
            -- Sleep for a random number of seconds:
            dbms_lock.sleep(dbms_random.VALUE(1, 60));
          end if;
      end;
    end loop;
  exception
    when others then
      utl.pkg_errorhandler.handle;
      utl.pkg_errorhandler.log_sqlerror;
      raise;
  end safe_commit;

  -- Get the path name for a directory object.
  -- returns NULL if invalid DIRECTORY object specified.
  function get_directory_path(p_directory IN varchar2) return varchar2 is
    v_path sys.all_directories.directory_path%type;
  begin
    select a.directory_path
    into   v_path
    from   sys.all_directories a
    where  a.directory_name = upper(TRIM(p_directory));
    return v_path;
  exception
    when no_data_found then
      return NULL;
    when others then
      utl.pkg_errorhandler.handle;
      utl.pkg_errorhandler.log_sqlerror;
      raise;
  end get_directory_path;

  -- Gets the Server Name
  -- returns localhost if Server name could not be found
  function get_server_name return varchar2 is
    v_host_name varchar2(100);
  begin
    select utl_inaddr.get_host_name into v_host_name from dual;
    return v_host_name;
  exception
    when no_data_found then
      return 'localhost';
    when others then
      utl.pkg_errorhandler.handle;
      utl.pkg_errorhandler.log_sqlerror;
      raise;
  end get_server_name;

  -- Gets the Instance Name
  -- returns NULL if Instance name could not be found
  function get_instance_name return varchar2 is
    v_instance_name varchar2(100);
  begin
    select sys_context('USERENV', 'DB_NAME')
    into   v_instance_name
    from   dual;
    return v_instance_name;
  exception
    when no_data_found then
      return NULL;
    when others then
      utl.pkg_errorhandler.handle;
      utl.pkg_errorhandler.log_sqlerror;
      raise;
  end get_instance_name;

  -- Get the current O/S user
  function get_current_osuser return varchar2 is
    v_osuser varchar2(100);
  begin
    select sys_context('USERENV', 'OS_USER')
    into   v_osuser
    from   dual;
    return v_osuser;
  exception
    when no_data_found then
      return NULL;
    when others then
      utl.pkg_errorhandler.handle;
      utl.pkg_errorhandler.log_sqlerror;
      raise;
  end get_current_osuser;


end pkg_system;
------------------------------------------------------------------------
-- end of file
------------------------------------------------------------------------
/
