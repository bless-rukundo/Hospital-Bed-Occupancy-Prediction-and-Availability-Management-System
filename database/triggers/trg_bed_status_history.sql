CREATE OR REPLACE TRIGGER trg_bed_status_history
AFTER UPDATE OF bed_status ON beds
FOR EACH ROW
WHEN (OLD.bed_status <> NEW.bed_status)
BEGIN
    INSERT INTO bed_status_history (bed_id, old_status, new_status, change_reason)
    VALUES (:NEW.bed_id, :OLD.bed_status, :NEW.bed_status, 'Status changed through application workflow');
END;
/
