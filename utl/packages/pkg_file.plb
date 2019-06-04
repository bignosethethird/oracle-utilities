create or replace package body utl.pkg_file as
------------------------------------------------------------------------
------------------------------------------------------------------------
--  File-based utility functions
------------------------------------------------------------------------


-- Writes a clob to a UTL_FILE-controlled file
procedure clob2file( p_dir in varchar2,
                        p_file in varchar2,
                        p_clob in clob )
is      
  c_proc_name   constant varchar2(100)  := pc_schema||'.'||pc_package||'.clob2file';                  
  l_output utl_file.file_type;
  l_amt    number default 32000;
  l_offset number default 1;
  l_length number default nvl(dbms_lob.getlength(p_clob),0);
begin
  dbms_application_info.set_module(c_proc_name,null);
  l_output := utl_file.fopen(p_dir, p_file, 'w', 32760);
  while ( l_offset < l_length )
  loop
    utl_file.put(l_output,dbms_lob.substr(p_clob,l_amt,l_offset) );
     utl_file.fflush(l_output);
     l_offset := l_offset + l_amt;
  end loop;
  utl_file.new_line(l_output);
  utl_file.fclose(l_output);
  dbms_application_info.set_module(null,null);
end clob2file;

end pkg_file;                        
------------------------------------------------------------------------
-- end of file
------------------------------------------------------------------------
/
