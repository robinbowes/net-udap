# -*- mode: Perl -*-

##########################################################################
#
#   HexDump.pm  -  Hexadecial Dumper
#
# version : 0.02
# Copyright (c) 1998, 1999, Fabien Tassin <fta@oleane.net>
##########################################################################
# ABSOLUTELY NO WARRANTY WITH THIS PACKAGE. USE IT AT YOUR OWN RISKS.
##########################################################################

package Data::HexDump;

use strict;
use vars qw(@ISA $VERSION @EXPORT);
use Exporter;
use Carp;
use FileHandle;

@ISA     = ('Exporter');
$VERSION = 0.02;
@EXPORT  = qw(HexDump);

sub new {
	my $this  = shift;
	my $class = ref($this) || $this;
	my $self  = {};
	bless $self, $class;
	$self->{'readsize'} = 128;
	return $self;
}

sub DESTROY {
	my $self = shift;
	$self->{'fh'}->close if defined $self->{'file'};
}

sub file {
	my $self = shift;
	my $file = shift;
	$self->{'file'} = $file if defined $file;
	$self->{'file'};
}

sub fh {
	my $self = shift;
	my $fh   = shift;
	$self->{'fh'} = $fh if defined $fh;
	$self->{'fh'};
}

sub data {
	my $self = shift;
	my $data = shift;
	$self->{'data'} = $data if defined $data;
	$self->{'data'};
}

sub block_size {
	my $self = shift;
	my $bs   = shift;
	$self->{'blocksize'} = $bs if defined $bs;
	$self->{'blocksize'};
}

sub dump {
	my $self = shift;

	my $out;
	my $l;
	$self->{'i'} = 0 unless defined $self->{'i'};
	$self->{'j'} = 0 unless defined $self->{'j'};
	my $i = $self->{'i'};
	my $j = $self->{'j'};
	unless ( $i || $j ) {
		$out = "          ";
		$l   = "";
		for ( my $i = 0; $i < 16; $i++ ) {
			$out .= sprintf "%02X", $i;
			$out .= " "  if $i < 15;
			$out .= "- " if $i == 7;
			$l .= sprintf "%X", $i;
		}
		$i = $j = 0;
		$out .= "  $l\n\n";
	}
	return undef if $self->{'eod'};
	$out .= sprintf "%08X  ", $j * 16;
	$l = "";
	my $val;
	while ( $val = $self->get ) {
		while ( length $val && defined( my $v = substr $val, 0, 1, '' ) ) {
			$out .= sprintf "%02X", ord $v;
			$out .= " " if $i < 15;
			$out .= "- "
				if $i == 7
					&& ( length $val || !( $self->{'eod'} || length $val ) );
			$i++;
			$l .= ord($v) >= 0x20 && ord($v) <= 0x7E ? $v : ".";
			if ( $i == 16 ) {
				$i = 0;
				$j++;
				$out .= "  " . $l;
				$l = "";
				$out .= "\n";
				if (   defined $self->{'blocksize'}
					&& $self->{'blocksize'}
					&& ( $j - $self->{'j'} ) > $self->{'blocksize'} / 16 )
				{
					$self->{'i'}   = $i;
					$self->{'j'}   = $j;
					$self->{'val'} = $val;
					return $out;
				}
				$out .= sprintf "%08X  ", $j * 16
					if length $val
						|| !length $val && !$self->{'eod'};
			}
		}
	}
	if ( $i || ( !$i && !$j ) ) {
		$out .= " " x ( 3 * ( 17 - $i ) - 2 * ( $i > 8 ) );
		$out .= "$l\n";
	}
	$self->{'i'}   = $i;
	$self->{'j'}   = $j;
	$self->{'val'} = $val;
	return $out;
}

# get data from different sources (scalar, filehandle, file..)
sub get {
	my $self = shift;

	my $buf;
	my $length = $self->{'readsize'};
	undef $self->{'val'} if defined $self->{'val'} && !length $self->{'val'};
	if ( defined $self->{'val'} ) {
		$buf = $self->{'val'};
		undef $self->{'val'};
	}
	elsif ( defined $self->{'data'} ) {
		$self->{'data_offs'} = 0 unless defined $self->{'data_offs'};
		my $offset = $self->{'data_offs'};
		$buf = substr $self->{'data'}, $offset, $length;
		$self->{'data_offs'} += length $buf;
		$self->{'eod'} = 1 if $self->{'data_offs'} == length $self->{'data'};
	}
	elsif ( defined $self->{'fh'} ) {
		read $self->{'fh'}, $buf, $length;
		$self->{'eod'} = eof $self->{'fh'};
	}
	elsif ( defined $self->{'file'} ) {
		$self->{'fh'} = new FileHandle $self->{'file'};
		read $self->{'fh'}, $buf, $length;
		$self->{'eod'} = eof $self->{'fh'};
	}
	else {
		print "Not yet implemented\n";
	}
	$buf;
}

sub HexDump ($) {
	my $val = shift;

	my $f = new Data::HexDump;
	$f->data($val);
	$f->dump;
}

1;

=head1 NAME

Data::HexDump - Hexadecial Dumper

=head1 SYNOPSIS

  use Data::HexDump;

  my $buf = "foo\0bar";
  print HexDump $buf;

  or

  my $f = new Data::HexDump;
  $f->data($buf);
  print $f->dump;

  or

  my $fh = new FileHandle $file2dump;
  my $f = new Data::HexDump;
  $f->fh($fh);
  $f->block_size(1024);
  print while $_ = $f->dump;
  close $fh;

  or

  my $f = new Data::HexDump;
  $f->file($file2dump);
  $f->block_size(1024);
  print while $_ = $f->dump;

=head1 DESCRIPTION

Dump in hexadecimal the content of a scalar. The result is returned in a
string. Each line of the result consists of the offset in the
source in the leftmost column of each line, followed by one or more
columns of data from the source in hexadecimal. The rightmost column
of each line shows the printable characters (all others are shown
as single dots).

=head1 COPYRIGHT

Copyright (c) 1998-1999 Fabien Tassin. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Fabien Tassin E<lt>fta@oleane.netE<gt>

=head1 VERSION

0.02 - Second release (September 1999)

=head1 SEE ALSO

perl(1)

=cut
