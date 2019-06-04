set feedback off;
Prompt Creating utl.hostcmd function
create or replace function utl.hostcmd(p_cmd in varchar2)
return binary_integer
as external name "hostcmd"
library utl.libhostcmd
language C
parameters (p_cmd STRING, RETURN INT);
/
exit
/
