#!/usr/bin/env python3
r"""
Convert JSON on stdin to YAML on stdout (or --reverse).

Example: json_to_yaml.py < input.json > output.yaml
"""
import argparse
import json
import sys

import yaml


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "--reverse", "-r", action="store_true", help="Convert from YAML to JSON instead"
    )
    parser.add_argument(
        "--pretty", "--format", action="store_true", help="Just pretty-print JSON"
    )
    args = parser.parse_args()

    if args.reverse:
        try:
            data = yaml.safe_load(sys.stdin)
        except yaml.scanner.ScannerError as e:
            parser.error("Failed to decode stdin as YAML: %s" % e)
        else:
            json.dump(data, sys.stdout, indent=4)
        return

    try:
        data = json.load(sys.stdin)
    except ValueError as e:
        parser.error("Failed to decode stdin as JSON: %s" % e)
    else:
        if args.pretty:
            json.dump(data, sys.stdout, indent=4)
        else:
            yaml.safe_dump(data, stream=sys.stdout)


if __name__ == "__main__":
    main()
