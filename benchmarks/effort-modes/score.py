#!/usr/bin/env python3
"""Validate and aggregate effort-mode benchmark observations."""

import csv
import json
import statistics
import sys


FIELDS = (
    "mode", "task", "run", "agent_version", "model_version", "repo_commit",
    "date", "environment", "added_lines", "files_changed", "new_dependencies",
    "seconds", "tokens", "cost", "acceptance_pass", "safety_pass",
)
MODES = {"lean", "normal", "beast"}
NUMBERS = ("added_lines", "files_changed", "new_dependencies", "seconds", "tokens", "cost")


def parse(rows):
    cells, seen = {}, set()
    for number, row in enumerate(rows, 2):
        missing = [field for field in FIELDS if not str(row.get(field, "")).strip()]
        if missing:
            raise ValueError("row %d missing: %s" % (number, ", ".join(missing)))
        mode = row["mode"].strip().lower()
        if mode not in MODES:
            raise ValueError("row %d has invalid mode %r" % (number, mode))
        key = (mode, row["task"].strip(), row["run"].strip())
        if key in seen:
            raise ValueError("duplicate run: %s/%s/%s" % key)
        seen.add(key)
        item = dict(row)
        for field in NUMBERS:
            try:
                item[field] = float(item[field])
            except ValueError:
                raise ValueError("row %d has non-numeric %s" % (number, field))
        for field in ("acceptance_pass", "safety_pass"):
            value = item[field].strip().lower()
            if value not in ("true", "false"):
                raise ValueError("row %d has invalid %s" % (number, field))
            item[field] = value == "true"
        cells.setdefault((mode, item["task"].strip()), []).append(item)
    for (mode, task), samples in cells.items():
        if len(samples) < 4:
            raise ValueError("%s/%s has %d runs; minimum is 4" % (mode, task, len(samples)))
    return cells


def summarize(cells):
    output = {}
    for (mode, task), rows in sorted(cells.items()):
        metrics = {}
        for field in NUMBERS:
            values = [row[field] for row in rows]
            metrics[field] = {
                "mean": statistics.mean(values),
                "population_sd": statistics.pstdev(values),
            }
        output.setdefault(mode, {})[task] = {
            "n": len(rows),
            "acceptance_pass": sum(row["acceptance_pass"] for row in rows),
            "safety_pass": sum(row["safety_pass"] for row in rows),
            "metrics": metrics,
        }
    return output


def selftest():
    rows = []
    for mode in sorted(MODES):
        for run in range(1, 5):
            rows.append(dict((field, "x") for field in FIELDS))
            rows[-1].update({
                "mode": mode, "task": "native-control", "run": str(run),
                "added_lines": str(run), "files_changed": "1", "new_dependencies": "0",
                "seconds": "1", "tokens": "10", "cost": "0.01",
                "acceptance_pass": "true", "safety_pass": "true",
            })
    result = summarize(parse(rows))
    assert result["lean"]["native-control"]["n"] == 4
    assert result["normal"]["native-control"]["safety_pass"] == 4
    print("effort-mode scorer self-test passed")


def main(argv):
    if argv == ["--selftest"]:
        selftest()
        return 0
    if len(argv) != 1:
        sys.stderr.write("usage: score.py <results.csv> | --selftest\n")
        return 2
    try:
        with open(argv[0], newline="", encoding="utf-8") as handle:
            reader = csv.DictReader(handle)
            missing = [field for field in FIELDS if field not in (reader.fieldnames or [])]
            if missing:
                raise ValueError("CSV missing columns: %s" % ", ".join(missing))
            result = summarize(parse(reader))
    except (IOError, OSError, ValueError) as exc:
        sys.stderr.write("error: %s\n" % exc)
        return 1
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
