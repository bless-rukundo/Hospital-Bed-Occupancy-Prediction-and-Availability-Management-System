-- HBOPAMS clean schema installer for SQL*Plus.
-- Run from the project root while connected as HBOPAMS.
-- Example: sqlplus HBOPAMS/your_password@localhost:1521/XEPDB1 @database/install.sql
-- This script creates schema objects only. It does not load demo data or execute tests.

WHENEVER OSERROR EXIT FAILURE ROLLBACK
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SET DEFINE OFF
SET ECHO ON

PROMPT [HBOPAMS] Verifying schema identity...
@@00_schema_guard.sql

PROMPT [HBOPAMS] Creating tables...
@@tables/departments.sql
@@tables/patients.sql
@@tables/staff.sql
@@tables/app_users.sql
@@tables/user_roles.sql
@@tables/rooms.sql
@@tables/beds.sql
@@tables/admissions.sql
@@tables/admission_requests.sql
@@tables/bed_status_history.sql
@@tables/audit_log.sql
@@tables/capacity_alerts.sql
@@tables/data_load_runs.sql
@@tables/rejected_data_rows.sql

PROMPT [HBOPAMS] Creating constraints and indexes...
@@constraints/table_constraints.sql
@@indexes/performance_indexes.sql

PROMPT [HBOPAMS] Creating reporting views...
@@views/v_bed_summary.sql
@@views/v_capacity_alerts.sql

PROMPT [HBOPAMS] Creating security and business packages...
@@security/pkg_security.sql
@@packages/pkg_bed_management.sql

PROMPT [HBOPAMS] Creating triggers...
@@triggers/trg_bed_status_history.sql
@@triggers/trg_validate_admission_bed.sql

PROMPT [HBOPAMS] Schema installation completed successfully.
PROMPT [HBOPAMS] Optional next steps: @@demo_data/seed_demo_data.sql then @@tests/workflow_demo.sql
EXIT SUCCESS
