package Net::UDAP;

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


# Module implementation here
use vars qw( $AUTOLOAD );    # Keep 'use strict' happy
use base qw(Class::Accessor);

use IO::Socket::INET;
use IO::Select;

use Net::UDAP::Constant;
use Net::UDAP::Util;
use Net::UDAP::Message;
use Net::UDAP::Client;

use Data::Dumper;

{

    # Encapsulated class data

    # global hash of devices
    my %_devices;

    # Class methods; these operate on encapsulated class data

    sub new {
        my ( $caller, %args ) = @_;
        my $class = ref $caller || $caller;
        my $self = bless {}, $class;

        # define stuff here

        return $self;
    }

    sub setup_socket {
        my (%args) = @_;

        # If no IP address passed, use 0.0.0.0
        if ( !exists $args{ip_addr} ) {
            $args{ip_addr} = decode_ip(IP_ZERO);
        }

        # If no broadcast setting specified, use "broadcast off"
        if ( !exists $args{broadcast} ) {
            $args{broadcast} = BROADCAST_OFF;
        }

        # Setup listening socket on UDAP port
        my $sock = IO::Socket::INET->new(
            Proto     => 'udp',
            LocalPort => PORT_UDAP,
            LocalAddr => $args{ip_addr},
            Broadcast => $args{broadcast},
            Blocking  => 0,
            )
            or do {
            warn "Can't open socket on ip address: $args{ip_addr}";
            };

        # May need to set non-blocking a different way, depending on
        # whether or not the std method works on Windows
	# This is how SC does it:
        #defined( Slim::Utils::Network::blocking( $_sock, 0 ) ) || do {
        #    logger('')
        #        ->logdie(
        #        "FATAL: Discovery init: Cannot set port nonblocking");
        #};

        return $sock;
    }

    sub add_client {
        my $msg = shift;
        my $mac = decode_mac( $msg->{dst_mac} );
        if ( !exists $_devices{$mac} ) {
            $_devices{$mac} = Net::UDAP::Client->new();
            $_devices{$mac}
                ->set( mac => $msg->{dst_mac}, type => $msg->{device_name} );
        }
    }

    sub readUDP {
        my $sock = shift;

        warn "readUDP triggered";

        my $clientpaddr;
        my $rawmsg = '';

	my $packet_received = 0;

    WHILE: {
        while ( $clientpaddr = $sock->recv( $rawmsg, UDP_MAX_MSG_LEN ) ) {

	    $packet_received = 1;

            # get src port and src IP
            my ( $src_port, $src_ip ) = sockaddr_in($clientpaddr);

            # Don't process packets we sent
            # Will need to tweak this code when the clients start
            # sending packets with non-zero IP address
            if ( $src_ip ne IP_ZERO ) {
                warn "Ignoring packet with non-zero IP address";
                last WHILE;
            }

            my $msg = Net::UDAP::Message->new();

            # Unpack the msg and extract the UCP Method
            $msg->udap_decode($rawmsg);
            my $method = $msg->{ucp_method};

        SWITCH: {
                ( !defined $method ) && do {
                    warn "msg method not set";
                    last SWITCH;
                };
                ( $method eq UCP_METHOD_DISCOVER ) && do {
                    add_client($msg);
                    last SWITCH;
                };

                # default action
                use Data::Dumper;
                warn "Unknown message. Here's a dump:\n" . Dumper( \$msg );
            }
        }
	}
	return $packet_received;
    }

    sub _clear_data {

        # reset all data structures
        undef %_devices;
    }

    sub discover {
        my $sock = shift;

        # Empty the device list
        undef %_devices;

        # Create a discovery msg
        my $msg = Net::UDAP::Message->new(
            ucp_method => UCP_METHOD_DISCOVER );

        # send msg
        my $destpaddr = sockaddr_in( PORT_UDAP, INADDR_BROADCAST );
        $sock->send( $msg->packed(), 0, $destpaddr );

    }

    sub devices {

        # return the hash of clients
        return %_devices;
    }

    sub get_device_list {
        my @devices = ();
        foreach my $device ( keys %_devices ) {
            push @devices, $_devices{$device}->display_name();
        }
        return \@devices;
    }

    sub get_device_hash {
        my %devices;
        foreach my $device ( keys %_devices ) {
            $devices{$device} = $_devices{$device}->display_name();
        }
        return \%devices;
    }
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Net::UDAP - [One line description of module's purpose here]


=head1 VERSION

This document describes Net::UDAP version 0.0.1


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
