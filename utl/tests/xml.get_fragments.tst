PL/SQL Developer Test script 3.0
37
--  File name:                  $Workfile:  $
--  Source Control version:     $Revision: 1.1 $
--  Last modified by:           $Author: apenney $
--  Source Control location:    $Archive:  $
declare
  v_start   number;
  v_end     number;
  v_retcode integer:=0;
  v_count   integer:=0;
  i         integer;
  v_result_set utl.global.t_result_set;
  v         dbms_sql.varchar2s;
begin
  dbms_output.put_line('Test Start at '||to_char(sysdate,'YYYYMMDD HH24:MI:SS'));
  v_start := dbms_utility.get_time;

  -- Test statements  
  v:=utl.xml.get_fragments('<?xml version="1.0" encoding="UTF-8"?><VENOM><VRM VRM="String" Time="2001-12-17T09:30:47-05:00" F="0" S="0" I="0"><In><User ID="String"/><Img P="0" O="0"/><Conf V="0"/><Op S="String"/><GPS><OS E="4294967295" N="74635241"/><NMEA S="String"/></GPS></In><Hit Hotlist="String" F="0" S="0"><Alert F="1"/><Text S="String"/><Desc S="String"/><Data>Text</Data></Hit><Hit Hotlist="String" F="0" S="0"><Alert F="1"/><Text S="String"/><Desc S="String"/><Data>Text</Data></Hit></VRM></VENOM>',
  '/VENOM/VRM/Hit/Data');
  for i in v.first..v.last loop
    dbms_output.put_line(v(i));  
  end loop;
  

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
