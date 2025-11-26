#!/usr/bin/env perl
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

# DESCRIPTION:
# Find out and print the directory permissions of all parent
# directories to the files specified as script parameters.

use 5.010.1;
use strict;
use warnings;
use File::Spec;
use Fcntl ':mode';

use constant FILE_SEPARATOR => '----------------------------------------------------------------------';

my ($verbose, $debug, $help);
my $separator;
my %BITS = (
    0 => '---',
    1 => '--x',
    2 => '-w-',
    3 => '-wx',
    4 => 'r--',
    5 => 'r-x',
    6 => 'rw-',
    7 => 'rwx',
);

while (my $arg = shift) {
    unless (-e $arg) {
        say "`$arg`: $!";
        next;
    }
    say $separator if $separator;
    $separator = FILE_SEPARATOR;

    my $full = File::Spec->rel2abs($arg);
    my (undef, $directories, $file) = File::Spec->splitpath($full);
    my @dirs = File::Spec->splitdir($directories);
    #say Dumper \@dirs;

    # Process all parent dirs
    my $parent = '';
    for my $dir (@dirs, $file) {
        next unless $dir;
        my $test = "$parent/$dir";
        my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
            $atime,$mtime,$ctime,$blksize,$blocks) = stat($test);

        my $unix_str = sprintf("%s%s%s%s",
            S_ISDIR($mode) ? 'd' : '-',
            $BITS{ ($mode & S_IRWXU) >> 6 },    # user rwx
            $BITS{ ($mode & S_IRWXG) >> 3 },    # group rwx
            $BITS{ ($mode & S_IRWXO) },         # other rwx
        );
        printf("%04o\t%s\t%-15s %-15s %s\n",
            $mode & 07777,
            $unix_str,
            getpwuid($uid) // $uid,
            getgrgid($gid) // $gid,
            $test,
        );
        $parent = $test;
    }
}

exit 0;
