# Database foundation: what to understand

## Relationship picture

```text
Department 1--many Room 1--many Bed
     |                         |
     |                         +--many BedStatusHistory
     +--many Admission --1 Patient
                    |
                    +--0..1 Bed (while the patient is admitted)
```

`departments`, `rooms`, and `beds` describe hospital capacity. `admissions` describes a patient's stay. Keeping these separate is normalization: a room number is saved once, not repeated for each patient.

## Important rules already enforced

1. A bed status must be one of `AVAILABLE`, `OCCUPIED`, `CLEANING`, or `MAINTENANCE`.
2. One department cannot have duplicate room numbers.
3. One bed cannot have two active admissions. The function-based unique index permits many old admissions but only one whose status is `ADMITTED`.
4. An admitted patient needs a bed, and the chosen bed must currently be available.
5. A discharge time cannot be earlier than admission time.
6. Any change to a bed's status is recorded automatically in `bed_status_history`.

## Why status becomes CLEANING after discharge

Discharge is not the same as availability. The upcoming PL/SQL package will move the state as follows:

```text
AVAILABLE -> OCCUPIED -> CLEANING -> AVAILABLE
                     \-> MAINTENANCE -> AVAILABLE
```

Only an explicit cleaning-confirmation operation may change `CLEANING` to `AVAILABLE`.

## Try these read-only queries after creating the schema

```sql
SELECT * FROM v_bed_summary;
SELECT * FROM v_capacity_alerts;
SELECT constraint_name, constraint_type FROM user_constraints ORDER BY table_name;
```

## Next lesson

The `pkg_bed_management` package puts related procedures and functions behind one safe interface: the application calls `admit_patient`, `discharge_patient`, and `mark_bed_clean`, instead of running arbitrary `UPDATE` statements.

## How to verify the workflow

After running `install.sql`, `demo_data/seed_demo_data.sql`, and `tests/workflow_demo.sql` in order, the workflow demonstration should show:

1. A new admission with an `OCCUPIED` bed.
2. A discharge with that bed in `CLEANING`.
3. A cleaning confirmation with that bed back to `AVAILABLE`.
4. Two history entries and three audit entries (admit, discharge, cleaning confirmation).

This is a useful project demonstration: it proves that a bed cannot be reused immediately after discharge.
