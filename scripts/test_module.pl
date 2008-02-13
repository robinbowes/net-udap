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

use Net::UDAP;
use Net::UDAP::Constant;

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

$udap->discover( { advanced => 1 } );

# Get the hash of discovered devices
my $discovered_devices_ref = $udap->get_devices;

if ($discovered_devices_ref) {

    foreach my $device ( values %{$discovered_devices_ref} ) {
        $udap->set_ip(
            {   mac         => $device->get_mac,
#                data_to_set => {
#                    ip      => '172.29.28.27',
#                    netmask => '255.255.0.0',
#                    gateway => '172.28.28.1',
#                }
            }
        ) if 0;
        
        $udap->get_ip( { mac => $device->get_mac } ) if 0;

        $udap->get_data(
            {   mac         => $device->get_mac,
                data_to_get => [
                    qw(
                        lan_ip_mode
                        lan_network_address
                        lan_subnet_mask
                        lan_gateway
                        hostname
                        bridging
                        interface
                        primary_dns
                        secondary_dns
                        server_address
                        slimserver_address
                        slimserver_name
                        wireless_wireless_mode
                        wireless_SSID
                        wireless_channel
                        wireless_region_id
                        wireless_keylen
                        wireless_wep_key_0
                        wireless_wep_key_1
                        wireless_wep_key_2
                        wireless_wep_key_3
                        wireless_wep_on
                        wireless_wpa_cipher
                        wireless_wpa_mode
                        wireless_wpa_enabled
                        wireless_wpa_psk
                        )
                ],
            }
        ) if 0;
        $udap->set_data(
            {   mac         => $device->get_mac,
                data_to_set => {
                    wireless_wireless_mode => WLAN_MODE_INFRASTRUCTURE,
                    wireless_wep_on        => WLAN_WEP_ON,
                    wireless_wep_key_0     => 'abcde',
                },
            }
        ) if 0;
    }
    print Dumper \$discovered_devices_ref;
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
