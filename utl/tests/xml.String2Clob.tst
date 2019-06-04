PL/SQL Developer Test script 3.0
60
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
  c clob;
begin
  dbms_output.put_line('Test Start at '||to_char(sysdate,'YYYYMMDD HH24:MI:SS'));
  v_start := dbms_utility.get_time;

  -- Test statements
  c:=utl.xml.String2Clob('<?xml version="1.0"?><EMPLOYEES><EMP><EMPNO>7369</EMPNO><ENAME>SMITH</ENAME><JOB>CLERK</JOB><MGR>7902</MGR><HIREDATE>17-DEC-80</HIREDATE><SAL>800</SAL></EMP>
<EMP><EMPNO>7499</EMPNO><ENAME>ALLEN</ENAME><JOB>SALESMAN</JOB><MGR>7698</MGR><HIREDATE>20-FEB-81</HIREDATE><SAL>1600</SAL><COMM>300</COMM></EMP>
<EMP><EMPNO>7521</EMPNO><ENAME>WARD</ENAME><JOB>SALESMAN</JOB><MGR>7698</MGR><HIREDATE>22-FEB-81</HIREDATE><SAL>1250</SAL><COMM>500</COMM></EMP>
<EMP><EMPNO>7566</EMPNO><ENAME>JONES</ENAME><JOB>MANAGER</JOB><MGR>7839</MGR><HIREDATE>02-APR-81</HIREDATE><SAL>2975</SAL></EMP>
<EMP><EMPNO>7654</EMPNO><ENAME>MARTIN</ENAME><JOB>SALESMAN</JOB><MGR>7698</MGR><HIREDATE>28-SEP-81</HIREDATE><SAL>1250</SAL><COMM>1400</COMM></EMP>
<EMP><EMPNO>7698</EMPNO><ENAME>BLAKE</ENAME><JOB>MANAGER</JOB><MGR>7839</MGR><HIREDATE>01-MAY-81</HIREDATE><SAL>2850</SAL></EMP>
<EMP><EMPNO>7782</EMPNO><ENAME>CLARK</ENAME><JOB>MANAGER</JOB><MGR>7839</MGR><HIREDATE>09-JUN-81</HIREDATE><SAL>2450</SAL></EMP>
<EMP><EMPNO>7788</EMPNO><ENAME>SCOTT</ENAME><JOB>ANALYST</JOB><MGR>7566</MGR><HIREDATE>19-APR-87</HIREDATE><SAL>3000</SAL></EMP>
<EMP><EMPNO>7839</EMPNO><ENAME>KING</ENAME><JOB>PRESIDENT</JOB><HIREDATE>17-NOV-81</HIREDATE><SAL>5000</SAL></EMP>
<EMP><EMPNO>7844</EMPNO><ENAME>TURNER</ENAME><JOB>SALESMAN</JOB><MGR>7698</MGR><HIREDATE>08-SEP-81</HIREDATE><SAL>1500</SAL><COMM>0</COMM></EMP>
<EMP><EMPNO>7876</EMPNO><ENAME>ADAMS</ENAME><JOB>CLERK</JOB><MGR>7788</MGR><HIREDATE>23-MAY-87</HIREDATE><SAL>1100</SAL></EMP>
<EMP><EMPNO>7900</EMPNO><ENAME>JAMES</ENAME><JOB>CLERK</JOB><MGR>7698</MGR><HIREDATE>03-DEC-81</HIREDATE><SAL>950</SAL></EMP>
<EMP><EMPNO>7902</EMPNO><ENAME>FORD</ENAME><JOB>ANALYST</JOB><MGR>7566</MGR><HIREDATE>03-DEC-81</HIREDATE><SAL>3000</SAL></EMP>
<EMP><EMPNO>7934</EMPNO><ENAME>MILLER</ENAME><JOB>CLERK</JOB><MGR>7782</MGR><HIREDATE>23-JAN-82</HIREDATE><SAL>1300</SAL></EMP>
</EMPLOYEES>');

 dbms_output.put_line(substr(c,1,100));

  dbms_lob.freetemporary(c); 



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
    dbms_lob.freetemporary(c); 
end;
0
