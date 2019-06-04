-- Create library 
-- calling script substitutes home directory
set feedback off;
Prompt Creating utl.libhostcmd library 
create or replace library UTL.LIBHOSTCMD as '%APP_HOME%/lib/libhostcmd.so';
/
exit
