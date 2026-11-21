-- Demonstration-only data. It is simulated operational data, not Kaggle historical data.

INSERT INTO departments (department_name, alert_threshold_pct) VALUES ('Medical', 85);
INSERT INTO departments (department_name, alert_threshold_pct) VALUES ('Surgical', 80);
INSERT INTO departments (department_name, alert_threshold_pct) VALUES ('Paediatrics', 85);

INSERT INTO rooms (department_id, room_number, room_type)
SELECT department_id, 'M-101', 'GENERAL' FROM departments WHERE department_name = 'Medical';
INSERT INTO rooms (department_id, room_number, room_type)
SELECT department_id, 'M-102', 'GENERAL' FROM departments WHERE department_name = 'Medical';
INSERT INTO rooms (department_id, room_number, room_type)
SELECT department_id, 'S-201', 'GENERAL' FROM departments WHERE department_name = 'Surgical';
INSERT INTO rooms (department_id, room_number, room_type)
SELECT department_id, 'P-301', 'GENERAL' FROM departments WHERE department_name = 'Paediatrics';

INSERT INTO beds (room_id, bed_code)
SELECT room_id, 'M101-A' FROM rooms WHERE room_number = 'M-101';
INSERT INTO beds (room_id, bed_code)
SELECT room_id, 'M101-B' FROM rooms WHERE room_number = 'M-101';
INSERT INTO beds (room_id, bed_code)
SELECT room_id, 'M102-A' FROM rooms WHERE room_number = 'M-102';
INSERT INTO beds (room_id, bed_code)
SELECT room_id, 'M102-B' FROM rooms WHERE room_number = 'M-102';
INSERT INTO beds (room_id, bed_code)
SELECT room_id, 'S201-A' FROM rooms WHERE room_number = 'S-201';
INSERT INTO beds (room_id, bed_code)
SELECT room_id, 'S201-B' FROM rooms WHERE room_number = 'S-201';
INSERT INTO beds (room_id, bed_code)
SELECT room_id, 'P301-A' FROM rooms WHERE room_number = 'P-301';
INSERT INTO beds (room_id, bed_code)
SELECT room_id, 'P301-B' FROM rooms WHERE room_number = 'P-301';

INSERT INTO staff (department_id, employee_number, first_name, last_name, staff_role)
SELECT department_id, 'N-001', 'Aline', 'Uwase', 'NURSE' FROM departments WHERE department_name = 'Medical';

INSERT INTO app_users (staff_id, username)
SELECT staff_id, 'aline.nurse' FROM staff WHERE employee_number = 'N-001';

INSERT INTO user_roles (user_id, role_name)
SELECT user_id, 'NURSE' FROM app_users WHERE username = 'aline.nurse';

INSERT INTO patients (hospital_number, first_name, last_name, date_of_birth, sex)
VALUES ('DEMO-0001', 'Jean', 'Mugisha', DATE '1988-05-12', 'MALE');

COMMIT;

-- Run this after 02_bed_management_package.sql to simulate an admission:
-- DECLARE v_admission_id NUMBER; BEGIN
--   pkg_bed_management.admit_patient(1, 1, 1, 1, SYSDATE + 3, v_admission_id);
--   COMMIT;
-- END;
-- /

SELECT * FROM v_bed_summary ORDER BY department_name;
