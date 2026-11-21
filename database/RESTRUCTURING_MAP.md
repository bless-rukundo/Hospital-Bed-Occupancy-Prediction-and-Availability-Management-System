# Restructuring map and preserved backups

The exact original SQL files are preserved in `backups/original_sql/`. They must remain until approval of the new structure.

| Original file | New authoritative location(s) |
|---|---|
| `01_schema.sql` | `tables/*.sql`, `constraints/table_constraints.sql`, `indexes/performance_indexes.sql`, `views/*.sql`, `triggers/*.sql` |
| `02_security_package.sql` | `security/pkg_security.sql` |
| `02_bed_management_package.sql` | `packages/pkg_bed_management.sql` |
| `03_seed_demo_data.sql` | `demo_data/seed_demo_data.sql` |
| `04_workflow_demo.sql` | `tests/workflow_demo.sql` |

`sequences/`, `functions/`, and `procedures/` contain documentation only. No standalone objects were created because the original implementation uses identity columns and a package as the unit of related business logic.

Future dataset work belongs in `staging/` and `data_loading/` without changing the current schema objects.
