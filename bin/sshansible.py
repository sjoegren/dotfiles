#!/usr/bin/python3
"""
SSH to hostnames in an ansible-inventory file when using inventory's
"ansible_host" keys instead of name resolution.

Given an inventory file like this:

    [buildslaves]
    foo     ansible_host=192.0.2.1

Running 'sshansible.py -- -v foo', will exec the command 'ssh -o Hostname=192.0.2.1 -v foo'.
That way any config in 'ssh_config' for host 'foo' will still be honored.

scp:
    sshansible.py --scp bar -- /etc/foo.conf bar:/tmp
"""

import argparse
import os
import pathlib
import queue
import re
import subprocess
import sys
import threading
import time

ANSIBLE_INVENTORY = os.path.expanduser(
    os.environ.get("ANSIBLE_INVENTORY", "~/.ansible-inventory")
)
CACHE_FILE = pathlib.Path("/var/run/user") / str(os.getuid()) / "sshansible_last_host"


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "-i",
        "--inventory",
        default=ANSIBLE_INVENTORY,
        metavar="FILE",
        type=argparse.FileType("r"),
        help="Specify inventory file to use. Can also be specified with environment "
        "variable 'ANSIBLE_INVENTORY'. Default: %(default)s",
    )
    parser.add_argument("--complete-hosts", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument(
        "sshargs",
        nargs="*",
        metavar="arg",
        help="ssh arguments, like host from ansible inventory to connect to",
    )
    parser.add_argument(
        "-c",
        "--remote-cmd",
        metavar="FILE",
        help="Execute remote command read from FILE (- to read from stdin), "
        "on target host",
    )
    parser.add_argument(
        "--scp",
        nargs="?",
        const="last",
        metavar="hostname",
        help="Run scp instead of ssh, if used together with -l no hostname is "
        "requiredi, leave host empty is target spec.",
    )
    parser.add_argument(
        "--copy-id", action="store_true", help="Run ssh-copy-id instead of ssh"
    )
    parser.add_argument(
        "-l", "--last", action="store_true", help="ssh to last target used"
    )
    parser.add_argument(
        "-L", "--list", action="store_true", help="List hosts in inventory"
    )
    args = parser.parse_args()

    hostname = None
    if args.complete_hosts:
        hosts = []
        for line in args.inventory:
            match = re.match(rf"(^[\w.-]+)\s.*?\bansible_host=(\S+)", line)
            if match:
                hosts.append(match[1])
        print("\t".join(hosts))
        return True
    elif args.last:
        try:
            hostname = CACHE_FILE.read_text()
        except OSError:
            print(
                "Cannot use --last because cache file doesn't exist.", file=sys.stderr
            )
            sys.exit(1)
        if not args.sshargs:
            args.sshargs.append(hostname)
    elif args.list:
        list_inventory(args.inventory)
        return
    elif not args.sshargs:
        parser.error("hostname argument is required")

    if not hostname:
        hostname = args.scp or args.sshargs[-1]

    # Allow empty hostname in scp src/dest specifications
    for i, arg in enumerate(args.sshargs):
        if arg.startswith(":"):
            args.sshargs[i] = f"{hostname}{arg}"

    for line in args.inventory:
        match = re.match(rf"({hostname}\b\S*)\s.*?\bansible_host=(\S+)", line)
        if match:
            print(line, end="")
            ansible_host = match[2]
            break
    else:
        print(f"Couldn't find any hosts matching '{hostname}'")
        return False
    args.inventory.close()
    CACHE_FILE.write_text(hostname)

    command = "scp" if args.scp else "ssh-copy-id" if args.copy_id else "ssh"
    exec_args = [command, "-o", f"Hostname={ansible_host}", *args.sshargs]

    if args.remote_cmd:
        return run_remote_command(args.remote_cmd, hostname, ansible_host, exec_args)

    print(f"exec: {' '.join(exec_args)}")
    sys.stdout.flush()
    os.execvp(command, exec_args)


def host_status(tasks, result):
    """Return True if host is online, otherwise False."""
    host = tasks.get()
    proc = subprocess.run(
        ["ping", "-c", "1", "-W", "0.5", "-q", host["address"]],
        text=True,
        capture_output=True,
    )
    host["status"] = proc.returncode == 0
    result.put((threading.current_thread(), host))
    tasks.task_done()


def list_inventory(inventory):
    tasks = queue.Queue()
    hosts = {}
    threads = []
    results = queue.Queue()
    for line in inventory:
        match = re.match(r"^(\S+)\s.*?\bansible_host=(\S+)", line)
        if match:
            host_data = {
                "name": match[1],
                "address": match[2],
                "has_status": threading.Event(),
            }
            hosts[match[1]] = host_data
            t = threading.Thread(target=host_status, args=(tasks, results))
            threads.append(t)
            tasks.put(host_data)
            t.start()
    maxhostlen = max(len(h["name"]) for h in hosts.values())
    print(
        "Hostname{padding}  Address          Status  URL".format(
            padding=" " * (maxhostlen - 8)
        )
    )
    # print hosts as soon as they are ready
    for _ in range(len(threads)):
        thread, host = results.get(timeout=5)
        thread.join()
        print(
            "{0:<{colwidth}}  {1:<15}  {2:<6}  https://{1}".format(
                host["name"],
                host["address"],
                "Online" if host["status"] else "-",
                colwidth=maxhostlen,
            )
        )
    assert threading.active_count() == 1


def run_remote_command(remote_cmd_file, hostname, ansible_host, exec_args):
    """Run the script in file remote_cmd_file on the remote host.

    First transfer the file to remote host with scp.
    Run the file with "sh", then remove the file and print any output.
    """
    assert os.path.exists(remote_cmd_file)
    if remote_cmd_file == "-":
        print("not implemented", file=sys.stderr)
        return False
    remote_tmp_file = "/tmp/sshansible_cmd_{}.sh".format(str(int(time.time())))
    proc = subprocess.run(
        [
            "scp",
            "-o",
            f"Hostname={ansible_host}",
            remote_cmd_file,
            f"{hostname}:{remote_tmp_file}",
        ],
        text=True,
        check=True,
        capture_output=True,
    )
    proc = subprocess.run(
        exec_args
        + [f"sh {remote_tmp_file}; ret=$?; rm -f {remote_tmp_file}; exit $ret"],
        text=True,
        capture_output=True,
    )
    if proc.stdout:
        print(
            ">>>>> Remote stdout start <<<<<",
            proc.stdout,
            ">>>>> Remote stdout end <<<<<",
            sep="\n",
        )
    if proc.stderr:
        print(
            ">>>>> Remote stderr start <<<<<",
            proc.stderr,
            ">>>>> Remote stderr end <<<<<",
            sep="\n",
        )
    print(f"Remote exit code: {proc.returncode}")
    return proc.returncode == 0


if __name__ == "__main__":
    if not main():
        sys.exit(1)
