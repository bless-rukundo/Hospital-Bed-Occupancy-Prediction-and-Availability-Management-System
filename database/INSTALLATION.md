# Install HBOPAMS database scripts

## Before installing

1. Create and connect with the dedicated Oracle schema named `HBOPAMS`. Do **not** connect as `SYSTEM`.
2. Start from an empty HBOPAMS schema. These are create scripts, so rerunning them against existing objects will fail by design.
3. Open a terminal in the project root.

## Install the schema

```powershell
sqlplus HBOPAMS/your_password@localhost:1521/XEPDB1 @database/install.sql
```

`install.sql` uses SQL*Plus `@@` commands, stops at the first operating-system or Oracle error, rolls back uncommitted DML, and checks that both the session user and current schema are `HBOPAMS`.

It installs objects in this order:

1. Tables
2. Constraints and indexes
3. Views
4. Security package, then bed-management package
5. Triggers

## Optional demo and verification

After the schema installation succeeds, run these manually from the project root:

```sql
@database/demo_data/seed_demo_data.sql
@database/tests/workflow_demo.sql
```

Verify the objects and workflow with:

```sql
SELECT object_type, object_name, status
  FROM user_objects
 WHERE object_name IN ('PKG_SECURITY', 'PKG_BED_MANAGEMENT',
                       'TRG_BED_STATUS_HISTORY', 'TRG_VALIDATE_ADMISSION_BED',
                       'V_BED_SUMMARY', 'V_CAPACITY_ALERTS')
 ORDER BY object_type, object_name;

SELECT * FROM v_bed_summary ORDER BY department_name;
SELECT * FROM bed_status_history ORDER BY changed_at;
SELECT * FROM audit_log ORDER BY action_at;
```

The test should show the controlled lifecycle `AVAILABLE → OCCUPIED → CLEANING → AVAILABLE`, plus history and audit records.
