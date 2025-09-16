#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.9"
# dependencies = ["plumbum>=1.8.2"]
# ///
"""
Sync ~/SyncDrive to an rclone remote using bisync.

- Prompts for S3 credentials if the base remote doesn't exist.
- Prompts for a bucket name if the alias remote doesn't exist.
- Runs: rclone bisync ~/SyncDrive SyncDrive: <default options> <user args>

Usage Notes:

Initial setup:
  - Create or place files in ~/SyncDrive (optional).
  - Run this script with `--resync` once to establish sync state:
      ./syncdrive_bisync.py --resync

Ongoing use:
  - Run the script with no arguments to sync changes:
      ./syncdrive_bisync.py

Testing (no changes made):
  - Add `--dry-run` to simulate a sync without modifying anything:
      ./syncdrive_bisync.py --dry-run
"""

import os
import sys
from getpass import getpass
from pathlib import Path
from plumbum import local, RETCODE

# Configurable paths and names
remote_name = os.environ.get("SYNCDRIVE_REMOTE", "minio-syncdrive")
alias_name = "SyncDrive"
sync_dir = Path(os.environ.get("SYNC_DIR", Path.home() / "SyncDrive"))

# rclone binary
rclone = local["rclone"]

# Ensure local sync directory exists
sync_dir.mkdir(parents=True, exist_ok=True)

# Get current remotes
remotes = rclone("listremotes").splitlines()

# Create the rclone S3 remote if needed
if f"{remote_name}:" not in remotes:
    key = input("AWS Access Key ID: ").strip()
    secret = getpass("AWS Secret Access Key: ").strip()
    endpoint = input("S3 Endpoint (e.g. https://minio.example.com): ").strip()

    rclone[
        "config", "create", remote_name, "s3",
        "provider", "Minio",
        "access_key_id", key,
        "secret_access_key", secret,
        "endpoint", endpoint,
    ]()

# Create the alias remote if needed
if f"{alias_name}:" not in remotes:
    bucket = input("Bucket name for SyncDrive: ").strip()
    rclone[
        "config", "create", alias_name, "alias",
        "remote", f"{remote_name}:{bucket}",
    ]()

# Default bisync args
default_args = [
    "--resilient",
    "--recover",
    "--max-lock", "2m",
    "--conflict-resolve", "newer",
    "--links",
]

# Run the rclone bisync command
cmd = rclone[
    "bisync", str(sync_dir), f"{alias_name}:",
    *default_args,
    *sys.argv[1:],
]

print("Running:", " ".join(map(str, cmd.formulate())), file=sys.stderr)
rc = cmd & RETCODE(FG=1)
sys.exit(rc)
