#!/usr/bin/env perl

# $Id$
#
# Copyright (c) 2008 by Robin Bowes <robin@robinbowes.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

# Add the modules to the libpath
use FindBin;
use lib "$FindBin::Bin/../src/Net-UDAP/lib";

use version; our $VERSION = qv('1.0_01');

use Carp;
use Data::Dumper;
use Getopt::Long;
use Net::UDAP::Shell;
use Pod::Usage;

$| = 1;

my $opt = {};

my $options_okay = GetOptions(

    # store options in hash
    $opt,

    # Application-specific options
    'local-address|a=s@',

    # Standard meta-options
    'help|?',
    'man',

) or pod2usage(0);

pod2usage(1) if $opt->{help};
pod2usage(-verbose => 2) if $opt->{man};

my $shell = Net::UDAP::Shell->new(%$opt);
$shell->cmdloop;

__END__

=head1 NAME

    udap_shell.pl - Interactive UDAP shell

=head1 SYNOPSIS

    udap_shell.pl [options]

    --local-address, -a   

=head1 DESCRIPTION

B<udap_shell.pl>

Simple wrapper around Net::UDAP discovery libraries

=over 4

=item --local-address, -a

send/listen on this local IP address

=back

=cut

# vim:set softtabstop=4:
# vim:set shiftwidth=4:
