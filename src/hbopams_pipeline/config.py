from dataclasses import dataclass
from pathlib import Path


REQUIRED_COLUMNS = {
    "patients": ["patient_id", "name", "age", "arrival_date", "departure_date", "service", "satisfaction"],
    "services_weekly": ["week", "month", "service", "available_beds", "patients_request", "patients_admitted", "patients_refused", "patient_satisfaction", "staff_morale", "event"],
    "staff": ["staff_id", "staff_name", "role", "service"],
    "staff_schedule": ["week", "staff_id", "staff_name", "role", "service", "present"],
}

FILE_NAMES = {name: f"{name}.csv" for name in REQUIRED_COLUMNS}


@dataclass(frozen=True)
class PipelinePaths:
    root: Path

    @property
    def raw_dir(self) -> Path:
        return self.root / "data" / "raw" / "Hospital bed mngnt"

    @property
    def cleaned_dir(self) -> Path:
        return self.root / "data" / "cleaned"

    @property
    def processed_dir(self) -> Path:
        return self.root / "data" / "processed"

    @property
    def reports_dir(self) -> Path:
        return self.root / "data" / "reports"

    def create_output_directories(self) -> None:
        for directory in (self.cleaned_dir, self.processed_dir, self.reports_dir):
            directory.mkdir(parents=True, exist_ok=True)
