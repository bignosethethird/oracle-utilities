create or replace package body utl.pkg_errorhandler as
  --------------------------------------------------------------------------
  --------------------------------------------------------------------------
  --  Capture and log error information, optionally raising helpdesk incidents
  --------------------------------------------------------------------------
  gv_callstack  varchar2(2000);
  gv_errorstack varchar2(2000);
  gv_sqlcode    number;

  gv_errorishandled boolean := false;
  gv_errorislogged  boolean := false;

  -- handle should be called in the exception block of any function or procedure
  -- where the call/error stack of any error should be retained.
  -- record error and call stack in package body variables
  -- at the point the exception is caused
  procedure handle as
  begin
    dbms_application_info.set_module('utl.pkg_errorhandler.handle',null);
    -- if not already been called
    if not gv_errorishandled
    then
      gv_sqlcode := sqlcode;
      -- flick flag
      gv_errorishandled := true;
      gv_errorislogged  := false;
    
      -- record stack information
      gv_callstack  := dbms_utility.format_call_stack;
      gv_errorstack := dbms_utility.format_error_stack;
    end if;
    
    dbms_application_info.set_module(null,null);
  end handle;

  -- this routine logs a handled sql error
  --
  -- it should be called at the point the error information should be logged
  -- e.g. in the main controlling function or procedure called from the scheduler
  -- any subsequent call in that session will not log anything as the assumption
  -- is that the sql error will be propogated fully and the session ended
  -- this routine will by default raise a helpdesk incident
  -- the optional parent table parameters allow the log entry to be related to some other item 
  -- such as a VCR source_load_run 
  procedure log_sqlerror(p_parent_table in log_message.parent_table%type default null,
                         p_parent_id    in log_message.parent_table%type default null,
                         p_incident     in boolean default true) as
    v_error       varchar2(2000) := '';
    v_errorstring varchar2(2000) := '';
    v_callstring  varchar2(2000) := '';
    v_call        varchar2(2000) := '';
    v_index       number;
    v_endline     number;
  
    c_newline constant char(1) := pkg_constants.gc_cr;
  begin
    dbms_application_info.set_module('utl.pkg_errorhandler.log_sqlerror',null);
    
    if not gv_errorislogged
    then
      v_index := 1;
    
      -- remove new lines from the stack string and concatenate the errors in square brackets
      while v_index < length(gv_errorstack)
      loop
        v_endline := instr(gv_errorstack, c_newline, v_index);
        v_error   := substr(gv_errorstack, v_index, v_endline - v_index);
      
        v_errorstring := v_errorstring || '[' || v_error || ']';
      
        v_index := v_index + length(v_error) + 1;
      end loop;
    
      v_index := instr(gv_callstack, 'name') + 5; -- skip to the start of the call info
      v_index := instr(gv_callstack, c_newline, v_index) + 1; -- skip the first call in the stack as this will be the error handler itself
    
      -- remove new lines and object handles from the stack string and concatenate the calls in square brackets
      while v_index < length(gv_callstack)
      loop
        v_endline := instr(gv_callstack, c_newline, v_index);
      
        v_call := substr(gv_callstack, v_index, v_endline - v_index);
      
        v_index := v_index + length(v_call) + 1;
      
        v_call := ltrim(v_call);
        v_call := substr(v_call,
                         length(substr(v_call, 1, instr(v_call, ' '))) + 1);
        v_call := ltrim(v_call);
      
        v_callstring := v_callstring || '[' || v_call || ']';
      
      end loop;
   
      log_error(gv_sqlcode,
                v_errorstring || v_callstring,
                p_parent_table,
                p_parent_id,
                p_incident);
    
      gv_errorislogged := true; -- remember that we have logged the error now
      gv_errorishandled := false;
    end if;
    
    dbms_application_info.set_module(null,null);
  end log_sqlerror;
  
  -- this routine logs an error as defined by the parameters p_error_code and p_error_message
  --
  -- the optional parent table parameters allow the log entry to be related to some other item 
  -- this routine will by default raise a helpdesk incident
  -- it is called by log_sqlerror, for non-sql errors it should be called directly
  procedure log_error(p_error_code    in log_message.error_code%type,
                      p_error_message in log_message.message_text%type,
                      p_parent_table  in log_message.parent_table%type default null,
                      p_parent_id     in log_message.parent_table%type default null,
                      p_incident      in boolean default true) as
  begin
    dbms_application_info.set_module('utl.pkg_errorhandler.log_error',null);
    
    pkg_logger.log(pkg_logger.gc_log_message_error,
                   p_error_message,
                   p_parent_table,
                   p_parent_id,
                   p_error_code);
  
    if p_incident
    then
      pkg_helpdesk.create_incident('VCR Error:' || p_error_code || ' ' ||
                                   rpad(p_error_message, 200),
                                   get_message(p_error_code)||utl.pkg_constants.gc_cr||
                                   get_explanation(p_error_code));
    end if;    
    dbms_application_info.set_module(null,null);
  exception
    when others then 
      null; -- THE BUTT STOPS HERE. If the SMTP server does not work, then the system should not fall over
  end log_error;

  ------------------------------------------------------------------------
  --  Get complete description: error message and error explanation
  -- The error code can either be -'ve or +'ve
  -- If positive, check if there is a positive error code first and return details
  -- for this, else return details for the negative error code. This is
  -- useful when there are UNIX or other system's error codes, which 
  -- should not coincide with Oracle's (always negative) error codes.
  -- If negative, only return details to this.
  function code2desc(p_error_code  in error_codes.error_code%type,
                     p_message     out error_codes.message%type,
                     p_explanation out error_codes.explanation%type)
    return utl.global.t_error_code 
  is
    v_error_code  error_codes.error_code%type:=p_error_code;
    v_retcode     utl.global.t_error_code := pkg_exceptions.gc_success;
  begin
    dbms_application_info.set_module('utl.pkg_errorhandler.code2desc',null);   
    
    if(v_error_code>=0)then
      -- +'ve error code - could be a UNIX error code
      begin
        select message, explanation
          into p_message, p_explanation
          from utl.error_codes
         where error_code = v_error_code;
      exception      
        when no_data_found then
          v_error_code:=-v_error_code;
      end;
    end if;    
    
    if(v_error_code<0)then
      -- Definiately an Oracle or Application error code
      begin
        select message, explanation
          into p_message, p_explanation
          from utl.error_codes
         where error_code = v_error_code;
      exception
        when no_data_found then
          if (p_error_code between -20001 and -20999)
            then
            p_message     := 'Undocumented Application-specific error';
            p_explanation := 'Application-specific error that has not been documented yet';
          else
            p_message     := sqlerrm(v_error_code);
            -- TODO: Determine the facility, eg 'ora' etc...
            -- TODO: The placeholders (%s etc...) in the error message are not populated
            p_explanation := 'Possible Oracle Error of an unknown facility. Please refer to the Oracle Error Documentation for more details, or run "oerr [facility code] '
                             ||to_char(abs(v_error_code))||'" on a terminal to the Oracle server.';
          end if;
          v_retcode := pkg_exceptions.gc_undefined;
      end;    
    end if;      
    
    dbms_application_info.set_module(null,null);    
    return v_retcode;
  exception
    when others then
      handle;    
      raise;
  end code2desc;
  
  -- Procedure wrapper
  procedure code2desc(p_error_code  in error_codes.error_code%type,
                       p_message     out error_codes.message%type,
                       p_explanation out error_codes.explanation%type)
  is
    v_retcode utl.global.t_error_code;
  begin
    v_retcode:=code2desc(p_error_code,p_message,p_explanation);
  end code2desc;              

  ------------------------------------------------------------------------
  -- Is the error code a success i.e. greater and equal to 0 ? --> returns true
  ------------------------------------------------------------------------
  function is_success(p_code in pls_integer) return boolean is
  begin
    return(p_code >= pkg_exceptions.gc_success);
  end is_success;

  ------------------------------------------------------------------------
  -- Is the error code a failure? --> returns true
  ------------------------------------------------------------------------
  function is_error(p_code in pls_integer) return boolean is
  begin
    return(not is_success(p_code));
  end is_error;

  -- returns error explanation
  function get_explanation(p_error_code in error_codes.error_code%type) return error_codes.explanation%type
  as
    v_message     error_codes.message%type;
    v_explanation error_codes.explanation%type;
    v_error_code  error_codes.error_code%type;
  begin
    v_error_code := code2desc(p_error_code, v_message, v_explanation);    
    return v_explanation;
  end get_explanation;
  
  -- returns error message
  function get_message(p_error_code in error_codes.error_code%type) return error_codes.message%type
  as
    v_message     error_codes.message%type;
    v_explanation error_codes.explanation%type;
    v_error_code  error_codes.error_code%type;
  begin
    v_error_code := code2desc(p_error_code, v_message, v_explanation);   
    return v_message;
  end get_message;
  
end pkg_errorhandler;
/
