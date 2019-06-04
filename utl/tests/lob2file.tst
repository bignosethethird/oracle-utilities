PL/SQL Developer Test script 3.0
69
declare
  v_vcr_home          utl.config.string_value%type:=utl.pkg_config.get_variable_string('$APP_HOME');
  v_retcode           pls_integer;
  v_attachement_dir   varchar2(50) := v_vcr_home||'/tmp';
  v_attachement_file  varchar2(250);
  v_attachement_handle utl_file.file_type;      
  v_chunk_size        pls_integer:=100;
  v_chunk             raw(100);
  v_chunk_read_size   pls_integer;
  v_chunked_so_far    pls_integer:=0;
  v_attachment_length pls_integer;
  
  -- Test setup
  p_attachment blob;
  one_byte raw(1);
  
begin
  -- Test setup
  p_attachment := empty_blob();
  dbms_lob.createTemporary(p_attachment, true);
  dbms_lob.open(p_attachment, dbms_lob.lob_readwrite);

  -- filling the lob with bytes 0 .. 255
  for i in 0 .. 255 loop
    one_byte := utl_raw.cast_to_raw(chr(i));
    dbms_lob.append(p_attachment, one_byte);
  end loop;


  


  -- Implementation
  
  select 'attachment'||sq_attachement_id.nextval
    into v_attachement_file
    from dual;
  v_attachement_handle:=utl_file.fopen(v_attachement_dir,v_attachement_file,'WB');
  -- Chunk LOB
  v_attachment_length := dbms_lob.getlength(p_attachment);
  while v_chunked_so_far+v_chunk_size < v_attachment_length loop
    v_chunk_read_size:=v_chunk_size;
    dbms_lob.read(p_attachment,v_chunk_read_size,v_chunked_so_far+1,v_chunk);
    utl_file.put_raw(v_attachement_handle,v_chunk);
    v_chunked_so_far := v_chunked_so_far + v_chunk_size;
  end loop;
  -- Write last remaining chunkie bit
  v_chunk_read_size := v_attachment_length-v_chunked_so_far;
  if(v_chunk_read_size<>0)then
    dbms_lob.read(p_attachment,v_chunk_read_size,v_chunked_so_far+1,v_chunk);
    utl_file.put_raw(v_attachement_handle,v_chunk);
  end if;
  utl_file.fclose(v_attachement_handle);     
  
  -- Test teardown
  dbms_lob.close(p_attachment);
       
exception
  when others then
    utl.pkg_errorhandler.handle;    
    begin
      -- Cleanup 
      utl_file.fremove(v_attachement_dir,v_attachement_file);
    exception
      when others then 
        null;
    end;        
    raise;
end;     
0
0
