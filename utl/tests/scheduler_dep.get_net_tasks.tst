PL/SQL Developer Test script 3.0
27
-- Created on 27/10/2005 by GHOEKSTRA 
declare 
  -- Local variables here
  v_start   number;
  v_end     number;
  
  i integer;
  p_curr_net_tasks  sched.t_schedules;  -- Current accumulated set of tasks
  p_prev_net_tasks  sched.t_schedules;  -- Set of accumulated at previous recursion
  p_task_id  pls_integer:=9721;  
begin
  dbms_output.put_line('Start ');
  v_start := dbms_utility.get_time;

  -- Test statements here
  scheduler_dep.get_net_tasks(
    p_curr_net_tasks , 
    p_prev_net_tasks , 
    p_task_id);
  --  
  v_end := dbms_utility.get_time;
  dbms_output.put_line('Time taken : '||(v_end-v_start)/100||' seconds');
  
  for i in p_curr_net_tasks.first..p_curr_net_tasks.last loop
    dbms_output.put_line(p_curr_net_tasks(i).task_id);
  end loop;
end;
0
19
p_curr_net_tasks(1).task_id
p_curr_net_tasks(2).task_id
p_curr_net_tasks(3).task_id
p_curr_net_tasks(4).task_id
p_curr_net_tasks(5).task_id
p_prev_net_tasks(1).task_id
p_prev_net_tasks(2).task_id
p_prev_net_tasks(3).task_id
p_prev_net_tasks(4).task_id
p_prev_net_tasks(5).task_id
p_task_id
p_curr_pos
l_new_tasks(1).task_id
l_new_tasks(2).task_id
l_new_tasks(3).task_id
l_new_tasks(4).task_id
i
j
