#!/usr/bin/env perl

# $Id: udap_shell.pl 31 2008-02-14 23:53:47Z robin $
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

# Add the modules to the libpath
use FindBin;
use lib "$FindBin::Bin/../src/Net-UDAP/lib";

use Net::UDAP::Util;
use IO::Interface::Simple;

$| = 1;

my $socket = create_socket;

my @interfaces = IO::Interface::Simple->interfaces;
for my $if (@interfaces) {
    print "interface = $if\n";
    print "addr =      ",$if->address,"\n",
          "broadcast = ",$if->broadcast,"\n",
          "netmask =   ",$if->netmask,"\n",
          "dstaddr =   ",$if->dstaddr,"\n",
          "hwaddr =    ",$if->hwaddr,"\n",
          "mtu =       ",$if->mtu,"\n",
          "metric =    ",$if->metric,"\n",
          "index =     ",$if->index,"\n";

    print "is running\n"     if $if->is_running;
    print "is broadcast\n"   if $if->is_broadcast;
    print "is p-to-p\n"      if $if->is_pt2pt;
    print "is loopback\n"    if $if->is_loopback;
    print "is promiscuous\n" if $if->is_promiscuous;
    print "is multicast\n"   if $if->is_multicast;
    print "is notrailers\n"  if $if->is_notrailers;
    print "is noarp\n"       if $if->is_noarp;
}

# vim:set softtabstop=4:
# vim:set shiftwidth=4:
