#!/usr/bin/env python3
"""
Find custom shell functions and print their name and description.
"""
import argparse
import logging as log
import pathlib
import itertools
import textwrap
import re

BASHRC = pathlib.Path("~/.bashrc").expanduser()
BASH_DIRS = (
    pathlib.Path("~/.bashrc.d").expanduser(),
    pathlib.Path(__file__).parent.parent / "bash",
)


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.set_defaults(log_level="WARNING")
    parser.add_argument(
        "--debug", action="store_const", dest="log_level", const="DEBUG"
    )
    parser.add_argument(
        "-v", "--verbose", "--where", action="store_true", dest="verbose",
        help="Print filename where function is defined")
    parser.add_argument(
        "pattern",
        nargs="?",
        help="Print functions that match pattern in name or description.",
    )
    args = parser.parse_args()
    log.basicConfig(
        level=args.log_level,
        format="%(asctime)s %(levelname)-8s %(pathname)s:%(lineno)s [%(funcName)s]: "
        "%(message)s"
        if args.log_level == "DEBUG"
        else "%(asctime)s %(levelname)-8s %(message)s",
    )
    functions = {}
    for f in itertools.chain(
        (BASHRC,),
        itertools.chain.from_iterable(path.glob("*.bash") for path in BASH_DIRS),
    ):
        log.info("Processing %s", f)
        functions.update({name: (desc, path) for name, desc, path in get_functions(f)})

    regex = re.compile(args.pattern, flags=re.I) if args.pattern else None
    for name in sorted(functions):
        desc, path = functions[name]
        desc = "\n".join(desc)
        if (not regex and not name.startswith("_")) or (
            regex and (regex.search(name) or regex.search(desc))
        ):
            print("{:<30}{}".format(name, f" ({path})" if args.verbose else ""))
            print(textwrap.indent(desc, "  "))
            if desc:
                print()
        else:
            log.info("Not printing %s", name)


def get_functions(bashfile):
    comment = []
    with bashfile.open() as f:
        for line in f:
            if (match := re.match(r"(?:(\w+)\(\)|# dotfiles-help: (.+))", line)) :
                log.debug("Function: %s", match[1])
                yield match[1] or match[2], comment, bashfile
                comment = []
            if re.match(r"# ", line):
                comment.append(line[2:].strip())
                log.debug("Comment: %s", line)
            else:
                comment = []


if __name__ == "__main__":
    main()
