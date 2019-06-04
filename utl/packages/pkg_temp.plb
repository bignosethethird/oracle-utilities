create or replace package body utl.pkg_temp as
------------------------------------------------------------------------------
------------------------------------------------------------------------------
--  Temporary table management
------------------------------------------------------------------------------

--==================================================================--
-- Temp Functions
--==================================================================--


----------------------------------------------------------------------------
--  Create a "temp" table in the current schema that should be deleted
--  at the end of the process.
--  Comma-delimited list req columns in the form e.g.
--  '"Trader Type" varchar2(30), "Firm" varchar2(30),"Freq" varchar2(10)';
--  Returns the name of the temp table that was created.
--
--  Usage:
--  begin
--    v_table_name:=create_temp_table4cols('"Trader Type" varchar2(30), "Badge" varchar2(30), "Freq" varchar2(10)');
--    ...
--    execute immediate 'drop table '||v_table_name;
--  exception
--    when others then
--      if(v_table_name is not null)then
--        execute immediate 'drop table '||v_table_name;
--      end if;
--  end;
--
-- TODO: Use the list gl_temp_tables delete the temp table when the calling
--       procedure goes out of scope
----------------------------------------------------------------------------
function create_temp_table4cols(p_cols  in    varchar2)
return varchar2
is
  c_proc_name           constant varchar2(50) := pc_schema||'.'||pc_package||'.create_temp_table4cols';
  v_table_name          varchar2(30);
  v_table_create_sql    varchar2(1000);  
begin
  -- Make up temp table to save data in
  v_table_name := 'tmp_##_'||ltrim(rtrim(sys.dbms_session.unique_session_id));
  v_table_create_sql := 'create table '||v_table_name||' ('||p_cols||')';
  execute immediate v_table_create_sql;
  gl_temp_tables(nvl(gl_temp_tables.last,0)+1):=v_table_name;
  return v_table_name;
exception
  when others then
    utl.pkg_errorhandler.handle;
    utl.pkg_logger.log;
    return null;
end create_temp_table4cols;

----------------------------------------------------------------------------
--  Create a "temp" table in the current schema that should be deleted
--  at the end of the process.
--  Returns the name of the temp table that was created.
--  Note:
--  Does not create an index.
--
--  Usage:
--  begin
--    v_table_name:=create_temp_table4tables('traders');
--    ...
--    execute immediate 'drop table '||v_table_name;
--  exception
--    when others then
--      if(v_table_name is not null)then
--        execute immediate 'drop table '||v_table_name;
--      end if;
--  end;
----------------------------------------------------------------------------
function create_temp_table4tables(p_table_name  in    varchar2)
return varchar2
is
  c_proc_name           constant varchar2(50) := pc_schema||'.'||pc_package||'.create_temp_table4tables';
  v_table_name          varchar2(30);
  v_table_create_sql    varchar2(1000);  
begin
  -- Make up temp table to save data in
  v_table_name := 'tmp_##_'||ltrim(rtrim(sys.dbms_session.unique_session_id));
  v_table_create_sql := 'create table '||v_table_name||' as select * from '||p_table_name||' where 1=2';
  execute immediate v_table_create_sql;
  gl_temp_tables(nvl(gl_temp_tables.last,0)+1):=v_table_name;
  return v_table_name;
exception
  when others then
    utl.pkg_errorhandler.handle;
    utl.pkg_logger.log;
    return null;
end create_temp_table4tables;


end pkg_temp;
------------------------------------------------------------------------------
-- end of file
------------------------------------------------------------------------------
/
