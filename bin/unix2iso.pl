#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use POSIX qw(strftime);

my ($opt_help, $opt_strict, $opt_utc);
my $formatted;

sub usage {
    $0 =~ s#^.*/##;
    print "Read lines from stdin and converts any POSIX timestamps to ISO8601 timestamps.

Usage: $0 [OPTIONS]
  -s --strict             YYYY-MM-DDTHH:MM:SS+HH:MM. Default is 'YYYY-MM-DD HH:MM:SS'.
  -u --utc                Print ISO8601 timestamps in UTC instead of local time.
  -h                      Print usage text.
";
    exit 0;
}

GetOptions(
    'help'              => \$opt_help,
    'strict'            => \$opt_strict,
    'utc'               => \$opt_utc,
) || usage;
usage if $opt_help;

while (<>) {
	if (/(\d{10})/) {;
		my $tz = $opt_utc ? 'Z' : '%z';
		$formatted = strftime(
			defined $opt_strict ? "%Y-%m-%dT%H:%M:%S$tz" : '%Y-%m-%d %H:%M:%S',
			defined $opt_utc ? gmtime($1) : localtime($1)
		);
		s/(\d{10})/$formatted/;
	}
    print;
}

exit 0;
