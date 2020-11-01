#!/usr/bin/env python
"""
Convert any POSIX timestamps within specified bounds in input to a human
readable timestamp format, defaults to ISO 8601 in the systems localtime.
"""

import argparse
import fileinput
import functools
import locale
import logging as log
import re
import sys
import time


class Unix2ISOException(Exception):
    """Program exceptions."""


def main():
    locale.setlocale(locale.LC_ALL, "")
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.set_defaults(log_level="WARNING")
    parser.add_argument(
        "-v", "--verbose", action="store_const", dest="log_level", const="INFO"
    )
    parser.add_argument(
        "--debug", action="store_const", dest="log_level", const="DEBUG"
    )
    parser.add_argument(
        "--limit-past",
        type=int,
        metavar="days",
        default=365,
        help="Timestamps number of days in past that will be considered for "
        "conversion. Default: %(default)s.",
    )
    parser.add_argument(
        "--limit-future",
        type=int,
        metavar="days",
        default=30,
        help="Timestamps number of days in future that will be considered for "
        "conversion. Default: %(default)s.",
    )
    parser.add_argument(
        "--format",
        default="iso",
        help="Set output format. Possible values are 'iso', 'iso-strict' or a strftime"
        " format string (respects locale settings). Default: %(default)s.",
    )
    parser.add_argument(
        "-u",
        "--utc",
        action="store_true",
        help="Convert to UTC instead of localtime",
    )
    parser.add_argument(
        "-q",
        "--quote",
        action="store_true",
        help="Quote the formatted timestamp",
    )
    args, filenames = parser.parse_known_args()

    log.basicConfig(
        level=args.log_level,
        format="%(asctime)s %(levelname)-8s %(pathname)s:%(lineno)s [%(funcName)s]: "
        "%(message)s"
        if args.log_level == "DEBUG"
        else "%(asctime)s %(levelname)-8s %(message)s",
    )
    log.debug("args: %s", args)

    now = time.time()
    limit_past = now - args.limit_past * 86400
    limit_future = now + args.limit_future * 86400
    log.info(
        "Convert timestamps in range: %s (%d) - %s (%d)",
        time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(limit_past)),
        limit_past,
        time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(limit_future)),
        limit_future,
    )
    if args.utc:
        log.info("UTC: %s", time.strftime("%Y-%m-%d %H:%M:%S (%Z)", time.gmtime(now)))
    else:
        log.info(
            "Local time: %s",
            time.strftime("%Y-%m-%d %H:%M:%S %z (%Z)", time.localtime(now)),
        )

    q = '"' if args.quote else ""

    time_func = time.gmtime if args.utc else time.localtime

    if args.format == "iso":
        strftime = functools.partial(time.strftime, f"{q}%Y-%m-%d %H:%M:%S{q}")
    elif args.format == "iso-strict":
        strftime = functools.partial(time.strftime, f"{q}%Y-%m-%dT%H:%M:%S{q}")
    else:
        strftime = functools.partial(time.strftime, f"{q}{args.format}{q}")

    @functools.lru_cache(maxsize=128)
    def _format(ts):
        return strftime(time_func(ts))

    def _replace_timestamp(match):
        timestamp = int(match[0])
        if limit_past <= timestamp <= limit_future:
            return _format(timestamp)
        return match[0]

    with fileinput.input(files=filenames) as file_:
        for line in file_:
            print(re.sub(r"\b[123]\d{9}\b", _replace_timestamp, line), end="")


if __name__ == "__main__":
    try:
        main()
    except Unix2ISOException as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
