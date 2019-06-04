PL/SQL Developer Test script 3.0
42
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
begin
  dbms_output.put_line('Test Start at '||to_char(sysdate,'YYYYMMDD HH24:MI:SS'));
  v_start := dbms_utility.get_time;

  -- Test statements
  utl.logger.error('object',-20000,'parameters',1000);
  utl.logger.warn('object',-20000,'parameters',1000);
  utl.logger.info('object','test message');
  v_count:=1;


  -- Test analysis
  if(v_count>0)then
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
