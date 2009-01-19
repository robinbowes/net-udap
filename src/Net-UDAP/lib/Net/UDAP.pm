package Net::UDAP;

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

use vars qw( $AUTOLOAD );    # Keep 'use strict' happy
use base qw(Class::Accessor);

use Carp;
use Data::Dumper;
use Data::HexDump;
use IO::Select;
use IO::Socket::INET;
use Net::UDAP::Client;
use Net::UDAP::Constant;
use Net::UDAP::Log;
use Net::UDAP::MessageIn;
use Net::UDAP::MessageOut;
use Net::UDAP::Util;
use Time::HiRes;

my %field_default = (
	socket      => undef,
	device_hash => undef,    # store devices in a hash ref
	local_ips   => undef,    # hash ref of local IPs
);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors( keys %field_default );

{

	# Class methods; these operate on encapsulated class data

	sub new {
		my ( $caller, %args ) = @_;

		# values from $arg_ref over-write the defaults
		my %arg = ( %field_default, %args );
		my $class = ref $caller || $caller;
		my $self = bless {%arg}, $class;

		$self->set_socket(create_socket);

		# Create a hash keyed on local IP addresses
		my @local_ips = get_local_addresses;
		my %temp_hash;
		@temp_hash{@local_ips} = ();
		$self->set_local_ips( \%temp_hash );
		return $self;
	}

	sub close {
		my $self = shift;
		$self->get_socket->close;
	}

	sub get_device_list {
		my $self        = shift;
		my $device_hash = $self->get_device_hash;
		return @{$device_hash}{ sort keys %{$device_hash} };
	}

	sub discover {
		my ( $self, $arg_ref ) = @_;
		$arg_ref = {} unless ref($arg_ref) eq 'HASH';

		# pass { advanced => 1 } to use advanced discovery
		my $ucp_method
			= ( $arg_ref->{advanced} )
			? UCP_METHOD_ADV_DISCOVER
			: UCP_METHOD_DISCOVER;

		# Empty the device list
		$self->set_device_hash( {} );

		if ( $self->send_msg( undef, $ucp_method, $arg_ref ) ) {
			$self->read_responses;
		}
		return;
	}

	sub get_ip {
		my ( $self, $mac, $arg_ref ) = @_;
		$arg_ref = {} unless ref($arg_ref) eq 'HASH';

		$arg_ref->{mac} = $mac
			unless exists $arg_ref->{mac};

		if ( $self->send_msg( $mac, UCP_METHOD_GET_IP, $arg_ref ) ) {
			$self->read_responses;
		}
		return;
	}

	sub set_ip {
		my ( $self, $mac, $arg_ref ) = @_;
		$arg_ref = {} unless ref($arg_ref) eq 'HASH';

		$arg_ref->{mac} = $mac
			unless exists $arg_ref->{mac};

		if ( $self->send_msg( $mac, UCP_METHOD_SET_IP, $arg_ref ) ) {
			$self->read_responses;
		}
		return;
	}

	sub get_data {
		my ( $self, $mac, $arg_ref ) = @_;
		$arg_ref = {} unless ref($arg_ref) eq 'HASH';

		$arg_ref->{mac} = $mac
			unless exists $arg_ref->{mac};

		if ( $self->send_msg( $mac, UCP_METHOD_GET_DATA, $arg_ref ) ) {
			$self->read_responses;
		}
		return;
	}

	sub set_data {
		my ( $self, $mac, $arg_ref ) = @_;
		$arg_ref = {} unless ref($arg_ref) eq 'HASH';

		$arg_ref->{mac} = $mac
			unless exists $arg_ref->{mac};

		if ( $self->send_msg( $mac, UCP_METHOD_SET_DATA, $arg_ref ) ) {
			$self->read_responses;
		}
		return;
	}

	sub reset {
		my ( $self, $mac ) = @_;

		if ( $self->send_msg( $mac, UCP_METHOD_RESET ) ) {
			$self->read_responses;
		}
		return;

	}

	sub send_msg {
		my ( $self, $mac, $ucp_method, $arg_ref ) = @_;
		$arg_ref = {} unless ref($arg_ref) eq 'HASH';

		croak('Must specify ucp_method') if !defined $ucp_method;

		my $encoded_mac;

		# use MAC_ZERO for discovery packets
		# Otherwise MAC must be specified
		if (   ( $ucp_method eq UCP_METHOD_DISCOVER )
			or ( $ucp_method eq UCP_METHOD_ADV_DISCOVER ) )
		{
			$encoded_mac = MAC_ZERO;
		}
		else {
			croak(
				'Must specify mac address for $ucp_method_name->{$ucp_method} packets'
			) if !defined $mac;
			$encoded_mac = encode_mac($mac);
		}

		my $msg_ref;
		eval {
			$msg_ref = Net::UDAP::MessageOut->new(
				{   ucp_method  => $ucp_method,
					dst_mac     => $encoded_mac,
					data_to_get => $arg_ref->{data_to_get},
					data_to_set => $arg_ref->{data_to_set},
				}
			);
			}
			or do {
			carp($@);
			return;
			};

		my $sock    = $self->get_socket;
		my $dest_ip = inet_ntoa(INADDR_BROADCAST);
		my $dest    = pack_sockaddr_in( PORT_UDAP, INADDR_BROADCAST );
		log(      info => '*** Broadcasting '
				. $ucp_method_name->{$ucp_method}
				. ' message to MAC address '
				. decode_mac($encoded_mac)
				. " on $dest_ip\n" );
		return $sock->send( $msg_ref->packed, 0, $dest );
	}

	sub read_responses {
		my ($self) = @_;

		# Wait a while
		select( undef, undef, undef, UDAP_TIMEOUT );

		# read responses
		while ( $self->read_UDP ) { }
		return;
	}

	sub read_UDP {
		my ($self) = @_;

		log( debug => '    read_UDP triggered' );

		my $packet_received = 0;

		my $select = IO::Select->new( $self->get_socket );

		while ( $select->can_read(1) ) {
			if ( my $clientpaddr
				= $self->get_socket->recv( my $raw_msg, UDP_MAX_MSG_LEN ) )
			{

				$packet_received = 1;

				# get src port and src IP
				my ( $src_port, $src_ip ) = sockaddr_in($clientpaddr);
				my $src_ip_a = inet_ntoa($src_ip);

				# Don't process packets we sent
				if ( exists $self->get_local_ips->{$src_ip_a} ) {
					log(debug => '  Ignoring packet sent from this machine' );
					next;
				}

				$self->process_msg($raw_msg);
			}

		}
		return $packet_received;
	}

	# dispatch table for received msgs
	my %METHOD = (

		# UCP_METHOD_ZERO,              undef,
		UCP_METHOD_DISCOVER(),          \&callback_discover,
		UCP_METHOD_GET_IP(),            \&callback_get_ip,
		UCP_METHOD_SET_IP(),            \&callback_set_ip,
		UCP_METHOD_RESET(),             \&callback_reset,
		UCP_METHOD_GET_DATA(),          \&callback_get_data,
		UCP_METHOD_SET_DATA(),          \&callback_set_data,
		UCP_METHOD_ERROR(),             \&callback_error,
		UCP_METHOD_CREDENTIALS_ERROR(), \&callback_credentials_error,
		UCP_METHOD_ADV_DISCOVER(),      \&callback_discover,

		# UCP_METHOD_TEN,               undef,
	);

	sub process_msg {
		my ( $self, $raw_msg ) = @_;

		# Create a new msg object from the raw msg string
		# wrap in an eval to catch any croaks
		#  - convert the croak to a carp and return to continue processing
		my $msg_ref;
		eval {
			$msg_ref = Net::UDAP::MessageIn->new( { raw_msg => $raw_msg } );
		} or return;
		if ($@) {
			carp($@);
			return;
		}

		my $method  = $msg_ref->get_ucp_method;
		my $handler = $METHOD{$method}
			|| croak('ucp_method invalid or not defined.');

		my $mac = decode_mac( $msg_ref->get_src_mac );
		log( info =>
				"  $ucp_method_name->{$method} response received from $mac\n"
		) if defined $mac;
		return $handler->( $self, $msg_ref );
	}

	sub callback_discover {
		my ( $self, $msg_ref ) = @_;
		log( debug => '    processing discover packet' );
		return $self->add_client($msg_ref);
	}

	sub callback_get_ip {
		my ( $self, $msg_ref ) = @_;
		log( debug => '    processing get_ip packet' );
		return ( $self->update_client($msg_ref) );
		return;
	}

	sub callback_set_ip {
		my ( $self, $msg_ref ) = @_;
		log( debug => '    processing set_ip packet' );
		return;
	}

	sub callback_reset {
		my ( $self, $msg_ref ) = @_;
		log( debug => '    processing reset packet' );
		return;
	}

	sub callback_get_data {
		my ( $self, $msg_ref ) = @_;
		log( debug => '    processing get_data packet' );
		return ( $self->update_client($msg_ref) );
		return;
	}

	sub callback_set_data {
		my ( $self, $msg_ref ) = @_;
		log( debug => '    processing set_data packet' );
		return;
	}

	sub callback_error {
		my ( $self, $msg_ref ) = @_;
		log( debug => '    processing error packet' );
		return;
	}

	sub callback_credentials_error {
		my ( $self, $msg_ref ) = @_;
		log( debug => '    processing credentials_error packet' );
		return;
	}

	sub add_client {
		my ( $self, $msg_ref ) = @_;
		croak '$msg_ref not a Net::UDAP::MessageIn object'
			unless ref($msg_ref) eq 'Net::UDAP::MessageIn';

		my $mac = decode_mac( $msg_ref->get_src_mac );

		if ($mac) {
			my $device_data_ref = $msg_ref->get_device_data_ref;
			$device_data_ref->{mac} = $mac;
			$self->get_device_hash->{$mac}
				= Net::UDAP::Client->new($device_data_ref);
		}
		else {
			carp('mac not found in msg');
			return;
		}
	}

	sub update_client {
		my ( $self, $msg_ref ) = @_;
		croak '$msg_ref not a Net::UDAP::MessageIn object'
			unless ref($msg_ref) eq 'Net::UDAP::MessageIn';

		my $mac = decode_mac( $msg_ref->get_src_mac );

		if ($mac) {
			$self->get_device_hash->{$mac}
				->update( $msg_ref->get_device_data_ref );
		}
		else {
			carp "MAC address not defined";
		}
	}
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
