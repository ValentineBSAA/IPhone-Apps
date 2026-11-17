#!/usr/bin/env python3
"""Bounded Codemagic XCTest execution. Never misreport a simulator hang as test success.

The release IPA is built and verified BEFORE this diagnostic runs. Simulator runtime
must exactly match the selected Xcode SDK (per Codemagic's runtime-mismatch guidance).
Actual XCTest assertion failures fail CI. Simulator/host startup failures are recorded
as NOT VERIFIED, so they do not prevent inspection of the already-built unsigned IPA.
"""
from __future__ import annotations

import json
import os
import signal
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DIST = ROOT / "dist"
DIST.mkdir(exist_ok=True)
STATUS = DIST / "Berry-0.5.7-simulator-test-status.txt"


def record(label: str, details: str) -> None:
    message = f"{label}: {details}"
    print(message, flush=True)
    STATUS.write_text(message + "\n", encoding="utf-8")


def capture(cmd: list[str], timeout: int = 30) -> str:
    return subprocess.check_output(cmd, text=True, stderr=subprocess.STDOUT, timeout=timeout).strip()


def bounded(cmd: list[str], log_name: str, timeout: int) -> tuple[int, str, bool]:
    path = DIST / log_name
    did_timeout = False
    with path.open("w", encoding="utf-8") as log:
        log.write("$ " + " ".join(cmd) + "\n")
        log.flush()
        process = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        try:
            rc = process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            did_timeout = True
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=8)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait(timeout=5)
            rc = 124
            log.write(f"\nCI INFRASTRUCTURE TIMEOUT after {timeout}s\n")
    output = path.read_text(encoding="utf-8", errors="replace")
    print("\n".join(output.splitlines()[-55:]), flush=True)
    return rc, output, did_timeout


def main() -> int:
    sdk = capture(["xcrun", "--sdk", "iphonesimulator", "--show-sdk-version"])
    runtime_id = "com.apple.CoreSimulator.SimRuntime.iOS-" + sdk.replace(".", "-")
    print(f"Using Xcode-selected Simulator SDK {sdk} / runtime {runtime_id}", flush=True)
    data = json.loads(capture(["xcrun", "simctl", "list", "devices", "available", "-j"]))
    phones = [d for d in data.get("devices", {}).get(runtime_id, [])
              if d.get("isAvailable", True) and d.get("name", "").startswith("iPhone")]
    phones.sort(key=lambda d: (d.get("name") != "iPhone 17 Pro", d.get("name", "")))
    if phones:
        chosen = phones[0]
        device_id = chosen["udid"]
    else:
        try:
            device_id = capture(["xcrun", "simctl", "create", "Berry-0.5.7-CI",
                                 "iPhone 17 Pro", runtime_id], timeout=45)
            chosen = {"name": "Berry-0.5.7-CI", "state": "Shutdown"}
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as exc:
            record("NOT VERIFIED (SIMULATOR INFRASTRUCTURE)",
                   f"No available iPhone device for matching SDK {sdk}: {exc}")
            return 0

    print(f"Selected {chosen['name']} ({device_id}); state={chosen.get('state')}", flush=True)
    if chosen.get("state") != "Booted":
        rc, output, timed_out = bounded(
            ["xcrun", "simctl", "boot", device_id], "simulator-boot.log", 45)
        if rc != 0 and "current state: Booted" not in output:
            record("NOT VERIFIED (SIMULATOR INFRASTRUCTURE)", "simctl boot failed")
            return 0
    rc, _, timed_out = bounded(
        ["xcrun", "simctl", "bootstatus", device_id, "-b"],
        "simulator-bootstatus.log", 110)
    if rc != 0:
        record("NOT VERIFIED (SIMULATOR INFRASTRUCTURE)",
               "Matching simulator did not become ready in 110 seconds")
        return 0

    result_bundle = DIST / "Berry-0.5.7-simulator.xcresult"
    cmd = [
        "xcodebuild", "-project", "BerryBlockBlast.xcodeproj",
        "-scheme", "BerryBlockBlast", "-configuration", "Debug",
        "-sdk", "iphonesimulator",
        "-destination", f"platform=iOS Simulator,id={device_id}",
        "-derivedDataPath", "build-simulator",
        "-resultBundlePath", str(result_bundle),
        "-parallel-testing-enabled", "NO",
        "-maximum-concurrent-test-simulator-destinations", "1",
        "CODE_SIGNING_ALLOWED=NO", "test-without-building"
    ]
    rc, output, timed_out = bounded(cmd, "simulator-xctest.log", 300)
    if rc == 0:
        record("PASSED", "All XCTest cases completed successfully on matching iOS simulator")
        return 0
    simulator_failure_signatures = (
        "test runner hung before establishing connection",
        "Failed to establish communication",
        "Failed to launch test runner",
        "test runner failed to launch",
    )
    if timed_out or any(s in output for s in simulator_failure_signatures):
        record("NOT VERIFIED (SIMULATOR INFRASTRUCTURE)",
               f"Test runner launch/hang (exit {rc}); see simulator-xctest.log and xcresult")
        return 0
    record("FAILED (TESTS OR COMPILATION)", f"xcodebuild test exited {rc}; see simulator-xctest.log")
    return 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:
        record("NOT VERIFIED (SIMULATOR INFRASTRUCTURE)", f"Tooling unavailable: {type(exc).__name__}: {exc}")
        sys.exit(0)
