CREATE OR REPLACE PACKAGE BODY utl.pkg_audit_trail_mod IS
  ------------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------
  -- Package for the creation of audit trail entries
  ------------------------------------------------------------------------------------------
  -- add an entry, relies on calling package/trigger to commit or rollback
  -- with following parameters
  -- p_action             e.g. INSERT, UPDATE, DELETE
  -- p_object             description of the item being changed
  -- p_owner              name of owner of object, typically the schema tha the object is in
  -- p_reason             mandatory text describing rationale for change
  -- p_before_image       description of deleted or pre-update record
  -- p_after_image        description of inserted or post-update record
  ------------------------------------------------------------------------------------------
  PROCEDURE insert_entry(p_action       audit_trail.action%TYPE,
                         p_object       audit_trail.object%TYPE,
                         p_owner        audit_trail.owner%TYPE,
                         p_reason       audit_trail.reason%TYPE,
                         p_before_image audit_trail.before_image%TYPE DEFAULT NULL,
                         p_after_image  audit_trail.after_image%TYPE DEFAULT NULL)
  AS
  BEGIN
    dbms_application_info.set_module('pkg_audit_trail.insert_entry',null);
    
    INSERT INTO audit_trail
      (date_time,
       action,
       user_id,
       owner,
       object,
       before_image,
       after_image,
       reason)
    VALUES
      (SYSDATE,
       p_action,
       USER,
       p_owner,
       p_object,
       p_before_image,
       p_after_image,
       p_reason);
       
    dbms_application_info.set_module(null,null);
  EXCEPTION
    WHEN OTHERS THEN
      utl.pkg_errorhandler.handle;
      
      RAISE;
  END insert_entry;
END pkg_audit_trail_mod;
/
