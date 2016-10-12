#!/usr/bin/env python3

# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <http://unlicense.org>

"""
Print absolute path of file(s).

Usage: abspath.py [FILES...]

For each file specified, print the absolute path of that file, but don't
resolve links (unline `readlink -f`).
Useful for example to "copy" the absolute path of a file in current dir,
to refer to somewhere else.
"""

import argparse
import os
import sys

sys.dont_write_bytecode = True


def main():
    """Print absolute path to file(s)."""
    parser = argparse.ArgumentParser(description='Print absolute path of file(s)')
    parser.add_argument('files', nargs='+', metavar='file',
                        help='a relative filename')
    parser.add_argument('-n', dest='newline', action="store_false",
                        help="Don't print newline character at end of list")

    args = parser.parse_args()

    if args.newline:
        for filename in args.files:
            print(os.path.abspath(filename))
    else:
        print(*[os.path.abspath(f) for f in args.files], sep="\n", end="")


if __name__ == '__main__':
    main()
