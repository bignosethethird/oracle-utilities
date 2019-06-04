PL/SQL Developer Test script 3.0
41
--  File name:                  $Workfile:  $
--  Source Control version:     $Revision: 1.1 $
--  Last modified by:           $Author: apenney $
--  Source Control location:    $Archive:  $
declare
  v_start   number;
  v_end     number;
  v_retcode integer;
  v_count   integer:=0;
  i         integer;
  v_result_set utl.global.t_result_set;
  v_instance varchar2(100);
begin
  dbms_output.put_line('Test Start at '||to_char(sysdate,'YYYYMMDD HH24:MI:SS'));
  v_start := dbms_utility.get_time;

  -- Test statements
  v_instance:=utl.system.get_instance_name();
  
  dbms_output.put_line(v_instance);

  -- Test analysis
  if(v_instance is not null)then
    v_retcode:=0;
  else
    v_retcode:=-1;
  end if;

  -- Test Summary
  if(v_retcode=0) then
    dbms_output.put_line('Test Success.');
  else
    dbms_output.put_line('Test Failure. Error Code: '||v_retcode||'.');
  end if;
  -- Text Conclusion
  v_end := dbms_utility.get_time;
  dbms_output.put_line('Test End. Time taken : '||(v_end-v_start)/100||' seconds');
exception
  when others then
    dbms_output.put_line('* Exception: Error Code: '||to_char(sqlcode)||' in $Workfile: $. Message: '||sqlerrm||'.');
end;
0
