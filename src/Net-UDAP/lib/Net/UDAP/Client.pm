package Net::UDAP::Client;

# $Id$

use warnings;
use strict;
use Carp;
use Data::Dumper;

use version; our $VERSION = qv('0.1');

# Module implementation here
use vars qw( $AUTOLOAD );    # Keep 'use strict' happy
use base qw(Class::Accessor);

use Net::UDAP::Util;
use Net::UDAP::Log;

my %fields_default = (

    # define fields and default values here
    bridging             => undef,
    hostname             => undef,
    device_id            => undef,
    device_type          => undef,
    firmware_rev         => undef,
    hardware_rev         => undef,
    interface            => undef,
    lan_gateway          => undef,
    lan_ip_mode          => undef,
    lan_network_address  => undef,
    lan_subnet_mask      => undef,
    mac                  => undef,
    primary_dns          => undef,
    secondary_dns        => undef,
    server_address       => undef,
    slimserver_address   => undef,
    slimserver_name      => undef,
    uuid                 => undef,
    wireless_channel     => undef,
    wireless_keylen      => undef,
    wireless_mode        => undef,
    wireless_region_id   => undef,
    wireless_SSID        => undef,
    wireless_wep_key_0   => undef,
    wireless_wep_key_1   => undef,
    wireless_wep_key_2   => undef,
    wireless_wep_key_3   => undef,
    wireless_wepon       => undef,
    wireless_wpa_cipher  => undef,
    wireless_wpa_enabled => undef,
    wireless_wpa_mode    => undef,
    wireless_wpa_psk     => undef,
);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors( keys(%fields_default) );

{

    # class methods
    sub new {
        my ( $caller, $args_ref ) = @_;
        my $class = ref $caller || $caller;

        # make sure $arg_ref is a hash ref
        $args_ref = {} unless defined $args_ref;

        # values from $arg_ref over-write the defaults
        my %arg = ( %fields_default, %{$args_ref} );

        # A mac must be specified when creating a client
        if ( !defined $arg{mac} ) {
            croak(
                'Must specify a MAC address when creating a new Client object'
            );
        }

        my $self = bless {%arg}, $class;
        return $self;
    }

    sub display_name {
        my $self  = shift;
        my $dname = $self->get_device_type . ' ';
        my @mac   = split( /:/, $self->get_mac );
        $dname .= $mac[3] . $mac[4] . $mac[5];
        return $dname;
    }

    sub set_ip {
        my ( $caller, $args_ref ) = @_;
        my $class = ref $caller || $caller;

        # make sure $arg_ref is a hash ref
        $args_ref = {} unless defined $args_ref;

    }
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Net::UDAP::Client - [One line description of module's purpose here]


=head1 VERSION

This document describes Net::UDAP::Client version 0.0.1


=head1 SYNOPSIS

    use Net::UDAP::Client;

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
  
Net::UDAP::Client requires no configuration files or environment variables.


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
C<bug-net-udap-client@rt.cpan.org>, or through the web interface at
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
