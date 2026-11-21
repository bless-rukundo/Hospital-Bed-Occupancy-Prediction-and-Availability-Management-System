# Rubric build plan

This document converts the marking guide into deliverables. We will demonstrate every item live, rather than treating it as a future idea.

| Marks | Evidence we will produce |
|---:|---|
| 2 Proposal | Approved proposal retained in `docs/` (do not expose private feedback) |
| 5 Database design | 12+ normalized tables, ERD, PK/FK/check constraints |
| 12 PL/SQL, rules, access | Packages, procedures, functions, cursors, custom exceptions, `BULK COLLECT`/`FORALL`, authorization checks, 4+ business triggers |
| 5 Real data | Dataset link, staging table, cleaning package, rejected-row table, load report |
| 4 Answers/prediction | Five approved views, dashboard charts, three findings, two forecast methods with metrics |
| 3 Ask your system | Intent mapping to read-only views only; proof that writes are impossible |
| 3 Easy use | Streamlit app calling only PL/SQL packages and showing Oracle errors |
| 6 Demo | Demo script plus explanation of each rule and a prepared live rule modification |

## Planned automatic actions

1. Store a history row whenever bed status changes.
2. Create a high-occupancy alert when a bed becomes occupied and a department reaches its threshold.
3. Create a no-bed alert when the last available bed in a department is occupied.
4. Block an invalid admission assignment.
5. Automatically send a discharged bed to `CLEANING`.

## Dataset decision needed

Before writing the staging/cleaning package, record the approved dataset's exact link, file name, column names, and row count. The loader must reflect the real source—not invented columns.
