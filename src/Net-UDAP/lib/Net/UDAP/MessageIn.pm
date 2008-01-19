package Net::UDAP::MessageIn;

# $Id$

use warnings;
use strict;

use version; our $VERSION = qv('0.1');

use Net::UDAP::Constant;

use vars qw( $AUTOLOAD );    # Keep 'use strict' happy
use base qw(Class::Accessor);

my %field_default_values = (

    # define fields and default values here
    dst_addr_type => undef,
    dst_mac       => undef,
    dst_ip        => undef,
    dst_port      => undef,
    src_addr_type => undef,
    src_mac       => undef,
    src_ip        => undef,
    src_port      => undef,
    seq           => undef,    # unused?
    udap_type     => undef,
    ucp_flags     => undef,    # unused?
    uap_class     => undef,
    ucp_method    => undef,
    ucp_code      => undef,
    data_length   => undef,
    device_name   => undef,
);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors( keys(%field_default_values) );

{

    sub new {
        my ( $caller, $args ) = @_;
        my $class = ref $caller || $caller;

        $args = {} unless defined $args;

        # add default values to args hash if fieldname not specified
        foreach my $fieldname ( keys %field_default_values ) {
            if ( !exists $args->{$fieldname} ) {
                $args->{$fieldname} = $field_default_values{$fieldname};
            }
        }

        my $self = bless {%$args}, $class;
        return $self;
    }

    sub prepare_credential {

        # return 32 packed hex zeros
        return pack( 'C' x 32, (0x00) x 32 );
    }

    sub udap_decode {
        my ( $self, $rawmsg ) = @_;

        my $os = 0;    # offset from start of raw message

        # src addr type
        $self->set_dst_addr_type( substr( $rawmsg, $os, 2 ) );
        $os += 2;

        # src mac or src IP + port
    SWITCH: {
            ( $self->get_dst_addr_type eq ADDR_TYPE_ETH ) && do {
                $self->set_dst_mac( substr( $rawmsg, $os, 6 ) );
                last SWITCH;
            };
            ( $self->get_dst_addr_type eq ADDR_TYPE_UDP ) && do {
                $self->set_dst_ip( substr( $rawmsg, $os, 4 ) );
                $self->set_dst_port( substr( $rawmsg, $os + 4, 2 ) );
                last SWITCH;
            };
            warn "unknown address type";
        }
        $os += 6;

        # dest addr type ( two bytes)
        $self->set_src_addr_type( substr( $rawmsg, $os, 2 ) );
        $os += 2;

        # dest mac or src IP + port
    SWITCH: {
            ( $self->get_src_addr_type eq ADDR_TYPE_ETH ) && do {
                $self->set_src_mac( substr( $rawmsg, $os, 6 ) );
                last SWITCH;
            };
            ( $self->get_src_addr_type eq ADDR_TYPE_UDP ) && do {
                $self->set_src_ip( substr( $rawmsg, $os, 4 ) );
                $self->set_src_port( substr( $rawmsg, $os + 4, 2 ) );
                last SWITCH;
            };
            warn "unknown address type";
        }
        $os += 6;

        # seq
        $self->set_seq( substr( $rawmsg, $os, 2 ) );
        $os += 2;

        # udap type
        $self->set_udap_type( substr( $rawmsg, $os, 2 ) );
        $os += 2;

        # flag
        $self->set_ucp_flags( substr( $rawmsg, $os, 1 ) );
        $os += 1;

        # uap class
        $self->set_uap_class( substr( $rawmsg, $os, 4 ) );
        $os += 4;

        # ucp method
        $self->set_ucp_method( substr( $rawmsg, $os, 2 ) );
        $os += 2;

        # Now, do different things depending on what packet type this is
    SWITCH: {
            ( $self->get_ucp_method eq UCP_METHOD_DISCOVER ) && do {

                # ucp code
                $self->set_ucp_code( substr( $rawmsg, $os, 1 ) );
                $os += 1;

                # length of following string
                $self->set_data_length( substr( $rawmsg, $os, 1 ) );
                $os += 1;

                my $length = unpack( 'c', $self->get_data_length );

                # Get name of target
                $self->set_device_name( substr( $rawmsg, $os, $length ) );
                $os += $length;

                last SWITCH;
            };

            () && do {

                last SWITCH;
            };

            # default goes here
            use Data::HexDump;
            warn "raw msg:\n" . HexDump($rawmsg);
            warn "unpacked msg object:\n" . Dumper( \$self );

        }
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
C<bug-net-udap-message@rt.cpan.org>, or through the web interface at
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
