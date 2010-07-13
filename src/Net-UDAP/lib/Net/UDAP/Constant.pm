package Net::UDAP::Constant;

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

use version; our $VERSION = qv('1.0_01');

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Carp;
use Exporter qw(import);

%EXPORT_TAGS = (
	ADDR_TYPES => [
		qw( ADDR_TYPE_RAW ADDR_TYPE_ETH ADDR_TYPE_UDP ADDR_TYPE_THREE ADDR_TYPE_XXX )
	],
	BROADCAST => [qw( BROADCAST_OFF BROADCAST_ON )],
	DHCP      => [qw( DHCP_OFF DHCP_ON )],
	NETWORK   => [qw( DST_TYPE_ETH IP_ZERO MAC_ZERO PORT_UDAP PORT_ZERO )],
	HASHES    => [
		qw( $field_help_from_name $field_default_from_name $field_size_from_name
			$field_name_from_offset $field_offset_from_name $field_pack_from_name
			$field_unpack_from_offset
			$ucp_method_name
			$ucp_code_name $ucp_code_help $ucp_code_default $ucp_code_pack $ucp_code_unpack )
	],
	UCP_CODES => [
		qw( UCP_CODE_ZERO UCP_CODE_ONE UCP_CODE_DEVICE_NAME UCP_CODE_DEVICE_TYPE UCP_CODE_USE_DHCP UCP_CODE_IP_ADDR UCP_CODE_SUBNET_MASK UCP_CODE_GATEWAY_ADDR UCP_CODE_EIGHT UCP_CODE_FIRMWARE_REV UCP_CODE_HARDWARE_REV UCP_CODE_DEVICE_ID UCP_CODE_DEVICE_STATUS UCP_CODE_UUID )
	],
	UCP_METHODS => [
		qw( UCP_METHOD_ZERO UCP_METHOD_DISCOVER UCP_METHOD_GET_IP UCP_METHOD_SET_IP UCP_METHOD_RESET UCP_METHOD_GET_DATA UCP_METHOD_SET_DATA UCP_METHOD_ERROR UCP_METHOD_CREDENTIALS_ERROR UCP_METHOD_ADV_DISCOVER UCP_METHOD_TEN )
	],
	WLAN_MODES       => [qw( WLAN_MODE_INFRASTRUCTURE WLAN_MODE_ADHOC )],
	WLAN_REGIONS_ATH => [
		qw( WLAN_REGION_ATH_US WLAN_REGION_ATH_CA WLAN_REGION_ATH_EU WLAN_REGION_ATH_FR WLAN_REGION_ATH_CH WLAN_REGION_ATH_TW WLAN_REGION_ATH_AU WLAN_REGION_ATH_JP )
	],
	WLAN_WEP => [
		qw( WLAN_WEP_KEYLENGTH_40 WLAN_WEP_KEYLENGTH_104 WLAN_WEP_OFF WLAN_WEP_ON )
	],
	WLAN_WPA => [
		qw( WLAN_WPA_CIPHER_CCMP WLAN_WPA_CIPHER_TKIP WLAN_WPA_OFF WLAN_WPA_ON WLAN_WPA_MODE_WPA WLAN_WPA_MODE_WPA2 )
	],
	MISC => [qw(  UDP_MAX_MSG_LEN UDAP_TIMEOUT UDAP_TYPE_UCP UAP_CLASS_UCP )],
);

# add all the other ":class" tags to the ":all" class,
# deleting duplicates
{
	my %seen;
	push @{ $EXPORT_TAGS{all} }, grep { !$seen{$_}++ } @{ $EXPORT_TAGS{$_} }
		foreach keys %EXPORT_TAGS;
}

Exporter::export_tags('all');

# hashes holding lookup tables
# (hashrefs are exported as constants)
our $ucp_method_name  = {};
our $ucp_code_name    = {};
our $ucp_code_help    = {};
our $ucp_code_default = {};
our $ucp_code_pack    = {};
our $ucp_code_unpack  = {};

# Address Types
use constant ADDR_TYPE_RAW   => pack( 'C', 0x00 );
use constant ADDR_TYPE_ETH   => pack( 'C', 0x01 );
use constant ADDR_TYPE_UDP   => pack( 'C', 0x02 );
use constant ADDR_TYPE_THREE => pack( 'C', 0x03 );

# Broadcast
use constant BROADCAST_OFF => pack( 'C', 0x00 );
use constant BROADCAST_ON  => pack( 'C', 0x01 );

# DHCP
use constant DHCP_OFF => 0;
use constant DHCP_ON  => 1;

# Network stuff
use constant DST_TYPE_ETH => pack( 'C', 0x01 );
use constant IP_ZERO  => pack( 'C4', (0x00) x 4 );
use constant MAC_ZERO => pack( 'C6', (0x00) x 6 );
use constant PORT_UDAP => 0x4578;                     # port no. 17784
use constant PORT_ZERO => pack( 'C2', (0x00) x 2 );

# UCP Codes
use constant UCP_CODE_ZERO          => pack( 'C', 0x00 );
use constant UCP_CODE_ONE           => pack( 'C', 0x01 );
use constant UCP_CODE_DEVICE_NAME   => pack( 'C', 0x02 );
use constant UCP_CODE_DEVICE_TYPE   => pack( 'C', 0x03 );
use constant UCP_CODE_USE_DHCP      => pack( 'C', 0x04 );
use constant UCP_CODE_IP_ADDR       => pack( 'C', 0x05 );
use constant UCP_CODE_SUBNET_MASK   => pack( 'C', 0x06 );
use constant UCP_CODE_GATEWAY_ADDR  => pack( 'C', 0x07 );
use constant UCP_CODE_EIGHT         => pack( 'C', 0x08 );
use constant UCP_CODE_FIRMWARE_REV  => pack( 'C', 0x09 );
use constant UCP_CODE_HARDWARE_REV  => pack( 'C', 0x0a );
use constant UCP_CODE_DEVICE_ID     => pack( 'C', 0x0b );
use constant UCP_CODE_DEVICE_STATUS => pack( 'C', 0x0c );
use constant UCP_CODE_UUID          => pack( 'C', 0x0d );

# UCP methods
use constant UCP_METHOD_ZERO              => pack( 'CC', 0x00, 0x00 );
use constant UCP_METHOD_DISCOVER          => pack( 'CC', 0x00, 0x01 );
use constant UCP_METHOD_GET_IP            => pack( 'CC', 0x00, 0x02 );
use constant UCP_METHOD_SET_IP            => pack( 'CC', 0x00, 0x03 );
use constant UCP_METHOD_RESET             => pack( 'CC', 0x00, 0x04 );
use constant UCP_METHOD_GET_DATA          => pack( 'CC', 0x00, 0x05 );
use constant UCP_METHOD_SET_DATA          => pack( 'CC', 0x00, 0x06 );
use constant UCP_METHOD_ERROR             => pack( 'CC', 0x00, 0x07 );
use constant UCP_METHOD_CREDENTIALS_ERROR => pack( 'CC', 0x00, 0x08 );
use constant UCP_METHOD_ADV_DISCOVER      => pack( 'CC', 0x00, 0x09 );
use constant UCP_METHOD_TEN               => pack( 'CC', 0x00, 0x0A );
use constant UCP_METHOD_GET_UUID          => pack( 'CC', 0x00, 0x0B );

# Lookup hash mapping ucp_method constants to name strings
$ucp_method_name = {
	UCP_METHOD_ZERO,              undef,
	UCP_METHOD_DISCOVER,          'discovery',
	UCP_METHOD_GET_IP,            'get_ip',
	UCP_METHOD_SET_IP,            'set_ip',
	UCP_METHOD_RESET,             'reset',
	UCP_METHOD_GET_DATA,          'get_data',
	UCP_METHOD_SET_DATA,          'set_data',
	UCP_METHOD_ERROR,             'error',
	UCP_METHOD_CREDENTIALS_ERROR, 'credentials_error',
	UCP_METHOD_ADV_DISCOVER,      'adv_discovery',
	UCP_METHOD_TEN,               undef,
	UCP_METHOD_GET_UUID,          'get_uuid',
};

# Wireless modes
use constant WLAN_MODE_INFRASTRUCTURE => pack( 'C', 0x00 );
use constant WLAN_MODE_ADHOC          => pack( 'C', 0x01 );

# Wireless Regions (atheros codes)
use constant WLAN_REGION_ATH_US => pack( 'C', 4 );
use constant WLAN_REGION_ATH_CA => pack( 'C', 6 );
use constant WLAN_REGION_ATH_AU => pack( 'C', 7 );
use constant WLAN_REGION_ATH_FR => pack( 'C', 13 );
use constant WLAN_REGION_ATH_EU => pack( 'C', 14 );
use constant WLAN_REGION_ATH_JP => pack( 'C', 16 );
use constant WLAN_REGION_ATH_TW => pack( 'C', 21 );
use constant WLAN_REGION_ATH_CH => pack( 'C', 23 );

# Wireless WEP
use constant WLAN_WEP_KEYLENGTH_40  => pack( 'C', 0x00 );
use constant WLAN_WEP_KEYLENGTH_104 => pack( 'C', 0x01 );
use constant WLAN_WEP_OFF           => pack( 'C', 0x00 );
use constant WLAN_WEP_ON            => pack( 'C', 0x01 );

# Wireless WPA
use constant WLAN_WPA_CIPHER_CCMP => pack( 'C', 0x01 );
use constant WLAN_WPA_CIPHER_TKIP => pack( 'C', 0x02 );
use constant WLAN_WPA_OFF         => pack( 'C', 0x00 );
use constant WLAN_WPA_ON          => pack( 'C', 0x01 );
use constant WLAN_WPA_MODE_WPA    => pack( 'C', 0x01 );
use constant WLAN_WPA_MODE_WPA2   => pack( 'C', 0x02 );

# Misc constants
use constant UAP_CLASS_UCP => pack( 'C4', 0x00, 0x01, 0x00, 0x01 );
use constant UDAP_TIMEOUT => 1;
use constant UDAP_TYPE_UCP => pack( 'C2', 0xC0, 0x01 );
use constant UDP_MAX_MSG_LEN => 1500;

my @device_data = (

	# name,
	#   default,
	#   help,
	#   offset, length,
	#   sub to pack, sub to unpack,
	'lan_ip_mode',
	undef,
	'0 - Use static IP details, 1 - use DHCP to discover IP details',
	4, 1,
	sub { pack( 'C', shift ) }, sub { unpack( 'C', shift ) },
	'lan_network_address',
	undef,
	'IP address of device, (e.g. 192.168.1.10)',
	5,                   4,
	\&Socket::inet_aton, \&Socket::inet_ntoa,
	'lan_subnet_mask',
	undef,
	'Subnet mask of local network, (e.g. 255.255.255.0)',
	9,                   4,
	\&Socket::inet_aton, \&Socket::inet_ntoa,
	'lan_gateway',
	undef,
	'IP address of default network gateway, (e.g. 192.168.1.1)',
	13,                  4,
	\&Socket::inet_aton, \&Socket::inet_ntoa,
	'hostname',
	undef,
	'Device hostname (is this set automatically?)',
	17, 33,
	sub { pack( 'Z*', shift ) }, sub { unpack( 'Z*', shift ) },
	'bridging',
	undef,
	'Use device as a wireless bridge (not sure about this)',
	50, 1,
	sub { pack( 'C', shift ) }, sub { unpack( 'C', shift ) },
	'interface',
	undef,
	'0 - wireless, 1 - wired (is set to 128 after factory reset)',
	52, 1,
	sub { pack( 'C', shift ) }, sub { unpack( 'C', shift ) },
	'primary_dns',
	undef,
	'IP address of primary DNS server',
	59,                  4,
	\&Socket::inet_aton, \&Socket::inet_ntoa,
	'secondary_dns',
	undef,
	'IP address of secondary DNS server',
	67,                  4,
	\&Socket::inet_aton, \&Socket::inet_ntoa,
	'server_address',
	undef,
	'IP address of currently active server (either Squeezenetwork or local server',
	71,                  4,
	\&Socket::inet_aton, \&Socket::inet_ntoa,
	'squeezecenter_address',
	undef,
	'IP address of local Squeezecenter server',
	79,                  4,
	\&Socket::inet_aton, \&Socket::inet_ntoa,
	'squeezecenter_name',
	undef,
	'Name of local Squeezecenter server (???)',
	83, 33,
	sub { pack( 'Z*', shift ) }, sub { unpack( 'Z*', shift ) },
	'wireless_mode',
	undef,
	'0 - Infrastructure, 1 - Ad Hoc',
	173, 1,
	sub { pack( 'C', shift ) }, sub { unpack( 'C', shift ) },
	'wireless_SSID',
	undef,
	'Wireless network name',
	183, 33,
	sub { pack( 'Z*', shift ) }, sub { unpack( 'Z*', shift ) },
	'wireless_channel',
	undef,
	'Wireless channel (used by AdHoc mode???)',
	216, 1,
	sub { pack( 'C', shift ) }, sub { unpack( 'C', shift ) },
	'wireless_region_id',
	undef,
	'4 - US, 6 - CA, 7 - AU, 13 - FR, 14 - EU, 16 - JP, 21 - TW, 23 - CH',
	218, 1,
	sub { pack( 'C', shift ) }, sub { unpack( 'C', shift ) },
	'wireless_keylen',
	undef,
	'Length of wireless key, (0 - 64-bit, 1 - 128-bit)',
	220, 1,
	sub { pack( 'C', shift ) }, sub { unpack( 'C', shift ) },
	'wireless_wep_key_0',
	undef,
	'WEP Key 0 - enter in hex',
	222, 13,
	sub { pack('H*', shift) }, sub { unpack('H*', shift) },
	'wireless_wep_key_1',
	undef,
	'WEP Key 1 - enter in hex',
	235, 13,
	sub { pack( 'H*', shift ) }, sub { unpack( 'H*', shift ) },
	'wireless_wep_key_2',
	undef,
	'WEP Key 2 - enter in hex',
	248, 13,
	sub { pack( 'H*', shift ) }, sub { unpack( 'H*', shift ) },
	'wireless_wep_key_3',
	undef,
	'WEP Key 3 - enter in hex',
	261, 13,
	sub { pack( 'H*', shift ) }, sub { unpack( 'H*', shift ) },
	'wireless_wep_on',
	undef,
	'0 - WEP Off, 1 - WEP On',
	274, 1,
	sub { pack( 'C', shift ) }, sub { unpack( 'C', shift ) },
	'wireless_wpa_cipher',
	undef,
	'1 - TKIP, 2 - AES, 3 - TKIP & AES',
	275, 1,
	sub { pack( 'C', shift ) }, sub { unpack( 'C', shift ) },
	'wireless_wpa_mode',
	undef,
	'1 - WPA, 2 - WPA2',
	276, 1,
	sub { pack( 'C', shift ) }, sub { unpack( 'C', shift ) },
	'wireless_wpa_on',
	undef,
	'0 - WPA Off, 1 - WPA On',
	277, 1,
	sub { pack( 'C', shift ) }, sub { unpack( 'C', shift ) },
	'wireless_wpa_psk',
	undef,
	'WPA Public Shared Key',
	278, 64,
	sub { pack( 'a64', shift ) }, sub { unpack( 'a*', shift ) },
);

our $field_help_from_name     = {};
our $field_default_from_name  = {};
our $field_size_from_name     = {};
our $field_name_from_offset   = {};
our $field_offset_from_name   = {};
our $field_pack_from_name     = {};
our $field_unpack_from_offset = {};

while (@device_data) {
	my $field_name    = shift @device_data;
	my $field_default = shift @device_data;
	my $field_help    = shift @device_data;
	my $field_offset  = shift @device_data;
	my $field_size    = shift @device_data;
	my $field_pack    = shift @device_data;
	my $field_unpack  = shift @device_data;
	$field_default_from_name->{$field_name}    = $field_default;
	$field_help_from_name->{$field_name}       = $field_help;
	$field_name_from_offset->{$field_offset}   = $field_name;
	$field_size_from_name->{$field_name}       = $field_size;
	$field_offset_from_name->{$field_name}     = $field_offset;
	$field_pack_from_name->{$field_name}       = $field_pack;
	$field_unpack_from_offset->{$field_offset} = $field_unpack;
}
my @ucp_code_data = (

	# name,
	#   constant,
	#   sub to pack
	#   sub to unpack
	#    UCP_CODE_ZERO,             undef,
	#    UCP_CODE_ONE,              undef,
	'hostname',
	undef,
	UCP_CODE_DEVICE_NAME,
	'Device name',
	sub { pack( 'a*', shift ) }, sub { unpack( 'a*', shift ) },
	'device_type',
	undef,
	UCP_CODE_DEVICE_TYPE,
	'Device type, (e.g. squeezebox)',
	sub { pack( 'a*', shift ) }, sub { unpack( 'a*', shift ) },
	'lan_ip_mode',
	undef,
	UCP_CODE_USE_DHCP,
	'0 - Use static IP details, 1 - use DHCP to discover IP details',
	sub { pack( 'C', shift ) }, sub { unpack( 'n', shift ) },
	'lan_network_address',
	undef,
	UCP_CODE_IP_ADDR,
	'IP address of device, (e.g. 192.168.1.10)',
	\&Socket::inet_aton, \&Socket::inet_ntoa,
	'lan_subnet_mask',
	undef,
	UCP_CODE_SUBNET_MASK,
	'Subnet mask of local network, (e.g. 255.255.255.0)',
	\&Socket::inet_aton, \&Socket::inet_ntoa,
	'lan_gateway',
	undef,
	UCP_CODE_GATEWAY_ADDR,
	'IP address of default network gateway, (e.g. 192.168.1.1)',
	\&Socket::inet_aton, \&Socket::inet_ntoa,

	#    UCP_CODE_EIGHT,            undef,
	'firmware_rev',
	undef,
	UCP_CODE_FIRMWARE_REV,
	'Device firmware revision',
	sub { pack( 'a*', shift ) }, sub { unpack( 'a*', shift ) },
	'hardware_rev',
	undef,
	UCP_CODE_HARDWARE_REV,
	'Device hardware revision',
	sub { pack( 'a*', shift ) }, sub { unpack( 'a*', shift ) },
	'device_id',
	undef,
	UCP_CODE_DEVICE_ID,
	'Device ID (??? Do not know what this is)',
	sub { pack( 'a*', shift ) }, sub { unpack( 'a*', shift ) },
	'device_status',
	undef,
	UCP_CODE_DEVICE_STATUS,
	'Device status, one of: init, wait_wireless, wait_dhcp, wait_slimserver, connected',
	sub { pack( 'a*', shift ) }, sub { unpack( 'a*', shift ) },
	'uuid',
	undef,
	UCP_CODE_UUID,
	'Device UUID (?????)',
	sub { pack( 'a*', shift ) }, sub { unpack( 'a*', shift ) },
);

while (@ucp_code_data) {
	my $code_name    = shift @ucp_code_data;
	my $code_default = shift @ucp_code_data;
	my $code         = shift @ucp_code_data;
	my $code_help    = shift @ucp_code_data;
	my $code_pack    = shift @ucp_code_data;
	my $code_unpack  = shift @ucp_code_data;
	$ucp_code_name->{$code}         = $code_name;
	$ucp_code_default->{$code_name} = $code_default;
	$ucp_code_help->{$code_name}    = $code_help;
	$ucp_code_pack->{$code}         = $code_pack;
	$ucp_code_unpack->{$code}       = $code_unpack;
}
1;    # Magic true value required at end of module
__END__

=head1 NAME

Net::UDAP::Constant - [One line description of module's purpose here]


=head1 VERSION

This document describes Net::UDAP::Constant version 0.0.1


=head1 SYNOPSIS

    use Net::UDAP::Constant;

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.
  
  
=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
Net::UDAP::Constant requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-net-udap-constant@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Robin Bowes  C<< <robin@robinbowes.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Robin Bowes C<< <robin@robinbowes.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

# vim:set softtabstop=4:
# vim:set shiftwidth=4:
