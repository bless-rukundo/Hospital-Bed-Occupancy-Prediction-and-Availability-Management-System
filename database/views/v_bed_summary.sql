CREATE OR REPLACE VIEW v_bed_summary AS
SELECT d.department_id,
       d.department_name,
       COUNT(b.bed_id) AS total_beds,
       SUM(CASE WHEN b.bed_status = 'AVAILABLE' THEN 1 ELSE 0 END) AS available_beds,
       SUM(CASE WHEN b.bed_status = 'OCCUPIED' THEN 1 ELSE 0 END) AS occupied_beds,
       SUM(CASE WHEN b.bed_status = 'CLEANING' THEN 1 ELSE 0 END) AS cleaning_beds,
       SUM(CASE WHEN b.bed_status = 'MAINTENANCE' THEN 1 ELSE 0 END) AS maintenance_beds,
       ROUND(100 * SUM(CASE WHEN b.bed_status = 'OCCUPIED' THEN 1 ELSE 0 END)
             / NULLIF(COUNT(b.bed_id), 0), 2) AS occupancy_pct,
       d.alert_threshold_pct
  FROM departments d
  LEFT JOIN rooms r ON r.department_id = d.department_id
  LEFT JOIN beds b ON b.room_id = r.room_id
 GROUP BY d.department_id, d.department_name, d.alert_threshold_pct;
