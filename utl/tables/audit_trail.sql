------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Table creation script for table UTL.AUDIT_TRAIL
--
-- This file was generated from database instance APP01.
--   Database Time    : 23AUG2005 11:39:14
--   IP address       : 10.44.0.228
--   Database Language: AMERICAN_AMERICA.WE8ISO8859P1
--   Client Machine   : misqux42
--   O/S user         : abc
-- To run this script from the command line:
-- sqlplus UTL/[password]@[instance] @audit_trail.sql
------------------------------------------------------------------------------
set feedback off;
set serveroutput on size 1000000;
prompt Creating table UTL.AUDIT_TRAIL

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
     and object_name = upper('AUDIT_TRAIL');
  if(v_count>0)then
    dbms_output.put_line('Table UTL.AUDIT_TRAIL already exists. Dropping it');
    execute immediate 'drop table UTL.AUDIT_TRAIL';
  end if;
exception
  when others then
    if(v_count>0)then
      dbms_output.put_line('and dropping referential constraints to it');
      execute immediate 'drop table UTL.AUDIT_TRAIL cascade constraints';
    end if;
end;
/
------------------------------------------------------------------------------
-- Create table
------------------------------------------------------------------------------
create table UTL.AUDIT_TRAIL
(
  DATE_TIME                       DATE       not null
, ACTION                          VARCHAR2  (20) not null
, USER_ID                         VARCHAR2  (30) not null
, OWNER                           VARCHAR2  (50) not null
, OBJECT                          VARCHAR2  (100) not null
, BEFORE_IMAGE                    VARCHAR2  (4000)
, AFTER_IMAGE                     VARCHAR2  (4000)
, REASON                          VARCHAR2  (500)
)
tablespace UTL_DATA_SMALL
;
 
------------------------------------------------------------------------------
-- Table comment:
------------------------------------------------------------------------------
comment on table UTL.AUDIT_TRAIL is
  'Generic audit trail table';
------------------------------------------------------------------------------
-- end of file
------------------------------------------------------------------------------

