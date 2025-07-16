#!/usr/bin/env -S uv run
# /// script
# dependencies = [
#     "dateparser",
# ]
# ///

# Script to selectively delete old backup files, keeping a specified number of
# backups based on daily, weekly, monthly, and yearly retention policies.

import argparse
import sys
from pathlib import Path
from datetime import datetime, timedelta
import dateparser
import doctest


def parse_args():
    parser = argparse.ArgumentParser(
        description="Time-slot-based backup retention tool."
    )
    parser.add_argument(
        "paths", nargs="*", default=["."],
        help="List of directories or files (default: current directory)."
    )
    parser.add_argument("-d", "--keep-daily", type=int, default=7)
    parser.add_argument("-w", "--keep-weekly", type=int, default=4)
    parser.add_argument("-m", "--keep-monthly", type=int, default=6)
    parser.add_argument("-y", "--keep-yearly", type=int, default=1)
    parser.add_argument(
        "--date-from-filename", action="store_true",
        help="Extract date from filename instead of file mtime."
    )
    parser.add_argument(
        "--filename-prefix", default="",
        help="Prefix to remove from filename before parsing date."
    )
    parser.add_argument(
        "--filename-suffix", default="",
        help="Suffix to remove from filename before parsing date."
    )
    parser.add_argument(
        "-f", "--force", action="store_true",
        help="Actually delete the files."
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true",
        help="Print kept files and why."
    )
    parser.add_argument(
        "--run-tests", action="store_true",
        help="Run doctests and exit. Add -v for verbose output."
    )
    parser.add_argument(
        "--simulate", type=int, default=0,
        help="Simulate running retention for N days with the current settings"
    )
    parser.add_argument(
        "--simulate-retention-interval", default="daily",
        help="How often to run retention: 'daily', 'weekly', or number of days"
    )
    return parser.parse_args()


def extract_date(args, file):
    """
    >>> f = Path('prefix2025-07-15suffix.tar.gz')
    >>> class Args:
    ...     date_from_filename = True
    ...     filename_prefix = 'prefix'
    ...     filename_suffix = 'suffix.tar.gz'
    >>> extract_date(Args(), f).date()
    datetime.date(2025, 7, 15)

    >>> f2 = Path('2025-07-15.txt')
    >>> class Args:
    ...     date_from_filename = True
    ...     filename_prefix = ''
    ...     filename_suffix = ''
    >>> extract_date(Args(), f2).date()
    datetime.date(2025, 7, 15)
    """
    prefix = args.filename_prefix
    suffix = args.filename_suffix
    if args.date_from_filename:
        name = file.name
        if suffix and name.endswith(suffix):
            name = name[:-len(suffix)]
        else:
            name = file.stem
            if suffix and name.endswith(suffix):
                name = name[:-len(suffix)]
        if prefix and name.startswith(prefix):
            name = name[len(prefix):]
        return dateparser.parse(name)
    return datetime.fromtimestamp(file.stat().st_mtime)


def extract_dates(args, files):
    """
    >>> files = [Path('2025-07-15.txt'), Path('2025-07-14.txt')]
    >>> class Args:
    ...     date_from_filename = True
    ...     filename_prefix = ''
    ...     filename_suffix = ''
    >>> for i in extract_dates(Args(), files): print(i)
    (PosixPath('2025-07-15.txt'), datetime.datetime(2025, 7, 15, 0, 0))
    (PosixPath('2025-07-14.txt'), datetime.datetime(2025, 7, 14, 0, 0))
    """
    return [(f, extract_date(args, f)) for f in files]


def get_limits(args):
    """
    >>> class Args:
    ...     keep_daily = 7
    ...     keep_weekly = 4
    ...     keep_monthly = 0
    ...     keep_yearly = 1
    >>> get_limits(Args())
    {'daily': 7, 'weekly': 4, 'yearly': 1}
    """
    types = ['daily', 'weekly', 'monthly', 'yearly']
    limits = {}
    for t in types:
        val = getattr(args, f'keep_{t}', 0)
        if val > 0:
            limits[t] = val

    return limits


def bucket_key(dt, bucket_type):
    """
    >>> d = datetime(2025, 7, 15)
    >>> bucket_key(d, 'daily')
    '2025-07-15'
    >>> bucket_key(d, 'monthly')
    '2025-07'
    >>> bucket_key(d, 'yearly')
    '2025'
    >>> bucket_key(d, 'weekly').startswith('2025-W')
    True
    """
    if bucket_type == "daily":
        return dt.strftime("%Y-%m-%d")
    elif bucket_type == "weekly":
        return f"{dt.strftime('%G')}-W{dt.strftime('%V')}"
    elif bucket_type == "monthly":
        return dt.strftime("%Y-%m")
    elif bucket_type == "yearly":
        return dt.strftime("%Y")


def collect_retention(files_with_dates, limits):
    """
    >>> files = [
    ...     (Path('2025-07-15.txt'), datetime(2025, 7, 15)),
    ...     (Path('2025-07-14.txt'), datetime(2025, 7, 14)),
    ...     (Path('2025-07-13.txt'), datetime(2025, 7, 13)),
    ...     (Path('2025-07-12.txt'), datetime(2025, 7, 12))
    ... ]
    >>> r = collect_retention(files, {'daily': 2})
    >>> sorted(r['daily'].keys())
    ['2025-07-14', '2025-07-15']
    """
    bucket_map = {k: {} for k in limits}
    for path, dt in sorted(files_with_dates, key=lambda x: x[1], reverse=True):
        for k in limits:
            key = bucket_key(dt, k)
            if len(bucket_map[k]) < limits[k] and key not in bucket_map[k]:
                bucket_map[k][key] = path
    return bucket_map


def print_keep_reasons(bucket_map):
    reason_map = {}
    for bucket_type, mapping in bucket_map.items():
        for slot, path in mapping.items():
            reason_map.setdefault(path, []).append(f"{bucket_type} {slot}")

    for path, reasons in sorted(reason_map.items()):
        print(f"Keep {path}: {', '.join(reasons)}")


def get_files_to_keep(files, args):
    """
    >>> files = [Path('2025-07-15.txt'), Path('2025-07-14.txt'),
    ...          Path('2025-07-13.txt'), Path('2025-07-12.txt')]
    >>> class Args:
    ...     keep_daily = 2
    ...     date_from_filename = True
    ...     filename_prefix = ''
    ...     filename_suffix = ''
    ...     verbose = False
    >>> sorted(get_files_to_keep(files, Args()))
    [PosixPath('2025-07-14.txt'), PosixPath('2025-07-15.txt')]
    """
    files_with_dates = extract_dates(args, files)
    limits = get_limits(args)
    bucket_map = collect_retention(files_with_dates, limits)
    keep_set = set(f for m in bucket_map.values() for f in m.values())

    if args.verbose:
        print_keep_reasons(bucket_map)

    return keep_set


def process_group(files, args):
    keep_set = get_files_to_keep(files, args)
    delete_set = set(files) - keep_set
    for f in delete_set:
        if args.force:
            try:
                f.unlink()
                print(f"Deleted: {f}")
            except Exception as e:
                print(f"Failed to delete {f}: {e}", file=sys.stderr)
        else:
            print(f)


def run_simulation(args):
    backups = []
    now = datetime.now()
    try:
        interval = int(args.simulate_retention_interval)
        delta = timedelta(days=interval)
    except ValueError:
        delta = {
            "daily": timedelta(days=1),
            "weekly": timedelta(weeks=1),
            "monthly": timedelta(days=30)
        }.get(args.simulate_retention_interval, timedelta(days=1))

    print(f"# Simulating retention for {args.simulate} days\n")
    print("* Backups are created daily")
    print(f"* Retention is run every {delta.days} days\n")

    for i in range(args.simulate):
        current_day = now + timedelta(days=i)
        filename = f"backup_{current_day.strftime('%Y-%m-%d')}.tar.gz"
        print(f"# {current_day.strftime('%Y-%m-%d')}\n")
        print(f"* Create backup: {filename}")

        backups.append(Path(filename))

        # Simulate retention once per interval
        if (i + 1) % delta.days == 0:
            print("* Run retention\n")

            class SimArgs:
                keep_daily = args.keep_daily
                keep_weekly = args.keep_weekly
                keep_monthly = args.keep_monthly
                keep_yearly = args.keep_yearly
                date_from_filename = True
                filename_prefix = "backup_"
                filename_suffix = ".tar.gz"
                force = False
                verbose = True

            keep_set = get_files_to_keep(backups, SimArgs())
            delete_set = set(backups) - keep_set
            for f in sorted(delete_set):
                print(f"Delete {f}")
                backups.remove(f)

        print()


def main():
    args = parse_args()
    if args.run_tests:
        doctest.testmod()
        return

    if args.simulate > 0:
        run_simulation(args)
        return

    paths = [Path(p) for p in args.paths]

    if all(p.is_dir() for p in paths):
        for p in paths:
            files = [f for f in p.iterdir() if f.is_file()]
            if args.verbose:
                print(f"\nProcessing directory: {p}", file=sys.stderr)
            process_group(files, args)
    elif all(p.is_file() for p in paths):
        process_group(paths, args)
    else:
        print("Error: Cannot mix files and directories.", file=sys.stderr)
        return


if __name__ == "__main__":
    main()
