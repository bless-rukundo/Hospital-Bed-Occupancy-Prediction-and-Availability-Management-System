CREATE OR REPLACE TRIGGER trg_validate_admission_bed
BEFORE INSERT OR UPDATE OF bed_id, admission_status ON admissions
FOR EACH ROW
DECLARE
    v_status beds.bed_status%TYPE;
BEGIN
    IF :NEW.admission_status = 'ADMITTED' THEN
        IF :NEW.bed_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'An ADMITTED patient must have a bed.');
        END IF;
        SELECT bed_status INTO v_status FROM beds WHERE bed_id = :NEW.bed_id;
        IF v_status <> 'AVAILABLE' THEN
            RAISE_APPLICATION_ERROR(-20002, 'The selected bed is not available.');
        END IF;
    END IF;
END;
/
