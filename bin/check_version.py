#!/usr/bin/env python3
r"""
Check how a program version compares to a version string.

Example:
    # Check if git version is > 2.0
    $ git --version | check_version.py --match 'version (\d+\.\d+\.\d+)' \
        --operator gt --check-version 2.0
    2.21.0 is gt 2.0: True
    $ echo $?
    0
"""

import argparse
import functools
import operator
import re
import sys

sys.dont_write_bytecode = True


class Error(Exception):
    """Program errors."""


@functools.total_ordering
class Version:
    """Dotted version strings like 1.2.3 with comparison operators.

    Example:
        >>> v = Version('1.2.3')
        >>> v == Version('1.2')
        False
        >>> v == Version('1.2.3')
        True
        >>> v > Version('1.2')
        True
        >>> v < Version('2.0.0')
        True
        >>> Version('0.10.1000') > Version('0.9.99999')
        True
    """

    def __init__(self, version):
        self.version = tuple(int(x) for x in version.split("."))

    def __eq__(self, other):
        return self.version == other.version

    def __gt__(self, other):
        return self.version > other.version

    def __str__(self):
        return ".".join(str(x) for x in self.version)


def _init():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "--match",
        metavar="REGEX",
        required=True,
        help="Pattern that captures the version string in a capture group. "
        "Example: 'version (\\d+\\.\\d+\\.\\d+)'",
    )
    parser.add_argument(
        "--operator",
        choices=("lt", "le", "eq", "ne", "ge", "gt"),
        default="ge",
        help="Comparison operator to use, default: %(default)s",
    )
    parser.add_argument(
        "--file",
        type=argparse.FileType("r"),
        help="File with input, defaults to stdin",
        default=sys.stdin,
    )
    parser.add_argument(
        "--check-version", required=True, help="The version to compare to"
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

    input_version = Version(match.group(1))
    compare_version = Version(args.check_version)
    oper = getattr(operator, args.operator)
    passed = oper(input_version, compare_version)
    if args.verbose:
        print("{} is {} {}: {}".format(input_version, args.operator, compare_version, passed))
    return passed


if __name__ == "__main__":
    try:
        args = _init()
        success = main(args)
        sys.exit(0 if success else 1)
    except Error as e:
        print(str(e), file=sys.stderr)
        sys.exit(2)
