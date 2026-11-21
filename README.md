# Hospital Bed Occupancy Prediction and Availability Management System

This is a learning-focused prototype for managing hospital beds with Oracle SQL/PLSQL, then analysing the data with Python and presenting it in Streamlit.

## Build order

1. **Database foundation** — tables, keys, checks, views, and PL/SQL rules.
2. **Operational workflow** — patients, admission, discharge, cleaning confirmation, alerts, audit trail.
3. **Data pipeline** — clean a Kaggle dataset and load it into Oracle.
4. **Dashboard and forecast** — display live capacity and estimate the next seven days.
5. **Safe chatbot** — map approved question types to approved queries/procedures; never run unrestricted AI-generated SQL.

## Current milestone: database foundation

The first script defines these ideas:

| Table | Why it exists |
|---|---|
| `departments` | Hospital units and their occupancy alert thresholds |
| `patients` | Patient identity and contact data |
| `staff`, `app_users`, `user_roles` | Employees, active application accounts, and database-enforced authorization |
| `rooms` / `beds` | Physical capacity; each bed has a controlled status |
| `admissions` | A patient's stay, including assignment and discharge dates |
| `bed_status_history` | Historical record for reporting and auditing |
| `audit_log` | Records sensitive operational changes |
| `admission_requests`, `capacity_alerts` | Workflow queue and automatic capacity warnings |
| `data_load_runs`, `rejected_data_rows` | Proof of clean/rejected real-data loading |

### Run the script

1. Create an Oracle schema/user for the project (do not use `SYSTEM` for application tables).
2. Open a terminal in this folder and connect with SQL*Plus:

   ```powershell
   sqlplus hbopams/your_password@localhost:1521/XEPDB1
   ```

3. Execute:

   ```sql
   @database/install.sql
   ```

4. Check the setup:

   ```sql
   SELECT * FROM v_bed_summary;
   ```

See [database/INSTALLATION.md](database/INSTALLATION.md) for the dependency-safe installation order and verification queries. [database/LEARNING_GUIDE.md](database/LEARNING_GUIDE.md) explains the relationships and constraints in plain language.

## Folder map

```text
database/       Oracle DDL, PL/SQL packages, seed data
data/           Raw Kaggle files (not committed) and cleaned exports
app/            Streamlit interface
prediction/     Forecasting and evaluation code
chatbot/        Safe intent-to-query mapping
docs/           Diagrams and project report material
```

> This is a prototype. Use synthetic/de-identified data only; never upload real patient data to an external AI service.
