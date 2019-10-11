#!/usr/bin/env python
"""
Check if version is --ge/--le to another version.

Usage:
"""

from __future__ import print_function
import argparse
import re
import sys

sys.dont_write_bytecode = True


class Error(Exception):
    """Program errors."""


def _init():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--match",
        metavar="REGEX",
        help="Pattern that captures the version string in a capture group. "
        "Example: 'version (\\d\\.\\d\\.\\d)'",
    )
    parser.add_argument("--min-version", "--ge", help="Minimum version to match")
    parser.add_argument(
        "--file",
        type=argparse.FileType("r"),
        help="File with input, defaults to stdin",
        default=sys.stdin,
    )
    parser.add_argument(
        "-q", action="store_false", dest="verbose", help="Don't print anything"
    )
    return parser.parse_args()


def main(args):
    """Compare version strings."""
    data = args.file.read()
    match = re.search(args.match, data, re.I)
    if not match:
        raise Error("--match pattern doesn't find anything in input")

    if args.min_version:
        is_ge = version_is_ge(match.group(1), args.min_version)
        if args.verbose:
            print("%s version check" % ("PASSED" if is_ge else "FAILED"))
        return is_ge


def version_is_ge(version_string, min_version_string):
    """Return True if version_string >= min_version_string.

    Example:
        >>> version_is_ge('8.2.5', '8.1')
        True
        >>> version_is_ge('8.2.5', '8.3')
        False
    """
    version = tuple(int(x) for x in version_string.split("."))
    min_version = tuple(int(x) for x in min_version_string.split("."))
    return version >= min_version


if __name__ == "__main__":
    try:
        args = _init()
        success = main(args)
        sys.exit(0 if success else 1)
    except Error as e:
        print(str(e), file=sys.stderr)
        sys.exit(2)
