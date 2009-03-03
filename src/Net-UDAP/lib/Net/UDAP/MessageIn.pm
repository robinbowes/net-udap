package Net::UDAP::MessageIn;

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

use vars qw( $AUTOLOAD );                    # Keep 'use strict' happy
use base qw(Class::Accessor);

use Carp;
use Data::Dumper;
use Net::UDAP::Constant;
use Net::UDAP::Util;
use Net::UDAP::Log;

my %field_default = (
    raw_msg         => undef,
    dst_broadcast   => undef,
    dst_addr_type   => undef,
    dst_mac         => undef,
    dst_ip          => undef,
    dst_port        => undef,
    src_broadcast   => undef,
    src_addr_type   => undef,
    src_mac         => undef,
    src_ip          => undef,
    src_port        => undef,
    seq             => undef,
    udap_type       => undef,
    ucp_flags       => undef,
    uap_class       => undef,
    ucp_method      => undef,
    device_data_ref => undef,    # hash containing decoded client data
                                 # param_name => param_value
);

__PACKAGE__->mk_accessors( keys %field_default );

{

    sub new {
        my ( $caller, $arg_ref ) = @_;
        my $class = ref $caller || $caller;

        # Define arg hash ref if no args passed
        $arg_ref = {} unless ref($arg_ref) eq 'HASH';

        # Define device_data hash ref if not defined
        $arg_ref->{device_data_ref} = {}
            unless ref( $arg_ref->{device_data_ref} ) eq 'HASH';

        # Values from $arg_ref over-write the default values
        my %arg = ( %field_default, %{$arg_ref} );

        my $self = bless {%arg}, $class;

        if ( defined $self->raw_msg ) {
            eval { $self->udap_decode; } or do {
                carp($@);
                return;
                }
        }
        return $self;
    }

    sub update_device_data {
        my ( $self, $arg_ref ) = @_;

        # Define hash ref if no args passed
        $arg_ref = {} unless ref($arg_ref) eq 'HASH';

        my $device_data_ref = $self->device_data_ref;

        # Update the device_data hash with the new values
        # No need to write the device_data hash back since
        # we're working with a reference to it

        @$device_data_ref{ keys %{$arg_ref} } = values %{$arg_ref};

        return;
    }

    sub prepare_credential {

        # return 32 packed hex zeros
        return pack( 'C' x 32, (0x00) x 32 );
    }

    sub udap_decode {
        my $self = shift;

        my $raw_msg = $self->raw_msg;

        ( !defined $raw_msg ) && do {
            croak('raw msg not set');
        };

        # print "\$raw_msg in MessageIn::udap_decode\n" . hex2str($raw_msg);

        # Initialise offset from start of raw string
        # This is incremented as we read characters from the string
        my $os = 0;

        # get dst_broadcast
        $self->dst_broadcast( substr( $raw_msg, $os, 1 ) );
        $os += 1;

        # get dst addr type
        $self->dst_addr_type( substr( $raw_msg, $os, 1 ) );
        $os += 1;

     # get *either* dst mac *or* dst IP + port, depending on the dst_addr_type
    SWITCH: {
            ( $self->dst_addr_type eq ADDR_TYPE_ETH ) && do {
                $self->dst_mac( substr( $raw_msg, $os, 6 ) );
                last SWITCH;
            };
            ( $self->dst_addr_type eq ADDR_TYPE_UDP ) && do {
                $self->dst_ip( substr( $raw_msg, $os, 4 ) );
                $self->dst_port( substr( $raw_msg, $os + 4, 2 ) );
                last SWITCH;
            };

            # default action if dst address type not recognised
            croak( 'Unknown dst_addr_type value found: '
                    . format_hex( $self->dst_addr_type ) );
        }
        $os += 6;

        # get src_broadcast
        $self->src_broadcast( substr( $raw_msg, $os, 1 ) );
        $os += 1;

        # get src addr type
        $self->src_addr_type( substr( $raw_msg, $os, 1 ) );
        $os += 1;

     # get *either* src mac *or* src IP + port, depending on the src_addr_type
    SWITCH: {
            ( $self->src_addr_type eq ADDR_TYPE_ETH ) && do {
                $self->src_mac( substr( $raw_msg, $os, 6 ) );
                last SWITCH;
            };
            ( $self->src_addr_type eq ADDR_TYPE_UDP ) && do {
                $self->src_ip( substr( $raw_msg, $os, 4 ) );
                $self->src_port( substr( $raw_msg, $os + 4, 2 ) );
                last SWITCH;
            };

            # default action if src address type not recognised
            croak( 'Unknown src_addr_type value found: '
                    . format_hex( $self->src_addr_type ) );
        }
        $os += 6;

        # seq
        $self->seq( substr( $raw_msg, $os, 2 ) );
        $os += 2;

        # udap type
        $self->udap_type( substr( $raw_msg, $os, 2 ) );
        $os += 2;

        # flag
        $self->ucp_flags( substr( $raw_msg, $os, 1 ) );
        $os += 1;

        # uap class
        $self->uap_class( substr( $raw_msg, $os, 4 ) );
        $os += 4;

        # ucp method
        $self->ucp_method( substr( $raw_msg, $os, 2 ) );
        $os += 2;

        # Now, do different things depending on what packet type this is
    SWITCH: {

            (          ( $self->ucp_method eq UCP_METHOD_DISCOVER )
                    or ( $self->ucp_method eq UCP_METHOD_ADV_DISCOVER )
                    or ( $self->ucp_method eq UCP_METHOD_GET_IP )
                )
                && do {

                # The rest of the packet is in the format:
                #   ucp_code, length, data

                my $param_data_ref = {};

                while ( $os < length($raw_msg) ) {

                    # get ucp code
                    my $ucp_code = substr( $raw_msg, $os, 1 );
                    $os += 1;

                    # length of following string
                    my $data_length
                        = unpack( 'c', substr( $raw_msg, $os, 1 ) );
                    $os += 1;

                    # If the data is not present, $data_length will be 0
                    my $data
                        = ($data_length)
                        ? substr( $raw_msg, $os, $data_length )
                        : '';
                    $os += $data_length;
                    
                    log( debug => '*** ucp_code_name: ' . $ucp_code_name->{$ucp_code} . ', data string: ' . format_hex($data) . "\n" ) if $data;

                    # add to the data hash
                    if ( exists $ucp_code_name->{$ucp_code} ) {
                        $param_data_ref->{ $ucp_code_name->{$ucp_code} }
                            = $ucp_code_unpack->{$ucp_code}->($data);
                    }
                    else {
                        log( warn => "  Invalid ucp_code: [$ucp_code]\n" );
                        return;
                    }
                }

                $self->update_device_data($param_data_ref);

                last SWITCH;
                };

            ( $self->ucp_method eq UCP_METHOD_GET_DATA ) && do {

                # get number of data items
                my $num_items = unpack( 'n', substr( $raw_msg, $os, 2 ) );

                last SWITCH if !$num_items;

                $os += 2;

                log( debug => "    num_items: $num_items\n" );

                my $param_data_ref = {};

                while ( $os < length($raw_msg) ) {

                    #get offset
                    my $param_offset
                        = unpack( 'n', substr( $raw_msg, $os, 2 ) );
                    $os += 2;

                    log( debug => "    param offset: $param_offset\n" );

                    #get length
                    my $data_length
                        = unpack( 'n', substr( $raw_msg, $os, 2 ) );
                    $os += 2;

                    log( debug => "     data length: $data_length\n" );

                    #get string
                    my $data_string = unpack( "a*",
                        substr( $raw_msg, $os, $data_length ) );
                    $os += $data_length;

#if ($field_name_from_offset->{$param_offset} eq 'squeezecenter_name') {
#    print "squeezecenter_name data string in MessageIn::udap_decode", hex2str($data_string);
#};

                    log( debug => '*** field name: ' . $field_name_from_offset->{$param_offset} . ', data string: ' . format_hex($data_string) . "\n" ) if $data_string;

                    $param_data_ref
                        ->{ $field_name_from_offset->{$param_offset} }
                        = $field_unpack_from_offset->{$param_offset}
                        ->($data_string) if $param_offset;
                }
                $self->update_device_data($param_data_ref);
                last SWITCH;
            };

            ( $self->ucp_method eq UCP_METHOD_SET_IP ) && do {
                log( warn =>
                        '    Need to check contents of set_ip response msg' );
                last SWITCH;
            };

            # default action if ucp_method is not recognised goes here
            if ( exists $ucp_method_name->{ $self->ucp_method } ) {
                log( debug => 'ucp_method ' . $ucp_method_name->{ $self->ucp_method }
                        . ' callback not implemented yet' );
                print "Raw msg:\n" . format_hex($raw_msg);
            }
            else {
                croak( 'Unknown ucp_method value found: '
                        . format_hex( $self->ucp_method ) );
            }
        }
        return $self;
    }
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Net::UDAP::MessageIn - [One line description of module's purpose here]


=head1 VERSION

This document describes Net::UDAP::MessageIn version 0.1


=head1 SYNOPSIS

    use Net::UDAP::MessageIn;

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
  
Net::UDAP::Message requires no configuration files or environment variables.


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
C<bug-net-udap-messagein@rt.cpan.org>, or through the web interface at
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
