PL/SQL Developer Test script 3.0
17
-- Created on 14/10/2005 by GHOEKSTRA 
declare 
  -- Local variables here
  i integer;
  v_count pls_integer;

  l_lines   dbms_sql.varchar2s;
begin
  -- Test statements here

  i:=utl.pkg_string.break_string(scheduler_rep.schedule_dump,l_lines,v_count,null,80);
  for i in l_lines.first..l_lines.last loop
     dbms_output.put_line(l_lines(i));
  end loop;

  
end;
0
0
