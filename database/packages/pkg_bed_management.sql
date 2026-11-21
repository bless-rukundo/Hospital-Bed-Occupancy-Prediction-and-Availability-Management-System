-- HBOPAMS operational workflow.
-- Application code should call this package instead of directly changing BEDS or ADMISSIONS.

CREATE OR REPLACE PACKAGE pkg_bed_management AS
    PROCEDURE admit_patient (
        p_user_id                 IN app_users.user_id%TYPE,
        p_patient_id              IN patients.patient_id%TYPE,
        p_department_id           IN departments.department_id%TYPE,
        p_admitted_by_staff_id    IN staff.staff_id%TYPE,
        p_expected_discharge_date IN DATE DEFAULT NULL,
        p_admission_id            OUT admissions.admission_id%TYPE
    );

    PROCEDURE discharge_patient (
        p_user_id                  IN app_users.user_id%TYPE,
        p_admission_id             IN admissions.admission_id%TYPE,
        p_recorded_by_staff_id     IN staff.staff_id%TYPE
    );

    PROCEDURE mark_bed_clean (
        p_user_id                  IN app_users.user_id%TYPE,
        p_bed_id                   IN beds.bed_id%TYPE,
        p_confirmed_by_staff_id    IN staff.staff_id%TYPE
    );

    FUNCTION department_occupancy_pct (
        p_department_id IN departments.department_id%TYPE
    ) RETURN NUMBER;
END pkg_bed_management;
/

CREATE OR REPLACE PACKAGE BODY pkg_bed_management AS

    PROCEDURE admit_patient (
        p_user_id                 IN app_users.user_id%TYPE,
        p_patient_id              IN patients.patient_id%TYPE,
        p_department_id           IN departments.department_id%TYPE,
        p_admitted_by_staff_id    IN staff.staff_id%TYPE,
        p_expected_discharge_date IN DATE DEFAULT NULL,
        p_admission_id            OUT admissions.admission_id%TYPE
    ) AS
        v_bed_id     beds.bed_id%TYPE;
        v_bed_status beds.bed_status%TYPE;
    BEGIN
        pkg_security.assert_role(p_user_id, 'NURSE');
        -- Find a candidate. The next SELECT locks it, so two sessions cannot claim it.
        BEGIN
            SELECT bed_id
              INTO v_bed_id
              FROM (
                  SELECT b.bed_id
                    FROM beds b
                    JOIN rooms r ON r.room_id = b.room_id
                   WHERE r.department_id = p_department_id
                     AND b.bed_status = 'AVAILABLE'
                   ORDER BY b.bed_id
              )
             WHERE ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20010, 'No available bed exists in this department.');
        END;

        SELECT bed_status
          INTO v_bed_status
          FROM beds
         WHERE bed_id = v_bed_id
           FOR UPDATE;

        IF v_bed_status <> 'AVAILABLE' THEN
            RAISE_APPLICATION_ERROR(-20011, 'The selected bed was just assigned. Please try again.');
        END IF;

        -- The validation trigger confirms the bed is available at insert time.
        INSERT INTO admissions (
            patient_id, department_id, bed_id, admitted_by_staff_id,
            expected_discharge_date, admission_status
        ) VALUES (
            p_patient_id, p_department_id, v_bed_id, p_admitted_by_staff_id,
            p_expected_discharge_date, 'ADMITTED'
        ) RETURNING admission_id INTO p_admission_id;

        UPDATE beds
           SET bed_status = 'OCCUPIED', last_status_at = SYSTIMESTAMP
         WHERE bed_id = v_bed_id;

        INSERT INTO audit_log (entity_name, entity_id, action_name, details)
        VALUES ('ADMISSIONS', p_admission_id, 'ADMIT', 'Assigned bed ' || v_bed_id);
    END admit_patient;

    PROCEDURE discharge_patient (
        p_user_id              IN app_users.user_id%TYPE,
        p_admission_id         IN admissions.admission_id%TYPE,
        p_recorded_by_staff_id IN staff.staff_id%TYPE
    ) AS
        v_bed_id beds.bed_id%TYPE;
    BEGIN
        pkg_security.assert_role(p_user_id, 'NURSE');
        SELECT bed_id
          INTO v_bed_id
          FROM admissions
         WHERE admission_id = p_admission_id
           AND admission_status = 'ADMITTED'
           FOR UPDATE;

        UPDATE admissions
           SET admission_status = 'DISCHARGED',
               discharged_at = SYSTIMESTAMP,
               discharge_recorded_by_id = p_recorded_by_staff_id
         WHERE admission_id = p_admission_id;

        -- Deliberately not AVAILABLE: cleaning confirmation is a separate safety step.
        UPDATE beds
           SET bed_status = 'CLEANING', last_status_at = SYSTIMESTAMP
         WHERE bed_id = v_bed_id;

        INSERT INTO audit_log (entity_name, entity_id, action_name, details)
        VALUES ('ADMISSIONS', p_admission_id, 'DISCHARGE', 'Bed ' || v_bed_id || ' moved to CLEANING');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20012, 'Active admission not found.');
    END discharge_patient;

    PROCEDURE mark_bed_clean (
        p_user_id               IN app_users.user_id%TYPE,
        p_bed_id                IN beds.bed_id%TYPE,
        p_confirmed_by_staff_id IN staff.staff_id%TYPE
    ) AS
    BEGIN
        pkg_security.assert_role(p_user_id, 'NURSE');
        UPDATE beds
           SET bed_status = 'AVAILABLE', last_status_at = SYSTIMESTAMP
         WHERE bed_id = p_bed_id
           AND bed_status = 'CLEANING';

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20013, 'Only a CLEANING bed can be marked AVAILABLE.');
        END IF;

        INSERT INTO audit_log (entity_name, entity_id, action_name, details)
        VALUES ('BEDS', p_bed_id, 'CLEAN_CONFIRMED', 'Confirmed by staff ' || p_confirmed_by_staff_id);
    END mark_bed_clean;

    FUNCTION department_occupancy_pct (
        p_department_id IN departments.department_id%TYPE
    ) RETURN NUMBER IS
        v_pct NUMBER;
    BEGIN
        SELECT NVL(occupancy_pct, 0)
          INTO v_pct
          FROM v_bed_summary
         WHERE department_id = p_department_id;
        RETURN v_pct;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20014, 'Department not found.');
    END department_occupancy_pct;
END pkg_bed_management;
/

SHOW ERRORS PACKAGE
SHOW ERRORS PACKAGE BODY
