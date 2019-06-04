CREATE OR REPLACE PACKAGE BODY utl.pkg_audit_trail IS
  -------------------------------------------------
  -------------------------------------------------
  -- Package for the querying of audit trail entries
  -------------------------------------------------
  
  -- get a count of audit trail entries, optionally for
  --     p_user_id
  --     p_object
  --     p_from_date   -- between two dates
  --     p_to_date
 
  FUNCTION get_count(p_user_id     IN audit_trail.user_id%TYPE,
                     p_object      IN audit_trail.object%TYPE,
                     p_from_date   IN DATE,
                     p_to_date     IN DATE) RETURN INTEGER
  AS
    v_count INTEGER;
  BEGIN
    dbms_application_info.set_module('utl.pkg_audit_trail.get_count',null);
    
    SELECT COUNT(*)
    INTO   v_count
    FROM   audit_trail at
    WHERE  ((p_user_id IS NOT NULL AND at.user_id = p_user_id) OR (p_user_id IS NULL))
    AND    ((p_object IS NOT NULL AND at.object = p_object) OR (p_object IS NULL))
    AND    ((p_from_date IS NOT NULL AND at.date_time > p_from_date) OR (p_from_date IS NULL))
    AND    ((p_to_date IS NOT NULL AND at.date_time < p_to_date+1) OR (p_to_date IS NULL));

    dbms_application_info.set_module(null,null);
      
    RETURN v_count;  
  EXCEPTION
    WHEN OTHERS THEN
      utl.pkg_errorhandler.handle;
      utl.pkg_errorhandler.log_sqlerror(p_incident=>FALSE);
      RAISE;
  END get_count;
  
  -- get a result set of audit trail entries, optionally for
  --     p_user_id
  --     p_object
  --     p_from_date   -- between two dates
  --     p_to_date
  -- returns a result set
  --     utl.audit_trail.date_time "Date/Time"
  --     utl.audit_trail.action "Action"
  --     utl.audit_trail.user_id "User"
  --     utl.audit_trail.object "Object"
  --     utl.audit_trail.before_image "Before Image"
  --     utl.audit_trail.after_image "After Image"
  --     utl.audit_trail.reason "Reason"
  -- ordered by date_time descending
  
  FUNCTION get_list(p_user_id     IN audit_trail.user_id%TYPE,
                    p_object      IN audit_trail.object%TYPE,
                    p_from_date   IN DATE,
                    p_to_date     IN DATE) RETURN utl.global.t_result_set
  AS
   cur_list utl.global.t_result_set;
  BEGIN
    dbms_application_info.set_module('utl.pkg_audit_trail.get_list',null);
    
    OPEN cur_list
    FOR 
    SELECT to_char(at.date_time, 'dd-MON-yyyy hh24:mi:ss'),
           at.action,
           at.user_id,
           at.object,
           at.before_image,
           at.after_image,
           at.reason
    FROM   audit_trail at
    WHERE  ((p_user_id IS NOT NULL AND at.user_id = p_user_id) OR (p_user_id IS NULL))
    AND    ((p_object IS NOT NULL AND at.object = p_object) OR (p_object IS NULL))
    AND    ((p_from_date IS NOT NULL AND at.date_time > p_from_date) OR (p_from_date IS NULL))
    AND    ((p_to_date IS NOT NULL AND at.date_time < p_to_date+1) OR (p_to_date IS NULL))
    ORDER BY at.date_time DESC;

    dbms_application_info.set_module(null,null);
      
    RETURN cur_list;  
  EXCEPTION
    WHEN OTHERS THEN
      utl.pkg_errorhandler.handle;
      utl.pkg_errorhandler.log_sqlerror(p_incident=>FALSE);
      RAISE;
  END get_list;
             
  -- gets a count of audit trail entry users
  FUNCTION get_user_dropdown_count RETURN INTEGER
  IS
    v_count INTEGER;
  BEGIN
    dbms_application_info.set_module('utl.pkg_audit_trail.get_user_dropdown_count',null);
    
    SELECT COUNT(*)
    INTO   v_count
    FROM
    (
      SELECT DISTINCT at.user_id
      FROM   audit_trail at
    );

    dbms_application_info.set_module(null,null);

    RETURN v_count;  
  EXCEPTION
    WHEN OTHERS THEN
      utl.pkg_errorhandler.handle;
      utl.pkg_errorhandler.log_sqlerror(p_incident=>FALSE);
      RAISE;
  END get_user_dropdown_count;
  
  -- gets a list of audit trail entry users
  FUNCTION get_user_dropdown_list RETURN utl.global.t_result_set
  IS
    cur_list utl.global.t_result_set;
  BEGIN
    dbms_application_info.set_module('utl.pkg_audit_trail.get_user_dropdown_list',null);
    
    OPEN cur_list FOR
      SELECT DISTINCT at.user_id
      FROM   audit_trail at
      ORDER BY at.user_id;

    dbms_application_info.set_module(null,null);

    RETURN cur_list;  
  EXCEPTION
    WHEN OTHERS THEN
      utl.pkg_errorhandler.handle;
      utl.pkg_errorhandler.log_sqlerror(p_incident=>FALSE);
      RAISE;
  END get_user_dropdown_list;
  
  -- gets a count of audit trail objects
  FUNCTION get_object_dropdown_count RETURN INTEGER
  IS
    v_count INTEGER;
  BEGIN
    dbms_application_info.set_module('utl.pkg_audit_trail.get_object_dropdown_count',null);
    
    SELECT COUNT(*)
    INTO   v_count
    FROM
    (
      SELECT DISTINCT at.object
      FROM   audit_trail at
    );

    dbms_application_info.set_module(null,null);

    RETURN v_count;  
  EXCEPTION
    WHEN OTHERS THEN
      utl.pkg_errorhandler.handle;
      utl.pkg_errorhandler.log_sqlerror(p_incident=>FALSE);
      RAISE;
  END get_object_dropdown_count;
  
  -- gets a list of audit trail entry objects
  FUNCTION get_object_dropdown_list RETURN utl.global.t_result_set
  IS
    cur_list utl.global.t_result_set;
  BEGIN
    dbms_application_info.set_module('utl.pkg_audit_trail.get_object_dropdown_list',null);
    
    OPEN cur_list FOR
      SELECT DISTINCT at.object
      FROM   audit_trail at
      ORDER BY at.object;

    dbms_application_info.set_module(null,null);

    RETURN cur_list;  
  EXCEPTION
    WHEN OTHERS THEN
      utl.pkg_errorhandler.handle;
      utl.pkg_errorhandler.log_sqlerror(p_incident=>FALSE);
      RAISE;
  END get_object_dropdown_list;
END pkg_audit_trail;
/
