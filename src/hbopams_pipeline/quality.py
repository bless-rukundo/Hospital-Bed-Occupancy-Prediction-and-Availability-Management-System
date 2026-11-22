"""Normalization and non-destructive data-quality checks."""
from collections import defaultdict
from typing import Any

import pandas as pd

from .config import REQUIRED_COLUMNS

TEXT_COLUMNS = {
    "patients": ["patient_id", "name", "service"],
    "services_weekly": ["service", "event"],
    "staff": ["staff_id", "staff_name", "role", "service"],
    "staff_schedule": ["staff_id", "staff_name", "role", "service"],
}
NUMERIC_COLUMNS = {
    "patients": ["age", "satisfaction"],
    "services_weekly": ["week", "month", "available_beds", "patients_request", "patients_admitted", "patients_refused", "patient_satisfaction", "staff_morale"],
    "staff_schedule": ["week", "present"],
}


def _normalise_text(series: pd.Series, upper: bool = False) -> pd.Series:
    value = series.astype("string").str.strip().str.replace(r"\s+", " ", regex=True)
    return value.str.upper() if upper else value


def standardize(datasets: dict[str, pd.DataFrame]) -> dict[str, pd.DataFrame]:
    """Apply reversible formatting rules; source files are never changed."""
    result: dict[str, pd.DataFrame] = {}
    for dataset, source in datasets.items():
        frame = source.copy()
        frame.insert(0, "source_row_number", range(2, len(frame) + 2))
        for column in TEXT_COLUMNS.get(dataset, []):
            frame[column] = _normalise_text(frame[column], upper=column not in {"name", "staff_name"})
        for column in NUMERIC_COLUMNS.get(dataset, []):
            frame[column] = pd.to_numeric(frame[column], errors="coerce").astype("Int64")
        if dataset == "patients":
            for column in ("arrival_date", "departure_date"):
                frame[column] = pd.to_datetime(frame[column], errors="coerce")
        result[dataset] = frame
    return result


def validate(datasets: dict[str, pd.DataFrame]) -> tuple[list[dict[str, Any]], dict[str, dict[int, list[str]]]]:
    """Return summary issues and row-level reasons without removing records."""
    issues: list[dict[str, Any]] = []
    reasons: dict[str, dict[int, list[str]]] = defaultdict(lambda: defaultdict(list))

    def add(dataset: str, rule: str, mask: pd.Series, severity: str = "error") -> None:
        count = int(mask.sum())
        issues.append({"dataset": dataset, "rule": rule, "severity": severity, "rows_affected": count})
        if severity == "error":
            for index in datasets[dataset].index[mask]:
                reasons[dataset][int(index)].append(rule)

    for dataset, frame in datasets.items():
        source_columns = REQUIRED_COLUMNS[dataset]
        add(dataset, "fully_duplicated_row", frame.duplicated(subset=source_columns, keep=False), "warning")

    patients = datasets["patients"]
    add("patients", "duplicate_patient_id", patients["patient_id"].duplicated(keep=False))
    add("patients", "invalid_age", patients["age"].isna() | ~patients["age"].between(0, 130))
    add("patients", "invalid_satisfaction", patients["satisfaction"].isna() | ~patients["satisfaction"].between(0, 100))
    add("patients", "invalid_arrival_or_departure_date", patients["arrival_date"].isna() | patients["departure_date"].isna())
    add("patients", "departure_before_arrival", patients["departure_date"] < patients["arrival_date"])

    weekly = datasets["services_weekly"]
    add("services_weekly", "duplicate_week_service", weekly.duplicated(["week", "service"], keep=False))
    add("services_weekly", "invalid_week", weekly["week"].isna() | ~weekly["week"].between(1, 53))
    add("services_weekly", "invalid_month", weekly["month"].isna() | ~weekly["month"].between(1, 12))
    for column in ["available_beds", "patients_request", "patients_admitted", "patients_refused"]:
        add("services_weekly", f"invalid_{column}", weekly[column].isna() | (weekly[column] < 0))
    for column in ["patient_satisfaction", "staff_morale"]:
        add("services_weekly", f"invalid_{column}", weekly[column].isna() | ~weekly[column].between(0, 100))
    add("services_weekly", "admitted_plus_refused_not_equal_requests", weekly["patients_admitted"] + weekly["patients_refused"] != weekly["patients_request"])
    add("services_weekly", "admitted_exceeds_available_beds", weekly["patients_admitted"] > weekly["available_beds"])

    staff = datasets["staff"]
    add("staff", "duplicate_staff_id", staff["staff_id"].duplicated(keep=False))

    schedule = datasets["staff_schedule"]
    add("staff_schedule", "duplicate_week_staff", schedule.duplicated(["week", "staff_id"], keep=False))
    add("staff_schedule", "invalid_week", schedule["week"].isna() | ~schedule["week"].between(1, 53))
    add("staff_schedule", "invalid_present", schedule["present"].isna() | ~schedule["present"].isin([0, 1]))

    all_services = set().union(*(set(frame["service"].dropna()) for frame in datasets.values()))
    for dataset, frame in datasets.items():
        add(dataset, "blank_service", frame["service"].isna() | (frame["service"] == ""))
    issues.append({"dataset": "cross_dataset", "rule": "canonical_services", "severity": "info", "rows_affected": len(all_services)})
    return issues, reasons


def reconcile_schedule(schedule: pd.DataFrame, staff: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame, list[dict[str, Any]]]:
    """Safely map schedules only with a unique exact natural-key match."""
    key = ["staff_name", "role", "service"]
    reference = staff[key + ["staff_id"]].rename(columns={"staff_id": "canonical_staff_id"})
    merged = schedule.merge(reference, on=key, how="left", validate="many_to_one")
    merged = merged.rename(columns={"staff_id": "source_staff_id"})
    direct = schedule.merge(
        staff[["staff_id"] + key], on="staff_id", how="left", suffixes=("_schedule", "_reference")
    )
    direct_match = direct["staff_name_reference"].notna()
    direct_conflict = direct_match & (
        (direct["staff_name_schedule"] != direct["staff_name_reference"])
        | (direct["role_schedule"] != direct["role_reference"])
        | (direct["service_schedule"] != direct["service_reference"])
    )
    unmatched = merged[merged["canonical_staff_id"].isna()].copy()
    unmatched["dataset"] = "staff_schedule"
    unmatched["rejection_reason"] = "staff_schedule_identity_not_found_in_staff_reference"
    metrics = [
        {"dataset": "staff_schedule", "rule": "staff_id_missing_from_reference", "severity": "warning", "rows_affected": int((~schedule["staff_id"].isin(staff["staff_id"])).sum())},
        {"dataset": "staff_schedule", "rule": "staff_name_role_or_service_conflicts_with_direct_staff_id", "severity": "error", "rows_affected": int(direct_conflict.sum())},
        {"dataset": "staff_schedule", "rule": "reconciled_by_unique_name_role_service", "severity": "info", "rows_affected": int(merged["canonical_staff_id"].notna().sum())},
        {"dataset": "staff_schedule", "rule": "identity_not_found_in_staff_reference", "severity": "error", "rows_affected": len(unmatched)},
    ]
    return merged, unmatched, metrics
