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
use Carp;

use version; our $VERSION = qv('0.1');

use Data::Dumper;

# Add the Net-UDAP modules to the libpath
use FindBin;
use lib "$FindBin::Bin/../src/Net-UDAP/lib";

use Net::UDAP::MessageIn;

while (<>) {
	next if /^#/;

	# convert to binary data
	my $raw_msg = pack( 'H*', $_ );
	my $arg_ref = {};
	$arg_ref->{raw_msg} = $raw_msg;
	my $msg = Net::UDAP::MessageIn->new($arg_ref);
	print Dumper \$msg;
}
