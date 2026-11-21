ALTER TABLE departments ADD PRIMARY KEY (department_id);
ALTER TABLE departments ADD CONSTRAINT uq_department_name UNIQUE (department_name);
ALTER TABLE departments ADD CONSTRAINT ck_dept_threshold CHECK (alert_threshold_pct BETWEEN 1 AND 100);

ALTER TABLE patients ADD PRIMARY KEY (patient_id);
ALTER TABLE patients ADD CONSTRAINT uq_patient_hospital_number UNIQUE (hospital_number);
ALTER TABLE patients ADD CONSTRAINT ck_patient_sex CHECK (sex IN ('FEMALE', 'MALE', 'OTHER', 'UNKNOWN'));

ALTER TABLE staff ADD PRIMARY KEY (staff_id);
ALTER TABLE staff ADD CONSTRAINT uq_staff_employee_number UNIQUE (employee_number);
ALTER TABLE staff ADD CONSTRAINT fk_staff_department FOREIGN KEY (department_id) REFERENCES departments(department_id);
ALTER TABLE staff ADD CONSTRAINT ck_staff_role CHECK (staff_role IN ('RECEPTIONIST', 'NURSE', 'DOCTOR', 'ADMINISTRATOR'));
ALTER TABLE staff ADD CONSTRAINT ck_staff_active CHECK (active_flag IN ('Y', 'N'));

ALTER TABLE app_users ADD PRIMARY KEY (user_id);
ALTER TABLE app_users ADD CONSTRAINT uq_app_user_staff UNIQUE (staff_id);
ALTER TABLE app_users ADD CONSTRAINT uq_app_user_username UNIQUE (username);
ALTER TABLE app_users ADD CONSTRAINT fk_app_user_staff FOREIGN KEY (staff_id) REFERENCES staff(staff_id);
ALTER TABLE app_users ADD CONSTRAINT ck_app_user_active CHECK (active_flag IN ('Y', 'N'));

ALTER TABLE user_roles ADD PRIMARY KEY (user_role_id);
ALTER TABLE user_roles ADD CONSTRAINT uq_user_role UNIQUE (user_id, role_name);
ALTER TABLE user_roles ADD CONSTRAINT fk_user_role_user FOREIGN KEY (user_id) REFERENCES app_users(user_id);
ALTER TABLE user_roles ADD CONSTRAINT fk_user_role_assigner FOREIGN KEY (assigned_by_id) REFERENCES app_users(user_id);
ALTER TABLE user_roles ADD CONSTRAINT ck_user_role_name CHECK (role_name IN ('RECEPTIONIST', 'NURSE', 'DOCTOR', 'ADMINISTRATOR'));

ALTER TABLE rooms ADD PRIMARY KEY (room_id);
ALTER TABLE rooms ADD CONSTRAINT uq_room_department_number UNIQUE (department_id, room_number);
ALTER TABLE rooms ADD CONSTRAINT fk_room_department FOREIGN KEY (department_id) REFERENCES departments(department_id);
ALTER TABLE rooms ADD CONSTRAINT ck_room_type CHECK (room_type IN ('GENERAL', 'PRIVATE', 'ICU', 'ISOLATION'));

ALTER TABLE beds ADD PRIMARY KEY (bed_id);
ALTER TABLE beds ADD CONSTRAINT uq_bed_code UNIQUE (bed_code);
ALTER TABLE beds ADD CONSTRAINT fk_bed_room FOREIGN KEY (room_id) REFERENCES rooms(room_id);
ALTER TABLE beds ADD CONSTRAINT ck_bed_status CHECK (bed_status IN ('AVAILABLE', 'OCCUPIED', 'CLEANING', 'MAINTENANCE'));

ALTER TABLE admissions ADD PRIMARY KEY (admission_id);
ALTER TABLE admissions ADD CONSTRAINT fk_admission_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id);
ALTER TABLE admissions ADD CONSTRAINT fk_admission_department FOREIGN KEY (department_id) REFERENCES departments(department_id);
ALTER TABLE admissions ADD CONSTRAINT fk_admission_bed FOREIGN KEY (bed_id) REFERENCES beds(bed_id);
ALTER TABLE admissions ADD CONSTRAINT fk_admitted_by FOREIGN KEY (admitted_by_staff_id) REFERENCES staff(staff_id);
ALTER TABLE admissions ADD CONSTRAINT fk_discharged_by FOREIGN KEY (discharge_recorded_by_id) REFERENCES staff(staff_id);
ALTER TABLE admissions ADD CONSTRAINT ck_admission_status CHECK (admission_status IN ('PENDING', 'ADMITTED', 'DISCHARGED', 'CANCELLED'));
ALTER TABLE admissions ADD CONSTRAINT ck_discharge_after_admission CHECK (discharged_at IS NULL OR discharged_at >= admitted_at);

ALTER TABLE admission_requests ADD PRIMARY KEY (request_id);
ALTER TABLE admission_requests ADD CONSTRAINT fk_request_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id);
ALTER TABLE admission_requests ADD CONSTRAINT fk_request_department FOREIGN KEY (department_id) REFERENCES departments(department_id);
ALTER TABLE admission_requests ADD CONSTRAINT fk_request_requester FOREIGN KEY (requested_by_user_id) REFERENCES app_users(user_id);
ALTER TABLE admission_requests ADD CONSTRAINT fk_request_reviewer FOREIGN KEY (reviewed_by_user_id) REFERENCES app_users(user_id);
ALTER TABLE admission_requests ADD CONSTRAINT ck_request_priority CHECK (priority_level IN ('ROUTINE', 'URGENT', 'EMERGENCY'));
ALTER TABLE admission_requests ADD CONSTRAINT ck_request_status CHECK (request_status IN ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED'));

ALTER TABLE bed_status_history ADD PRIMARY KEY (bed_status_history_id);
ALTER TABLE bed_status_history ADD CONSTRAINT fk_bed_history_bed FOREIGN KEY (bed_id) REFERENCES beds(bed_id);
ALTER TABLE bed_status_history ADD CONSTRAINT fk_bed_history_staff FOREIGN KEY (changed_by_staff_id) REFERENCES staff(staff_id);
ALTER TABLE bed_status_history ADD CONSTRAINT ck_history_old_status CHECK (old_status IS NULL OR old_status IN ('AVAILABLE', 'OCCUPIED', 'CLEANING', 'MAINTENANCE'));
ALTER TABLE bed_status_history ADD CONSTRAINT ck_history_new_status CHECK (new_status IN ('AVAILABLE', 'OCCUPIED', 'CLEANING', 'MAINTENANCE'));

ALTER TABLE audit_log ADD PRIMARY KEY (audit_id);

ALTER TABLE capacity_alerts ADD PRIMARY KEY (alert_id);
ALTER TABLE capacity_alerts ADD CONSTRAINT fk_alert_department FOREIGN KEY (department_id) REFERENCES departments(department_id);
ALTER TABLE capacity_alerts ADD CONSTRAINT fk_alert_resolver FOREIGN KEY (resolved_by_id) REFERENCES app_users(user_id);
ALTER TABLE capacity_alerts ADD CONSTRAINT ck_alert_type CHECK (alert_type IN ('HIGH_OCCUPANCY', 'NO_AVAILABLE_BEDS', 'FORECAST_CAPACITY'));
ALTER TABLE capacity_alerts ADD CONSTRAINT ck_alert_status CHECK (alert_status IN ('OPEN', 'RESOLVED'));

ALTER TABLE data_load_runs ADD PRIMARY KEY (load_run_id);
ALTER TABLE data_load_runs ADD CONSTRAINT ck_load_status CHECK (load_status IN ('RUNNING', 'COMPLETED', 'FAILED'));
ALTER TABLE rejected_data_rows ADD PRIMARY KEY (rejected_row_id);
ALTER TABLE rejected_data_rows ADD CONSTRAINT fk_rejected_load FOREIGN KEY (load_run_id) REFERENCES data_load_runs(load_run_id);
