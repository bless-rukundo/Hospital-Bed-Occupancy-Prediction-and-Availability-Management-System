"""Orchestrates loading, validation, clean exports, and Oracle staging exports."""
import json
import logging
from pathlib import Path

import pandas as pd

from .config import PipelinePaths
from .io import load_raw_datasets, write_csv
from .quality import reconcile_schedule, standardize, validate

LOGGER = logging.getLogger(__name__)


def _write_markdown_report(path: Path, issues: list[dict], counts: dict[str, int]) -> None:
    lines = ["# HBOPAMS Data Quality and Cleaning Report", "", "## Output counts", "", "| Dataset | Cleaned rows | Oracle-ready rows |", "|---|---:|---:|"]
    for dataset in ("patients", "services_weekly", "staff", "staff_schedule"):
        lines.append(f"| {dataset} | {counts[dataset + '_cleaned']} | {counts[dataset + '_processed']} |")
    lines += ["", "## Validation results", "", "| Dataset | Rule | Severity | Rows affected |", "|---|---|---|---:|"]
    for item in issues:
        lines.append(f"| {item['dataset']} | {item['rule']} | {item['severity']} | {item['rows_affected']} |")
    lines += ["", "## Cleaning decisions", "", "- Raw files are read-only inputs and are never overwritten.", "- Text is trimmed, repeated spaces collapsed, and identifiers/categories normalized to uppercase.", "- Dates are parsed as ISO-compatible dates; numeric fields use nullable integer types.", "- Invalid structural or logical rows are retained in cleaned exports but excluded from Oracle-ready exports and recorded in `questionable_records.csv`.", "- No duplicate was silently deleted. If duplicates appear in a future run, they are reported for review.", "- Schedule IDs do not match the staff master in this source. A canonical staff ID is assigned only when exactly one normalized name/role/service master record matches. All other schedules remain in cleaned output and are routed to review.", "", "## Approval needed", "", "The source has schedule identities that are absent from the staff master. Confirm whether the missing staff should be added to the authoritative master before loading their schedules. Until then, they are intentionally excluded from the referentially valid staging file."]
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def _invalid_rows(frame: pd.DataFrame, row_reasons: dict[int, list[str]], dataset: str) -> pd.DataFrame:
    records = []
    for index, reasons in row_reasons.items():
        row = frame.loc[index].copy()
        row["dataset"] = dataset
        row["rejection_reason"] = "; ".join(sorted(set(reasons)))
        records.append(row)
    return pd.DataFrame(records)


def run_pipeline(project_root: Path) -> dict[str, int]:
    paths = PipelinePaths(project_root)
    paths.create_output_directories()
    raw = load_raw_datasets(paths)
    cleaned = standardize(raw)
    issues, reasons = validate(cleaned)
    reconciled_schedule, unmatched_schedule, reconciliation_issues = reconcile_schedule(cleaned["staff_schedule"], cleaned["staff"])
    issues.extend(reconciliation_issues)

    for dataset, frame in cleaned.items():
        write_csv(frame, paths.cleaned_dir / f"{dataset}_cleaned.csv")
    write_csv(reconciled_schedule, paths.cleaned_dir / "staff_schedule_cleaned.csv")

    questionable = [_invalid_rows(cleaned[name], reason_rows, name) for name, reason_rows in reasons.items() if reason_rows]
    questionable.append(unmatched_schedule)
    questionable = [frame for frame in questionable if not frame.empty]
    write_csv(pd.concat(questionable, ignore_index=True, sort=False) if questionable else pd.DataFrame(columns=["dataset", "rejection_reason"]), paths.reports_dir / "questionable_records.csv")

    for dataset in ("patients", "services_weekly", "staff"):
        invalid_indices = set(reasons.get(dataset, {}))
        processed = cleaned[dataset].drop(index=list(invalid_indices)).copy()
        write_csv(processed, paths.processed_dir / f"{dataset}_stg.csv")
    schedule_invalid = set(reasons.get("staff_schedule", {}))
    schedule_staging = reconciled_schedule[reconciled_schedule["canonical_staff_id"].notna()].drop(index=list(schedule_invalid)).copy()
    schedule_staging = schedule_staging.rename(columns={"canonical_staff_id": "staff_id"})
    write_csv(schedule_staging, paths.processed_dir / "staff_schedule_stg.csv")

    counts = {"patients_cleaned": len(cleaned["patients"]), "services_weekly_cleaned": len(cleaned["services_weekly"]), "staff_cleaned": len(cleaned["staff"]), "staff_schedule_cleaned": len(reconciled_schedule), "patients_processed": len(pd.read_csv(paths.processed_dir / "patients_stg.csv")), "services_weekly_processed": len(pd.read_csv(paths.processed_dir / "services_weekly_stg.csv")), "staff_processed": len(pd.read_csv(paths.processed_dir / "staff_stg.csv")), "staff_schedule_processed": len(schedule_staging), "questionable_records": sum(len(frame) for frame in questionable)}
    (paths.reports_dir / "data_quality_summary.json").write_text(json.dumps({"counts": counts, "issues": issues}, indent=2) + "\n", encoding="utf-8")
    _write_markdown_report(paths.reports_dir / "cleaning_decisions.md", issues, counts)
    LOGGER.info("Pipeline completed: %s", counts)
    return counts
