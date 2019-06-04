PL/SQL Developer Test script 3.0
16
declare 
  i integer;
  p_task_spec sched.t_schedule_rec;
  p_due_date date;
begin
  p_task_spec.month:=11;
  p_task_spec.day:=12;  
  p_task_spec.hour:=13;
  p_task_spec.minute:=14;
  p_task_spec.state:='INITIAL';
  -- Call the function
  i := scheduler_due.calc_next_due_date(p_task_spec,
                                              sysdate,
                                              p_due_date);
  dbms_output.put_line(to_char(p_due_date,'YYYYMMDD HH:MI'));                                              
end;
0
0
