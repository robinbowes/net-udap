package Net::UDAP::Util;

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

# Add the modules to the libpath
use FindBin;
use lib "$FindBin::Bin/../src/Net-UDAP/lib";

use version; our $VERSION = qv('1.0_01');

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Carp;
use Exporter qw(import);

%EXPORT_TAGS = (
    all => [
        qw( hexstr decode_hex encode_mac decode_mac create_socket detect_local_ip set_blocking get_local_addresses)
    ]
);
Exporter::export_tags('all');

use Net::UDAP::Log;
use Net::UDAP::Constant;
use IO::Socket::INET;
use Socket;

{

    sub decode_hex {

        # Decode a hex string of specified length into a human-readable string
        # $rawstr	- the raw hex string
        # $strlen	- the length of the hex string
        # $fmt		- the format to use to unpack each byte
        # $separator	- the string to use as separator in the output string
        my ( $rawstr, $strlen, $fmt, $separator ) = @_;
        $separator = '' if !defined $separator;
        if ( length($rawstr) == $strlen ) {
            my @parts = unpack( "($fmt)*", $rawstr );
            if (wantarray) {
                return @parts;
            }
            else {
                return join( "$separator", @parts );
            }
        }
        else {
            carp 'Supplied string has length'
                . length($rawstr)
                . "(expected length: $strlen)";
            return undef;
        }
    }

    sub encode_mac {

        # Encode a mac address to a 6-byte string
        # $mac		- MAC address in format xx:xx:xx:xx:xx:xx
        my $mac = shift;
        if ($mac =~ /
		    \A			# start of string
		    ( [0-9A-Fa-f]{2} )	# match and capture two hex digits
		    :			# semi-colon literal
		    ( [0-9A-Fa-f]{2} )	# match and capture two hex digits
		    :			# semi-colon literal
		    ( [0-9A-Fa-f]{2} )	# match and capture two hex digits
		    :			# semi-colon literal
		    ( [0-9A-Fa-f]{2} )	# match and capture two hex digits
		    :			# semi-colon literal
		    ( [0-9A-Fa-f]{2} )	# match and capture two hex digits
		    :			# semi-colon literal
		    ( [0-9A-Fa-f]{2} )	# match and capture two hex digits
		    /xms
            )
        {
            return pack( 'C6',
                hex($1), hex($2), hex($3), hex($4), hex($5), hex($6) );
        }
        else {
            carp
                "MAC address \"$mac\" not in expected format (xx:xx:xx:xx:xx:xx)";
            return undef;
        }
    }

    sub decode_mac {

        # Decode a 6-byte MAC string into human-readable form
        # $rawstr	- 6-byte hex string representing MAC address
        my $rawstr = shift;
        return decode_hex( $rawstr, 6, 'H2', ':' );
    }

    sub hexstr {

        # decode the supplied bytes as a hex number string
        # $bytes	- the byte string to decode
        # $width	- the width of the output
        # sample output (width=4): 0x0001
        my ( $bytes, $width ) = @_;
        return sprintf(
            join( q{}, '0x%0', int($width), 'x' ),
            unpack( 'n', $bytes )
        );
    }

    sub create_socket {

        # Setup listening socket on UDAP port
        my $sock = IO::Socket::INET->new(
            Proto     => 'udp',
            LocalPort => PORT_UDAP,

            # Setting Blocking like this doesn't work on Windows. bah.
            #            Blocking  => 0,
            Broadcast => 1,
        );
        if ( !defined $sock ) {
            croak "error creating socket: $@";
        }

        # Now set socket non-blocking in a way that works on Windows
        if ( !set_blocking( $sock, 0 ) ) {
            croak "error setting socket non-blocking";
        }
        return $sock;
    }

    sub get_local_addresses {

        # This is a dirty hack to get IP addresses in use on the system
        my @ips = qw( );
        my $syscmd;
        my $regex;

        # Use ipconfig on Windows + under cygwin
        if ( $^O =~ /Win|cygwin/ ) {
            $syscmd = 'ipconfig';
            $regex  = qr{IP Address.* ((?:\d{1,3}\.){3}\d{1,3})};
        }
        else {
            $syscmd = '/sbin/ifconfig';
            $regex  = qr{inet addr:((?:\d{1,3}\.){3}\d{1,3})};
        }
        my @output = qx/$syscmd/;
        for my $line (@output) {
            if ( $line =~ /$regex/ ) {
                my $ip = $1;
                if ( $ip ne '127.0.0.1' ) {
                    push @ips, $ip;
                }
            }
        }
        return @ips;
    }

    sub detect_local_ip {

        # This routine adapted from code used in SqueezeCenter
        #
        # Thanks to trick from Bill Fenner, trying to use a UDP socket won't
        # send any packets out over the network, but will cause the routing
        # table to do a lookup, so we can find our address. Don't use a high
        # level abstraction like IO::Socket, as it dies when connect() fails.
        #
        # time.nist.gov - though it doesn't really matter.
        my $raddr = '192.43.244.18';
        my $rport = 123;

        my $proto     = ( getprotobyname('udp') )[2];
        my $pname     = ( getprotobynumber($proto) )[0];
        my $sock      = Symbol::gensym();
        my $localhost = INADDR_LOOPBACK;

        my $iaddr = inet_aton($raddr) or do {
            log( warn =>
                    "    Couldn't call inet_aton($raddr) - falling back to $localhost"
            );
            return $localhost;
        };

        my $paddr = sockaddr_in( $rport, $iaddr );

        socket( $sock, PF_INET, SOCK_DGRAM, $proto ) || do {
            log( warn =>
                    "    Couldn't call socket(PF_INET, SOCK_DGRAM, \$proto) - falling back to $localhost"
            );
            return $localhost;
        };

        connect( $sock, $paddr ) || do {
            log( warn =>
                    "    Couldn't call connect() - falling back to $localhost"
            );
            return $localhost;
        };

        # Find my half of the connection
        my ( $port, $address ) = sockaddr_in( ( getsockname($sock) )[0] );
        return $address;
    }

=head2 set_blocking( $sock, [0 | 1] )

Set the passed socket to be blocking (1) or non-blocking (0)

=cut

    sub set_blocking {

        my ( $sock, $block_val ) = @_;

        # Can just set blocking status on systems other than Windows
        return $sock->blocking($block_val) unless $^O =~ /Win32/;

        # $nonblocking is the opposite of $block_val!
        my $nonblocking = $block_val ? "0" : "1";
        my $retval = ioctl( $sock, 0x8004667e, \$nonblocking );

        # presumably, this is because ioctl returns undef for true
        # in perl 5.8 and lateR?
        if ( !defined($retval) && $] >= 5.008 ) {
            $retval = "0 but true";
        }

        return $retval;
    }

}
1;    # Magic true value required at end of module
__END__

=head1 NAME

Net::UDAP::Util - [One line description of module's purpose here]


=head1 VERSION

This document describes Net::UDAP::Util version 0.0.1


=head1 SYNOPSIS

    use Net::UDAP::Util;

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
  
Net::UDAP::Util requires no configuration files or environment variables.


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
C<bug-net-udap-util@rt.cpan.org>, or through the web interface at
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
