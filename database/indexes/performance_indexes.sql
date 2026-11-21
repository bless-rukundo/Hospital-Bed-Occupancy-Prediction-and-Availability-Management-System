CREATE INDEX ix_admissions_patient ON admissions(patient_id);
CREATE INDEX ix_admissions_bed_status ON admissions(bed_id, admission_status);
CREATE INDEX ix_beds_room_status ON beds(room_id, bed_status);
CREATE INDEX ix_history_bed_date ON bed_status_history(bed_id, changed_at);
CREATE INDEX ix_request_status ON admission_requests(department_id, request_status);
CREATE INDEX ix_alert_open ON capacity_alerts(department_id, alert_status);
CREATE UNIQUE INDEX uq_active_admission_bed
    ON admissions (CASE WHEN admission_status = 'ADMITTED' THEN bed_id END);
