create or replace package body 
------------------------------------------------------------------------
------------------------------------------------------------------------
--  String and String Array functions
------------------------------------------------------------------------
    utl.pkg_string
as

------------------------------------------------------------------------------
-- Double up quotes and wrap with two more single quotes.
-- A null ends up as '', or 'NULL' if p_null_text is TRUE
procedure enquote (
  p_string                  in out  varchar2,
  p_null_text               in      boolean := false
) is
  c_proc_name   constant varchar2(100)  := pc_schema||'.'||pc_package||'.enquote';
begin
  if(p_string is null and p_null_text=true) then
    p_string := 'NULL';
  else
    p_string := replace (p_string, gc_single_quote, gc_double_quote);
    p_string := gc_single_quote || p_string || gc_single_quote;
  end if;
exception
  when others then
    dbms_output.put_line('* Exception ['||sqlcode||'] in '||pc_schema||'.'||pc_package||'.enquote. Message ['||sqlerrm||']');
    p_string:=null;
end enquote;

function  enquote(p_string in  varchar2, p_null_text in boolean := false) return varchar2 is
  s varchar2(4000);
begin
  s:=p_string;
  enquote(s,p_null_text);
  return s;
end enquote;

------------------------------------------------------------------------------
-- Removes all quotes from a string
procedure dequote (
  p_string        in out  varchar2,
  p_inside_string in      boolean := false
) is
  c_proc_name   constant varchar2(100)  := pc_schema||'.'||pc_package||'.dequote';
  v_a_char char;
begin
  if p_string is null then return; end if;
  if(p_inside_string)then
    -- check first character
    v_a_char := substr (p_string, 1, 1);
    if v_a_char <> gc_single_quote then
      p_string:=null;
      return;
    end if;
    -- check last character
    v_a_char := substr (p_string, -1, 1);
    if v_a_char <> gc_single_quote then
      p_string:=null;
      return;
    end if;
  end if;

  -- Remove two single quotes - hopefully the first and last character
  p_string := substr (p_string, 2, length (p_string) - 2) ;

  -- check that no more single quotes inside string
  if(p_inside_string)then
    declare
      v_string_length pls_integer := length (p_string);
      v_string_index  pls_integer := 1;
    begin
      while v_string_index <= v_string_length loop
        if(substr (p_string, v_string_index, 1)=gc_single_quote)then
          if((v_string_index = v_string_length)
             or substr (p_string, v_string_index + 1, 1) <> gc_single_quote)
          then
             -- embedded single quote
             return;
          else
             -- skip doubled quotes
             v_string_index := v_string_index + 1;
          end if;
        end if;
        -- next character
        v_string_index := v_string_index + 1;
      end loop;
    end;
  end if;
  -- remove all double quotes from result
  p_string := replace (p_string, gc_double_quote, gc_single_quote);
exception
  when others then
    dbms_output.put_line('* Exception ['||sqlcode||'] in '||pc_schema||'.'||pc_package||'.dequote. Message ['||sqlerrm||']');
    p_string:=null;
end dequote;

function dequote(p_string in varchar2, p_inside_string in boolean := false) return varchar2 is
  s varchar2(4000);
begin
  s:=p_string;
  dequote(s,p_inside_string);
  return s;
end dequote;

------------------------------------------------------------------------
-- Remove last trailing X (default 1) chars from string, regardless of whether it is a char or new line
procedure chop(p_string in out varchar2,p_number in number := 1) is
begin
  p_string:=substr(p_string,1,length(p_string)-p_number);
end chop;

------------------------------------------------------------------------
-- Remove trailing new-line chars from string
procedure chomp(p_string in out varchar2) is
  v_last_char varchar2(1);
begin
  v_last_char:=substr(p_string,length(p_string));
  while(v_last_char=gc_nl or v_last_char=gc_cr)  loop
    p_string:=substr(p_string,1,length(p_string)-1);
    v_last_char:=substr(p_string,length(p_string));
  end loop;
end chomp;


------------------------------------------------------------------------------
-- Parses a comma-separated list into a table of varchar
-- and dequotes string elements
-- Only works when a single character is used as a separator.
function string2list(
  p_string              in    varchar2,
  p_separator           in    varchar2:=gc_comma
) return dbms_sql.varchar2s
is
  c_proc_name   constant varchar2(100)  := pc_schema||'.'||pc_package||'.string2list';
  v_item_count          pls_integer := 0;
  v_string_tab          dbms_sql.varchar2s;
  v_string_length       pls_integer := length (p_string);
  v_string_index        pls_integer := 1;
  v_item_index          pls_integer := 1;    -- start of current item
  v_current_char        char;
  v_single_quote_flag   boolean := false;
  v_double_quotes_flag  boolean := false;
begin
  -- find each *unquoted* comma and break item at comma
  while v_string_index <= v_string_length loop
     v_current_char := substr (p_string, v_string_index, 1);
     if v_current_char = gc_single_quote then
        if v_double_quotes_flag then
           -- second of a pair of quotes
           v_double_quotes_flag := false;
        elsif v_string_index != v_string_length
              and substr (p_string, v_string_index + 1, 1) <> gc_single_quote
        then
          -- flag double quotes
          v_double_quotes_flag := true;
        else
           -- start or end of a string
           v_single_quote_flag := not v_single_quote_flag;
        end if;
     end if;

     if(v_current_char = p_separator)
        and not v_single_quote_flag
     then
        -- item then a comma
        v_item_count := v_item_count + 1;
        v_string_tab (v_item_count) := ltrim(substr (p_string, v_item_index, v_string_index - v_item_index));
        v_item_index := v_string_index + 1;
        -- trailing quote - a null item
        if v_string_index = v_string_length then
           v_item_count := v_item_count + 1;
           v_string_tab (v_item_count) := null;
        end if;
     elsif v_string_index = v_string_length then
        -- item then end of string
        v_item_count := v_item_count + 1;
        v_string_tab (v_item_count) := ltrim(substr (p_string, v_item_index, v_string_index - v_item_index + 1));
     end if;
     v_string_index := v_string_index + 1;
  end loop;
  return v_string_tab;
exception
  when others then
    --dbms_output.put_line('* Exception ['||sqlcode||'] in '||pc_schema||'.'||pc_package||'.string2list. Message ['||sqlerrm||']');
    return v_string_tab;
end string2list;

------------------------------------------------------------------------------
-- Makes a varchar2 list into a comma-separated string
function list2string(
  p_list          in       dbms_sql.varchar2s,
  p_separator     in       varchar2:=','
) return varchar2
is
  c_proc_name   constant varchar2(100)  := pc_schema||'.'||pc_package||'.list2string';
  v_string varchar2(4000);
  v_string_item varchar2(4000);
  v_index  number;
begin
  -- Iterate through string
  v_index:=p_list.first;
  while(v_index is not null)loop
    v_string_item:=p_list(v_index);
    if(length(v_string_item)+nvl(length(v_string),0)<4000)then
      if(v_string is not null)then
        v_string:=v_string||p_separator||v_string_item;
      else
        v_string:=v_string_item;
      end if;
    end if;
    v_index:=p_list.next(v_index);
  end loop;
  return v_string;
exception
  when others then
    --dbms_output.put_line('* Exception ['||sqlcode||'] in '||pc_schema||'.'||pc_package||'.list2string. Message ['||sqlerrm||']');
    return v_string;
end list2string;

-- Makes a number list into a comma-separated string
function numlist2string(
  p_list          in       dbms_sql.number_table,
  p_separator     in       varchar2:=','
) return varchar2
is
  c_proc_name   constant varchar2(100)  := pc_schema||'.'||pc_package||'.numlist2string';
  v_string varchar2(4000);
  v_string_item varchar2(4000);
  v_index  number;
begin
  -- Iterate through string
  v_index:=p_list.first;
  while(v_index is not null)loop
    v_string_item:=p_list(v_index);
    if(length(v_string_item)+nvl(length(v_string),0)<4000)then
      if(v_string is not null)then
        v_string:=v_string||p_separator||v_string_item;
      else
        v_string:=v_string_item;
      end if;
    end if;
    v_index:=p_list.next(v_index);
  end loop;
  return v_string;
exception
  when others then
    dbms_output.put_line('* Exception ['||sqlcode||'] in '||pc_schema||'.'||pc_package||'.numlist2string. Message ['||sqlerrm||']');
    return v_string;
end numlist2string;


-- Parses a comma-separated list into a table of varchar
-- and dequotes string elements
function string2varchar2_table(
  p_string        in      varchar2,
  p_separator     in      varchar2:=gc_comma
) return dbms_sql.varchar2_table
is
  c_proc_name   constant varchar2(100)  := pc_schema||'.'||pc_package||'.string2varchar2_table';
  v_lst     dbms_sql.varchar2s;
  v_tab     dbms_sql.varchar2_table;
  v_index   pls_integer;
begin
  v_lst:=string2list(p_string,p_separator);
  -- Copy list to table
  v_index:=v_lst.first();
  while(v_index is not null)loop
    v_tab(v_index):=v_lst(v_index);
    v_index:=v_lst.next(v_index);
  end loop;
  return v_tab;
exception
  when others then
    --dbms_output.put_line('* Exception ['||sqlcode||'] in '||pc_schema||'.'||pc_package||'.string2varchar2_table. Message ['||sqlerrm||']');
    return v_tab;
end string2varchar2_table;

-- Parses a comma-separated list into a table of numbers
-- Any non-numeric items will be ignored
function string2number_table(p_string in varchar2,p_separator in varchar2:=gc_comma) return dbms_sql.number_table
is
  c_proc_name   constant varchar2(100)  := pc_schema||'.'||pc_package||'.string2number_table';
  v_lst     dbms_sql.varchar2s;
  v_tab     dbms_sql.number_table;
  v_index   pls_integer;
  v_target  pls_integer:=1;
begin
  v_lst:=string2list(p_string,p_separator);  
  -- Copy list to table
  v_index:=v_lst.first();
  while(v_index is not null)loop
    begin
      v_tab(v_target):=to_number(v_lst(v_index));      
      v_target:=v_target+1;      
    exception
      when others then
        null;
    end;    
    v_index:=v_lst.next(v_index);
  end loop;
  return v_tab;
exception
  when others then
    --dbms_output.put_line('* Exception ['||sqlcode||'] in '||pc_schema||'.'||pc_package||'.string2number_table. Message ['||sqlerrm||']');
    return v_tab;
end string2number_table;

-- Only on Oracle 10g
/*
function string2binary_double_table(p_string in varchar2,p_separator in varchar2:=gc_comma) return dbms_sql.binary_double_table
is
  c_proc_name   constant varchar2(100)  := pc_schema||'.'||pc_package||'.string2binary_double_table';
  v_lst     dbms_sql.varchar2s;
  v_tab     dbms_sql.binary_double_table;
  v_index   pls_integer;
  v_target  pls_integer:=1;
begin
  v_lst:=string2list(p_string,p_separator);  
  -- Copy list to table
  v_index:=v_lst.first();
  while(v_index is not null)loop
    begin
      v_tab(v_target):=to_number(v_lst(v_index));      
      v_target:=v_target+1;      
    exception
      when others then
        null;
    end;    
    v_index:=v_lst.next(v_index);
  end loop;
  return v_tab;
exception
  when others then
    dbms_output.put_line('* Exception ['||sqlcode||'] in '||pc_schema||'.'||pc_package||'.string2number_table. Message ['||sqlerrm||']');
    return v_tab;
end string2binary_double_table;
*/

------------------------------------------------------------------------------
-- Makes a string list into a comma-separated string
function table2string(
  p_table        in       dbms_sql.varchar2_table,
  p_separator    in       varchar2:=','
) return varchar2
is
  c_proc_name   constant varchar2(100)  := pc_schema||'.'||pc_package||'.table2string';
  v_string varchar2(4000);
  v_string_item varchar2(4000);
  v_index  number;
begin
  -- Iterate through string
  v_index:=p_table.first;
  while(v_index is not null)loop
    v_string_item:=p_table(v_index);
    if(length(v_string_item)+nvl(length(v_string),0)<4000)then
      if(v_string is not null)then
        v_string:=v_string||p_separator||v_string_item;
      else
        v_string:=v_string_item;
      end if;
    end if;
    v_index:=p_table.next(v_index);
  end loop;
  return v_string;
exception
  when others then
    --dbms_output.put_line('* Exception ['||sqlcode||'] in '||pc_schema||'.'||pc_package||'.table2string. Message ['||sqlerrm||']');
    return v_string;
end table2string;

------------------------------------------------------------------------------
-- Makes a number list into a comma-separated string
function numtable2string(
  p_table        in       dbms_sql.number_table,
  p_separator    in       varchar2:=','
) return varchar2
is
  c_proc_name   constant varchar2(100)  := pc_schema||'.'||pc_package||'.numtable2string';
  v_string varchar2(4000);
  v_string_item varchar2(4000);
  v_index  number;
begin
  -- Iterate through string
  v_index:=p_table.first;
  while(v_index is not null)loop
    v_string_item:=to_char(p_table(v_index));
    if(length(v_string_item)+nvl(length(v_string),0)<4000)then
      if(v_string is not null)then
        v_string:=v_string||p_separator||v_string_item;
      else
        v_string:=v_string_item;
      end if;
    end if;
    v_index:=p_table.next(v_index);
  end loop;
  return v_string;
exception
  when others then
    --dbms_output.put_line('* Exception ['||sqlcode||'] in '||pc_schema||'.'||pc_package||'.numtable2string. Message ['||sqlerrm||']');
    return v_string;
end numtable2string;

------------------------------------------------------------------------------
-- Converts a string table to a ref cursor / recordset
function table2recordset(
  p_table       in  dbms_sql.varchar2_table,
  p_resultset   out UTL.global.t_result_set
) return UTL.global.t_error_code
is
  c_proc_name   constant varchar2(100)  := pc_schema||'.'||pc_package||'.table2recordset';
  v_retcode       global.t_error_code:= pkg_exceptions.gc_undefined;
  v_temp_table    varchar2(20);
  v_sql           varchar2(100);
  i               pls_integer;
begin
  -- Alas, we need to create a temp table to put the list in,
  -- and then select from it to form a recordset
  v_temp_table:=pkg_temp.create_temp_table4cols('item_no number, item varchar2(255)');
  if(v_temp_table is not null)then
    i:=p_table.first();
    while(i is not null)loop
      v_sql:='insert into '||v_temp_table||'(item_no,item) values ('||i||','''||p_table(i)||''')';
      execute immediate v_sql;
      i:=p_table.next(i);
    end loop;
    -- Get this into a nice record set
    open p_resultset for 'select item from '||v_temp_table||' order by item_no';
    execute immediate 'drop table '||v_temp_table;
    v_retcode:=pkg_exceptions.gc_success;
  end if;
  return v_retcode;
exception
  when others then
    --dbms_output.put_line('* Exception ['||sqlcode||'] in '||pc_schema||'.'||pc_package||'.table2recordset. Message ['||sqlerrm||']');
    if(v_temp_table is not null)then
      execute immediate 'drop table '||v_temp_table;
    end if;
    return sqlcode;
end table2recordset;

/*
----------------------------------------------------------------------------
-- Converts a number list to a ref cursor / recordset
function table2recordset(
  p_list        in  dbms_sql.number_table,
  p_resultset   out UTL.error.t_result_set
) return UTL.error.t_error_code
is
  v_retcode       error.t_error_code:= error.gc_undefined;
  v_temp_table    varchar2(20);
  v_sql           varchar2(100);
  i               pls_integer;
begin
  -- Alas, we need to create a temp table to put the list in,
  -- and then select from it to form a recordset
  v_temp_table:=temp.create_temp_table('item_no number, item number');
  if(v_temp_table is not null)then
    i:=p_list.first();
    while(i is not null)loop
      v_sql:='insert into '||v_temp_table||'(item_no,item) values ('||i||','||p_list(i)||')';
      execute immediate v_sql;
      i:=p_list.next(i);
    end loop;
    -- Get this into a nice record set
    open p_resultset for 'select item from '||v_temp_table||' order by item_no';
    execute immediate 'drop table '||v_temp_table;
    v_retcode:=error.gc_success;
  end if;
  return v_retcode;
exception
  when others then
    dbms_output.put_line('* Exception ['||sqlcode||'] in '||pc_schema||'.'||pc_package||'.numberlist2recordset. Message ['||sqlerrm||']');
    if(v_temp_table is not null)then
      execute immediate 'drop table '||v_temp_table;
    end if;
    return sqlcode;
end table2recordset;
*/

------------------------------------------------------------------------------
-- Breaks up the long input string into nice chunks of specified length
-- in a string table dbms_sql.varchar2s.
-- Attempts to break on white space between words. If no white space space
-- or resulting string is about to become to short, then hard-break on
-- required line width.
-- Mandatory break when a line-feed character has been encountered
-- Multiple lines can be broken up and added to the same line by reusing
-- the p_line_count variable.
function break_string(
  p_string                in   varchar2,                        -- The long string to break up
  p_strings               in   out  nocopy dbms_sql.varchar2s,  -- String table
  p_line_count            in   out  pls_integer,                -- Start point in string table, usually 1.
                                                                -- Returns the final number of strings in the string table.
  p_prolog                in   varchar2:=null,                  -- Add this in front of every string
  p_width                 in   integer := 60                    -- Desired string width including width of prolog
)
return global.t_error_code
is
  c_proc_name   constant varchar2(100)  := pc_schema||'.'||pc_package||'.break_string';
  v_line_width            pls_integer;      -- Actual line width
  v_des_line_width        pls_integer := p_width-nvl(length(p_prolog),0); -- Desired line width
  v_pos                   pls_integer := 1;
  v_len                   pls_integer;
  v_newline_pos           pls_integer;
  v_no_break_found        boolean;
  v_retcode               global.t_error_code:=pkg_exceptions.gc_success;
begin
  v_len := length(p_string);
  p_line_count := nvl(p_line_count,1);
  if (p_line_count<1)then 
    p_line_count:=1; 
  end if;

  -- break up
  while (v_pos <= v_len)  loop
    -- Look for new-line char before proposed line end
    v_newline_pos:=instr(p_string, chr(10), v_pos);
    if(v_newline_pos>0 and v_newline_pos<(v_pos+v_des_line_width))then
      -- Found one - break here
      p_strings(p_line_count) := p_prolog||trim(substr(p_string, v_pos, v_newline_pos-v_pos));
      v_pos := v_newline_pos+1;
    else
      -- Look for a convenient line break
      -- Calculate optimal line width approximating p_width
      -- in such a way that no words are broken (eg look for white space)    
      v_line_width := v_des_line_width;
      v_no_break_found:=false;
      while(substr(p_string, v_line_width + v_pos, 1)<>' ') loop        
        v_line_width := v_line_width - 1;
        -- Stop this when the lines become too short
        if(v_line_width < (p_width / 4))then
          v_no_break_found:=true;
          exit;
        end if;        
      end loop;
      if(v_no_break_found)then
        -- Could not find a line break, so use the entire line
        v_line_width:=v_des_line_width;
      end if;
      
  
      -- If less than 8 characters remaining after this,
      -- add the last bit to this line and do not continue
      --if((v_len-v_pos-v_line_width)<=8)then
      --  v_line_width := v_line_width+v_len-v_pos;
      --end if;
  
      p_strings(p_line_count) := p_prolog||trim(substr(p_string, v_pos, v_line_width));
      v_pos := v_pos + v_line_width;
    end if;
    p_line_count := p_line_count + 1;
  end loop;

  p_line_count := p_line_count - 1;
  return v_retcode;
exception
  when others then
     --dbms_output.put_line('* Exception ['||sqlcode||'] in '||c_proc_name||'. Message ['||sqlerrm||']');
     return sqlcode;
end break_string;


-- Breaks up the long input string into nice chunks of specified length
-- and spearates each chunk with the indicated separator string - usually
-- a carriage return.
function break_string(
  p_string                in   varchar2,                        -- The long string to break up
  p_separator             in   varchar2:=chr(10),               -- String separator
  p_width                 in   integer := 60                    -- Desired string width
) return varchar2
is
  l_strings dbms_sql.varchar2s;
  v_line_count pls_integer;
  v_return_string varchar2(32000);
begin
  if(break_string(p_string,l_strings,v_line_count,null,p_width)=pkg_exceptions.gc_success)then
    for i in l_strings.first..l_strings.last loop
      if(i=1)then
        v_return_string:=l_strings(i);
      else
        v_return_string:=v_return_string||p_separator||l_strings(i);
      end if;
    end loop;
    return v_return_string;
  else
    return p_string;
  end if;
exception
  when others then
    return null;
end break_string;


------------------------------------------------------------------------
-- Dumps the contents of the table to the indicated file path.
-- If file is not indicated, a timestamped filename in the directory
-- specified in the System Variable "Dump Path" will be created, and the
-- contents will be written to it.
-- The parameter p_file_name must be a fully qualified file and path name.
-- Note:
-- The path (wether specified on the command line or in the parameter directory),
--  must also exist in the INIT.ORA file, in the form:
-- UTL_FILE_DIR=[OS file directory name]
-- TODO:
-- Use BFILE declaration instead.
procedure table2file(
  p_table     in dbms_sql.varchar2s,
  p_file_name in varchar2 := null
)is
  c_proc_name             constant varchar2(100) := pc_schema||'.'||pc_package||'.'||'table2file';
  v_dump_path             varchar2(100);
  v_dump_file_handle      utl_file.file_type;
  v_dump_file             varchar2(100);
  v_got_path              boolean := false;
  v_dbms_output           boolean := true;
  v_pos                   pls_integer;
begin
  -- Get file path
  if(p_file_name is null)then
    v_dump_path:=pkg_config.get_variable_string('TableDumpPath');
    -- Make up file name
    v_dump_file:=to_char(sysdate,'YYYYMMDDHH24MISS')||'.dmp';
  else
    -- Use specified p_file_name
    -- TODO: Ensure that a UTL_FILE entry is working
    -- Get path from file path
    v_pos:=instr(p_file_name,'/',-1);
    if(v_pos is not null)then
      v_dump_path:=substr(p_file_name,1,v_pos-1);
      v_dump_file:=substr(p_file_name,v_pos);
      v_got_path:=true;
    end if;
  end if;

  if(v_got_path)then
    begin
      v_dump_file_handle  := utl_file.fopen(v_dump_path, v_dump_file,'w');
      if(utl_file.is_open(v_dump_file_handle)) then
        for i in 1..p_table.count loop
          utl_file.put_line(v_dump_file_handle, p_table(i));
          -- Occasionally flush file
          if(mod(i,100)=0)then
            utl_file.fflush(v_dump_file_handle);
          end if;
        end loop;
        utl_file.fflush(v_dump_file_handle);
        utl_file.fclose(v_dump_file_handle);
        v_dbms_output := false;
      end if;
    exception
      when others then
        v_dbms_output := true;
    end;
  else
    v_dbms_output := true;
  end if;


  if(v_dbms_output)then
    dbms_output.put_line('* BEGIN DUMP *');
    for i in 1..p_table.count loop
      dbms_output.put_line(p_table(i));
    end loop;
    dbms_output.put_line('* END DUMP *');
  end if;
exception
  when others then
    --dbms_output.put_line('* Exception ['||sqlcode||'] in '||c_proc_name||'. Message ['||sqlerrm||']');
    -- TODO: Clean up the file
    null;
end table2file;

------------------------------------------------------------------------------
-- Number format will be in default format
procedure numtable2file(
  p_table in dbms_sql.number_table, 
  p_file_name in varchar2 := null
)is
  c_proc_name             constant varchar2(100) := pc_schema||'.'||pc_package||'.'||'numtable2file';
  v_dump_path             varchar2(100);
  v_dump_file_handle      utl_file.file_type;
  v_dump_file             varchar2(100);
  v_got_path              boolean := false;
  v_dbms_output           boolean := true;
  v_pos                   pls_integer;
begin
  -- Get file path
  if(p_file_name is null)then
    v_dump_path:=pkg_config.get_variable_string('TableDumpPath');
    if(v_dump_path is not null)then
      v_got_path:=true;
    end if;
    -- Make up file name
    v_dump_file:=to_char(sysdate,'YYYYMMDDHH24MISS')||'.dmp';
  else
    -- Use specified p_file_name
    -- TODO: Ensure that a UTL_FILE entry is working
    -- Get path from file path
    v_pos:=instr(p_file_name,'/',-1);
    if(v_pos is not null)then
      v_dump_path:=substr(p_file_name,1,v_pos-1);
      v_dump_file:=substr(p_file_name,v_pos);
      v_got_path:=true;
    end if;
  end if;

  if(v_got_path)then
    begin
      v_dump_file_handle  := utl_file.fopen(v_dump_path, v_dump_file,'w');
      if(utl_file.is_open(v_dump_file_handle)) then
        for i in 1..p_table.count loop
          utl_file.put_line(v_dump_file_handle, to_char(p_table(i)));
          -- Occasionally flush file
          if(mod(i,100)=0)then
            utl_file.fflush(v_dump_file_handle);
          end if;
        end loop;
        utl_file.fflush(v_dump_file_handle);
        utl_file.fclose(v_dump_file_handle);
        v_dbms_output := false;
      end if;
    exception
      when others then
        v_dbms_output := true;
    end;
  else
    v_dbms_output := true;
  end if;


  if(v_dbms_output)then
    dbms_output.put_line('* BEGIN DUMP *');
    for i in 1..p_table.count loop
      dbms_output.put_line(to_char(p_table(i)));
    end loop;
    dbms_output.put_line('* END DUMP *');
  end if;
exception
  when others then
    --dbms_output.put_line('* Exception ['||sqlcode||'] in '||c_proc_name||'. Message ['||sqlerrm||']');
    -- TODO: Clean up the file
    null;
end numtable2file;

------------------------------------------------------------------------------
-- Is this char whitespace? (space, tab, newline, other wierd stuff)
function is_whitespace(p_char in varchar2)
return boolean
is
begin
  -- return (substr(p_char, 1, 1) in (gc_space, gc_tab, gc_nl));
  return ascii(p_char) <= 32;
end is_whitespace;

-- Cleans string for query
-- Removes non-alpha numeric characters, except for the '%','*' and '?',
-- which may have been entered as wild card characters.
-- Makes the string input string UPPER CASE and removes leading and trailing spaces.
function clean4query(
  p_string    in  varchar2
) return varchar2
is
  c_proc_name   constant varchar2(100)  := pc_schema||'.'||pc_package||'.clean4query';
  v_string      varchar2(1000);
  v_last_length pls_integer;
  cv_from       constant varchar2(80):='ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789*?%`!"''£$^()_+-=/#~@]}[{><;:|¬.,'||chr(38)||chr(47);
  -- Leave off the chars that we do not want to keep
  cv_to         constant varchar2(60):='ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789*?%';
begin  
  -- Clean input query string
  v_string:=trim(upper(p_string));
  -- Remove unwanted chars and replace * with %
  v_string:=translate(v_string,cv_from,cv_to);
  -- Exit when nothing left
  if(v_string is null)then return null; end if;
  -- Replace '*' with '%'
  v_string:=replace(v_string,'*','%'); 
  -- Deal with nonsense '?' mixed with '%' and '*'
  --if(instr(v_string,'?')>0 and instr(v_string,'%')>0)then
  --  v_string:=replace(v_string,'?','%');
  --end if; 
  -- Special case of Ampersand, as we do not like to type it in PLSQL code
  v_string:=replace(v_string,gc_ampersand);
  -- Remove resulting artifacts
  v_last_length:=length(v_string);
  loop
    v_string:=replace(v_string,'%%','%');
    v_string:=replace(v_string,'  ',' ');
    exit when (length(v_string)=v_last_length);
    v_last_length:=length(v_string);
  end loop;

  return v_string;
exception
  when others then
    --dbms_output.put_line('* Exception ['||sqlcode||'] in '||c_proc_name||'. Message ['||sqlerrm||']');
    return null;
end clean4query;

-- Cleans alpha-numerical string
function clean4alphanum(
  p_string    in  varchar2
) return varchar2
is
  c_proc_name   constant varchar2(100)  := pc_schema||'.'||pc_package||'.clean4alphanum';
  v_string      varchar2(1000);
  v_last_length pls_integer;
  cv_from       constant varchar2(80):='ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789*?%`!"''£$^()_+-=/#~@]}[{><;:|¬., '||chr(38)||chr(47);
  -- Leave off the chars that we do not want to keep
  cv_to         constant varchar2(60):='ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
begin
  if(p_string is null)then return null; end if;
  -- Clean input query string
  v_string:=trim(upper(p_string));
  -- Remove unwanted chars and replace * with %
  v_string:=translate(v_string,cv_from,cv_to);
  return v_string;
exception
  when others then
    --dbms_output.put_line('* Exception ['||sqlcode||'] in '||c_proc_name||'. Message ['||sqlerrm||']');
    return null;
end clean4alphanum;

-- Cleans for an alphabetical string only
function clean4alpha(p_string    in  varchar2) return varchar2
is
  c_proc_name   constant varchar2(100)  := pc_schema||'.'||pc_package||'.clean4alpha';
  v_string      varchar2(1000);
  v_last_length pls_integer;
  cv_from       constant varchar2(80):='ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789*?%`!"''£$^()_+-=/#~@]}[{><;:|¬., '||chr(38)||chr(47);
  -- Leave off the chars that we do not want to keep
  cv_to         constant varchar2(60):='ABCDEFGHIJKLMNOPQRSTUVWXYZ';
begin
  if(p_string is null)then return null; end if;
  -- Clean input query string
  v_string:=trim(upper(p_string));
  -- Remove unwanted chars and replace * with %
  v_string:=translate(v_string,cv_from,cv_to);
  return v_string;
exception
  when others then
    --dbms_output.put_line('* Exception ['||sqlcode||'] in '||c_proc_name||'. Message ['||sqlerrm||']');
    return null;
end clean4alpha;



-- Cleans an input string by stripping all non-numbers
-- Keeps decimal points and commas
function clean4numbers(
  p_string    in  varchar2
) return varchar2
is
  c_proc_name   constant varchar2(100)  := pc_schema||'.'||pc_package||'.clean4numbers';
  v_string      varchar2(1000);
  v_last_length pls_integer;
  cv_from       constant varchar2(80):='.,0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ*?%`!"''£$^()_+-=/#~@]}[{><;:|¬ '||chr(38)||chr(47);
  -- Leave off the chars that we do not want to keep
  cv_to         constant varchar2(60):='.,0123456789';
begin
  if(p_string is null)then return null; end if;
  -- Clean input query string
  v_string:=translate(upper(trim(p_string)),cv_from,cv_to);
  v_string:=replace(v_string,'x');
  return v_string;
exception
  when others then
    --dbms_output.put_line('* Exception ['||sqlcode||'] in '||c_proc_name||'. Message ['||sqlerrm||']');
    return null;
end clean4numbers;


-- Convert an integer to spoken text
function int2text(
  p_integer              in            pls_integer
) return varchar2
is
  c_proc_name         constant varchar2(100) := pc_schema||'.'||pc_package||'.int2text';
  v_number            varchar2(200):='*COULD*NOT*CONVERT*';
begin
  if(abs(p_integer)>5373484)then
    return  v_number;
  end if;

  select decode(sign(p_integer), -1, 'Negative ', 0, 'Zero', NULL) ||
         decode(sign(abs(p_integer)), +1, to_char(to_date(abs(p_integer),'J'),'Jsp'))
    into v_number
    from dual;
  return v_number;
exception
  when others then
    --dbms_output.put_line('* Exception ['||sqlcode||'] in '||c_proc_name||'. Message ['||sqlerrm||']');
    return v_number;
end int2text;

------------------------------------------------------------------------
-- Create a string of same characters
-- (there has to be an inbuilt oracle function for this?)
function same_charstring(p_char in char, p_length in pls_integer) return varchar2
is
begin
  return lpad(p_char,p_length,p_char);
end same_charstring;

-------------------------------------------------------------------------------
-- Count the number of occurances of a substring in a string
function substr_count(p_string in varchar2, p_substr in varchar2) return pls_integer
is
  v_pos   pls_integer:=1;
  v_count pls_integer:=0;
begin
  v_pos:=instr(p_string,p_substr,v_pos);
  while(v_pos>0)loop
    v_count:=v_count+1;
    v_pos:=instr(p_string,p_substr,v_pos+1);
  end loop;
  return v_count;
end substr_count;

-------------------------------------------------------------------------------
--  Attempts to extract the first encountered numeric value from the string
--  starting at the point indicated by p_current_pos.
--  Returns:    TRUE if numeric value was found. 
--                p_current_pos is updated to end of the found number.
--              FALSE if no numeric value found
--                p_current_pos is undefined
--  TODO: Detect numbers represented in scientific format.
--  TODO: Use RegEx to save huge ammounts of troubles
function parse_number(
  p_string                  in        varchar2,       -- Input string
  p_current_pos             in out    pls_integer,    -- Entry and Exit point
  p_number                  out       number,         -- Resulting number
  p_length                  out       number          -- Length of resulting string holding number
)
return boolean
is
  c_proc_name   constant varchar2(100)  := pc_schema||'.'||pc_package||'.parse_number';
  v_num_length                pls_integer := 0;
  v_unary_negative            boolean := false;
  v_leading_decimal           boolean := false;
  v_str_length                pls_integer:=length(p_string);
  v_char                      varchar2(1);
begin
  -- Skip whitespace
  while(is_whitespace(substr(p_string,p_current_pos,1))) loop
    p_current_pos:=p_current_pos+1;
  end loop;

  -- Find first digit in string, while keeping tabs on leading unary minus and decimal points  
  <<CONTINUE>> 
  while(p_current_pos<=v_str_length)loop
    begin            
      v_char:=substr(p_string, p_current_pos, 1);
      if(v_char='-' and ( (v_unary_negative=false and v_leading_decimal=false) or 
                          (v_unary_negative=true  and v_leading_decimal=true )) )then
        if(v_unary_negative=true and v_leading_decimal=true)then
          -- One-shot from previous iteration
          v_leading_decimal:=false;
        else
          v_unary_negative:=true;          
        end if;  
        v_num_length:=1;        
        p_current_pos:=p_current_pos+1;
        goto CONTINUE;
      end if;      

      if(v_char='.' and v_leading_decimal=false)then
        v_leading_decimal:=true;
        if(not v_unary_negative)then
          v_num_length:=1;
        else
          v_num_length:=v_num_length+1;
        end if;
        p_current_pos:=p_current_pos+1;
        goto CONTINUE;
      end if;
    
      if(v_char=' ')then
        if(v_leading_decimal)then
          v_num_length:=1;
        else
          v_num_length:=v_num_length+1;
        end if;
        p_current_pos:=p_current_pos+1;
        goto CONTINUE;
      end if;

      p_number := to_number(v_char);-- Got first digit
      v_num_length:=v_num_length+1;      
      exit;
    exception
      when others then
        -- Destroy logical train
        v_num_length:=0;
        v_leading_decimal:=false;
        v_unary_negative:=false;        
        p_current_pos:=p_current_pos+1;
    end;
  end loop;        
  
  if(p_number is null)then
    -- Could not find a number 
    return false;
  end if;
  
  -- Continue to parse substring until the substring is not a number any more
  while((p_current_pos+v_num_length) <= v_str_length)loop
    begin
      -- attempt to convert token value to number - this will throw if not numeric
      if(v_leading_decimal)then    
        p_number := to_number('0.'||substr(p_string, p_current_pos, v_num_length+1));
      else
        p_number := to_number(substr(p_string, p_current_pos, v_num_length+1));
      end if;      
      v_num_length:=v_num_length+1;
    exception
      when others then                
        exit;
    end;
  end loop;

  -- Loop was not constrained because we hit the end of the string
  if((p_current_pos+v_num_length) <= v_str_length)then
    v_num_length:=v_num_length-1;    
  end if;
  p_current_pos:=p_current_pos+v_num_length;   

  if(v_unary_negative)then
    p_number:=-p_number;
  end if;
  p_length:=v_num_length;

  return true;
end parse_number;

-- Returns a string containing only unique characters that occurred in the 
-- input string. 
-- NOTE: Character order is not preserved - the characters are returned
--       in NLS order.
-- Maximum string length is ca. 2900. 
-- Characters beyond this limit are quietly ignored.
function dedupe_string(p_string in varchar2)
return varchar2
is
  s varchar2(4000);
begin
  for c in (select distinct substr(p_string,pos,1) unique_char
              from (select *
                      from (select level pos 
                              from dual 
                           connect by level<=length(p_string)
                           ) 
                   ) 
           )
  loop
    s:=s||c.unique_char;
  end loop;                  
  return s;                
exception
  when others then
    return null;  
end dedupe_string;


-- Converts a string to legal HTML code
-- Replaces all characters that could be interpreted as HTML command 
-- with HTML character codes
-- Assumption: Western European code page is in use
-- By default, end-of-line chars are translated into <br> tags
function string2html(p_string in varchar2, p_translate_eol in boolean:=true)
return varchar2
is 
  v_string  varchar2(32000);
  v_char    varchar2(1);
  v_code    pls_integer;
begin
  -- Step through each char and reinterpret to HTML where necessary
  for i in 1..length(p_string) loop
    v_char:=substr(p_string,i,1);
    v_code:=ascii(v_char);
    if(v_code=9 or v_code=10 or v_code=13 or  -- tab,linefeed,carriage return
       v_code between 32 and 47 or            -- space etc...
       v_code between 58 and 64 or            -- colon to monkey
       v_code between 91 and 96 or            -- bracket to grave
       v_code between 123 and 255 )           -- brace etc..
    then
      v_string:=v_string||gc_ampersand||'#'||lpad(to_char(v_code),3,'0')||';';
    else
      v_string:=v_string||v_char;
    end if;
  end loop;
  
  -- Replace 
  if(p_translate_eol)then
    v_string:=replace(replace(replace(v_string,
      gc_ampersand||'#013;'||gc_ampersand||'#010','<br>'),
      gc_ampersand||'#013;','<br>'),
      gc_ampersand||'#010;','<br>');
  end if;

  return v_string;
end string2html;

end pkg_string;
-----------------------------------------------------------------------
-- end of file
------------------------------------------------------------------------
/
