create or replace trigger utl.tr_ar_config
  after insert or update on utl.config  
  referencing new as new old as old
  for each row
------------------------------------------------------------------------------
-- Audit trail for indicated table
------------------------------------------------------------------------------
declare
  gc_object_name constant varchar2(100) := 'System config. params.';
  gc_owner_name  constant varchar2(10)  := 'utl';
  gc_datetime_format varchar2(30):=nvl(utl.pkg_config.get_variable_string('GUIDateTimeFormat'),'YYYY/MM/DD HH24:MI');  
  v_old_value config.string_value%type;
  v_new_value config.string_value%type;
begin 
  if inserting then
    utl.pkg_audit_trail_mod.insert_entry(utl.pkg_audit_trail.gc_action_insert,
      gc_object_name,
      gc_owner_name,
      :new.change_reason,
      null,  -- no old value
      'Parameter: '||:new.variable||utl.pkg_string.gc_nl||
      'Description: '||:new.description||utl.pkg_string.gc_nl||
      'Value: '||coalesce(to_char(:new.int_value),to_char(:new.float_value),to_char(:new.date_value,gc_datetime_format),:new.string_value));
  elsif deleting then
    utl.pkg_audit_trail_mod.insert_entry(utl.pkg_audit_trail.gc_action_delete,
      gc_object_name,
      gc_owner_name,
      :old.change_reason,
      'Parameter: '||:old.variable||utl.pkg_string.gc_nl||
      'Description: '||:old.description||utl.pkg_string.gc_nl||
      'Value: '||coalesce(to_char(:old.int_value),to_char(:old.float_value),to_char(:old.date_value,gc_datetime_format),:old.string_value),
      null);  -- new new value
  elsif updating then
    if(:old.variable<>'SchedulerFSMScanDuration')then
      v_old_value:=coalesce(to_char(:old.int_value),to_char(:old.float_value),to_char(:old.date_value,gc_datetime_format),:old.string_value);
      v_new_value:=coalesce(to_char(:new.int_value),to_char(:new.float_value),to_char(:new.date_value,gc_datetime_format),:new.string_value);
      if(v_old_value<>v_new_value)then
        utl.pkg_audit_trail_mod.insert_entry(utl.pkg_audit_trail.gc_action_update,
          gc_object_name,
          gc_owner_name,
          :new.change_reason,      
          'Parameter: '||:old.variable||utl.pkg_string.gc_nl||
          'Description: '||:old.description||utl.pkg_string.gc_nl||
          'Value: '||coalesce(to_char(:old.int_value),to_char(:old.float_value),to_char(:old.date_value,gc_datetime_format),:old.string_value),
          'Parameter: '||:new.variable||utl.pkg_string.gc_nl||
          'Description: '||:new.description||utl.pkg_string.gc_nl||
          'Value: '||coalesce(to_char(:new.int_value),to_char(:new.float_value),to_char(:new.date_value,gc_datetime_format),:new.string_value));      
      end if;
    end if;
  end if;
exception 
  when others then
    utl.pkg_errorhandler.handle;    
    raise;  
end tr_ar_config;
/
