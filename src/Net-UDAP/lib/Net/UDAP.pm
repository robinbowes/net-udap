package Net::UDAP;

# $Id$

use warnings;
use strict;
use Carp;
use Data::Dumper;
use Data::HexDump;

use version; our $VERSION = qv('0.1');

use Net::UDAP::Client;
use Net::UDAP::Constant;
use Net::UDAP::Log;
use Net::UDAP::MessageIn;
use Net::UDAP::MessageOut;
use Net::UDAP::Util;

use vars qw( $AUTOLOAD );    # Keep 'use strict' happy
use base qw(Class::Accessor);

my %field_default = (
    socket   => undef,
    devices  => {},          # store devices in a hash
    local_ip => undef,
);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors( keys %field_default );

use IO::Socket;
use Time::HiRes;

{

    # Class methods; these operate on encapsulated class data

    sub new {
        my ( $caller, %args ) = @_;
        my $class = ref $caller || $caller;
        my $self = bless {}, $class;

        $self->set_socket( $self->create_socket );
        $self->set_local_ip(detect_local_ip);
        return $self;
    }

    sub close {
        my $self = shift;
        $self->get_socket->close;
    }

    sub create_socket {

        # Setup listening socket on UDAP port
        my $sock = IO::Socket::INET->new(
            Proto     => 'udp',
            LocalPort => PORT_UDAP,
            Blocking  => 0,
            Broadcast => 1,
        );
        return $sock;

        # May need to set non-blocking a different way, depending on
        # whether or not the std method works on Windows
        # This is how SC does it:
        #defined( Slim::Utils::Network::blocking( $_sock, 0 ) ) || do {
        #    logger('')
        #        ->logdie(
        #        "FATAL: Discovery init: Cannot set port nonblocking");
        #};
    }

    sub discover {
        my ( $self, $args_ref ) = @_;

        $args_ref = {} if ( !defined $args_ref );

        # pass { advanced => 1 } to use advanced discovery
        my $ucp_method
            = ( $args_ref->{advanced} )
            ? UCP_METHOD_ADV_DISCOVER
            : UCP_METHOD_DISCOVER;

        # Empty the device list
        $self->set_devices( {} );

        # Create a discovery msg
        my $msg_ref
            = Net::UDAP::MessageOut->new( { ucp_method => $ucp_method } );

        # send msg
        if ($msg_ref) {
            $self->send_msg($msg_ref);
            $self->read_responses;
        }
        return;
    }

    sub get_ip {
        my ( $self, $args_ref ) = @_;
        $args_ref = {} if ( !defined $args_ref );

        ( exists $args_ref->{mac} ) && ( defined $args_ref->{mac} ) or do {
            croak('Must specify mac for get_ip');
        };

        my $encoded_mac = encode_mac( $args_ref->{mac} );

        my $msg_ref;
        eval {
            $msg_ref = Net::UDAP::MessageOut->new(
                {   ucp_method => UCP_METHOD_GET_IP,
                    dst_mac    => $encoded_mac,
                }
            );
            }
            or do {
            carp($@);
            return;
            };

        if ($msg_ref) {
            $self->send_msg($msg_ref);
            $self->read_responses;
        }
        return;
    }

    sub set_ip {
        my ( $self, $args_ref ) = @_;
        $args_ref = {} if ( !defined $args_ref );

        ( exists $args_ref->{mac} ) && ( defined $args_ref->{mac} ) or do {
            croak('Must specify mac for set_ip');
        };

        my $encoded_mac = encode_mac( $args_ref->{mac} );

        my $msg_ref;
        eval {
            $msg_ref = Net::UDAP::MessageOut->new(
                {   ucp_method => UCP_METHOD_SET_IP,
                    dst_mac    => $encoded_mac,
                }
            );
            }
            or do {
            carp($@);
            return;
            };

        if ($msg_ref) {
            $self->send_msg($msg_ref);
            $self->read_responses;
        }
        return;

    }

    sub get_data {
        my ( $self, $args_ref ) = @_;
        $args_ref = {} if ( !defined $args_ref );

        ( exists $args_ref->{mac} ) && ( defined $args_ref->{mac} ) or do {
            croak('Must specify mac for get_data');
        };

        my $encoded_mac = encode_mac( $args_ref->{mac} );

        my $msg_ref;
        eval {
            $msg_ref = Net::UDAP::MessageOut->new(
                {   ucp_method => UCP_METHOD_GET_DATA,
                    dst_mac    => $encoded_mac,
                    data       => $args_ref->{data},
                }
            );
            }
            or do {
            carp($@);
            return;
            };

        if ($msg_ref) {
            $self->send_msg($msg_ref);
            $self->read_responses;
        }
        return;
    }

    sub send_msg {
        my ( $self, $msg_ref ) = @_;

        my $sock       = $self->get_socket;
        my $dest_ip    = inet_ntoa(INADDR_BROADCAST);
        my $dest       = pack_sockaddr_in( PORT_UDAP, INADDR_BROADCAST );
        my $ucp_method = $msg_ref->get_ucp_method;
        log(      info => '*** Broadcasting '
                . $ucp_method_name->{$ucp_method}
                . " message on $dest_ip\n" );
        return $sock->send( $msg_ref->packed, 0, $dest );
    }

    sub read_responses {
        my ($self) = @_;

        # Wait a while
        select( undef, undef, undef, UDAP_TIMEOUT );

        # read responses
        $self->read_UDP;
        return;
    }

    sub read_UDP {
        my ($self) = @_;

        log( debug => 'read_UDP triggered' );

        my $packet_received = 0;
        my $local_ip        = $self->get_local_ip;
        my $local_ip_a      = inet_ntoa($local_ip);
        log( debug => "local ip: $local_ip_a\n" );

        while ( my $clientpaddr
            = $self->get_socket->recv( my $raw_msg, UDP_MAX_MSG_LEN ) )
        {
            ;

            $packet_received = 1;

            # get src port and src IP
            my ( $src_port, $src_ip ) = sockaddr_in($clientpaddr);

            # Don't process packets we sent
            if ( $src_ip eq $local_ip ) {
                log( info => '    Ignoring packet sent from this machine' );
                next;
            }

            $self->process_msg($raw_msg);
        }

        return $packet_received;
    }

    # dispatch table for received msgs
    my %METHOD = (

        # UCP_METHOD_ZERO,              undef,
        UCP_METHOD_DISCOVER(),          \&method_discover,
        UCP_METHOD_GET_IP(),            \&method_get_ip,
        UCP_METHOD_SET_IP(),            \&method_set_ip,
        UCP_METHOD_RESET(),             \&method_reset,
        UCP_METHOD_GET_DATA(),          \&method_get_data,
        UCP_METHOD_SET_DATA(),          \&method_set_data,
        UCP_METHOD_ERROR(),             \&method_error,
        UCP_METHOD_CREDENTIALS_ERROR(), \&method_credentials_error,
        UCP_METHOD_ADV_DISCOVER(),      \&method_discover,

        # UCP_METHOD_TEN,               undef,
    );

    sub process_msg {
        my ( $self, $raw_msg ) = @_;

        # Create a new msg object from the raw msg string
        # wrap in an eval to catch any croaks
        #  - convert the croak to a carp and return to continue processing
        my $msg_ref = {};
        eval {
            $msg_ref = Net::UDAP::MessageIn->new( { raw_msg => $raw_msg } );
            }
            or do {
            carp($@);
            return;
            };

        my $method = $msg_ref->get_ucp_method;

        my $handler = $METHOD{$method}
            || croak('ucp_method invalid or not defined.');
        my $mac = decode_mac( $msg_ref->get_src_mac );
        log( info =>
                "    $ucp_method_name->{$method} response received from $mac\n"
        );
        return $handler->( $self, $msg_ref );
    }

    sub method_discover {
        my ( $self, $msg_ref ) = @_;
        return $self->add_client($msg_ref);
    }

    sub method_get_ip {
        my ( $self, $msg_ref ) = @_;
        return;
    }

    sub method_set_ip {
        my ( $self, $msg_ref ) = @_;
        return;
    }

    sub method_reset {
        my ( $self, $msg_ref ) = @_;
        return;
    }

    sub method_get_data {
        my ( $self, $msg_ref ) = @_;
        return ( $self->update_client($msg_ref) );
        return;
    }

    sub method_set_data {
        my ( $self, $msg_ref ) = @_;
        return;
    }

    sub method_error {
        my ( $self, $msg_ref ) = @_;
        return;
    }

    sub method_credentials_error {
        my ( $self, $msg_ref ) = @_;
        return;
    }

    sub add_client {
        my ( $self, $msg_ref ) = @_;
        if ($msg_ref) {
            my $mac = decode_mac( $msg_ref->get_src_mac );

            #print "mac: $mac\n";
            if ($mac) {
                my $param_ref = $msg_ref->get_discovery_data_ref;
                $param_ref->{mac} = $mac;
                $self->get_devices->{$mac}
                    = Net::UDAP::Client->new($param_ref);
            }
            else {
                carp('mac not found in msg');
                return;
            }
        }
        else {
            carp('msg not defined');
            return;
        }
    }

    sub update_client {
        my ( $self, $msg_ref ) = @_;
        if ($msg_ref) {
            my $mac = decode_mac( $msg_ref->{src_mac} );
            if ($mac) {
                my $param_ref = $msg_ref->get_param_data_ref;

                #print "=" x 40 . "\n";
                #print Dumper \$param_ref;
                $self->get_devices->{$mac}->update($param_ref);
            }
        }
    }

#    sub unpack_msg_to_client {
#        my ($self, $msg_ref) = @_;
#
#        $msg_ref = {} if ( !defined $msg_ref );
#
#        my $client_params_ref = {};
#
#        $client_params_ref->{mac} = decode_mac( $msg_ref->{src_mac} );
#
#        # unpack discovery data to client param hash
#        foreach my $data_key ( keys %{ $msg_ref->get_discovery_data_ref } ) {
#            $client_params_ref->{ $ucp_code_name->{$data_key} }
#                = $msg_ref->get_discovery_data_ref->{$data_key}{data};
#        }
#
#        # unpack get_data data to client param hash
#        foreach my $param ( keys %{ $msg_ref->get_param_data_ref } ) {
#            $client_params_ref->{ $param } = (defined $unpack_from_name->{$param}) ?
#               $unpack_from_name->{$param}->( $msg_ref->get_param_data_ref->{$param} )
#               : $msg_ref->get_param_data_ref->{$param};
#        }
#
#        return $client_params_ref;
#    }

}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Net::UDAP - [One line description of module's purpose here]


=head1 VERSION

This document describes Net::UDAP version 0.1


=head1 SYNOPSIS

    use Net::UDAP;

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
  
Net::UDAP requires no configuration files or environment variables.


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
C<bug-net-udap@rt.cpan.org>, or through the web interface at
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
