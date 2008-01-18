package Net::UDAP::Constant;

# $Id$

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.1');

# Other recommended modules (uncomment to use):
#  use IO::Prompt;
#  use Perl6::Export;
#  use Perl6::Slurp;
#  use Perl6::Say;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);
use Exporter qw(import);

%EXPORT_TAGS = (
    ADDR_TYPES =>
        [qw( ADDR_TYPE_RAW ADDR_TYPE_ETH ADDR_TYPE_UDP ADDR_TYPE_THREE )],
    BROADCAST  => [qw( BROADCAST_OFF BROADCAST_ON )],
    DHCP       => [qw( DHCP_OFF DHCP_ON )],
    NETWORK    => [qw( DST_TYPE_ETH IP_ZERO MAC_ZERO PORT_UDAP PORT_ZERO )],
    SBR_PARAMS => [
        qw( SBR_PARAM_LENGTH_NAME SBR_PARAM_NAME_OFFSET SBR_PARAM_OFFSET_NAME )
    ],
    UCP_CODES => [
        qw( UCP_CODE_ZERO UCP_CODE_ONE UCP_CODE_DEVICE_NAME UCP_CODE_DEVICE_TYPE UCP_CODE_USE_DHCP UCP_CODE_IP_ADDR UCP_CODE_SUBNET_MASK UCP_CODE_GATEWAY_ADDR UCP_CODE_EIGHT UCP_CODE_FIRMWARE_REV UCP_CODE_HARDWARE_REV UCP_CODE_DEVICE_ID UCP_CODE_DEVICE_STATUS UCP_CODE_THIRTEEN )
    ],
    UCP_METHODS => [
        qw( UCP_METHOD_ZERO UCP_METHOD_DISCOVER UCP_METHOD_GET_IP UCP_METHOD_SET_IP UCP_METHOD_RESET UCP_METHOD_GET_DATA UCP_METHOD_SET_DATA UCP_METHOD_ERROR UCP_METHOD_CREDENTIALS_ERROR UCP_METHOD_ADV_DISCOVER UCP_METHOD_TEN )
    ],
    WLAN_MODES       => [ qw( WLAN_MODE_INFRASTRUCTURE WLAN_MODE_ADHOC ) ],
    WLAN_REGIONS_ATH => [
        qw( WLAN_REGION_ATH_US WLAN_REGION_ATH_CA WLAN_REGION_ATH_EU WLAN_REGION_ATH_FR WLAN_REGION_ATH_CH WLAN_REGION_ATH_TW WLAN_REGION_ATH_AU WLAN_REGION_ATH_JP )
    ],
    WLAN_WEP => [
        qw( WLAN_WEP_KEYLENGTH_40 WLAN_WEP_KEYLENGTH_104 WLAN_WEP_OFF WLAN_WEP_ON )
    ],
    WLAN_WPA => [
        qw( WLAN_WPA_CIPHER_CCMP WLAN_WPA_CIPHER_TKIP WLAN_WPA_OFF WLAN_WPA_ON WLAN_WPA_MODE_WPA WLAN_WPA_MODE_WPA2 )
    ],
    MISC => [qw(  UDP_MAX_MSG_LEN UDAP_TYPE_UCP UAP_CLASS_UCP )],
);

# add all the other ":class" tags to the ":all" class,
# deleting duplicates
{
    my %seen;
    push @{ $EXPORT_TAGS{all} }, grep { !$seen{$_}++ } @{ $EXPORT_TAGS{$_} }
        foreach keys %EXPORT_TAGS;
}

Exporter::export_tags('all');

my %name_from_offset;
my %length_from_name;
my %offset_from_name;

# Address Types
use constant ADDR_TYPE_RAW   => pack( 'CC', 0x00, 0x00 );
use constant ADDR_TYPE_ETH   => pack( 'CC', 0x00, 0x01 );
use constant ADDR_TYPE_UDP   => pack( 'CC', 0x00, 0x02 );
use constant ADDR_TYPE_THREE => pack( 'CC', 0x00, 0x03 );

# Broadcast
use constant BROADCAST_OFF => 0;
use constant BROADCAST_ON  => 1;

# DHCP
use constant DHCP_OFF => 0;
use constant DHCP_ON  => 1;

# Network stuff
use constant DST_TYPE_ETH => 0x01;
use constant IP_ZERO      => pack( 'C4', (0x00) x 4 );
use constant MAC_ZERO     => pack( 'C6', (0x00) x 6 );
use constant PORT_UDAP    => 0x4578;                     # port no. 17784
use constant PORT_ZERO    => pack( 'C2', (0x00) x 2 );

# Hashes to decode the offset and length of the parameters in the msg
use constant SBR_PARAM_LENGTH_NAME => \%length_from_name;
use constant SBR_PARAM_NAME_OFFSET => \%name_from_offset;
use constant SBR_PARAM_OFFSET_NAME => \%offset_from_name;

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
use constant UCP_CODE_THIRTEEN      => pack( 'C', 0x0d );

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

# Wireless modes
use constant WLAN_MODE_INFRASTRUCTURE => pack( 'C', 0x00 );
use constant WLAN_MODE_ADHOC          => pack( 'C', 0x01 );

# Wireless Regions (atheros codes)
use constant WLAN_REGION_ATH_US => pack( 'C', 4 );
use constant WLAN_REGION_ATH_CA => pack( 'C', 6 );
use constant WLAN_REGION_ATH_EU => pack( 'C', 14 );
use constant WLAN_REGION_ATH_FR => pack( 'C', 13 );
use constant WLAN_REGION_ATH_CH => pack( 'C', 23 );
use constant WLAN_REGION_ATH_TW => pack( 'C', 21 );
use constant WLAN_REGION_ATH_AU => pack( 'C', 7 );
use constant WLAN_REGION_ATH_JP => pack( 'C', 16 );

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
use constant UDAP_TYPE_UCP => pack( 'C2', 0xC0, 0x01 );
use constant UAP_CLASS_UCP => pack( 'C4', 0x00, 0x01, 0x00, 0x01 );
use constant UDP_MAX_MSG_LEN => 1500;

{
    our @parameter_data = (

        # name, offset, length
        'lan_ip_mode',            4,   1,
        'lan_network_address',    5,   4,
        'lan_subnet_mask',        9,   4,
        'lan_gateway',            13,  4,
        'hostname',               17,  33,
        'bridging',               50,  1,
        'interface',              52,  1,
        'primary_dns',            59,  4,
        'secondary_dns',          67,  4,
        'server_address',         71,  4,
        'slimserver_address',     79,  4,
        'slimserver_name',        83,  33,
        'wireless.wireless_mode', 173, 1,
        'wireless.SSID',          183, 33,
        'wireless.channel',       216, 1,
        'wireless.region_id',     218, 1,
        'wireless.keylen',        220, 1,
        'wireless.wep_key[0]',    222, 13,
        'wireless.wep_key[1]',    235, 13,
        'wireless.wep_key[2]',    248, 13,
        'wireless.wep_key[3]',    261, 13,
        'wireless.wepon',         274, 1,
        'wireless.wpa_cipher',    275, 1,
        'wireless.wpa_mode',      276, 1,
        'wireless.wpa_enabled',   277, 1,
        'wireless.wpa_psk',       278, 64,
    );
    while (@parameter_data) {
        my $param_name   = shift @parameter_data;
        my $param_offset = shift @parameter_data;
        my $param_length = shift @parameter_data;
        $name_from_offset{$param_offset} = $param_name;
        $length_from_name{$param_name}   = $param_length;
        $offset_from_name{$param_name}   = $param_offset;
    }
}

1; # Magic true value required at end of module
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
