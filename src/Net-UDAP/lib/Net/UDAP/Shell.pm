package Net::UDAP::Shell;

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

use warnings;
use strict;
use Getopt::Long;
use Data::Dumper;

use version; our $VERSION = qv('0.1');

use base qw(
    Term::Shell
    Class::Accessor
);

my %fields_default = (
    num              => 0,
    log              => undef,
    name             => 'UDAP',
    history_filename => "$ENV{HOME}/.UDAP\_history",
);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors( keys %fields_default );

use Net::UDAP;
use Scalar::Util qw{ looks_like_number };

my $discovered_devices = undef;   # hash ref containing refs to device objects
                                  # for all devices found; keyed on MAC
my @device_list        = undef;   # array containing refs to device objects
                                  # for all devices found;
my $udap;    # object used to access all UDAP methods, etc.

my $current_device = undef;    # index of the device from @device_list that is
                               # currently being configured

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    my %args = @{ $self->{API}{args} };
    $self->set_log( $args{log} ) unless defined $self->get_log;

    while ( my ( $key, $value ) = each %fields_default ) {
        my $set_key = "set_$key";
        my $get_key = "get_$key";
        $self->$set_key($value) unless defined $self->$get_key;
    }

    # Only now can we try to read the history file, because the
    # 'history_filename' might have been defined in the DEFAULTS().

    if ( $self->{term}->Features->{setHistory} ) {
        my $filename = $self->get_history_filename;
        if ( -r $filename ) {
            open( my $fh, '<', $filename )
                or die "can't open history file $filename: $!\n";
            chomp( my @history = <$fh> );
            $self->{term}->SetHistory(@history);
            close $fh or die "can't close history file $filename: $!\n";
        }
    }
    $udap = Net::UDAP->new;
}

sub prompt_str {
    my $device
        = ( defined $current_device )
        ? ' ['
        . ( $current_device + 1 )
        . '] ('
        . $device_list[$current_device]->display_name . ')'
        : '';
    return "UDAP$device> "

}

sub postloop {
    my $self = shift;
    print "\n";

    if ( $self->{term}->Features->{getHistory} ) {
        my $filename = $self->get_history_filename;
        open( my $fh, '>', $filename )
            or die "can't open history file $filename for writing: $!\n";
        print $fh "$_\n" for grep {length} $self->{term}->GetHistory;
        close $fh or die "can't close history file $filename: $!\n";
    }
}

######## Exit ########

sub alias_exit {qw( exit quit )}

sub smry_exit {
    'Exit configure mode (if configuring a device), otherwise exit application';
}

sub help_exit {
    <<'END' }
In global mode:
    exit - quits the application
In configure mode:
    exit - returns to global mode
END

sub run_exit {
    my $self = shift;

    # Need to check if there is any information to save before exiting
    exit(0) if !defined $current_device;
    $current_device = undef;
}

######## Discovery ########

sub smry_discover {
    'Discover UDAP devices and get their current configuration';
}

sub help_discover {
    <<'END' }
Discovers all available UDAP devices and retrieves their current configuration details.
END

sub run_discover {
    my $self = shift;
    $udap->discover( { advanced => 1 } );
    $discovered_devices = $udap->get_devices;
    @device_list        = @{$discovered_devices}{sort keys %{$discovered_devices}};
    foreach my $device_mac ( keys %{$discovered_devices} ) {
        $udap->get_ip( { mac => $device_mac } );
        $udap->get_data(
            {   mac => $device_mac,
                data_to_get =>
                    $discovered_devices->{$device_mac}->get_all_param_names
            }
        );
    }
}

######## List ########

sub smry_list {'List discovered devices, or information about a device'}

sub help_list {
    <<'END' }
In global mode:
    list [all] - lists all discovered devices
    list n     - lists information about device n
In configure mode:
    list [all] - lists all information about current device
    list parameter [parameter1 parameter 2 ...]
               - lists the named parameters
END

sub run_list {
    my ( $self, @args ) = @_;
    my $nargs = scalar(@args);
    if ( defined $current_device ) {

        # configure mode
    SWITCH: {

            # 'list' or 'list all'
            ( $nargs == 0 )
                or ( ( $nargs == 1 ) and ( $args[0] eq 'all' ) ) and do {
                $self->list_device( $device_list[$current_device] );
                last SWITCH;
                };

            # send all supplied params to list_device sub
            $self->list_device( $device_list[$current_device],
                ($nargs) ? [@args] : undef );
        }
    }
    else {

        # global mode
    SWITCH: {
            (          ( $nargs == 0 )
                    or ( ( $nargs == 1 ) and ( $args[0] eq 'all' ) )
                )
                and do {

                # list all devices
                $self->show_devices;
                last SWITCH;
                };
            (           ( $nargs == 1 )
                    and ( looks_like_number( $args[0] ) )
                    and (
                    ref( $device_list[ $args[0] - 1 ] ) eq
                    'Net::UDAP::Client' )
                )
                and do {

                # list all details of one device
                # NB. The user will use device 1, 2, 3, etc. while the array
                #     index starts at 0; hence the need to subtract one from
                #     the number supplied by the user
                $self->list_device( $device_list[ $args[0] - 1 ] );
                last SWITCH;
                };

            # default SWITCH action here
            print "Syntax error in list command\n";
        }
    }

}

######## configure ########

sub smry_configure {'configure a device'}

sub help_configure {
    <<'END' }
    configure help goes here
END

sub run_configure {
    my ( $self, @args ) = @_;
    if ( !defined $discovered_devices ) {
        print "Discovery not yet run\n";
        return;
    }
    if ( scalar(@device_list) == 0 ) {
        print "No devices found to configure\n";
        return;
    }
    if (    ( scalar(@args) == 1 )
        and ( looks_like_number( $args[0] ) )
        and ( ref( $device_list[ $args[0] - 1 ] ) eq 'Net::UDAP::Client' ) )
    {
        $current_device = $args[0] - 1;
        return;
    }
}

######## non-command routines ########

sub show_devices {
    my $list_format = "%2s %-17s %-10s %-15s\n";
    my $count       = 1;
    printf $list_format, '#', '   MAC Address   ', 'Type', 'Status';
    printf $list_format, '=' x 2, '=' x 17, '=' x 10, '=' x 15;
    foreach my $device (@device_list) {
        printf $list_format, $count, $device->get_mac,
            $device->get_device_type, $device->get_device_status;
        $count++;
    }
}

sub list_device {
    my ( $self, $device, $param_names ) = @_;

    my %valid_param_names;
    @valid_param_names{ $device->get_all_param_names } = ();

    # If the user supplied any parameters, validate them and use them
    if ( defined $param_names ) {

        # create a lookup hash using a hash slice
        my @invalid_param_names;
        foreach my $param ( @{$param_names} ) {
            push( @invalid_param_names, $param )
                unless exists $valid_param_names{$param};
        }
        if ( scalar(@invalid_param_names) ) {
            print "Invalid param names in list: ["
                . join( ',', @invalid_param_names ) . "]\n";
            return;
        }
    }
    else {

        # Otherwise, use all param names
        $param_names = [ keys %valid_param_names ];
    }

    # Get a hash just those params that are not 'undef'
    my $defined_params = $device->get_defined_params;

    # Select only those params that are both defined and requested
    # also, use a hash slice to get the keys in sorted order
    my @keys_to_print;
    foreach my $param ( @{$param_names} ) {
        push( @keys_to_print, $param ) if exists $defined_params->{$param};
    }

    @keys_to_print = sort @keys_to_print;
    $self->print_pairs( [@keys_to_print],
        [ @{$defined_params}{@keys_to_print} ] );
}
1;    # Magic true value required at end of module
__END__

=head1 NAME

Net::UDAP::Shell - Wrapper module to implement interactive shell UDAP module


=head1 VERSION

This document describes Net::UDAP::Log version 0.1


=head1 SYNOPSIS

    use Net::UDAP::Shell;

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
  
Net::UDAP::Log requires no configuration files or environment variables.


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
C<bug-net-udap-shell@rt.cpan.org>, or through the web interface at
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
