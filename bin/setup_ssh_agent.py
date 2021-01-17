#!/usr/bin/env python
# coding: utf-8

# MIT License
#
# Copyright (c) 2014 Aksel Sjögren
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

"""
Usage: eval `setup_ssh_agent.py [tcsh|bash]`

Prints shell commands to setup environment for ssh-agent.
If user already has an agent running on the server, setup environment
to use that agent. Otherwise, start a new one.

"""

from __future__ import print_function, unicode_literals

import argparse
import logging
import os
import subprocess
import sys

sys.dont_write_bytecode = True


def main(shell):
    socket_exists = False

    # Check if agent env vars are set
    if "SSH_AUTH_SOCK" in os.environ:
        logging.info("Found SSH_AUTH_SOCK: %s", os.environ["SSH_AUTH_SOCK"])
        if os.path.exists(os.environ["SSH_AUTH_SOCK"]):
            # Ok, socket exists, use that one
            ssh_agent_pid = subprocess.check_output(
                ["pgrep", "-u", os.environ["USER"], "-o", "ssh-agent"],
                universal_newlines=True,
            )
            if not ssh_agent_pid.strip().isdigit():
                logging.error("Invalid ssh-agent pid, pgrep output: %r", ssh_agent_pid)
                return False
            set_env(shell, "SSH_AGENT_PID", ssh_agent_pid)
            socket_exists = True
        else:
            # Socket doesn't exist, remove invalid environment
            unset_env(shell, "SSH_AGENT_PID", "SSH_AUTH_SOCK")

    # If we didn't get socket from environment, try to find it on disk
    if not socket_exists:
        logging.info("SSH_AUTH_SOCK not found, try to locate on disk")
        try:
            cmd = "/bin/find /tmp/ -type s -user {} -name 'agent.*'".format(
                os.environ["USER"]
            )
            logging.debug("Run: %s", cmd)
            p = subprocess.Popen(
                cmd,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=True,
            )
            stdout, stderr = p.communicate()
            logging.debug("stdout: %r, stderr: %r", stdout, stderr)

            lines = stdout.strip().splitlines()
            logging.debug("lines: %s", lines)
            try:
                socket = lines[0]
            except IndexError:
                socket = None

            if len(lines) > 1:
                logging.warning(
                    "Found %d ssh-agent sockets, using %r", len(lines), lines[0]
                )

            if socket:
                logging.info("Found socket at %s", socket)
                set_env(shell, "SSH_AUTH_SOCK", socket)
                ssh_agent_pid = subprocess.check_output(
                    ["pgrep", "-u", os.environ["USER"], "-o", "ssh-agent"],
                    universal_newlines=True,
                )
                if not ssh_agent_pid.strip().isdigit():
                    logging.error(
                        "Invalid ssh-agent pid, pgrep output: %r", ssh_agent_pid
                    )
                    return False
                set_env(shell, "SSH_AGENT_PID", ssh_agent_pid)
            else:
                logging.info("No socket found, start new ssh-agent")
                print("eval `ssh-agent`;")

        except OSError as e:
            logging.error("Failed while finding agent, command: %r, error: %s", cmd, e)
            return False


def unset_env(shell, *args):
    """Print shell commands to remove an environment variable.

    :param shell: Shell type
    :param args: Names of environment variables

    """
    for var_name in args:
        format_str = {
            "tcsh": "unsetenv {name};",
            "bash": "unset {name};",
        }
        out = format_str[shell].format(name=var_name)
        logging.info(out)
        print(out)


def set_env(shell, var_name, var_value):
    """Print shell commands to set an environment variable.

    :param shell: Shell type
    :param var_name: Environment variable name
    :param var_value: New value

    """
    format_str = {
        "tcsh": "setenv {name} {value};",
        "bash": "export {name}={value};",
    }
    out = format_str[shell].format(name=var_name, value=var_value.strip())
    logging.info(out)
    print(out)


def _init():
    user_shell = os.path.basename(os.environ["SHELL"])

    parser = argparse.ArgumentParser(
        description="Print shell commands to setup ssh-agent."
        "Intended to use like: eval `setup_ssh_agent.py`"
    )

    parser.add_argument(
        "shell",
        nargs="?",
        choices=["tcsh", "bash"],
        default=user_shell,
        help="Specify login shell (default: %(default)s)",
    )
    parser.add_argument("-v", "--verbose", action="store_true")
    parser.add_argument("-d", "--debug", action="store_true", help=argparse.SUPPRESS)

    args = parser.parse_args()

    log_format = "%(asctime)s %(levelname)-8s %(message)s"
    log_level = logging.WARNING

    if args.verbose:
        log_level = logging.INFO
    if args.debug:
        log_level = logging.DEBUG
        log_format = (
            "%(asctime)s %(levelname)-8s %(pathname)s:%(lineno)s "
            "[%(funcName)s]: %(message)s"
        )

    logging.basicConfig(level=log_level, format=log_format)

    return args


if __name__ == "__main__":
    args = _init()
    if main(args.shell):
        sys.exit(0)
    else:
        sys.exit(1)
