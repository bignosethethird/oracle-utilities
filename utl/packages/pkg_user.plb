CREATE OR REPLACE PACKAGE BODY
------------------------------------------------------------------------
------------------------------------------------------------------------
--  Functions to provide user related information
------------------------------------------------------------------------
 utl.pkg_user AS

  -- returns a comma delimited list of all the roles the current user has
  
  FUNCTION get_roles RETURN VARCHAR2
  IS
    v_roles VARCHAR2(1000):=null;
  BEGIN
    FOR rec_role IN (SELECT lower(granted_role) userrole
                     FROM   role_role_privs
                     UNION
                     SELECT lower(granted_role) userrole
                     FROM   user_role_privs)
    LOOP
        v_roles := v_roles || ',' || rec_role.userrole;
    END LOOP;
    
    v_roles := substr(v_roles,2);
    
    RETURN v_roles;
  EXCEPTION
    WHEN OTHERS THEN
      utl.pkg_errorhandler.handle;
      utl.pkg_errorhandler.log_sqlerror(p_incident => FALSE);
      RAISE;
  END get_roles;
  
END pkg_user;
------------------------------------------------------------------------
-- end of file
------------------------------------------------------------------------
/
