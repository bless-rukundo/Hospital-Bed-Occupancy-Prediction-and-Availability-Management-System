# HBOPAMS data processing pipeline

Run from the project root using the existing virtual environment:

```powershell
.\.venv\Scripts\python.exe run_pipeline.py
.\.venv\Scripts\python.exe -m unittest discover -s tests -v
```

The source files remain in `data/raw/Hospital bed mngnt/`. The pipeline writes local-only outputs to `data/cleaned/`, `data/processed/`, and `data/reports/`; all are ignored by Git because they can contain patient-level data.

`data/cleaned/` keeps every standardized source record. `data/processed/` contains structurally valid staging data. `data/reports/questionable_records.csv` identifies records excluded from the staging outputs and why.

## Oracle staging mapping

| Source output | Suggested staging table | Key candidates | Important Oracle types and validation |
|---|---|---|---|
| `patients_stg.csv` | `stg_patients_historical` | `patient_id` | `patient_id VARCHAR2(20)`, `name VARCHAR2(160)`, `age NUMBER(3) CHECK (age BETWEEN 0 AND 130)`, `arrival_date DATE`, `departure_date DATE`, `service VARCHAR2(50)`, `satisfaction NUMBER(3) CHECK (satisfaction BETWEEN 0 AND 100)`; departure must not precede arrival. |
| `services_weekly_stg.csv` | `stg_services_weekly` | `(week, service)` | `week NUMBER(2)`, `month NUMBER(2)`, `service VARCHAR2(50)`, bed/request/admission/refusal values `NUMBER(10)`, scores `NUMBER(3)`, `event VARCHAR2(30)`; admissions + refusals must equal requests. |
| `staff_stg.csv` | `stg_staff_historical` | `staff_id` | IDs and names `VARCHAR2`, role/service `VARCHAR2(50)`; `staff_id` is the parent reference for schedules. |
| `staff_schedule_stg.csv` | `stg_staff_schedule_historical` | `(week, source_staff_id)` | `week NUMBER(2)`, `staff_id VARCHAR2(20)` foreign key to staging staff, `source_staff_id VARCHAR2(20)` for lineage, `present NUMBER(1) CHECK (present IN (0,1))`. |

Recommended staging load order is: staff, patients, weekly service statistics, then staff schedules. These historical files do not contain physical bed IDs, admission identifiers, date of birth, patient contacts, or user/request metadata, so they must not be loaded directly into the existing operational `patients`, `admissions`, or `beds` tables. Use dedicated staging tables first, then an approved transformation into the operational model.

## Staff-schedule exception

The supplied `staff_schedule.csv` uses staff IDs that are entirely different from `staff.csv`. The pipeline only reconciles a schedule to the master when its normalized name, role, and service identify exactly one staff record. The remaining schedule rows are retained in cleaned output and reported for master-data remediation; they are not silently discarded or loaded with a broken foreign key.
