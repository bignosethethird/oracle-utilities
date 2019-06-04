------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Table creation script for table UTL.ERROR_CODES
--
-- This file was generated from database instance APP01.
--   Database Time    : 23AUG2005 11:39:15
--   IP address       : 10.44.0.228
--   Database Language: AMERICAN_AMERICA.WE8ISO8859P1
--   Client Machine   : misqux42
--   O/S user         : abc
-- To run this script from the command line:
-- sqlplus UTL/[password]@[instance] @error_codes.sql
------------------------------------------------------------------------------
set feedback off;
set serveroutput on size 1000000;
prompt Creating table UTL.ERROR_CODES

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
     and object_name = upper('ERROR_CODES');
  if(v_count>0)then
    dbms_output.put_line('Table UTL.ERROR_CODES already exists. Dropping it');
    execute immediate 'drop table UTL.ERROR_CODES';
  end if;
exception
  when others then
    if(v_count>0)then
      dbms_output.put_line('and dropping referential constraints to it');
      execute immediate 'drop table UTL.ERROR_CODES cascade constraints';
    end if;
end;
/
------------------------------------------------------------------------------
-- Create table
------------------------------------------------------------------------------
create table UTL.ERROR_CODES
(
  ERROR_CODE                      NUMBER    (10) not null
, MESSAGE                         VARCHAR2  (255)
, EXPLANATION                     VARCHAR2  (2000)
)
tablespace UTL_DATA_SMALL
;
 
------------------------------------------------------------------------------
-- Create/Recreate primary key constraints
------------------------------------------------------------------------------
alter table UTL.ERROR_CODES
  add constraint PK_ERROR_CODE
  primary key (ERROR_CODE)
  using index
  tablespace UTL_DATA_SMALL
;
------------------------------------------------------------------------------
-- end of file
------------------------------------------------------------------------------

