------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Table creation script for table UTL.CONFIG
--
-- This file was generated from database instance APP01.
--   Database Time    : 23AUG2005 11:39:14
--   IP address       : 10.44.0.228
--   Database Language: AMERICAN_AMERICA.WE8ISO8859P1
--   Client Machine   : misqux42
--   O/S user         : abc
-- To run this script from the command line:
-- sqlplus UTL/[password]@[instance] @config.sql
------------------------------------------------------------------------------
set feedback off;
set serveroutput on size 1000000;
prompt Creating table UTL.CONFIG

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
     and object_name = upper('CONFIG');
  if(v_count>0)then
    dbms_output.put_line('Table UTL.CONFIG already exists. Dropping it');
    execute immediate 'drop table UTL.CONFIG';
  end if;
exception
  when others then
    if(v_count>0)then
      dbms_output.put_line('and dropping referential constraints to it');
      execute immediate 'drop table UTL.CONFIG cascade constraints';
    end if;
end;
/
------------------------------------------------------------------------------
-- Create table
------------------------------------------------------------------------------
create table UTL.CONFIG
(
  VARIABLE                        VARCHAR2  (50) not null
, DESCRIPTION                     VARCHAR2  (250) not null
, INT_VALUE                       NUMBER    (22)
, FLOAT_VALUE                     FLOAT     (22)
, DATE_VALUE                      DATE      
, STRING_VALUE                    VARCHAR2  (255)
, TMSTMP                          DATE      
, CHANGE_REASON                   VARCHAR2  (500)
)
tablespace UTL_DATA_SMALL
;
 
------------------------------------------------------------------------------
-- Column comments:
------------------------------------------------------------------------------
comment on column UTL.CONFIG.VARIABLE is
  'Variable Name';
comment on column UTL.CONFIG.DESCRIPTION is
  'Description';
comment on column UTL.CONFIG.INT_VALUE is
  'Integer TB_CONFIGuration value';
comment on column UTL.CONFIG.FLOAT_VALUE is
  'Floating point TB_CONFIGuration value';
comment on column UTL.CONFIG.DATE_VALUE is
  'Date TB_CONFIGuration value';
comment on column UTL.CONFIG.STRING_VALUE is
  'String TB_CONFIGuration value';
comment on column UTL.CONFIG.TMSTMP is
  'Timestamp when this value was last changed';
comment on column UTL.CONFIG.CHANGE_REASON is
  'Reason for last change';
 
------------------------------------------------------------------------------
-- Create/Recreate primary key constraints
------------------------------------------------------------------------------
alter table UTL.CONFIG
  add constraint PK_CONFIG
  primary key (VARIABLE)
  using index
  tablespace APP_IDX_SMALL
;
------------------------------------------------------------------------------
-- end of file
------------------------------------------------------------------------------

