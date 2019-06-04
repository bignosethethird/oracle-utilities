CREATE OR REPLACE PACKAGE BODY utl.pkg_emailer AS
  --------------------------------------------------------------------------
  --------------------------------------------------------------------------
  --  A package to send emails
  --------------------------------------------------------------------------

  -- A unique string that demarcates boundaries of parts in a multi-part email
  -- The string should not appear inside the body of any part of the email.
  -- Customize this if needed or generate this randomly dynamically.
  gc_boundary       CONSTANT VARCHAR2(256) := 'DMW.Boundary.605592468';
  gc_first_boundary CONSTANT VARCHAR2(256) := '--' || gc_boundary ||
                                              utl_tcp.crlf;
  gc_last_boundary  CONSTANT VARCHAR2(256) := '--' || gc_boundary || '--' ||
                                              utl_tcp.crlf;

  -- write a varchar2 value to a mail message 
  ------------------------------------------------------------------------
  PROCEDURE write_data(p_conn    IN OUT NOCOPY utl_smtp.connection,
                       p_message IN VARCHAR2) IS
  BEGIN
    dbms_application_info.set_module('utl.pkg_emailer.write_data',null);
    
    utl_smtp.write_data(p_conn, p_message);
    
    dbms_application_info.set_module(null,null);
  EXCEPTION
    WHEN OTHERS THEN
      pkg_errorhandler.handle;
    
      RAISE;
  END write_data;

  -- Mark a message-part boundary.  Set <last> to TRUE for the last boundary.
  ------------------------------------------------------------------------------
  PROCEDURE write_boundary(p_conn IN OUT NOCOPY utl_smtp.connection,
                           p_last IN BOOLEAN DEFAULT FALSE) IS
  BEGIN
    dbms_application_info.set_module('utl.pkg_emailer.write_boundary',null);
  
    IF (p_last)
    THEN
      write_data(p_conn, gc_last_boundary);
    ELSE
      write_data(p_conn, gc_first_boundary);
    END IF;
    
    dbms_application_info.set_module(null,null);
  EXCEPTION
    WHEN OTHERS THEN
      pkg_errorhandler.handle;
    
      RAISE;
  END write_boundary;

  -- write a clob value to a mail message
  ------------------------------------------------------------------------
  PROCEDURE write_data(p_conn    IN OUT NOCOPY utl_smtp.connection,
                       p_message IN CLOB) IS
    v_mesg VARCHAR2(32767);
  
    v_pos INTEGER := 1;
    v_amt BINARY_INTEGER := 32767;
  BEGIN
    dbms_application_info.set_module('utl.pkg_emailer.write_data',null);
    
    LOOP
      BEGIN
        dbms_lob.READ(p_message, v_amt, v_pos, v_mesg);
      EXCEPTION
        WHEN no_data_found THEN
          EXIT;
      END;
    
      v_pos := v_pos + v_amt;
    
      write_data(p_conn, v_mesg);
    
    END LOOP;
    
    dbms_application_info.set_module(null,null);
  EXCEPTION
    WHEN OTHERS THEN
      pkg_errorhandler.handle;
    
      RAISE;
  END write_data;

  -- function to get smtp connection for configured server and port
  -- tries a configurable number of times 
  FUNCTION begin_session RETURN utl_smtp.connection AS
    v_smtp_server      VARCHAR2(100);
    v_smtp_server_port INTEGER;
  
    v_conn    utl_smtp.connection;
    v_success BOOLEAN := FALSE;
  BEGIN
    dbms_application_info.set_module('utl.pkg_emailer.begin_session',null);
  
    v_smtp_server      := pkg_config.get_variable_string(gc_smtp_server_config_key);
    v_smtp_server_port := pkg_config.get_variable_int(gc_smtp_server_port_config_key);
  
    IF v_smtp_server IS NOT NULL
       AND v_smtp_server_port IS NOT NULL
    THEN
      FOR i IN 1 .. nvl(pkg_config.get_variable_int(gc_no_of_retries_config_key),
                        1)
      LOOP
        BEGIN
          v_conn := utl_smtp.open_connection(v_smtp_server,
                                             v_smtp_server_port);
        
          v_success := TRUE;
          EXIT;
        EXCEPTION
          WHEN utl_smtp.invalid_operation THEN
            NULL;
          WHEN utl_smtp.transient_error THEN
            NULL;
          WHEN utl_smtp.permanent_error THEN
            NULL;
          WHEN OTHERS THEN
            RAISE;
        END;
      END LOOP;
    
      IF NOT v_success
      THEN
        dbms_application_info.set_module(null,null);
        
        RAISE pkg_exceptions.e_smtp_conn_fail;
      ELSE
        utl_smtp.helo(v_conn,
                      pkg_config.get_variable_string(gc_domain_name_config_key));
      END IF;
    ELSE
      dbms_application_info.set_module(null,null);
    
      RAISE pkg_exceptions.e_smtp_config_missing;
    END IF;
  
    dbms_application_info.set_module(null,null);
  
    RETURN v_conn;
  EXCEPTION
    WHEN OTHERS THEN
      pkg_errorhandler.handle;
    
      RAISE;
  END begin_session;

  FUNCTION get_address(p_addr_list IN OUT VARCHAR2) RETURN VARCHAR2 IS
    v_addr VARCHAR2(256);
    i      PLS_INTEGER;
  
    FUNCTION lookup_unquoted_char(p_str IN VARCHAR2, p_chrs IN VARCHAR2)
      RETURN PLS_INTEGER IS
      c              VARCHAR2(5);
      i              PLS_INTEGER;
      v_len          PLS_INTEGER;
      v_inside_quote BOOLEAN;
    BEGIN
      v_inside_quote := FALSE;
      i              := 1;
      v_len          := length(p_str);
    
      WHILE (i <= v_len)
      LOOP
        c := substr(p_str, i, 1);
      
        IF (v_inside_quote)
        THEN
          IF (c = '"')
          THEN
            v_inside_quote := FALSE;
          ELSIF (c = '\')
          THEN
            i := i + 1; -- Skip the quote character
          END IF;
        
          GOTO next_char;
        END IF;
        IF (c = '"')
        THEN
          v_inside_quote := TRUE;
          GOTO next_char;
        END IF;
        IF (instr(p_chrs, c) >= 1)
        THEN
          RETURN i;
        END IF;
        <<next_char>>
        i := i + 1;
      END LOOP;
    
      RETURN 0;
    EXCEPTION
      WHEN OTHERS THEN
        pkg_errorhandler.handle;
      
        RAISE;
    END lookup_unquoted_char;
  BEGIN
    dbms_application_info.set_module('utl.pkg_emailer.get_address',null);

    p_addr_list := ltrim(p_addr_list);
    i           := lookup_unquoted_char(p_addr_list, ',;');
  
    IF (i >= 1)
    THEN
      v_addr      := substr(p_addr_list, 1, i - 1);
      p_addr_list := substr(p_addr_list, i + 1);
    ELSE
      v_addr      := p_addr_list;
      p_addr_list := '';
    END IF;
  
    i := lookup_unquoted_char(v_addr, '<');
  
    IF (i >= 1)
    THEN
      v_addr := substr(v_addr, i + 1);
    
      i := instr(v_addr, '>');
    
      IF (i >= 1)
      THEN
        v_addr := substr(v_addr, 1, i - 1);
      END IF;
    
    END IF;
  
    dbms_application_info.set_module(null,null);
  
    RETURN v_addr;
  EXCEPTION
    WHEN OTHERS THEN
      pkg_errorhandler.handle;
    
      RAISE;
  END get_address;
  -- Write a MIME header
  PROCEDURE write_mime_header(p_conn  IN OUT NOCOPY utl_smtp.connection,
                              p_name  IN VARCHAR2,
                              p_value IN VARCHAR2) IS
  BEGIN
    write_data(p_conn, p_name || ': ' || p_value || utl_tcp.crlf);
  EXCEPTION
    WHEN OTHERS THEN
      pkg_errorhandler.handle;
    
      RAISE;
  END write_mime_header;
  ------------------------------------------------------------------------
  PROCEDURE begin_attachment(p_conn         IN OUT NOCOPY utl_smtp.connection,
                             p_mime_type    IN VARCHAR2,
                             p_inline       IN BOOLEAN DEFAULT TRUE,
                             p_filename     IN VARCHAR2 DEFAULT NULL,
                             p_transfer_enc IN VARCHAR2 DEFAULT NULL) IS
  BEGIN
    dbms_application_info.set_module('utl.pkg_emailer.begin_attachment',null);
  
    write_boundary(p_conn);
  
    IF (p_filename IS NOT NULL)
    THEN
      write_mime_header(p_conn,
                        'Content-Type',
                        p_mime_type || '; name="' || p_filename || '"');
    
      IF (p_inline)
      THEN
        write_mime_header(p_conn,
                          'Content-Disposition',
                          'inline; filename="' || p_filename || '"');
      ELSE
        write_mime_header(p_conn,
                          'Content-Disposition',
                          'attachment; filename="' || p_filename || '"');
      END IF;
    ELSE
      write_mime_header(p_conn, 'Content-Type', p_mime_type);
    END IF;
  
    IF (p_transfer_enc IS NOT NULL)
    THEN
      write_mime_header(p_conn,
                        'Content-Transfer-Encoding',
                        p_transfer_enc);
    END IF;
  
    write_data(p_conn, utl_tcp.crlf);
    
    dbms_application_info.set_module(null,null);
  EXCEPTION
    WHEN OTHERS THEN
      pkg_errorhandler.handle;
    
      RAISE;
  END begin_attachment;

  ------------------------------------------------------------------------
  PROCEDURE end_attachment(p_conn IN OUT NOCOPY utl_smtp.connection,
                           p_last IN BOOLEAN DEFAULT FALSE) IS
  BEGIN
    dbms_application_info.set_module('utl.pkg_emailer.end_attachment',null);
  
    write_data(p_conn, utl_tcp.crlf);
    IF (p_last)
    THEN
      write_boundary(p_conn, p_last);
    END IF;
    
    dbms_application_info.set_module(null,null);
  EXCEPTION
    WHEN OTHERS THEN
      pkg_errorhandler.handle;
    
      RAISE;
  END end_attachment;
  ------------------------------------------------------------------------
  PROCEDURE attach_data(p_conn      IN OUT NOCOPY utl_smtp.connection,
                        p_data      IN CLOB,
                        p_mime_type IN VARCHAR2 DEFAULT 'text/plain',
                        p_inline    IN BOOLEAN DEFAULT TRUE,
                        p_filename  IN VARCHAR2 DEFAULT NULL,
                        p_last      IN BOOLEAN DEFAULT FALSE) IS
  BEGIN
    dbms_application_info.set_module('utl.pkg_emailer.attach_data',null);
  
    begin_attachment(p_conn, p_mime_type, p_inline, p_filename, '7bit');
    write_data(p_conn, p_data);
    end_attachment(p_conn, p_last);
    
    dbms_application_info.set_module(null,null);
  EXCEPTION
    WHEN OTHERS THEN
      pkg_errorhandler.handle;
    
      RAISE;
  END attach_data;

  ------------------------------------------------------------------------
  PROCEDURE attach_data(p_conn      IN OUT NOCOPY utl_smtp.connection,
                        p_data      IN VARCHAR2,
                        p_mime_type IN VARCHAR2 DEFAULT 'text/plain',
                        p_inline    IN BOOLEAN DEFAULT TRUE,
                        p_filename  IN VARCHAR2 DEFAULT NULL,
                        p_last      IN BOOLEAN DEFAULT FALSE) IS
  BEGIN
    dbms_application_info.set_module('utl.pkg_emailer.attach_data',null);
    
    begin_attachment(p_conn, p_mime_type, p_inline, p_filename, '7bit');
    write_data(p_conn, p_data);
    end_attachment(p_conn, p_last);
    
    dbms_application_info.set_module(null,null);
  EXCEPTION
    WHEN OTHERS THEN
      pkg_errorhandler.handle;
    
      RAISE;
  END attach_data;
  ------------------------------------------------------------------------
  PROCEDURE begin_mail_in_session(p_conn       IN OUT NOCOPY utl_smtp.connection,
                                  p_sender     IN VARCHAR2,
                                  p_recipients IN VARCHAR2,
                                  p_subject    IN VARCHAR2) IS
    v_my_recipients VARCHAR2(32767) := p_recipients;
    v_my_sender     VARCHAR2(32767) := p_sender;
  BEGIN
    dbms_application_info.set_module('utl.pkg_emailer.begin_mail_in_session',null);

    -- Specify sender's address (our server allows bogus address
    -- as long as it is a full email address (xxx@yyy.com).
    utl_smtp.mail(p_conn, get_address(v_my_sender));
    -- Specify recipient(s) of the email.
    WHILE (v_my_recipients IS NOT NULL)
    LOOP
      utl_smtp.rcpt(p_conn, get_address(v_my_recipients));
    END LOOP;
  
    -- Start body of email
    utl_smtp.open_data(p_conn);
  
    -- Set "Date" MIME header
    write_mime_header(p_conn,
                      'Date',
                      to_char(SYSDATE, 'dd Mon yy hh24:mi:ss'));
    -- Set "From" MIME header
    write_mime_header(p_conn,
                      'From',
                      nvl(p_sender,
                          pkg_config.get_variable_string(gc_default_sender_config_key)));
    -- Set "Subject" MIME header
    write_mime_header(p_conn, 'Subject', p_subject);
    -- Set "To" MIME header
    write_mime_header(p_conn, 'To', p_recipients);
    -- Set "Mime Version" MIME header
    write_mime_header(p_conn, 'Mime-Version', '1.0');
    -- Set "Content-Type" MIME header
    write_mime_header(p_conn,
                      'Content-Type',
                      'multipart/mixed; boundary="' || gc_boundary || '"');
  
    -- Send an empty line to denotes end of MIME headers and
    -- beginning of message body.
    write_data(p_conn, utl_tcp.crlf);
  
    write_data(p_conn,
               'This is a multi-part message in MIME format.' ||
               utl_tcp.crlf);
               
    dbms_application_info.set_module(null,null);
  EXCEPTION
    WHEN OTHERS THEN
      pkg_errorhandler.handle;
    
      RAISE;
  END begin_mail_in_session;

  ------------------------------------------------------------------------
  FUNCTION begin_mail(p_sender     IN VARCHAR2,
                      p_recipients IN VARCHAR2,
                      p_subject    IN VARCHAR2)
    RETURN utl_smtp.connection IS
    v_conn utl_smtp.connection;
  BEGIN
    dbms_application_info.set_module('utl.pkg_emailer.begin_mail',null);
  
    v_conn := begin_session;
    begin_mail_in_session(v_conn, p_sender, p_recipients, p_subject);
    
    dbms_application_info.set_module(null,null);
    
    RETURN v_conn;
  EXCEPTION
    WHEN OTHERS THEN
      pkg_errorhandler.handle;
    
      RAISE;
  END begin_mail;

  ------------------------------------------------------------------------
  PROCEDURE end_mail_in_session(p_conn IN OUT NOCOPY utl_smtp.connection) IS
  BEGIN
    dbms_application_info.set_module('utl.pkg_emailer.end_mail_in_session',null);

    utl_smtp.close_data(p_conn);
    
    dbms_application_info.set_module(null,null);
  EXCEPTION
    WHEN OTHERS THEN
      pkg_errorhandler.handle;
    
      RAISE;
  END end_mail_in_session;
  ------------------------------------------------------------------------
  PROCEDURE end_session(p_conn IN OUT NOCOPY utl_smtp.connection) IS
  BEGIN
    dbms_application_info.set_module('utl.pkg_emailer.end_session',null);

    utl_smtp.quit(p_conn);
    
    dbms_application_info.set_module(null,null);
  EXCEPTION
    WHEN OTHERS THEN
      pkg_errorhandler.handle;
    
      RAISE;
  END end_session;
  ------------------------------------------------------------------------
  PROCEDURE end_mail(p_conn IN OUT NOCOPY utl_smtp.connection) IS
  BEGIN
    dbms_application_info.set_module('utl.pkg_emailer.end_mail',null);

    end_mail_in_session(p_conn);
    end_session(p_conn);

    dbms_application_info.set_module(null,null);
  EXCEPTION
    WHEN OTHERS THEN
      pkg_errorhandler.handle;
    
      RAISE;
  END end_mail;

  -- procedure to send an email optionally with a single attachment 
  -- p_sender is optional, if not provided value for email.default_sender config property
  -- p_recipients is a list of email addresses  separated by either a "," or a ";"
  -- The format of an email address is one of these:
  --   someone@some-domain
  --   "Someone at some domain" <someone@some-domain>
  --   Someone at some domain <someone@some-domain>
  -- if p_attachment is not null this is attached as a file with the name p_attachment_name
  -- if p_attachment2 is not null this is attached as a file with the name p_attachment2_name
  PROCEDURE send(p_sender          IN VARCHAR2,
                 p_recipients      IN VARCHAR2,
                 p_subject         IN VARCHAR2,
                 p_body            IN VARCHAR2,
                 p_attachment_name IN VARCHAR2 DEFAULT NULL,
                 p_attachment      IN CLOB DEFAULT NULL,
                 p_attachment2_name IN VARCHAR2 DEFAULT NULL,
                 p_attachment2      IN CLOB DEFAULT NULL) 
  AS
    v_conn            utl_smtp.connection;
    v_attachment      CLOB;
    v_attachment_name VARCHAR2(1000);
  BEGIN
    dbms_application_info.set_module('utl.pkg_emailer.send',null);
  
    IF p_subject IS NULL
    OR p_body IS NULL
    OR p_recipients IS NULL
    THEN
      RAISE pkg_exceptions.e_email_param_missing;
    END IF;
  
    -- Open the SMTP connection and write mail header
    -- ------------------------
    v_conn := begin_mail(p_sender, p_recipients, p_subject);
  
    -- Write body of message
    -- ---------------------
    attach_data(v_conn, p_body, 'text/plain', TRUE, NULL, FALSE);
  
    -- Append the attachments
    -- ---------------------   
    
    IF p_attachment IS NOT NULL
    THEN
      IF  utl.pkg_config.get_variable_int(gc_max_attach_size_config_key) IS NOT NULL
      AND dbms_lob.getlength(p_attachment) > utl.pkg_config.get_variable_int(gc_max_attach_size_config_key)
      THEN
        v_attachment := p_attachment;
        dbms_lob.trim(v_attachment,utl.pkg_config.get_variable_int(gc_max_attach_size_config_key));
        
        v_attachment_name := p_attachment_name || '(truncated)';
      ELSE    
        v_attachment := p_attachment;
        v_attachment_name := p_attachment_name;
      END IF;
      
      IF p_attachment2 IS NOT NULL
      THEN
        attach_data(v_conn,
                    v_attachment,
                    'application/octet-stream',
                    FALSE,
                    nvl(v_attachment_name, 'attachment.txt'),
                    FALSE);
      ELSE
        attach_data(v_conn,
                    v_attachment,
                    'application/octet-stream',
                    FALSE,
                    nvl(v_attachment_name, 'attachment.txt'),
                    TRUE);
      END IF;
    END IF;
       
    IF p_attachment2 IS NOT NULL
    THEN
      IF  utl.pkg_config.get_variable_int(gc_max_attach_size_config_key) IS NOT NULL
      AND dbms_lob.getlength(p_attachment2) > utl.pkg_config.get_variable_int(gc_max_attach_size_config_key)
      THEN
        v_attachment := p_attachment2;
        dbms_lob.trim(v_attachment,utl.pkg_config.get_variable_int(gc_max_attach_size_config_key));
        
        v_attachment_name := p_attachment2_name || '(truncated)';
      ELSE    
        v_attachment := p_attachment2;
        v_attachment_name := p_attachment2_name;
      END IF;
      
      attach_data(v_conn,
                  v_attachment,
                  'application/octet-stream',
                  FALSE,
                  nvl(v_attachment_name, 'attachment.txt'),
                  TRUE);            
    END IF;
    
    IF p_attachment2 IS NULL AND p_attachment IS NULL
    THEN
      write_boundary(v_conn, TRUE);
    END IF;
  
    -- end mail and close connection
    end_mail(v_conn);
  
    dbms_application_info.set_module('utl.pkg_emailer.send',null);
  EXCEPTION
    WHEN OTHERS THEN
      pkg_errorhandler.handle;
    
      pkg_errorhandler.log_sqlerror(p_incident=>false);
      -- failures to send emails are just logged and not raised as exceptions as this may cause 
      -- calling processes to fail
  END send;

END pkg_emailer;
/
