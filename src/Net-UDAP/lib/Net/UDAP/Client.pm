package Net::UDAP::Client;

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

use vars qw( $AUTOLOAD );    # Keep 'use strict' happy
use base qw(Class::Accessor);

use Carp;
use Data::Dumper;
use Net::UDAP::Constant;
use Net::UDAP::Log;
use Net::UDAP::Util;

my %other_codes_default = (

    # Other
    mac                => undef,
    fields_from_device => {},
);

# Default values for client params
my %fields_default
    = ( %$field_default_from_name, %$ucp_code_default, %other_codes_default );

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors( keys(%fields_default) );

{

    # Hash to hold values originally read from the device
    #my %fields_from_device;
    #@fields_from_device{ keys %$field_default_from_name } = ();

    # class methods
    sub new {
        my ( $caller, $arg_ref ) = @_;
        my $class = ref $caller || $caller;

        # make sure $arg_ref is a hash ref
        $arg_ref = {} unless defined $arg_ref;

        $arg_ref->{fields_from_device} = {};

        # values from $arg_ref over-write the defaults
        my %arg = ( %fields_default, %{$arg_ref} );

        # A mac must be specified when creating a client
        if ( !defined $arg{mac} ) {
            croak(
                'Must specify a MAC address when creating a new Client object'
            );
        }

        my $self = bless {%arg}, $class;

        return $self;
    }

    sub load {
        my ( $self, $udap ) = @_;
        my $device_mac = $self->get_mac;
        $udap->get_ip($device_mac);
        $udap->get_data( $device_mac,
            { data_to_get => [ keys %$field_default_from_name ] } );

        @{ $self->get_fields_from_device }{ keys %$field_default_from_name }
            = @{$self}{ keys %$field_default_from_name };
    }

    sub save_data {
        my ( $self, $udap ) = @_;
        my $device_mac  = $self->get_mac;
        my $data_to_set = $self->get_modified_fields;
        $udap->set_data( $device_mac,
            { data_to_set => $self->get_modified_fields } );
    }

    sub save_ip {
        my ( $self, $udap ) = @_;
        my $device_mac  = $self->get_mac;
        my $data_to_set = $self->get_modified_fields;
        $udap->set_ip(
            $device_mac,
            {   data_to_set => {
                    lan_network_address => $self->get_lan_network_address,
                    lan_subnet_mask     => $self->get_lan_subnet_mask,
                    lan_gateway         => $self->get_lan_gateway,
                    lan_ip_mode         => $self->get_lan_ip_mode,
                }
            }
        );
    }

    sub reset {
        my ( $self, $udap ) = @_;
        $udap->reset( $self->get_mac );
    }

    sub get_modified_fields {
        my $self            = shift;
        my $modified_fields = {};
        foreach my $fieldname ( keys %$field_default_from_name ) {
            my $get_field = "get_$fieldname";
            my $newval    = $self->$get_field;
            my $oldval    = $self->get_fields_from_device->{$fieldname};
            if (    defined($newval)
                and defined($oldval)
                and $newval ne $oldval )
            {
            }
            $modified_fields->{$fieldname} = $newval;
        }
        return $modified_fields;
    }

    #    sub set {
    #        my ($self, $key) = splice(@_, 0, 2);
    #
    #        # Note every time someone sets some data.
    #        print STDERR "Setting $key to @_\n";
    #
    #        $self->SUPER::set($key, @_);
    #    }

    sub display_name {
        my $self  = shift;
        my $dname = $self->get_device_type . ' ';
        my @mac   = split( /:/, $self->get_mac );
        $dname .= $mac[3] . $mac[4] . $mac[5];
        return $dname;
    }

    sub update {
        my ( $self, $arg_ref ) = @_;
        $arg_ref = {} unless ref($arg_ref) eq 'HASH';

        foreach my $param ( keys %{$arg_ref} ) {
            my $set_sub = "set_$param";
            $self->$set_sub( $arg_ref->{$param} );
        }

        return $self;
    }

    sub get_field_names {
        return keys %$field_default_from_name;
    }

    sub get_defined_fields {
        my $self           = shift;
        my $defined_fields = {};
        foreach my $fieldname ( keys %fields_default ) {
            my $get_field = "get_$fieldname";
            if ( defined $self->$get_field ) {
                $defined_fields->{$fieldname} = $self->$get_field;
            }
        }
        return $defined_fields;
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
