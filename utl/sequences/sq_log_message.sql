------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Creation script for sequence UTL.SQ_LOG_MESSAGE
--
-- This file was generated from database instance CPAD.
--   Database Time    : 28FEB2005 17:10:06
--   IP address       : 192.5.20.64
--   Database Language: AMERICAN_AMERICA.WE8ISO8859P1
--   Client Machine   : ahl64
--   O/S user         : vcr
-- To run this script from the command line:
-- sqlplus UTL/[password]@[instance] @sq_log_message.sql
------------------------------------------------------------------------------
set feedback off;
prompt Creating sequence UTL.SQ_LOG_MESSAGE

-- Drop type if it already exists
-- Note that the contents of the table will also be deleted.
declare 
  v_count integer:=0;
begin
  select count(*)
    into v_count
    from sys.all_objects
   where object_type = 'SEQUENCE'
     and owner = upper('UTL')
     and object_name = upper('SQ_LOG_MESSAGE');
  if(v_count>0)then
    execute immediate 'drop sequence UTL.SQ_LOG_MESSAGE';
  end if;
end;
/
------------------------------------------------------------------------------
-- Create sequence
------------------------------------------------------------------------------

create sequence UTL.SQ_LOG_MESSAGE
  minvalue 1 
  maxvalue 999999999999999999999999999
  increment by 1
  nocycle
  nocache
  noorder
;

------------------------------------------------------------------------------
-- end of file
------------------------------------------------------------------------------

