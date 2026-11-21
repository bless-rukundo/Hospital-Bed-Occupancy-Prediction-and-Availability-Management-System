-- Central authorization. Every public operational procedure calls assert_role.
CREATE OR REPLACE PACKAGE pkg_security AS
    PROCEDURE assert_role (
        p_user_id       IN app_users.user_id%TYPE,
        p_required_role IN user_roles.role_name%TYPE
    );
END pkg_security;
/

CREATE OR REPLACE PACKAGE BODY pkg_security AS
    PROCEDURE assert_role (
        p_user_id       IN app_users.user_id%TYPE,
        p_required_role IN user_roles.role_name%TYPE
    ) AS
        v_active app_users.active_flag%TYPE;
        v_role_count PLS_INTEGER;
    BEGIN
        SELECT active_flag INTO v_active
          FROM app_users
         WHERE user_id = p_user_id;

        IF v_active <> 'Y' THEN
            RAISE_APPLICATION_ERROR(-20020, 'Access denied: this user account is inactive.');
        END IF;

        SELECT COUNT(*) INTO v_role_count
          FROM user_roles
         WHERE user_id = p_user_id
           AND role_name = p_required_role;

        IF v_role_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20021,
                'Access denied: ' || p_required_role || ' role is required for this action.');
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20022, 'Access denied: user account was not found.');
    END assert_role;
END pkg_security;
/

SHOW ERRORS PACKAGE
SHOW ERRORS PACKAGE BODY
