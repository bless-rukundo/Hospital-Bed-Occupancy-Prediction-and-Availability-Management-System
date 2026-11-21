CREATE OR REPLACE VIEW v_capacity_alerts AS
SELECT *
  FROM v_bed_summary
 WHERE occupancy_pct >= alert_threshold_pct;
