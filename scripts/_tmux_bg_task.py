#!/usr/bin/env python3
r"""
Helper script for tmux config, to run tasks in background.
"""
import argparse
import logging as log
import os
import pathlib
import signal
import subprocess
import sys
import time

from xdg.BaseDirectory import get_runtime_dir

DEBUG = int(os.environ.get("PDB_DEBUG", 0))


class Pidfile:
    file_prefix = "tmux_bg_sendkey"

    def __init__(self, window_id):
        self.window_id = window_id

    @property
    def path(self):
        return pathlib.Path(get_runtime_dir()) / f"{self.file_prefix}.{self.window_id}"

    @classmethod
    def from_path(cls, path: pathlib.Path):
        window_id = path.name.replace(f"{cls.file_prefix}.", "")
        return cls(window_id)

    def store_pid(self):
        self.path.write_text(str(os.getpid()))

    def read_pid(self):
        return int(self.path.read_text().strip())

    def remove(self):
        self.path.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.set_defaults(func=None)
    subs = parser.add_subparsers(
        title="Subcommands",
        description='"command --help" for help on the subcommand',
        required=True,
    )
    reminder = subs.add_parser("reminder", help="Periodic reminder")
    send = subs.add_parser("send-key", help="send-key to pane")

    # Arguments and defaults common for all parsers
    for p in parser, reminder, send:
        p.set_defaults(log_level="INFO")
        p.add_argument(
            "-q", "--quiet", action="store_const", dest="log_level", const="WARNING"
        )
        p.add_argument(
            "-v", "--verbose", action="store_const", dest="log_level", const="DEBUG"
        )
        p.add_argument(
            "--logfile",
            default=os.path.join(get_runtime_dir(), "tmux_bg_task.log"),
            help="- for stdout. Default: %(default)s",
        )

    reminder.set_defaults(func=_reminder)
    reminder.add_argument(
        "--interval", type=int, required=True, metavar="seconds", help="Sleep interval"
    )
    reminder.add_argument(
        "--tmux-delay",
        type=int,
        default=0,
        metavar="seconds",
        help="display-message delay",
    )
    reminder.add_argument("message")

    send.set_defaults(func=_cmd_send_key)
    send.add_argument("--window", required=True, help="tmux window")
    send.add_argument(
        "--kill", action="store_true", help="Kill send-key process for specified window"
    )
    send.add_argument("--keys", nargs="*", help="Key(s) to send, accepts multiple args")
    send.add_argument(
        "--enter", action="store_true", help="Append enter/newline to keys"
    )
    send.add_argument("--sleep-interval", type=int, default=10)
    send.add_argument(
        "--inactivity",
        type=int,
        default=60,
        metavar="seconds",
        help="send-key after [seconds] inactivity",
    )
    send.add_argument(
        "--pane-cmd", nargs="?", help="send-key only to panes running PANE_CMD"
    )

    args = parser.parse_args()
    kwargs = {"level": "DEBUG" if os.getenv("TMUX_VERBOSE") else args.log_level}
    if args.logfile != "-":
        kwargs["filename"] = args.logfile
    log.basicConfig(
        format="%(asctime)s [%(process)d] %(levelname)s: %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        **kwargs,
    )
    log.debug("args: %s", args)
    args.func(args)


def _cmd_send_key(args):
    if args.kill:
        _stop_sendkey(args.window)
        return
    keys = args.keys or []
    if args.enter:
        keys.append("C-m")
    if not keys:
        raise RuntimeError("No keys to send (set --keys/--enter)")
    log.info(
        "Send key %r to pane(s) with cmd %r in window %r after %s sec inactivity",
        keys,
        args.pane_cmd,
        args.window,
        args.inactivity,
    )
    pidfile = Pidfile(args.window)
    pidfile.store_pid()
    try:
        while True:
            if not _recent_window_activity(args.window, args.inactivity):
                log.info(
                    "No window_activity in %s in last %d seconds, send-key %s"
                    " to panes with command %s",
                    args.window,
                    args.inactivity,
                    keys,
                    args.pane_cmd,
                )
                if not _send_key(keys, args.window, args.pane_cmd):
                    log.warning("send-key failed, aborting")
                    break
            time.sleep(args.sleep_interval)
            if not pidfile.path.exists():
                log.info("Lock file %s doesn't exist, exiting...", pidfile.path)
                return
    except KeyboardInterrupt:
        log.info("Caught SIGINT (probably by `send-key --kill`), exiting...")
        pidfile.remove()
        return


def _recent_window_activity(window: str, inactivity_time: int = 60):
    """Return True if window's activity is more recent than last
    inactivity_time seconds."""
    proc = subprocess.run(
        ["tmux", "list-panes", "-F", "#{window_activity}", "-t", window],
        check=True,
        timeout=1,
        stdout=subprocess.PIPE,
        text=True,
    )
    last_activity = proc.stdout.splitlines()[0]
    ret = int(last_activity) > time.time() - inactivity_time
    log.debug(
        "Last activity time for %s: %s (%s). recent=%s",
        window,
        time.ctime(int(last_activity)),
        last_activity,
        ret,
    )
    return ret


def _send_key(keys, window, pane_cmd=None):
    proc = subprocess.run(
        [
            "tmux",
            "list-panes",
            "-F",
            "#{pane_id}|#{pane_current_command}",
            "-t",
            window,
        ],
        check=True,
        timeout=1,
        stdout=subprocess.PIPE,
        text=True,
    )
    retvals = 0
    for line in proc.stdout.splitlines():
        pane_id, pane_current_command = line.split("|", maxsplit=1)
        if pane_cmd and pane_cmd != pane_current_command:
            continue
        log.debug(
            "send-key to pane %r running command %r", pane_id, pane_current_command
        )
        proc = subprocess.run(["tmux", "send-key", "-t", pane_id] + keys, timeout=1)
        retvals += proc.returncode
    return retvals == 0


def _stop_sendkey(window_id):
    if window_id != "all":
        pidfile = Pidfile(window_id)
        _kill_pid(pidfile)
        return

    for lockfile in pathlib.Path(get_runtime_dir()).glob("tmux_bg_sendkey.*"):
        log.info("Found lockfile %s, attempt to kill the process owning it", lockfile)
        pidfile = Pidfile.from_path(lockfile)
        _kill_pid(pidfile)
    return


def _kill_pid(pidfile: Pidfile):
    try:
        pid = pidfile.read_pid()
    except FileNotFoundError:
        raise RuntimeError(
            "No stored pid for tmux window '{}' ({})".format(
                pidfile.window_id, pidfile.path
            )
        )
    log.debug("Send SIGINT to %s", pid)
    os.kill(pid, signal.SIGINT)


def _get_clients(*flags):
    """Get tmux clients with the flags in *flags."""
    proc = subprocess.run(
        ["tmux", "list-clients", "-F", "#{client_tty}|#{client_flags}"],
        check=True,
        timeout=1,
        stdout=subprocess.PIPE,
        text=True,
    )
    for line in proc.stdout.splitlines():
        log.debug("_get_clients %r", line)
        tty, flag_str = line.split("|", maxsplit=1)
        client_flags = set(flag_str.split(","))
        for flag in flags:
            if flag not in client_flags:
                break
        else:
            log.debug("Found all flags %s for client %s", flags, tty)
            yield tty


def _reminder(args):
    while True:
        time.sleep(args.interval)
        sent_to = []
        for client_tty in _get_clients("attached", "focused"):
            sent_to.append(client_tty)
            subprocess.run(
                [
                    "tmux",
                    "display-message",
                    "-c",
                    client_tty,
                    "-d",
                    str(args.tmux_delay),
                    args.message,
                ],
                check=True,
                timeout=1,
                text=True,
            )
        log.info("Sent message to tmux clients: %s", ", ".join(sent_to))
        if not sent_to:
            log.error("Did not get any attached tmux clients to send to")


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
