#!/usr/bin/env perl
# Copyright 2014 Aksel Sjögren

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;

my (%opts, %seen, @new_list);

GetOptions(\%opts, 'check-dirs', 'help', 'usage|h') or pod2usage(-verbose => 0);
pod2usage(-verbose => 2, exitval => 0) if $opts{help};
pod2usage(-verbose => 0, exitval => 0) if $opts{usage};

sub get_new_unique_dirs {
    my $seen = shift;
    my $dirlist = shift;
    my @new_dirlist;

    for my $d (@$dirlist) {
        unless (exists $seen->{$d}) {
            if (not $opts{'check-dirs'} or ($opts{'check-dirs'} and -d $d)) {
                push @new_dirlist, $d;
            }
            $seen->{$d} = 1;
        }
    }
    return @new_dirlist;
}

for my $arg (@ARGV) {
    my @dirs = split /:/, $arg;
    push @new_list, get_new_unique_dirs(\%seen, \@dirs);
}

print join(":", @new_list);

exit;

=pod

=encoding utf8

=head1 NAME

mergepaths.pl - Create directory list for PATH like environment variables.

=head1 SYNOPSIS

mergepaths.pl [-c|--check-dirs] [new_dir] $PATH [new_dir]

 Options:
    -c, --check-dirs            Only add directories that exists
    -h, --usage                 Short help
    --help                      Full help

=head1 OPTIONS

=over 8

=item B<--check-dirs>

Check that directories exists before adding them to the resulting PATH string.

This will also remove already existing directories from PATH that doesn't exist.

=back

=head1 DESCRIPTION

Returns a string for use with PATH like environment variables,
with each directory contained in the string only once.
This is to avoid getting duplicates in your PATH, MANPATH, PYTHONPATH etc.

Example in .bashrc, prepend PATH with /some/place/bin:

    C<export PATH=`mergepaths.pl /some/place/bin $PATH`>

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
