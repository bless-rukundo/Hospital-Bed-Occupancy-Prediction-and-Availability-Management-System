-- Run after 01_schema.sql, 02_bed_management_package.sql, and 03_seed_demo_data.sql.
-- This demonstrates the intended state transitions using the public package interface.

SET SERVEROUTPUT ON

DECLARE
    v_patient_id    patients.patient_id%TYPE;
    v_department_id departments.department_id%TYPE;
    v_staff_id      staff.staff_id%TYPE;
    v_user_id       app_users.user_id%TYPE;
    v_admission_id  admissions.admission_id%TYPE;
    v_bed_id        beds.bed_id%TYPE;
BEGIN
    SELECT patient_id INTO v_patient_id
      FROM patients WHERE hospital_number = 'DEMO-0001';
    SELECT department_id INTO v_department_id
      FROM departments WHERE department_name = 'Medical';
    SELECT staff_id INTO v_staff_id
      FROM staff WHERE employee_number = 'N-001';
    SELECT user_id INTO v_user_id
      FROM app_users WHERE username = 'aline.nurse';

    pkg_bed_management.admit_patient(
        p_user_id                 => v_user_id,
        p_patient_id              => v_patient_id,
        p_department_id           => v_department_id,
        p_admitted_by_staff_id    => v_staff_id,
        p_expected_discharge_date => SYSDATE + 3,
        p_admission_id            => v_admission_id
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Admission created: ' || v_admission_id);

    SELECT bed_id INTO v_bed_id FROM admissions WHERE admission_id = v_admission_id;
    DBMS_OUTPUT.PUT_LINE('Assigned bed: ' || v_bed_id);
    DBMS_OUTPUT.PUT_LINE('Medical occupancy: ' ||
        pkg_bed_management.department_occupancy_pct(v_department_id) || '%');

    pkg_bed_management.discharge_patient(v_user_id, v_admission_id, v_staff_id);
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Discharged: bed is now CLEANING.');

    pkg_bed_management.mark_bed_clean(v_user_id, v_bed_id, v_staff_id);
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Cleaning confirmed: bed is now AVAILABLE.');
END;
/

SELECT bed_code, bed_status, last_status_at
  FROM beds
 ORDER BY bed_code;

SELECT old_status, new_status, changed_at, change_reason
  FROM bed_status_history
 ORDER BY changed_at;

SELECT entity_name, entity_id, action_name, action_at, details
  FROM audit_log
 ORDER BY action_at;
