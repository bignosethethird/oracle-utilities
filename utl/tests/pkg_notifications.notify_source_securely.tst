PL/SQL Developer Test script 3.0
29
declare -- Test setup
  p_attachment clob;
  one_byte raw(1);
  
begin

  -- Test setup
  p_attachment := empty_clob();
  dbms_lob.createTemporary(p_attachment, true);
  dbms_lob.open(p_attachment, dbms_lob.lob_readwrite);

  -- filling the lob with bytes 0 .. 255
  for i in 0 .. 255 loop
    one_byte := utl_raw.cast_to_raw(chr(i));
    dbms_lob.writeappend(p_attachment, 1, one_byte);
  end loop;

  -- Call the procedure
  vcr.pkg_notifications.notify_source_securely(1,
                                           'test subject',
                                           'body',
                                           'attache',
                                           p_attachment
                                           );
                                           
  -- Test teardown
  dbms_lob.close(p_attachment);
                                           
end;
0
0
