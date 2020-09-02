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
import sys
import os
import re

ANSIBLE_INVENTORY = os.path.expanduser(
    os.environ.get("ANSIBLE_INVENTORY", "~/.ansible-inventory")
)


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
    parser.add_argument("--scp", metavar="hostname", help="Run scp instead of ssh")
    parser.add_argument(
        "--copy-id", action="store_true", help="Run ssh-copy-id instead of ssh"
    )
    args = parser.parse_args()

    if args.complete_hosts:
        hosts = []
        for line in args.inventory:
            match = re.match(rf"(^[\w.-]+)\s.*?\bansible_host=(\S+)", line)
            if match:
                hosts.append(match[1])
        print("\t".join(hosts))
        return True
    else:
        if not args.sshargs:
            parser.error("hostname argument is required")

    hostname = args.scp or args.sshargs[-1]

    # hostname = args.sshargs[0]
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

    command = "scp" if args.scp else "ssh-copy-id" if args.copy_id else "ssh"
    exec_args = (command, "-o", f"Hostname={ansible_host}", *args.sshargs)
    print(f"exec: {' '.join(exec_args)}")
    sys.stdout.flush()
    os.execlp(command, *exec_args)


if __name__ == "__main__":
    if not main():
        sys.exit(1)
