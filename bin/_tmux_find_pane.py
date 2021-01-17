#!/usr/bin/env python3
r"""
Helper script for tmux config.
Find and print the tmux pane id where the given pid(s) are running.

Usage:
    * `prefix >`     open menu
    * find pid in pane:
        - Find a line with e.g. 'process id: X' in the current pane (for example
        vim swapfile warning).
    * enter pid manually:

    * Locate the tmux pane parenting the pid.
    * Do a switch-client to that pane (previous pane will be marked).
    * `prefix '` to get back (switchc -t '{marked}').

Tmux config example:

```
bind-key -T prefix > display-menu -T \
  "#[align=centre]Magic features | #{pane_index} (#{pane_id})" -x P -y P \
"Find pid in pane (back: C-a ')" f \
  "run-shell '_tmux_find_pane.py --find-pid #{pane_id} -q --mark-pane #{pane_id}'; \
switchc -t \"{marked}\"; \
run-shell '_tmux_find_pane.py -q --mark-env-pane'" \
"Go to parent pane of pid" p \
  "command-prompt -p \"Enter PID:\" \
  \"run-shell '_tmux_find_pane.py --pid %% -q --mark-pane #{pane_id}'; \
  switchc -t '{marked}'; \
  run-shell '_tmux_find_pane.py -q --mark-env-pane'\"" \
"Go to globally last pane" b "run-shell '_tmux_find_pane.py -q --mark-env-pane'; \
switchc -t \"{marked}\""

bind \' switch-client -t "{marked}"
```

"""
import argparse
import os
import re
import subprocess
import sys

if sys.version_info < (3, 5):
    print("Python version >= 3.5 is required. Current version:\n" + sys.version)
    sys.exit(1)

DEBUG = int(os.environ.get("PDB_DEBUG", 0))


class Panes:
    def __init__(self, cmd_timeout):
        proc = subprocess.run(
            ["tmux", "list-panes", "-a", "-F", "#{pane_pid}:#{pane_id}:#{pane_marked}"],
            check=True,
            universal_newlines=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=cmd_timeout,
        )
        self.cmd_timeout = cmd_timeout
        self.pids = {}
        self.marked_pane = ""
        for line in proc.stdout.splitlines():
            pid, pane_id, marked = line.split(":")
            self.pids[int(pid)] = pane_id
            if marked == "1":
                assert self.marked_pane == ""
                self.marked_pane = pane_id

    def get_tmux_pane(self, pid):
        """Return the pane id owning the child process pid by recursively
        checking pids parent processes."""
        if pid in self.pids:
            return self.pids[pid]
        if pid < 100:
            raise RuntimeError("given pid doesn't belong to tmux server")
        proc = subprocess.run(
            ["ps", "--format", "ppid=", "--pid", str(pid)],
            check=True,
            universal_newlines=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=self.cmd_timeout,
        )
        ppid = int(proc.stdout.strip())
        return self.get_tmux_pane(ppid)


class Pids:
    def __init__(self, cmd_timeout):
        proc = subprocess.run(
            ["ps", "--format", "pid=", "ax"],
            check=True,
            universal_newlines=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=cmd_timeout,
        )
        self.cmd_timeout = cmd_timeout
        self.pids = set(int(line.strip()) for line in proc.stdout.splitlines())

    def exists(self, pid: int):
        return pid in self.pids

    def find_pid_in_pane(self, pane_id):
        proc = subprocess.run(
            ["tmux", "capture-pane", "-p", "-t", pane_id],
            check=True,
            universal_newlines=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=self.cmd_timeout,
        )
        for line in reversed(proc.stdout.splitlines()):
            match = re.search(r"(?:process (?:id)|pid).{1,3}?(\b\d{2,}\b)", line, re.I)
            if match and int(match.group(1)) in self.pids:
                if DEBUG:
                    print(
                        "found %r in line: %r" % (match.group(1), line), file=sys.stderr
                    )
                return int(match.group(1))


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "--timeout", type=int, default=1, help="Timeout for subprocesses"
    )
    parser.add_argument(
        "--mark-pane",
        metavar="save_pane_id",
        help="Mark the target pane and store %(metavar)s in global tmux environment.",
    )
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--mark-env-pane", action="store_true")
    group.add_argument("--find-pid", metavar="pane_id")
    group.add_argument("--pid", type=int)
    parser.add_argument("-q", "--quiet", dest="verbose", action="store_false")
    args = parser.parse_args()
    if "TMUX" not in os.environ:
        raise RuntimeError("must run in tmux client")
    panes = Panes(args.timeout)
    pids = Pids(args.timeout)
    if args.mark_env_pane:
        try:
            pane_id = os.environ["_TMUX_LAST_PANE"]
        except KeyError:
            raise RuntimeError(
                "_TMUX_LAST_PANE not in environment. "
                "Hint: are we running in tmux run-shell?"
            )
        if args.verbose:
            print(pane_id)
        # If pane is already marked, don't 'select-pane' since it will toggle it to off.
        if pane_id != panes.marked_pane:
            subprocess.run(
                ["tmux", "select-pane", "-m", "-t", pane_id], check=True, timeout=1
            )
        subprocess.run(
            ["tmux", "setenv", "-u", "-g", "_TMUX_LAST_PANE"], check=True, timeout=1
        )
        return
    if args.find_pid:
        pid = pids.find_pid_in_pane(args.find_pid)
        if pid:
            pane_id = panes.get_tmux_pane(pid)
            if args.verbose:
                # print(pid)
                print(pane_id)
        else:
            if args.verbose:
                print("No pid found in pane")
            return
    if args.pid:
        if not pids.exists(args.pid):
            raise RuntimeError("no such process: %s" % args.pid)
        pane_id = panes.get_tmux_pane(args.pid)
        if args.verbose:
            print(pane_id)
    assert pane_id
    if args.mark_pane:
        # Store the current pane id in tmux global environment to provide a way
        # to find our way back, by calling this script again with
        # `--mark-env-pane`, which will set the stored pane to the marked pane,
        # to ease navigating back again.
        subprocess.run(
            [
                "tmux",
                "setenv",
                "-g",
                "_TMUX_LAST_PANE",
                args.mark_pane,
            ],
            check=True,
            timeout=1,
        )
        if pane_id != panes.marked_pane:
            subprocess.run(
                ["tmux", "select-pane", "-m", "-t", pane_id], check=True, timeout=1
            )


if __name__ == "__main__":
    try:
        main()
    except RuntimeError as e:
        print("error: %s" % e)
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print("error: %s" % e)
        sys.exit(abs(e.returncode))
    except Exception:
        if DEBUG:
            import pdb

            pdb.post_mortem()
        else:
            raise
