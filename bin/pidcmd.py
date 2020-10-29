#!/usr/bin/env python3

import sys


def main():
    try:
        pid = sys.argv[1]
    except IndexError:
        print(f"Missing argument.\nUsage: {sys.argv[0]} ( PID | - )")
        return False

    if pid == "-":
        pid = sys.stdin.read().strip()
    try:
        with open(f'/proc/{pid}/cmdline', 'r') as f:
            cmdline = f.read().rstrip('\x00')
    except OSError as exc:
        print(f"Cannot read pid '{pid}': {exc}", file=sys.stderr)
        return False

    try:
        index = sys.argv[2]
    except IndexError:
        print(cmdline.replace('\x00', ' '))
    else:
        print(cmdline.split('\x00')[int(index)])


if __name__ == "__main__":
    main()
