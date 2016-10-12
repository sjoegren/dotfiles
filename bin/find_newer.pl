#!/usr/bin/perl
# Copyright 2012 Aksel Sjögren

use strict;
use warnings;
use Getopt::Long;
use File::Find;
use Time::Local;

my ($verbose, $help, $pattern, $dir, $older, $include_dots);
my $timestamp = '';
my ($year,$month,$mday,$hour,$minute);

# Usage: usage [errmsg [,exitstatus]]
sub usage {
    my $msg = shift;
    my $status = shift;
    $status = 0 unless defined $status;

    print "$msg\n" if defined $msg;
    $0 =~ s#^.*/##;
    print "Usage: $0 [-p regex-pattern ] [ -d directory ] [-o] { [YYYY]MMDDhhmm | MMDD }
    -p regex-pattern        Only matching filenames
    -d directory            Find in this directory instead of HOME
    -o --older              Match files modified before date instead of after
    -i[nclude]              Include dot-files/dirs
    -h          this help message
";
    exit $status;
}

sub wanted {
    my $match;

    # Skip printing dirs
    (-d $File::Find::name) && return;

    unless ($include_dots) {
        # skip .dirs
        return if $File::Find::dir =~ m#/\.\w#;
        # skip .files
        return if m#^\.#;
    }

    my $file_time = (stat)[9]; # unixtime of file
    my $time = timelocal(0, $minute, $hour, $mday, $month-1, $year-1900); # create unix time

    if ($older) {
        $match = 1 if ($file_time < $time);
    }
    else {
        $match = 1 if ($file_time > $time);
    }
    return unless $match;

    if ($pattern) {
        if (/$pattern/) {
            print $File::Find::name, $/;
        }
        return;
    }
    print $File::Find::name, $/;

}

GetOptions(
    'verbose'           => \$verbose,
    'help'              => \$help,
    'pattern=s'         => \$pattern,
    'dir=s'             => \$dir,
    'older'             => \$older,
    'include'           => \$include_dots,
) || usage;
usage if $help;

if ($dir) {
    (-d $dir) or die "Error: specified directory doesn't exist\n";
}
else {
    $dir = $ENV{HOME};
}

$timestamp = shift;

(defined $timestamp) || usage("Error: missing timestamp", 1);

if ($timestamp =~ /^(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/) {
    $year = $1;
    $month = $2;
    $mday = $3;
    $hour = $4;
    $minute = $5;
}
elsif ($timestamp =~ /^(\d\d)(\d\d)(\d\d)(\d\d)$/) {
    $year = (localtime(time))[5] + 1900;
    $month = $1;
    $mday = $2;
    $hour = $3;
    $minute = $4;
}
elsif ($timestamp =~ /^(\d\d)(\d\d)$/) {
    $year = (localtime(time))[5] + 1900;
    $month = $1;
    $mday = $2;
    $hour = 0;
    $minute = 0;
}
else {
    warn "Error: Invalid timestamp\n";
    exit 1;
}

find(\&wanted, $dir);

exit 0;

=pod

=encoding utf8

=head1 NAME

find_newer.pl - find files newer than the specified timestamp.

=head1 SYNOPSIS

Usage: find_newer.pl OPTIONS TIMESTAMP

TIMESTAMP can be either MMDD, MMDDhhmm or YYYYMMDDhhmm.

See C<find_newer.pl --help> for available options.

=head1 AUTHOR

Aksel Sjögren

L<Github|https://github.com/akselsjogren/dotfiles>

=head1 COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2012 Aksel Sjögren

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
