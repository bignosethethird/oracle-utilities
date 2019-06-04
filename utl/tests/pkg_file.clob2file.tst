PL/SQL Developer Test script 3.0
20
-- Created on 23/09/2005 by GHOEKSTRA 
declare 
  -- Local variables here
  i integer;
  v_clob clob;
  one_byte raw(1);
begin
  -- Test statements here
  v_clob := empty_clob();
  dbms_lob.createTemporary(v_clob, true);
  dbms_lob.open(v_clob, dbms_lob.lob_readwrite);

  -- filling the clob with bytes 0 .. 255
  for i in 0 .. 255 loop
    one_byte := utl_raw.cast_to_raw(chr(i));
    dbms_lob.writeappend(v_clob, 1, one_byte);
  end loop;

  utl.pkg_file.clob2file('VCRTMP','test1',v_clob); 
end;
0
0
