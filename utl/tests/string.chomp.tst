PL/SQL Developer Test script 3.0
44
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
  v_str varchar2(20);
begin
  dbms_output.put_line('Test Start at '||to_char(sysdate,'YYYYMMDD HH24:MI:SS'));
  v_start := dbms_utility.get_time;

  -- Test statements
  v_str:='Hello'||utl.string.gc_cr||utl.string.gc_cr;
  dbms_output.put_line('Length='||length(v_str));
  utl.string.chomp(v_str);
  dbms_output.put_line('Length='||length(v_str));



  -- Test analysis
  if(length(v_str)=5)then
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
