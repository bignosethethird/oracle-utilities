CREATE OR REPLACE PACKAGE BODY utl.pkg_helpdesk IS
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  gc_create_incident_yn_cfg_key CONSTANT VARCHAR2(50) := 'helpdesk.createincidentyn';
  gc_sys_email_cfg_key          CONSTANT VARCHAR2(50) := 'helpdesk.sysemailaddress';
  gc_sys_server_cfg_key         CONSTANT VARCHAR2(50) := 'helpdesk.sysserver';
  gc_incident_logger_cfg_key    CONSTANT VARCHAR2(50) := 'helpdesk.incidentlogger';
  gc_default_category_cfg_key   CONSTANT VARCHAR2(50) := 'helpdesk.defaultcategory';
  gc_default_type_cfg_key       CONSTANT VARCHAR2(50) := 'helpdesk.defaulttype';
  gc_default_item_cfg_key       CONSTANT VARCHAR2(50) := 'helpdesk.defaultitem';
    
  gc_urgency_low CONSTANT VARCHAR2(10) := 'Low';

  PROCEDURE create_incident(p_summary  IN VARCHAR2,
                            p_desc     IN VARCHAR2,
                            p_urgency  IN VARCHAR2 DEFAULT NULL,
                            p_category IN VARCHAR2 DEFAULT NULL,
                            p_type     IN VARCHAR2 DEFAULT NULL,
                            p_item     IN VARCHAR2 DEFAULT NULL,
                            p_logger   IN VARCHAR2 DEFAULT NULL) AS
    v_incident_body   VARCHAR2(32000);
    v_incident_logger VARCHAR2(255);
    v_sys_email       VARCHAR2(255);
    v_sys_server      VARCHAR2(255);
    
    v_default_category VARCHAR2(20);
    v_default_type     VARCHAR2(20);
    v_default_item     VARCHAR2(20);
    
    v_summary          VARCHAR2(128); -- these field sizes are fixed in line with Remedy
    v_description      VARCHAR2(255);
  BEGIN
    dbms_application_info.set_module('utl.pkg_errorhandler.create_incident',null);
  
    IF p_desc IS NULL
    THEN
      RAISE pkg_exceptions.e_incident_desc_missing;
    END IF;
  
    if(nvl(pkg_config.get_variable_string(gc_create_incident_yn_cfg_key),'N')='N')then
      pkg_logger.log(pkg_logger.gc_log_message_info,
                     'Helpdesk Incident not created for error.'||pkg_constants.gc_cr||pkg_constants.gc_cr||
                     p_summary ||pkg_constants.gc_cr||pkg_constants.gc_cr||
                     'Helpdesk incident creation is turned off');
    ELSE
      v_incident_logger := pkg_config.get_variable_string(gc_incident_logger_cfg_key);
      v_sys_email       := pkg_config.get_variable_string(gc_sys_email_cfg_key);
      v_sys_server      := pkg_config.get_variable_string(gc_sys_server_cfg_key);
    
      v_default_category := nvl(pkg_config.get_variable_string(gc_default_category_cfg_key),'IT Helpdesk');
      v_default_type     := nvl(pkg_config.get_variable_string(gc_default_type_cfg_key),'Business System');
      v_default_item     := nvl(pkg_config.get_variable_string(gc_default_item_cfg_key),'VCR - Production');
      
      IF v_incident_logger IS NOT NULL
      AND v_sys_email IS NOT NULL
      AND v_sys_server IS NOT NULL
      THEN
        IF p_summary IS NOT NULL
        THEN
          IF length(p_summary) > 128
          THEN
            v_summary := substr(p_summary,1,125) || '...';
          ELSE
            v_summary := p_summary;
          END IF;        
        ELSE
          IF length(p_desc) > 128
          THEN
            v_summary := substr(p_desc,1,128) || '...';
          ELSE
            v_summary := p_desc;
          END IF;
        END IF;
        -- remove any new lines or carriage returns from summary
        v_summary := replace(v_summary, utl.pkg_string.gc_cr);
        v_summary := replace(v_summary, utl.pkg_string.gc_crlf);
        v_summary := replace(v_summary, utl.pkg_string.gc_nl);
        
        IF length(p_desc) > 255
        THEN
          v_description := substr(p_desc,1,230) || '...truncated - see log';
        ELSE
          v_description := p_desc;
        END IF;

        v_incident_body := '#AR-Message-Begin                    Do Not Delete This Line' ||
                           pkg_constants.gc_cr ||
                           'Schema: +MISInboundEmail' ||
                           pkg_constants.gc_cr || 'Server: ' ||
                           v_sys_server || pkg_constants.gc_cr ||
                           'Action: Submit' || pkg_constants.gc_cr ||
                           'Format: Short' || pkg_constants.gc_cr ||
                           'Login*+ !240000005!: ' ||
                           lower(nvl(p_logger, v_incident_logger)) ||
                           pkg_constants.gc_cr || 'Summary* !536870913!: ' ||
                           v_summary ||
                           pkg_constants.gc_cr ||
                           'Status* !        7!: New' ||
                           pkg_constants.gc_cr ||
                          --'Urgency !240000009!: '||nvl(p_urgency, gc_urgency_low)||pkg_constants.gc_cr||
                          -- NOT CURRENTLY SUPPORTED BY REMEDY API
                           'Description* !536870914!: [$$'|| v_description ||'$$]'||
                           pkg_constants.gc_cr || 'Category* !200000003!: ' ||
                           nvl(p_category, v_default_category) ||
                           pkg_constants.gc_cr || 'Type* !200000004!: ' ||
                           nvl(p_type, v_default_type) ||
                           pkg_constants.gc_cr || 'Item* !200000005!: ' ||
                           nvl(p_item, v_default_item) ||
                           pkg_constants.gc_cr ||
                           '#AR-Message-End                      Do Not Delete This Line';
      
        pkg_logger.log_debug(v_incident_body);
      
        pkg_emailer.send(NULL,
                         v_sys_email,
                         v_summary,
                         v_incident_body);
      
        pkg_logger.log(pkg_logger.gc_log_message_info,
                       'Created Remedy Incident ' ||
                       v_summary);
      ELSE
        RAISE pkg_exceptions.e_no_hd_sys_cfg;
      END IF;
    END IF;
    
    dbms_application_info.set_module(null,null);
  EXCEPTION
    WHEN OTHERS THEN
      pkg_errorhandler.handle;
    
      RAISE;
  END create_incident;
END;
/
