#!/usr/bin/env python3
"""Sanity-check CI's deterministic, synthetic gameplay evidence."""
import json
import sys
from pathlib import Path
record = json.loads(Path(sys.argv[1]).read_text())
assert record["build"] == "4.5"
assert record["sample_count"] == 2030
assert record["total_placements"] > 4000
profiles = record["mode_profiles"]
assert len(profiles) == 9
assert sum(x["seeded_sessions"] for x in profiles) == 2030
assert sum(x["placements"] for x in profiles) == record["total_placements"]
for item in profiles:
    assert item["board_side"] in (8, 12, 24)
    for key in ("placements", "line_clears", "simulated_line_berries",
                "unrescued_stalls", "free_recoveries",
                "legal_tray_slots_observed", "blocked_tray_slots_observed"):
        assert item[key] >= 0, (item["profile"], key)
print("PASS: nine mode profiles and all synthetic counters verified")
