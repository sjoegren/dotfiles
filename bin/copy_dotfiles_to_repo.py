#!/usr/bin/env python2
# coding: utf-8
"""
Copy the dotfiles that dotbot control from home directory to repository.
This is used on Windows/msys2, where symlinks aren't supported and I want to
check in possibly local edits to the repository.
"""
from __future__ import absolute_import, print_function, unicode_literals

import argparse
import json
import logging
import os
import shutil
import sys

DOTFILES_DIR = os.path.normpath(os.path.dirname(os.path.dirname(__file__)))
DEFAULT_DOTBOT_CONFIG = os.path.join(DOTFILES_DIR, 'dotbot.conf.json')


def main():
    def _loglevel(level):
        try:
            return getattr(logging, level.upper())
        except AttributeError:
            raise argparse.ArgumentTypeError('%r is not a valid log level' % level.upper())

    parser = argparse.ArgumentParser()
    parser.add_argument('--loglevel', type=_loglevel, default=logging.INFO,
                        metavar='LEVEL', help='Set log level')
    parser.add_argument('-c', '--config', default=DEFAULT_DOTBOT_CONFIG, type=argparse.FileType('r'),
                        metavar='FILE', help='dotbot config file (default: %(default)s)')
    args = parser.parse_args()
    logging.basicConfig(stream=sys.stdout, level=args.loglevel,
                        format='%(levelname)s: %(message)s')

    logging.debug('Read config file: %s', args.config)
    config = json.load(args.config)
    logging.debug(json.dumps(config, indent=4))

    for section in config:
        try:
            links = section['link']
            break
        except KeyError:
            continue

    copy_files(links)


def copy_files(links):
    """Copy files from target location back to source path.

    Assume that links which has a string (not dict) as value are the files that
    should be copied. Links with dict are probably more complex and shouldn't
    be copied.
    """
    for target, source in links.items():
        if isinstance(source, basestring):
            from_ = os.path.expanduser(target)
            to = os.path.join(DOTFILES_DIR, source)
            logging.info('Copy %s => %s', from_, to)
            shutil.copyfile(from_, to)


if __name__ == '__main__':
    main()
