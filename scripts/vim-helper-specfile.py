#!/usr/bin/env python3
"""
Print stuff for vim macros.

Usage in vim:
    * configure: `:cabbrev spec r !vim-helper-specfile.py`
    * use: `:spec`
"""
import subprocess
import time


def main():
    print("* {} {} <{}> - VER-REL".format(time.strftime("%a %b %e %Y"), *_get_git_user()))


def _get_git_user():
    proc = subprocess.run(
        ["git", "config", "user.name"], check=True, capture_output=True, text=True
    )
    git_user = proc.stdout.strip()
    proc = subprocess.run(
        ["git", "config", "user.email"], check=True, capture_output=True, text=True
    )
    git_email = proc.stdout.strip()
    return git_user, git_email


if __name__ == "__main__":
    main()
