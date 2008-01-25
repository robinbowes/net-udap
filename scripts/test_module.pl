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

# Add the modules to the libpath
use FindBin;
use lib "$FindBin::Bin/../src/Net-UDAP/lib";

use Net::UDAP::Constant;
use Net::UDAP;

$| = 1;

# Set some values here to use later
#my $wireless_region = WLAN_REGION_ONE;
#my $wireless_mode = WLAN_MODE_INFRASTRUCTURE;
#my $wireless_ssid = '3com';
#my $wireless_encryption = 'wep';
#my $wireless_password = 'abcde';

# Create the socket
my $udap = Net::UDAP->new;

# Send the discovery packet

$udap->send_discovery({advanced => 1});

# Read the responses
# readUDP returns true if it processed a packet
# We need to repeatedly read packets until none are left
while ( $udap->read_UDP ) { }

# Get the hash of discovered devices
my $discovered_devices_ref = $udap->get_devices;

print "Discovered devices:\n" . Dumper \$discovered_devices_ref;

# set DHCP networking for each of the discovered devices
foreach my $device ( values %{$discovered_devices_ref} ) {
    #Net::UDAP::set_ip( {socket => $sock, device => $device} );
    print 'Device mac: ' . $device->get_mac . "\n";
    $udap->send_get_ip( { mac => $device->get_mac } );
}

# Set the IP and wireless information for the first device
# If no IP information is specified, DHCP will be used.
# A static IP address would be specified like this:
#
# $discovered_devices->{ $devices[0] }->set_data(
#   ip => '192.168.1.161',
#   netmask => '255.255.255.0',
#   gateway => '192.168.1.1'
#   );

#$discovered_devices->{ $devices[0] }->set(
#    wireless_region     => $wireless_region,
#    wireless_mode       => $wireless_mode,
#    wireless_ssid       => $wireless_ssid,
#    wireless_encryption => $wireless_encryption,
#    wireless_password   => $wireless_password
#);

# Write the config to the first player
#Plugins::PlayerDiscovery::UDAP::write_config(
#    $discovered_devices->{ $devices[0] } );

# vim:set softtabstop=4:
# vim:set shiftwidth=4:
