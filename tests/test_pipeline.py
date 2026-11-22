import tempfile
import unittest
from pathlib import Path
import sys

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))

from hbopams_pipeline.config import PipelinePaths
from hbopams_pipeline.io import DataLoadError, load_raw_datasets
from hbopams_pipeline.pipeline import run_pipeline
from hbopams_pipeline.quality import standardize, validate


class PipelineTests(unittest.TestCase):
    def test_raw_sources_load_with_required_columns(self):
        datasets = load_raw_datasets(PipelinePaths(ROOT))
        self.assertEqual(set(datasets), {"patients", "services_weekly", "staff", "staff_schedule"})
        self.assertEqual(len(datasets["patients"]), 1000)

    def test_validation_flags_bad_patient_age(self):
        datasets = load_raw_datasets(PipelinePaths(ROOT))
        datasets["patients"].loc[0, "age"] = -1
        issues, reasons = validate(standardize(datasets))
        self.assertIn("invalid_age", reasons["patients"][0])
        self.assertTrue(any(item["rule"] == "invalid_age" and item["rows_affected"] == 1 for item in issues))

    def test_missing_source_file_has_clear_error(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(DataLoadError):
                load_raw_datasets(PipelinePaths(Path(directory)))

    def test_pipeline_generates_readable_outputs(self):
        with tempfile.TemporaryDirectory() as directory:
            temporary_root = Path(directory)
            raw_target = temporary_root / "data" / "raw" / "Hospital bed mngnt"
            raw_target.mkdir(parents=True)
            for source in (ROOT / "data" / "raw" / "Hospital bed mngnt").glob("*.csv"):
                (raw_target / source.name).write_bytes(source.read_bytes())
            counts = run_pipeline(temporary_root)
            self.assertEqual(counts["patients_processed"], 1000)
            self.assertEqual(counts["staff_schedule_processed"], 1716)
            questionable = pd.read_csv(temporary_root / "data" / "reports" / "questionable_records.csv")
            self.assertEqual(set(questionable["dataset"]), {"staff_schedule"})
            processed = temporary_root / "data" / "processed"
            for filename in ("patients_stg.csv", "services_weekly_stg.csv", "staff_stg.csv", "staff_schedule_stg.csv"):
                self.assertFalse(pd.read_csv(processed / filename).empty)


if __name__ == "__main__":
    unittest.main()
