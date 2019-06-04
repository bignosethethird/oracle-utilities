------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Table creation script for table UTL.LOG_MESSAGE
--
-- This file was generated from database instance APP01.
--   Database Time    : 23AUG2005 11:39:15
--   IP address       : 10.44.0.228
--   Database Language: AMERICAN_AMERICA.WE8ISO8859P1
--   Client Machine   : misqux42
--   O/S user         : abc
-- To run this script from the command line:
-- sqlplus UTL/[password]@[instance] @log_message.sql
------------------------------------------------------------------------------
set feedback off;
set serveroutput on size 1000000;
prompt Creating table UTL.LOG_MESSAGE

-- Drop table if it already exists
-- Note that the contents of the table will also be deleted
--  and that referential constraints will also be dropped.
-- You will be warned when this happens.
declare 
  v_count integer:=0;
begin
  select count(*)
    into v_count
    from sys.all_objects
   where object_type = 'TABLE'
     and owner = upper('UTL')
     and object_name = upper('LOG_MESSAGE');
  if(v_count>0)then
    dbms_output.put_line('Table UTL.LOG_MESSAGE already exists. Dropping it');
    execute immediate 'drop table UTL.LOG_MESSAGE';
  end if;
exception
  when others then
    if(v_count>0)then
      dbms_output.put_line('and dropping referential constraints to it');
      execute immediate 'drop table UTL.LOG_MESSAGE cascade constraints';
    end if;
end;
/
------------------------------------------------------------------------------
-- Create table
------------------------------------------------------------------------------
create table UTL.LOG_MESSAGE
(
  MESSAGE_TEXT                    VARCHAR2  (4000) not null
, PROGRAM_NAME                    VARCHAR2  (200) not null
, LOG_DATE                        DATE       not null
, LOG_USER                        VARCHAR2  (100) not null
, MESSAGE_TYPE                    VARCHAR2  (5) not null
, SEQUENCE_ID                     NUMBER     not null
, PARENT_TABLE                    VARCHAR2  (30)
, PARENT_ID                       NUMBER    
, ERROR_CODE                      NUMBER    
)
tablespace UTL_DATA_SMALL
;
 
------------------------------------------------------------------------------
-- Create/Recreate primary key constraints
------------------------------------------------------------------------------
alter table UTL.LOG_MESSAGE
  add constraint PK_LOG_MESSAGE
  primary key (SEQUENCE_ID)
  using index
  tablespace APP_IDX_SMALL
;
 
------------------------------------------------------------------------------
-- Create/Recreate indexes 
------------------------------------------------------------------------------
create index UTL.IX_LOG_MESSAGE_DATE on UTL.LOG_MESSAGE(LOG_DATE)
  tablespace APP_IDX_SMALL
;
create index UTL.IX_LOG_MESSAGE_PARENT_ID on UTL.LOG_MESSAGE(PARENT_TABLE,PARENT_ID)
  tablespace APP_IDX_SMALL
;
------------------------------------------------------------------------------
-- end of file
------------------------------------------------------------------------------

