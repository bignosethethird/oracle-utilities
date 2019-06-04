PL/SQL Developer Test script 3.0
40
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
  v_dir     varchar2(100);
  v_report_dir varchar2(100):='report_dir';
begin
  dbms_output.put_line('Test Start at '||to_char(sysdate,'YYYYMMDD HH24:MI:SS'));
  v_start := dbms_utility.get_time;

  -- Test statements
  v_dir:=utl.system.get_directory_path(v_report_dir);
  dbms_output.put_line(v_dir);
  
  if(v_dir is null)then
   v_retcode:=-1;
  else
    v_retcode:=0;
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
