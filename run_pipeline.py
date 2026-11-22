"""Convenient project-root entry point for the HBOPAMS pipeline."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent / "src"))

from hbopams_pipeline.__main__ import main


if __name__ == "__main__":
    main()
