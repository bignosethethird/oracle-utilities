create or replace package body
------------------------------------------------------------------------------
------------------------------------------------------------------------------
--  Utilities for date manipulation
------------------------------------------------------------------------------
    utl.pkg_date
as

--==================================================================--
-- DATE ANDS TIME FUNCTIONS
--==================================================================--

------------------------------------------------------------------------
-- Return minimum date of year i.e. 01-JAN-YYYY 00:00:00.
------------------------------------------------------------------------
function minimum_year_date(p_date in date)
return date
is
begin
  return to_date('01-01-'||to_char(p_date,'YYYY')||' 00:00:00','DD-MM-YYYY HH24:MI:SS');
end minimum_year_date;

------------------------------------------------------------------------
-- Return maximum date of year i.e. 31-DEC-YYYY 23:59:59 .
------------------------------------------------------------------------
function maximum_year_date(p_date in date)
return date
is
begin
  return to_date('31-12-'||to_char(p_date,'YYYY')||' 23:59:59','DD-MM-YYYY HH24:MI:SS');
end maximum_year_date;


------------------------------------------------------------------------
-- Is the date a leap year
------------------------------------------------------------------------
function is_leap_year(p_date in date) return boolean
is
  v_year pls_integer:=to_number(to_char(p_date,'YYYY'));
begin
  return is_leap_year(v_year);
end is_leap_year;

function is_leap_year(p_year in number) return boolean
is
begin
  if(mod(p_year,4)=0)then
    if(mod(p_year,400)=0)then
      return true;
    else
      if(mod(p_year,100)=0)then
        return false;
      else
        return true;
      end if;
    end if;
  else
    return false;
  end if;
end is_leap_year;

------------------------------------------------------------------------
-- Return year the last time this month occurred, based on present
-- Example: If today is 10MAY1999, the last year in which JUNE occurrend was 1998
------------------------------------------------------------------------
function last_month_year(p_month in number) return number
is
  v_sys_month number;
begin
  v_sys_month := to_number(to_char(sysdate,'MM'));
  if(v_sys_month<p_month)then
    return to_number(to_char(sysdate,'YYYY'))-1;
  else
    return to_number(to_char(sysdate,'YYYY'))-1;
  end if;
end last_month_year;

------------------------------------------------------------------------
-- Return the first day of the month for a given date
-- Example: If today is 10MAY1999, the returned date is 01MAY1999 00:00:00
------------------------------------------------------------------------
function first_second_month(p_date in date) return date is
begin
  return to_date(to_char(p_date,'YYYYMM')||'01000000','YYYYMMDDHH24MISS');
end first_second_month;

------------------------------------------------------------------------
-- Return the last day of the month for a given date
-- Similar to Oracle's LAST_DAY function, except that this provides the latest
-- time point in the day : 23:59:59.
-- Example: If today is 10MAY1999, the returned date is 31MAY1999 23:59:59
------------------------------------------------------------------------
function last_second_month(p_date in date) return date
is
  v_last_day    date;
begin
  v_last_day:=last_day(p_date);
  return to_date(to_char(v_last_day,'YYYYMMDD')||'235959','YYYYMMDDHH24MISS');
end last_second_month;

------------------------------------------------------------------------
-- Return the first time point of the day for a given date
-- Example: If today is 10MAY1999, the returned date is 10MAY1999 00:00:00
------------------------------------------------------------------------
function first_second_day(p_date in date) return date
is
begin
  return to_date(to_char(p_date,'YYYYMMDD')||'000000','YYYYMMDDHH24MISS');
end first_second_day;

------------------------------------------------------------------------
-- Return the last time point of the day for a given date
-- Example: If today is 10MAY1999, the returned date is 10MAY1999 23:59:59
------------------------------------------------------------------------
function last_second_day(p_date in date) return date
is
begin
  return to_date(to_char(p_date,'YYYYMMDD')||'235959','YYYYMMDDHH24MISS');
end last_second_day;

------------------------------------------------------------------------
-- Return the first time point of the hour in a given date
-- Example: If today is 10MAY1999 05:46, the returned date is 10MAY1999 05:00:00
------------------------------------------------------------------------
function first_second_hour(p_date in date) return date
is
begin
  return to_date(to_char(p_date,'YYYYMMDDHH24')||'0000','YYYYMMDDHH24MISS');
end first_second_hour;

------------------------------------------------------------------------
-- Return the last time point of the hour in a given date
-- Example: If today is 10MAY1999 05:46, the returned date is 10MAY1999 05:59:59
------------------------------------------------------------------------
function last_second_hour(p_date in date) return date
is
begin
  return to_date(to_char(p_date,'YYYYMMDDHH24')||'5959','YYYYMMDDHH24MISS');
end last_second_hour;

------------------------------------------------------------------------
-- Is this date the first of the month ?
------------------------------------------------------------------------
function is_first_month_day(p_date in date) return boolean is
begin
  return (to_number(to_char(p_date,'DD'))=1);
end is_first_month_day;

------------------------------------------------------------------------
-- Is this date the last of the month ?
------------------------------------------------------------------------
function is_last_month_day(p_date in date) return boolean is
begin
  return (to_char(p_date,'MM')<>to_char(p_date+1,'MM'));
end is_last_month_day;

-- Get national language independent ordinal day of the week, such
-- that Monday = 1, Tuesday = 2, ... Sunday =7
-- Note: There is no world-wide consensus what the first day of the week is!
function day_of_week(p_date in date) return pls_integer
is
begin
  return mod(to_char(p_date,'J'),7)+1;
end day_of_week;

-- Get UNIX-style ordinal day of the week, such
-- that Monday = 1, Tuesday = 2, ... Saturday=6, Sunday =0
function unix_day_of_week(p_date in date) return pls_integer
is
  day pls_integer:=mod(to_char(p_date,'J'),7)+1;
begin
  if(day=7)then return 0; end if;
  return day;
end unix_day_of_week;

------------------------------------------------------------------------
-- Is p_date a "week day" ?
------------------------------------------------------------------------
function is_week_day(p_date in date) return boolean
is
begin
  return (day_of_week(p_date) not in (6,7));
end is_week_day;

------------------------------------------------------------------------------
-- Calculate seconds since midnight as an integer from current time
------------------------------------------------------------------------------
function seconds_since_midnight(p_date in date)return pls_integer is
begin
  return to_number(to_char(p_date, gc_SSM_MASK));
end seconds_since_midnight;

----------------------------------------------------------------------
-- Calculate days since specified date from current time
-- Example: days_since_date(yesterday) = 1
----------------------------------------------------------------------
function days_since_date(p_date in date) return pls_integer is
begin
  return trunc(sysdate-p_date);
end days_since_date;

----------------------------------------------------------------------
-- Calculate the date after adding a number of whole weeks to the date.
----------------------------------------------------------------------
function add_weeks(p_date in date, p_weeks in pls_integer) return date
is
begin
  return p_date+(7*p_weeks);
end add_weeks;


----------------------------------------------------------------------
-- Calculate the date after adding a number of months to the date.
-- Where the resulting month does not accomodate the number of days,
-- the day value is reduced.
-- This is probably the most natural way in which one would want to
-- increment a date by a month
--
-- Example: add_months_shrink('20FEB2001',2) = '20APR2001' (added 2 months)
--          add_months_shrink('28FEB2001',2) = '28APR2001' (added 2 months)
--          add_months_shrink('31JAN2001',1) = '28FEB2001' (added 1 month but shrunk to fit in month)
--          add_months_shrink('28FEB2001',1) = '28MAR2001' (added  months)
--
-- This function behaves differently to Oracle's add_months, which is:
-- SQL> select add_months(to_date('28FEB2005'),1) from dual;
-- ---------
-- 31-MAR-05
function add_months_shrink(p_date in date, p_months in pls_integer) return date
is
  v_date date;
begin
  v_date:=add_months(p_date,p_months);
  -- Deal with the odd behaviour of add_months (e.g. 28FEB2004+1month)
  if(to_char(v_date,'DD')>to_char(p_date,'DD'))then
    v_date:=to_date(to_char(v_date,'YYYYMMHH24MI')||to_char(p_date,'DD'),'YYYYMMHH24MIDD');
  end if;
  return v_date;
end add_months_shrink;


----------------------------------------------------------------------
-- Calculate the date after adding a number of whole months to the date.
-- Adding a month to a the end date of a short month may return a date two
-- months hence:
--
-- Example: add_whole_months('20FEB2001',2) = '20APR2001' (added 28 days of FEB and 31 days of MAR)
--          add_whole_months('28FEB2001',2) = '28APR2001' (added 28 days of FEB and 31 days of MAR)
--          add_whole_months('31JAN2001',1) = '02MAR2001' (added 31 days of Jan)
function add_whole_months(p_date in date, p_months in pls_integer) return date
is
  v_date date:=p_date;
  -- Date lookup table
  type t_days is varray(12) of number;
  v_days_leap constant t_days := t_days(31,29,31,30,31,30,31,31,30,31,30,31);
  v_days_norm constant t_days := t_days(31,28,31,30,31,30,31,31,30,31,30,31);
  v_year      pls_integer;
  v_month     pls_integer;
begin
  if(p_months=0 or p_months is null)then
    return p_date;
  end if;
  for i in 1..abs(p_months) loop
    -- Work out current year
    v_year:=to_number(to_char(v_date,'YYYY'));
    -- Work out current month
    v_month:=to_number(to_char(v_date,'MM'));
    if(is_leap_year(v_year))then
      if(p_months>0)then
        v_date:=v_date+v_days_leap(v_month);
      else
        v_date:=v_date-v_days_leap(v_month);
      end if;
    else
      if(p_months>0)then
        v_date:=v_date+v_days_norm(v_month);
      else
        v_date:=v_date-v_days_norm(v_month);
      end if;
    end if;
  end loop;
  return v_date;
end add_whole_months;


----------------------------------------------------------------------
-- Calculate the date after adding a number of years to the date.
-- Where the resulting year does not accomodate the number of days,
-- the day value is reduced.
-- This is probably the most natural way in which one would want to
-- increment a date by one year.
--
-- Example: add_years_shrink('20FEB2001',1) = '20FEB2002' (added 1 year)
--          add_years_shrink('29FEB2004',4) = '28FEB2008' (added 4 years)
--
function add_years_shrink(p_date in date, p_years in pls_integer) return date
is
begin
  return add_months_shrink(p_date,p_years*12);
end add_years_shrink;

----------------------------------------------------------------------
-- Calculate the date after adding a number of hours to the date
function add_hours_shrink(p_date in date, p_hours in pls_integer) return date
is
begin
  return to_date(to_char(p_date,'YYYYMMDDHH24'),'YYYYMMDDHH24')+p_hours/gc_hours_per_day;
end add_hours_shrink;

----------------------------------------------------------------------
-- Calculate the date after adding a number of minutes to the date
function add_minutes_shrink(p_date in date, p_minutes in pls_integer) return date
is
begin
  return to_date(to_char(p_date,'YYYYMMDDHH24MI'),'YYYYMMDDHH24MI')+p_minutes/gc_mins_per_day;
end add_minutes_shrink;

-- determines either next or previous weekday for p_current_date
-- if p_direction  is positive the next weekday is returned
-- if p_direcction is negative the previous weekday is returned
function get_weekday(p_current_date in date, p_direction in integer) return date
as
  v_next_date date;
begin
  v_next_date := p_current_date + sign(p_direction);

  while (not is_week_day(v_next_date))
  loop
    v_next_date := v_next_date + sign(p_direction);
  end loop;

  return v_next_date;
exception
  when others then
	 utl.pkg_errorhandler.handle;
	 raise;
end get_weekday;

-- calculates the weekday p_direction days in advance or previous to p_current_date
function calc_weekday(p_current_date in date, p_direction in integer) return date
as
  v_next_date date;
begin
  v_next_date := p_current_date;
  
  for i in 1..abs(p_direction)
  loop
    v_next_date := get_weekday(v_next_date, p_direction/abs(p_direction));
  end loop;
  
  return v_next_date;
exception
  when others then
	 utl.pkg_errorhandler.handle;
	 raise;
end calc_weekday;

----------------------------------------------------------------------
-- Calculate the first 'working' day of the month from current time
-- Example: check_fwdom(SYSDATE) returns the date of the first working day
-- of the month
----------------------------------------------------------------------

FUNCTION check_fwdom(p_date IN date) RETURN DATE IS
   v_date          DATE;
   v_fwdom_found   BOOLEAN  := FALSE;
   v_count         INTEGER  := 0;
BEGIN
   WHILE v_fwdom_found = FALSE LOOP
      v_count := v_count + 1;
      -- using p_date we get the last day of the previous month
      -- and then increment this day by 1 until we find the
      -- first working day of the month.
      v_date := LAST_DAY(ADD_MONTHS(TRUNC(p_date),-1)) + v_count;
      --
      -- if the date is not Sat or Sun then we have found
      -- the first day of the month.
      IF TO_CHAR(v_date,'Dy') NOT IN ('Sat','Sun') THEN
         v_fwdom_found := TRUE;
      END IF;
      --
   END LOOP;
   --
   RETURN v_date;
   --
END check_fwdom;

-- Return days on month
function days_in_month(p_month in pls_integer, p_year in pls_integer:=to_char(sysdate,'YYYY')) return pls_integer
is
  c_proc_name       constant varchar2(100)  := pc_schema||'.'||pc_package||'.days_in_month';
  type t_days is varray(12) of number;
  v_days_norm constant  t_days := t_days(31,28,31,30,31,30,31,31,30,31,30,31);
begin
  if(p_month=2)then
    if(is_leap_year(to_date(p_year,'YYYY')))then
      return 29;
    else 
      return 28;
    end if;
  else
    return v_days_norm(p_month);
  end if;
exception 
  when others then 
    dbms_output.put_line('* Exception ['||sqlcode||'] in '||c_proc_name||'. Message ['||sqlerrm||']');
    return null;
end days_in_month;



end pkg_date;
------------------------------------------------------------------------------
-- end of file
------------------------------------------------------------------------------
/
