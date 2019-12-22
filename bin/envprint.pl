#!/usr/bin/env perl
# Copyright 2014 Aksel Sjögren

use 5.010;
use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Pod::Usage;
use File::Basename qw(basename);

my ($debug); # for --debug options
my %opts = ('debug' => \$debug, );
my $pattern;

# Usage: debug(@items)
# If an item is a reference, print it using Data::Dumper
sub debug {
    return unless $debug;
    for my $item (@_) {
        $item = Dumper($item) if (ref $item);
        for (split /\n/, $item) {
            warn "--- DEBUG: $_\n";
        }
    }
}

sub print_env {
    my $var = shift;

    if ($opts{'only-names'}) {
        say $var;
        return;
    }

    if ($opts{'env'}) {
        say "$var=$ENV{$var}";
        return;
    }

    if ($ENV{$var} =~ /:/) {
        my @vals = split /:/, $ENV{$var};

        # if value contains : and first item looks like a directory,
        # guess we're dealing with some PATH var, so we split the values.
        if (scalar @vals > 0 && $vals[0] =~ m#^/\w\S*$#) {
            say "$var = ";
            say "\t$_" for (@vals);
            return;
        }
    }

    # single value
    say "$var = $ENV{$var}";
}

Getopt::Long::Configure(qw/bundling auto_version/);
GetOptions(\%opts, 'values|v', 'debug', 'usage|h', 'help', 'only-names|n', 'env|e')
    or pod2usage(-verbose => 0);
pod2usage(-verbose => 0, exitval => 0) if $opts{usage};
pod2usage(-verbose => 2) if $opts{help};

debug \%opts;

$pattern = shift;

for my $var (sort keys %ENV) {
    if ($pattern) {
        my $regex = qr{$pattern}i;

        # if any chars in pattern is UPPERCASE, match case sensitive
        if ($pattern =~ /[[:upper:]]/) {
            $regex = qr{$pattern};
        }

        if ($opts{values}) {
            print_env($var) if ($ENV{$var} =~ $regex);
        }
        else {
            print_env($var) if ($var =~ $regex);
        }

        next;
    }
    print_env($var);
}

exit;

=pod

=encoding utf8

=head1 NAME

envprint.pl - (Pretty)print environment variables matching pattern

=head1 SYNOPSIS

envprint.pl [options] [PATTERN]

 Options:
    -n, --only-names            Only print the environment variable names
    -e, --env                   Output the same was as `env` program
    -h                          Short help message
    --help                      Show full help
    -v, --values                Match on environment values instead of names.
    --debug                     Turn on debug output
    --version                   Show program version and exit

=head1 DESCRIPTION

B<envprint.pl> will print the environment variables, optionally matching a
pattern on the command-line. The pattern match can be a perl regex. The matching
case-insensitive, unless some character in PATTERN is uppercase.

Useful if you don't remember, or care to type, the exact name of some variable.
  Example:
    Find out any configured proxys
    $ envprint.pl proxy

    Find any PATH-like variables configured
    $ envprint.pl path

    Same as above, but only variables matching case-sensitive PATH
    $ envprint.pl PATH

    Show names of environment variables with values matching 'packages'
    $ envprint.pl -vn packages

=head1 AUTHOR

Aksel Sjögren

L<Github|https://github.com/akselsjogren/dotfiles>

=head1 COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2014 Aksel Sjögren

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
