"""CSV loading and export helpers."""
from pathlib import Path
import logging

import pandas as pd

from .config import FILE_NAMES, REQUIRED_COLUMNS, PipelinePaths

LOGGER = logging.getLogger(__name__)


class DataLoadError(RuntimeError):
    """Raised when a required source file cannot be used safely."""


def load_raw_datasets(paths: PipelinePaths) -> dict[str, pd.DataFrame]:
    datasets: dict[str, pd.DataFrame] = {}
    for dataset, filename in FILE_NAMES.items():
        file_path = paths.raw_dir / filename
        if not file_path.is_file():
            raise DataLoadError(f"Required source file is missing: {file_path}")
        try:
            frame = pd.read_csv(file_path, encoding="utf-8")
        except (OSError, UnicodeDecodeError, pd.errors.ParserError) as error:
            raise DataLoadError(f"Could not read {file_path}: {error}") from error
        missing = sorted(set(REQUIRED_COLUMNS[dataset]) - set(frame.columns))
        if missing:
            raise DataLoadError(f"{file_path} is missing required columns: {', '.join(missing)}")
        datasets[dataset] = frame[REQUIRED_COLUMNS[dataset]].copy()
        LOGGER.info("Loaded %s rows from %s", len(frame), file_path)
    return datasets


def write_csv(frame: pd.DataFrame, destination: Path) -> None:
    frame.to_csv(destination, index=False, encoding="utf-8", date_format="%Y-%m-%d")
