CREATE OR REPLACE PACKAGE BODY utl.pkg_config is
------------------------------------------------------------------------
------------------------------------------------------------------------
--  Access to system-wide variables.
--
--  Allows querying, insertion and updating of system variables.
--
--  How system variables work:
--  ~~~~~~~~~~~~~~~~~~~~~~~~
--  All system variables are provided with a unique, CaSe-InSenSiTiVe name.
--  Against them can be attributed either an integer, float, date or string value.
--  The values live in table config in this schema.
--
--  Operating Philosophy: 
--  ~~~~~~~~~~~~~~~~~~~~
--  Only values that already exist can be updated - i.e. it is not possible 
--  to update a non-existent value. You have to add the value first using the 
--  add_variable_... function.
-- 
--  DO NOT "BEAUTIFY" THIS CODE !!!!!  
------------------------------------------------------------------------

------------------------------------------------------------------------
-- Adds a variable of one type
procedure add_variable (
  p_key                      in       config.variable%type,
                             -- Mandatory: Name of the system variable being added
  p_description              in       config.description%type,
                             -- Mandatory: Description of the variable being added
  p_integer_val              in       integer:=null,
                             -- Should be null if variable is not integer
  p_float_val                in       float:=null,
                             -- Should be null if variable is not float
  p_date_val                 in       date:=null,
                             -- Should be null if variable is not date
  p_varchar_val              in       varchar2:=null
                             -- Should be null if variable is not string
)
is
  pragma autonomous_transaction;
  v_count   pls_integer:=0;
begin
  if(p_integer_val is not null)then
    v_count:=v_count+1;
  end if;
  if(p_float_val is not null)then
    v_count:=v_count+1;
  end if;
  if(p_date_val is not null)then
    v_count:=v_count+1;
  end if;
  if(p_varchar_val is not null)then
    v_count:=v_count+1;
  end if;
  
  if(v_count>1)then
    --dbms_output.put_line('Cannot have more than one value attributed to a variable. Variable will not be added. Exiting.');
    return;
  end if;

  -- Check if this variable already exists
  select count(*) 
    into v_count
    from config
  where upper(p_key)=upper(variable);
  if(v_count>0)then
    --dbms_output.put_line('Variable already exists. Will not overwrite. Exiting.');
    return;
  end if;

  insert into config (
    variable,
    int_value,
    float_value,
    date_value,
    string_value,
    description,
    tmstmp)
  values (
    p_key,
    p_integer_val,
    p_float_val,
    p_date_val,
    p_varchar_val,
    p_description,
    sysdate);
  commit;
end add_variable;

------------------------------------------------------------------------
-- Adds an INTEGER variable
------------------------------------------------------------------------
procedure add_variable_int (
  p_key                        in       config.variable%type,
                             -- Name of the system variable being added
  p_integer_val                in       integer,
                             -- Value of integer variable
  p_description                in       config.description%type
                             -- Description of the variable being added
)
is
  pragma autonomous_transaction;
begin
  insert into config (
    variable,
    int_value,
    description,
    tmstmp)
  values (
    p_key,
    p_integer_val,
    p_description,
    sysdate);
  commit;
end add_variable_int;

------------------------------------------------------------------------
-- Adds a FLOAT variable
------------------------------------------------------------------------
procedure add_variable_float (
  p_key                        in       config.variable%type,
                             -- Name of the system variable being added
  p_float_val                  in       float,
                             -- Value of floating-point variable
  p_description                in       config.description%type
                             -- Description of the variable being added
)
is
  pragma autonomous_transaction;
begin
  insert into config (
    variable,
    float_value,
    description,
    tmstmp)
  values (
    p_key,
    p_float_val,
    p_description,
    sysdate);

  commit;

end add_variable_float;

------------------------------------------------------------------------
-- Adds a DATE variable
------------------------------------------------------------------------
procedure add_variable_date (
  p_key                        in       config.variable%type,
                             -- Name of the system variable being added
  p_date_val                   in       date,
                             -- Value of date variable
  p_description                in       config.description%type
                             -- Description of the variable being added
)
is
  pragma autonomous_transaction;
begin
  insert into config (
    variable,
    date_value,
    description,
    tmstmp)
  values (
    p_key,
    p_date_val,
    p_description,
    sysdate);

  commit;

end add_variable_date;

------------------------------------------------------------------------
-- Adds a VARCHAR2 variable
------------------------------------------------------------------------
procedure add_variable_string (
  p_key                        in       config.variable%type,
                             -- Name of the system variable being added
  p_varchar_val                in       varchar,
                             -- Value of string variable
  p_description                in       config.description%type
                             -- Description of the variable being added
)
is
  pragma autonomous_transaction;
begin
  insert into  config (
    variable,
    string_value,
    description,
    tmstmp)
  values (
    p_key,
    p_varchar_val,
    p_description,
    sysdate);
  commit;
end add_variable_string;

------------------------------------------------------------------------
-- Get an INTEGER variable
-- Will not override the original value if variable cannot be found
------------------------------------------------------------------------
function get_variable_int (
  p_key                        in       config.variable%type,
                             -- Name of the system variable
  p_integer_val                in out   integer
                             -- Value of integer variable
)
return boolean                -- Whether the variable was found to exist
is
  v_integer_val               integer;
begin
  select int_value
    into v_integer_val
    from config
   where lower(trim(variable)) = lower(p_key);
  if(v_integer_val is not null)then
    p_integer_val:=v_integer_val;
    return true;
  else
    return false;
  end if;
exception
  when others then
    return false;
end get_variable_int;

function get_variable_int(p_key in config.variable%type) return integer
is
  b boolean;
  i config.int_value%type;
begin
  b:=get_variable_int(p_key,i);
  return i;
end get_variable_int;


------------------------------------------------------------------------
-- Get a FLOAT variable
-- Will not override the original value if variable cannot be found
------------------------------------------------------------------------
function get_variable_float (
  p_key                        in       config.variable%type,
                             -- Name of the system variable
  p_float_val                  in out   float
                             -- Value of floating-point variable
)
return boolean               -- Whether the variable was found to exist
is
  v_float_val                float;
begin
  select float_value
    into v_float_val
    from  config
   where lower(trim(variable)) = lower(p_key);
  if(v_float_val is not null)then
    p_float_val:=v_float_val;
    return true;
  else
    return false;
  end if;
exception
  when others then
    return false;
end get_variable_float;

function get_variable_float(p_key in config.variable%type) return float
is
  b boolean;
  f config.float_value%type;
begin
  b:=get_variable_float(p_key,f);
  return f;
end get_variable_float;

-- Get a DATE variable
-- Will not override the original value if variable cannot be found
function get_variable_date (
  p_key                        in       config.variable%type,
                             -- Name of the system variable
  p_date_val                   in out   date
                             -- Value of date variable
)
return boolean                -- Whether the variable was found to exist
is
  v_date_val                  date;
begin
  select date_value
    into v_date_val
    from config
   where lower(trim(variable)) = lower(p_key);
  if(v_date_val is not null)then
    p_date_val:=v_date_val;
    return true;
  else
    return false;
  end if;
exception
  when others then
    return false;
end get_variable_date;

function get_variable_date(p_key in config.variable%type) return date
is
  b boolean;
  d config.date_value%type;
begin
  b:=get_variable_date(p_key,d);
  return d;
end get_variable_date;

------------------------------------------------------------------------
-- Get a VARCHAR2 variable
-- Will not override the original value if variable cannot be found
------------------------------------------------------------------------
function get_variable_string (
  p_key                        in       config.variable%type,
                             -- Name of the system variable
  p_varchar_val                in out   varchar
                             -- Value of string variable
)
return boolean                -- Whether the variable was found to exist
is
  v_varchar_val               config.string_value%type;
begin
  select string_value
    into v_varchar_val
    from config
   where lower(trim(variable)) = lower(p_key);
  if(v_varchar_val is not null)then
    p_varchar_val:=v_varchar_val;
    return true;
  else
    return false;
  end if;
exception
  when others then
    return false;
end get_variable_string;

function get_variable_string(p_key in config.variable%type) return varchar2
is
  b boolean;
  s config.string_value%type;
begin
  b:=get_variable_string(p_key,s);
  return s;
end get_variable_string;

------------------------------------------------------------------------
-- Sets a  configuration variable.
-- All values are by default autonomously committed.
------------------------------------------------------------------------
function set_variable_int_upd (
    p_Key in config.variable%type
  , p_Val in integer
  , p_change_reason in config.change_reason%type  
  ) return boolean
is
begin
  update config
     set int_value = p_Val,
         tmstmp = sysdate,
         change_reason = p_change_reason
   where lower(trim(variable)) = lower(p_Key);
  return SQL%FOUND;
end set_variable_int_upd;

function set_variable_int_auto (
    p_Key in config.variable%type
  , p_Val in integer
  , p_change_reason in config.change_reason%type  
  ) return boolean
is
  pragma autonomous_transaction;
begin
  if set_variable_int_upd(p_Key, p_Val,p_change_reason) then
    commit;
    return true;
  else
    rollback;
    return false;
  end if;
end set_variable_int_auto;

procedure set_variable_int (
    p_Key in config.variable%type
  , p_Val in integer
  , p_change_reason in config.change_reason%type:=null
  , p_AutoCommit in boolean:=true
)      
is
  b boolean;
begin
  if p_AutoCommit then
    b:=set_variable_int_auto(p_Key,p_Val,p_change_reason);
  else
    b:=set_variable_int_upd(p_Key,p_Val,p_change_reason);
  end if;
end set_variable_int;

------------------------------------------------------------------------
-- Sets a FLOAT variable
-- All values are by default autonomously committed
------------------------------------------------------------------------
function set_variable_float_upd (
    p_Key in config.variable%type
  , p_Val in float
  , p_change_reason in config.change_reason%type  
  ) return boolean
is
begin
  update config
     set float_value = p_Val,
         tmstmp = sysdate,
         change_reason = p_change_reason
   where lower(trim(variable)) = lower(p_Key);
  return SQL%FOUND;
end set_variable_float_upd;

function set_variable_float_auto (
    p_Key in config.variable%type
  , p_Val in float
  , p_change_reason in config.change_reason%type  
  ) return boolean
is
  pragma autonomous_transaction;
begin
  if set_variable_float_upd(p_Key, p_Val,p_change_reason) then
    commit;
    return true;
  else
    rollback;
    return false;
  end if;
end set_variable_float_auto;

procedure set_variable_float (
    p_Key in config.variable%type
  , p_Val in float
  , p_change_reason in config.change_reason%type:=null  
  , p_AutoCommit in boolean:=true
) 
is
  b boolean;
begin
  if p_AutoCommit then
    b:=set_variable_float_auto(p_Key,p_Val,p_change_reason);
  else
    b:=set_variable_float_upd(p_Key,p_Val,p_change_reason);
  end if;
end set_variable_float;

------------------------------------------------------------------------
-- Sets a DATE variable
-- All values are by default autonomously committed
------------------------------------------------------------------------
function set_variable_date_upd (
    p_Key in config.variable%type
  , p_Val in date
  , p_change_reason in config.change_reason%type  
  ) return boolean
is
begin
  update config
     set date_value = p_Val,
         tmstmp = sysdate,
         change_reason = p_change_reason
   where lower(trim(variable)) = lower(p_Key);  
  return SQL%FOUND;
end set_variable_date_upd;

function set_variable_date_auto (
    p_Key in config.variable%type
  , p_Val in date
  , p_change_reason in config.change_reason%type  
  ) return boolean
is
  pragma autonomous_transaction;
begin
  if set_variable_date_upd(p_Key, p_Val,p_change_reason) then
    commit;
    return true;
  else
    rollback;
    return false;
  end if;
end set_variable_date_auto;

procedure set_variable_date (
    p_Key in config.variable%type
  , p_Val in date
  , p_change_reason in config.change_reason%type:=null  
  , p_AutoCommit in boolean:=true
  ) 
is
  b boolean;
begin
  if p_AutoCommit then
    b:=set_variable_date_auto(p_Key,p_Val,p_change_reason);
  else
    b:=set_variable_date_upd(p_Key,p_Val,p_change_reason);
  end if;
end set_variable_date;

------------------------------------------------------------------------
-- Sets a VARCHAR2 variable
-- All values are by default autonomously committed
------------------------------------------------------------------------
function set_variable_string_upd (
    p_Key in config.variable%type
  , p_Val in varchar2
  , p_change_reason in config.change_reason%type
  ) return boolean
is
begin
  update config
     set string_value = p_Val,
         tmstmp = sysdate,
         change_reason = p_change_reason
   where lower(trim(variable)) = lower(p_Key);  
  return SQL%FOUND;
end set_variable_string_upd;

function set_variable_string_auto (
    p_Key in config.variable%type
  , p_Val in varchar2
  , p_change_reason in config.change_reason%type
  ) return boolean
is
  pragma autonomous_transaction;
begin
  if set_variable_string_upd(p_Key, p_Val,p_change_reason) then
    commit;
    return true;
  else
    rollback;
    return false;
  end if;
end set_variable_string_auto;

procedure set_variable_string (
    p_Key in config.variable%type
  , p_Val in varchar2
  , p_change_reason in config.change_reason%type:=null  
  , p_AutoCommit in boolean :=true
  )   
is
  b boolean;
begin
  if p_AutoCommit then
    b:=set_variable_string_auto(p_Key,p_Val,p_change_reason);
  else
    b:=set_variable_string_upd(p_Key,p_Val,p_change_reason);
  end if;
end set_variable_string;

-- Sets a variable value - assumes same data type as the existing variable's data type. 
-- If the data type is a date, then the date format is assumed to be in the specified GUI format,
-- which if not defined is 'DD-MOM-YY HH24:MI'.
-- If a value does not already exist then it
-- If this cannot be determined, then the datatype is assumed to be string.
procedure set_variable(p_Key in config.variable%type, 
                       p_Val in varchar2,
                       p_change_reason in config.change_reason%type)
is
  v_int_value     config.int_value%type;
  v_float_value   config.float_value%type;
  v_date_value    config.date_value%type;
  v_string_value  config.string_value%type;
  v_datatype      varchar2(10);
begin
  if(gc_datetime_format is null)then
    gc_datetime_format :=nvl(utl.pkg_config.get_variable_string(gc_config_key_datetimeformat),'DD-MOM-YY HH24:MI');
  end if;
  
  -- Get existing datatype
  select int_value,
         float_value,
         date_value,
         string_value,
         coalesce(decode(c.int_value,null,null,'INTEGER'),
           decode(c.float_value,null,null,     'FLOAT'),
           decode(c.date_value,null,null,      'DATE'),
           decode(c.string_value,null,null,    'STRING'),
           'UNDEFINED') datatype
    into v_int_value,v_float_value,v_date_value,v_string_value,v_datatype
    from config c
   where c.variable = p_Key;
  
  if(v_datatype='UNDEFINED')then
    -- Not previously populated: 
    -- Attempt to determine the data type from the value supplied
    begin
      v_date_value := to_date(p_Val,gc_datetime_format);
      v_datatype := 'DATE';
    exception
      when others then
        begin
          v_int_value := trunc(to_number(p_Val));          
          if(v_int_value = to_number(p_Val))then
            v_datatype := 'INTEGER';
          else
            v_float_value := to_number(p_Val);
            v_datatype := 'FLOAT';
          end if;
        exception 
          when others then 
            v_string_value := p_Val;
            v_datatype := 'STRING';
        end;
    end;
  end if;
  case 
    when (v_datatype='INTEGER') then set_variable_int(p_Key,trunc(to_number(p_Val)),p_change_reason);
    when (v_datatype='FLOAT')   then set_variable_float(p_Key,to_number(p_Val),p_change_reason);
    when (v_datatype='DATE')    then set_variable_date(p_Key,to_date(p_Val,gc_datetime_format),p_change_reason);
    else set_variable_string(p_Key,p_Val,p_change_reason);
  end case;
exception
  when others then
    utl.pkg_errorhandler.handle;
    utl.pkg_errorhandler.log_sqlerror(p_incident=>false);
    raise;    
end set_variable;

------------------------------------------------------------------------------
-- Get the modified date of a variable.
------------------------------------------------------------------------------
function get_modified_date (
  p_key       in config.variable%type
)
return date
is
  v_date     date;
begin
  select tmstmp
    into v_date
    from UTL.config
   where lower(variable) = lower(p_Key);
  return v_date;
exception
  when no_data_found then
     return null;
end get_modified_date;

------------------------------------------------------------------------------
-- GUI Interface
-- Returns a resultset:
--    Value Key       VARCHAR
--    Description     VARCHAR
--    Value           VARCHAR
--    LastChange      DATE
------------------------------------------------------------------------------
function get_count(p_variable  in config.variable%type) return integer is
  v_count integer;
  v_searchterm varchar2(100):=pkg_string.clean4query(p_variable);
begin
  dbms_application_info.set_module(pc_package||'.'||pc_schema||'.get_count', null);    
  select count(*)
    into v_count
    from config c
   where upper(c.variable) like v_searchterm||'%';
  dbms_application_info.set_module(null, null);      
  return v_count; 
exception
  when others then
    utl.pkg_errorhandler.handle;
    utl.pkg_errorhandler.log_sqlerror(p_incident=>false);
    raise;
end get_count;

-- Gets list of config variables that fit search term.
-- If no term specified, returns all of them.
-- We break long strings up with carriage returns and the client needs 
-- to be configured on how to deal with these.
function get_list(p_variable  in config.variable%type) return utl.global.t_result_set is
  cur_list utl.global.t_result_set;
  v_searchterm varchar2(100):=pkg_string.clean4query(p_variable);
begin
  dbms_application_info.set_module(pc_package||'.'||pc_schema||'.get_list', null);    
  if(gc_datetime_format is null)then
    gc_datetime_format :=nvl(utl.pkg_config.get_variable_string(gc_config_key_datetimeformat),'DD-MOM-YY HH24:MI');
  end if;
  
  open cur_list for
    select c.variable                                          "Value Key",
           coalesce(to_char(c.int_value), 
                    to_char(c.float_value), 
                    to_char(c.date_value,gc_datetime_format), 
                    c.string_value)                            "Value",
           coalesce(decode(c.int_value,null,null,   'INTEGER'),
                    decode(c.float_value,null,null, 'FLOAT'),
                    decode(c.date_value,null,null,  'DATE'),
                    decode(c.string_value,null,null,'STRING'),
                    'UNDEFINED')                               "ValueType",
           to_char(c.tmstmp,gc_datetime_format)                "Last change",
           utl.pkg_string.break_string(c.description)          "Description"                      
      from config c
     where upper(c.variable) like v_searchterm||'%'
     order by 1 asc;
  dbms_application_info.set_module(null, null);      
  return cur_list; 
exception
  when others then
    utl.pkg_errorhandler.handle;
    utl.pkg_errorhandler.log_sqlerror(p_incident=>false);
    raise;
end get_list;

-- 
function get_detail(p_variable  in config.variable%type) return utl.global.t_result_set is
  cur_detail utl.global.t_result_set;
begin
  dbms_application_info.set_module(pc_package||'.'||pc_schema||'.get_detail', null);    
  if(gc_datetime_format is null)then
    gc_datetime_format      :=nvl(utl.pkg_config.get_variable_string(gc_config_key_datetimeformat),'DD-MOM-YY HH24:MI');
  end if;

  open cur_detail for
    select c.variable                                           "Value Key",
           coalesce(to_char(c.int_value), 
                    to_char(c.float_value), 
                    to_char(c.date_value,gc_datetime_format), 
                    c.string_value)                             "Value",
           coalesce(decode(c.int_value,null,null,   'INTEGER'),
                    decode(c.float_value,null,null, 'FLOAT'),
                    decode(c.date_value,null,null,  'DATE'),
                    decode(c.string_value,null,null,'STRING'),
                    'UNDEFINED')                                "ValueType",                    
           to_char(c.tmstmp,gc_datetime_format)                 "Last change",                          
           utl.pkg_string.break_string(c.description)           "Description"                      
      from config c
     where c.variable = p_variable;
   return cur_detail;
exception
  when others then
    utl.pkg_errorhandler.handle;
    utl.pkg_errorhandler.log_sqlerror(p_incident=>false);
    raise;  
end get_detail;

-- GUI-convention to Update detail of a value. 
procedure update_detail(p_variable  in config.variable%type,
                        p_value   in varchar2,
                        p_description in varchar2,
                        p_change_reason in config.change_reason%type)
is
begin
  dbms_application_info.set_module(pc_package||'.'||pc_schema||'.update_detail', null); 
  
  set_variable(p_variable,p_value,p_change_reason);
  
  update config c
  set    c.description   = p_description,
         c.tmstmp        = sysdate,
         c.change_reason = p_change_reason
  where  c.variable      = p_variable
  and    c.description   != p_description;
  
  commit;
  
  dbms_application_info.set_module(null, null);   
exception
  when others then
    utl.pkg_errorhandler.handle;
    utl.pkg_errorhandler.log_sqlerror(p_incident=>false);
    raise;
end update_detail;

end pkg_config;
------------------------------------------------------------------------
-- end of file
------------------------------------------------------------------------
/
