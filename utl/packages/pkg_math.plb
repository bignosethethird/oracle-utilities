create or replace package body 
------------------------------------------------------------------------------
------------------------------------------------------------------------------
--  Mathematical utilities and settings
------------------------------------------------------------------------------
    utl.pkg_math
as

--==========================================================================--
-- Numerical Conversion Functions
--==========================================================================--

-- Converts decimal to Hex string
procedure dec2hex(p_in_num  in  number,
                  p_out_hex out varchar2)
is
  c_proc_name         constant varchar2(100)  := pc_schema||'.'||pc_package||'.dec2hex';
  type vc2tab_type is table of varchar2(1) index by binary_integer;
  hextab              vc2tab_type;
  v_num               number;
  v_hex               varchar2(200);
begin
   if(p_in_num is null)then
     return;
   end if;

   hextab  (0)  := '0';
   hextab  (1)  := '1';
   hextab  (2)  := '2';
   hextab  (3)  := '3';
   hextab  (4)  := '4';
   hextab  (5)  := '5';
   hextab  (6)  := '6';
   hextab  (7)  := '7';
   hextab  (8)  := '8';
   hextab  (9)  := '9';
   hextab  (10) := 'A';
   hextab  (11) := 'B';
   hextab  (12) := 'C';
   hextab  (13) := 'D';
   hextab  (14) := 'E';
   hextab  (15) := 'F';
   v_num := p_in_num;

   while v_num >= 16 loop
      v_hex := hextab(mod(v_num,16))||v_hex;
      v_num := trunc (v_num/16);
   end loop;
   v_hex := hextab(mod(v_num,16))||v_hex;
   p_out_hex := v_hex;
exception
  when others then
    dbms_output.put_line('* Exception ['||sqlcode||'] in '||c_proc_name||'. Message ['||sqlerrm||']');
end dec2hex;

-- Converts Hex string to integer
function hex2int(h varchar2) return pls_integer
is
  c_proc_name         constant varchar2(100)  := pc_schema||'.'||pc_package||'.hex2int';
begin
  if(nvl(length(h),1)=1)then
    return instr ('0123456789abcdef', h)-1;
  else
    return 16 * hex2int(substr(h,1,length(h)-1))+instr('0123456789abcdef',substr(h,-1))-1;
   end if;
exception
  when others then
    dbms_output.put_line('* Exception ['||sqlcode||'] in '||c_proc_name||'. Message ['||sqlerrm||']');
end hex2int;

-- Converts integer to Hex string
function int2hex (n pls_integer) return varchar2
is
  c_proc_name         constant varchar2(100)  := pc_schema||'.'||pc_package||'.int2hex';
begin
  if n > 0 then
    return int2hex(trunc(n / 16))||substr('0123456789abcdef',mod(n,16)+1,1);
  else
    return null;
  end if;
exception
  when others then
    dbms_output.put_line('* Exception ['||sqlcode||'] in '||c_proc_name||'. Message ['||sqlerrm||']');
end int2hex;


-- Converts a number to words, and if required, to monatary units and 1/100 units
-- Parameters:
-- 1. Number to be converted
-- 2. Monetary Unit name. e.g. Euros
-- 3. Monetary Unit 1/100 name. e.g. Cents
-- Returns a nice English string
-- e.g. dec2words('289767685.489876') gives:
-- two hundred eighty-nine million seven hundred sixty-seven thousand six
--  hundred eighty-five point four eight nine eight seven-six
-- In the English language, the last digit is preceded by a hyphen 
-- or by the word 'and' when the last two digit are between 1 and 19 or the last 
-- digit is a 0 preceded by a non-0, e.g.1001 --> thousand and one, 
-- 610 --> six hundred and 10, 716 --> seven hundred and sixteen
--
-- Consider this simpler idea, which is limited by the maximum value allowed 
-- for a julian date (ca. 7 digits):
--select decode(sign(my_num ), -1, 'Negative ', 0, 'Zero', NULL ) ||
--       decode(sign(abs(my_num) ), +1, to_char( to_date( abs(my_num),'J'),'Jsp') )
--from dual
-- TODO: Make compatible with other codepages
function dec2words( p_number in number,
                    p_mon_unit in varchar2 := null,
                    p_mon_100 in varchar2 := null)
return varchar2
is
  c_proc_name       constant varchar2(100)  := pc_schema||'.'||pc_package||'.dec2words';
  v_number          number := p_number;
  v_word_string     varchar2(1000);
  v_lower_number    number;
  v_decimals        varchar2(100);
  lower_str         varchar2(200);
  v_units_defined   boolean:=false;

  --  Convert into string
  function to_string(p_val_in number) return char 
  is
    v_str varchar2(100);
    v_pos pls_integer;
  begin
    if(p_val_in > 0)then
      v_str:=lower(to_char(to_date(p_val_in,'SSSSS'), 'SSSSSSP'));
      if((p_val_in mod 100)>=1 and (p_val_in mod 100)<=19  or (p_val_in mod 10)=0)then
        -- insert an 'and'
        v_pos:=instr(v_str,' ',-1);
        v_str:=substr(v_str,1,v_pos)||'and'||substr(v_str,v_pos);
      end if;      
      return v_str;
    else
      return('');
    end if;
  end;

begin
  -- Check of units are defined
  if(p_mon_unit is not null and p_mon_100 is not null)then
    v_units_defined:=true;
  end if;

  v_lower_number:=(v_number MOD 1) * 100;
  if(v_lower_number<>0)then
    -- Check for lower denominations not exceeding two digits
    if(length(to_char(v_lower_number))<3 or v_units_defined=false)then
      if(v_number>=1 and v_lower_number>0)then
        if(v_units_defined=false)then
          lower_str:=lower_str||' point ';
          -- list the decimal digits out one by one
          v_decimals:=substr(to_char(v_number mod 1),2);
          while(length(v_decimals)>0)loop
            lower_str:=lower_str||to_string(substr(v_decimals,1,1))||' ';
            v_decimals:=substr(v_decimals,2);
          end loop;
        else
          lower_str:=p_mon_unit;
          -- list the decimal digits (only 2) as a full number
          lower_str:=lower_str||' and ';
          lower_str:=lower_str||to_string(v_lower_number)||' '||p_mon_100;
        end if;
  
      elsif(v_number < 1 and v_lower_number > 0)then
        lower_str:=lower (to_string (v_lower_number))||
                   nvl(p_mon_100||' ','');
      elsif(v_number >= 1 and v_lower_number = 0 and (p_mon_unit is not null))then
        lower_str := ' '||p_mon_unit;
      end if;
    else
      v_word_string := '* Invalid lower denomination' ;
      return  (v_word_string);
    end if; 
  end if;

  loop
    if(v_number > 0 and v_number <= 1000)then
      v_word_string:=v_word_string||to_string(floor(v_number))||lower_str;
      exit; 
    elsif(v_number > 1000 and v_number < 1000000)then
      v_word_string:=v_word_string||to_string(floor(v_number/1000))||' thousand '||to_string(floor(v_number mod 1000))||lower_str;
      exit;
    elsif(v_number >= 1000000 and v_number < 1000000000)then
      v_word_string:=v_word_string ||to_string (floor(v_number/1000000))||' million ';
      v_number := floor(v_number mod 1000000);
      if(v_number=0)then        
        v_word_string:=v_word_string||lower_str;
        exit;
      end if;
    elsif(v_number >= 1000000000 and v_number <= 999999999999.99)then
      v_word_string:=to_string(floor(v_number/1000000000))||' billion ';
      v_number:=floor(v_number mod 1000000000);
      if(v_number=0)then
        v_word_string:=v_word_string||lower_str;
        exit;
      end if;
    elsif(v_number=0) then
      v_word_string:='zero'||lower_str;
      exit;
    else
      v_word_string:='* Too big or too small number.';
      exit; 
    end if;
  end loop;
  return  (v_word_string);
exception
  when others then
    dbms_output.put_line('* Exception ['||sqlcode||'] in '||c_proc_name||'. Message ['||sqlerrm||']');
    return null;    
end dec2words;

-- Converts a cardinal number (1,2,3,....) to an ordinal number in 
-- string form (first, second, third,...)
-- If the ordinal could not be determined, returns null
-- TODO: Make compatible with other codepages. Assume English
function cardinal2ordinal(p_cardinal in pls_integer) return varchar2
is
  c_proc_name       constant varchar2(100)  := pc_schema||'.'||pc_package||'.cardinal2ordinal';
  v_cardinal pls_integer:=abs(p_cardinal);  
  v_str varchar2(200);
  v_last_hyphen_pos pls_integer;
  v_last_space_pos  pls_integer;
  v_last_digit pls_integer;
  v_last_term varchar2(20);
begin
  v_str:=dec2words(v_cardinal);
  if(v_cardinal mod 100 >= 11 and v_cardinal mod 100 <= 19)then
    v_last_digit:=v_cardinal mod 100;
    v_last_hyphen_pos:=0;
    v_last_space_pos :=instr(v_str,' ',-1);    
  else
    v_last_digit:=v_cardinal mod 10;
    v_last_hyphen_pos:=instr(v_str,'-',-1);
    v_last_space_pos :=instr(v_str,' ',-1);     
  end if;
  
  if(v_last_space_pos>v_last_hyphen_pos)then
    v_last_term:=substr(v_str,v_last_space_pos+1);
    v_str:=substr(v_str,1,v_last_space_pos);    
  else
    v_last_term:=substr(v_str,v_last_hyphen_pos+1);
    v_str:=substr(v_str,1,v_last_hyphen_pos);    
  end if;
  
  case v_last_digit
    when '1'   then v_str:=v_str||'first';
    when '2'   then v_str:=v_str||'second';
    when '3'   then v_str:=v_str||'third';
    when '4'   then v_str:=v_str||'fourth';
    when '5'   then v_str:=v_str||'fifth';
    when '6'   then v_str:=v_str||'sixth';
    when '7'   then v_str:=v_str||'seventh';
    when '8'   then v_str:=v_str||'eighth';
    when '9'   then v_str:=v_str||'nineth';
    when '12'  then v_str:=v_str||'twelfth';
    else v_str:=v_str||v_last_term||'th';  -- number ending on 0 or 11,13..19
  end case;
  return v_str;
exception
  when others then
    dbms_output.put_line('* Exception ['||sqlcode||'] in '||c_proc_name||'. Message ['||sqlerrm||']');  
    return null;
end cardinal2ordinal;


-- Converts a Boolean value to an acceptable SQL type
-- TRUE  => 1
-- FALSE => 0
function bool2num(p_bool in boolean) return number is
begin
  return sys.diutil.bool_to_int(p_bool);
end bool2num;

-- Converts a Boolean value to an acceptable SQL type
-- The string values for booleans are defined in this package spec.
-- TRUE  => 'T'
-- FALSE => 'F'
function bool2str(p_bool in boolean) return varchar2 is
begin
  if(p_bool is null)then
    return null;
  end if;
  if(p_bool=true)then
    return gc_str_true;
  end if;
  return gc_str_false;
end bool2str;

-- Converts an integer to a Boolean value 
-- 1 => TRUE 
-- 0 => FALSE 
function int2bool(p_int in pls_integer) return boolean 
is
begin
  return sys.diutil.int_to_bool(p_int);
end int2bool;

-- Converts a Boolean value to an acceptable SQL type
-- TRUE  => 'T'
-- FALSE => 'F'
function str2bool(p_bool in varchar2) return boolean is
begin
  if(p_bool=gc_str_true)then
    return true;
  else
    return false;
  end if;
end str2bool;

--==================================================================--
-- Geometric Conversion Functions
--==================================================================--

-- Converts degrees to radians.
-- Either specify degree to decimal, or use minutes and seconds with the degree decimal
function degrees2radians( p_degrees in real, 
                          p_minutes in real:=null, 
                          p_seconds in real:=null) 
return real
is
begin
  if(p_minutes is null)then
    return p_degrees/gc_degrees_per_radian;
  else
    return (degreeMS2degreeDec(p_degrees,p_minutes,p_seconds)/gc_degrees_per_radian);
  end if;
end degrees2radians;


-- Converts radians to degrees (decimal value only)
function radians2degrees(p_radians in real) 
return real
is    
begin
  return p_radians*gc_degrees_per_radian;
end radians2degrees;


-- Converts a decimal degree to hours minutes and seconds string
-- e.g. 50.5 returns 50 deg 30' 0"
function degreeDec2degreeMS(p_degrees in real) 
return varchar2
is
  v_deg real;
  v_min real;
  v_sec real;
begin  
  v_deg:=trunc(p_degrees);
  v_min:=trunc((p_degrees-v_deg)*60);
  v_sec:=(p_degrees-v_deg-v_min/60)*3600;
  return to_number(v_deg)||' deg '||to_number(v_min)||''' '||substr(to_number(v_sec),1,8)||'"';  
end degreeDec2degreeMS;

-- Converts degrees, minutes and seconds to a decimal degree
-- e.g. 50 deg 30' 0" return 50.5
function degreeMS2degreeDec(p_degrees in real,
                            p_minutes in real,
                            p_seconds in real)
return real
is
begin
  return trunc(p_degrees)+trunc(p_minutes)/60+trunc(p_seconds)/3600;
end degreeMS2degreeDec;

--==================================================================--
-- Maths Functions
--==================================================================--

function min(a pls_integer, b pls_integer) 
return pls_integer 
is
begin
  if(a<b)then return a; end if;
  return b;
end min;

function max(a pls_integer, b pls_integer) 
return pls_integer
is
begin
  if(a<b)then return b; end if;
  return a;
end max;


end pkg_math;
------------------------------------------------------------------------------
-- end of file
------------------------------------------------------------------------------
/
