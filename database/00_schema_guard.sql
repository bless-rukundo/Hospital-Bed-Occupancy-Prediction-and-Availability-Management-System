-- This installer is intentionally restricted to the application schema.
DECLARE
    v_session_user   VARCHAR2(128) := SYS_CONTEXT('USERENV', 'SESSION_USER');
    v_current_schema VARCHAR2(128) := SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA');
BEGIN
    IF UPPER(v_session_user) <> 'HBOPAMS' OR UPPER(v_current_schema) <> 'HBOPAMS' THEN
        RAISE_APPLICATION_ERROR(-20990,
            'Installation must run as the HBOPAMS schema, not as SYSTEM or another user.');
    END IF;
END;
/
