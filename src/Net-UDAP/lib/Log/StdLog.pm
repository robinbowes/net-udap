package Log::StdLog;

use version; $VERSION = qv('0.0.3');

use warnings;
use strict;
use Carp;

use base 'IO::File';

my @levels = qw( all trace debug user info warn error fatal none );
my %severity;
@severity{@levels} = 1 .. @levels;

# Aliases...
$severity{warning} = $severity{warn};

sub _make_formatter {
	my ($format) = @_;
	return sub {
		my ( $time, $source, $type, @msg ) = @_;
		my $msg = join q{}, @msg;
		return sprintf $format, $time, $source, $type, $msg;
		}
}

sub import {
	my ( $package, $opt_ref ) = @_;
	my ( $caller,  $file )    = caller;

	croak
		"Usage: use $package { file=>\$filename, level=>\$level, format=>sub{...} }\n "
		if $opt_ref && not ref $opt_ref eq 'HASH';

	if ( not exists $opt_ref->{file} ) {
		$opt_ref->{file} = "$file.log";
	}

	if ( not exists $opt_ref->{format} ) {
		$opt_ref->{format} = _make_formatter("[%s] [%s] [%s] %s");
	}
	elsif ( not ref $opt_ref->{format} ) {
		$opt_ref->{format} = _make_formatter( $opt_ref->{format} );
	}

	if ( not exists $opt_ref->{level} ) {
		$opt_ref->{level} = 'user';
	}

	no strict 'refs';
	tie *{ $caller . '::STDLOG' }, $package, $opt_ref;
}

sub TIEHANDLE {
	my ( $package, $opt_ref ) = @_;

	return bless {
		file              => $opt_ref->{file},
		handle            => $opt_ref->{handle},
		formatter         => $opt_ref->{format},
		min_severity_name => $opt_ref->{level} || 'user',
		min_severity => $severity{ $opt_ref->{level} } || $severity{user},
	};
}

use Fcntl ':flock';

sub PRINT {
	my ( $self, $level, @msg )
		= @_ == 1 ? ( $_[0], $_[0]->{min_severity_name}, $_ )
		: @_ == 2 ? ( $_[0], $_[0]->{min_severity_name}, $_[1] )
		:           (@_);

	# No-op if message isn't important enough...
	my $severity = $severity{$level} || $severity{user};
	return 0 if $self->{min_severity} > $severity;

	# Format message early to get accurate time-stamp...
	my ( $sec, $min, $hour, $day, $mon, $year ) = localtime;
	$year += 1900;
	$mon++;
	my $time = sprintf( "%04d%02d%02d.%02d%02d%02d",
		$year, $mon, $day, $hour, $min, $sec );
	$msg[-1] =~ s/\n\z// if @msg;
	my $log_msg = $self->{formatter}->( $time, $$, $level, @msg );

	# Create connection to log file, if necessary...
	if ( not $self->{handle} ) {
		open $self->{handle}, '>>', $self->{file}
			or croak "Unable to open log file '$self->{file}'";
	}

	# Synchronize writing to file via advisory locking...
	flock( $self->{handle}, LOCK_EX );
	my $result = $self->{handle}->print( $log_msg . "\n" );
	flock( $self->{handle}, LOCK_UN );

	return $result;
}

sub CLOSE {
	my ($self) = @_;
	$self->{handle}->close();
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Log::StdLog - A simple log file via a special filehandle


=head1 VERSION

This document describes Log::StdLog version 0.0.3


=head1 SYNOPSIS

    use Log::StdLog { level => 'warn', file => "$0.log" };

    # Messages at the same or a higher level are logged...
    print {*STDLOG} error => "This error message will be logged\n";
    print {*STDLOG} warn  => "This warning message will be logged\n";

    # Messages at a lower level are ignored...
    print {*STDLOG} info  => "This info message will NOT be logged\n";

    # The default message level is the one that was specified
    # when the module was loaded...

    print {*STDLOG} "This is a warning message. It will be logged\n";
  
  
=head1 DESCRIPTION

This module provides a very simple kind of log file, with a very simple
interface. Messages are logged simply by printing to *STDLOG, which the 
module exports to any namespace into which it's loaded.


=head1 INTERFACE 

The entire interface consists of the options that can be passed when the
module is loaded, plus normal C<print> calls via the C<*STDLOG> filehandle.

=head2 Load-time configuration

When loading Log::StdLog, you can pass up to four arguments to the module to
configure it. Those arguments are passed in a single hash:

    use Log::StdLog { file => $filename, level=>$min_level };

Each is described below.

=over 

=item use Log::StdLog { file => $filename };

Normally, Log::StdLog logs messages to a file named C<"$0.log"> (that is, the
current filename with C<.log> appended. But if you pass a C<'file'> option, it
uses that file as its logfile instead.

=item use Log::StdLog { handle => $filehandle };

Instead of specifying the name of the log file using the C<'file'> option, 
you can specify a filehandle to which log messages are written, using the
C<'handle'> option. If you specify both C<'file'> and C<'handle'>, the
C<'handle'> option takes precedence.

=item use Log::StdLog { level => $level_name };

The C<'level'> option specifies the minimum level of message to log, as well
as the default level of message, when a level isn't specified (see below).
The available levels (in decreasing order of severity) are:

    'none'
    'fatal'
    'error'
    'warn'
    'info'
    'user'
    'debug'
    'trace'
    'all'

If the C<'level'> option is used, only those messages whose level is at or
above the specified level will be printed. All other messages will be silently
discarded.

If the C<'level'> option is not specified, the level defaults to C<'user'>.


=item use Log::StdLog { format => $log_formatter };

Normally, log entries are autoformatted like so:

    [YYYYMMDD.HHMMSS] [PID] [LEVEL] Message

but you can change that default by specifying either a subroutine or a string
using the C<'format'> option.

If you specify a subroutine reference as the option's value, that
subroutine is called every time a message is logged, and is passed four
arguments: the date (in YYYYMMDD.HHMMSS format), the current process ID
(C<$$>), the level at which the message was logged, and a list of the
components of the message itself. The subroutine is expected to return the
log text to be printed (I<without> a trailing newline in the text). 

So, for example, to implement a new logging format:

    LEVEL (YYYYMMDD.HHMMSS/PID): Message

you could specify:

    sub new_format {
        my ($date, $pid, $level, @message) = @_

        return "$level ($date/$pid): " . join(q{}, @message);
    }

    use Log::StdLog { format => \&new_format };

Alternatively, you can specify the new logging format as a simple string.
That string will be passed to C<sprintf> and can use C<'%s'> or other escapes
to interpolate the date, pid, level, and message text (which are passed to the
C<sprintf()> call in that order). 

So, for example, to implement a new logging format:

    /YYYYMMDD.HHMMSS/PID/LEVEL/ << Message >>

you could specify:

    use Log::StdLog { format => '/%s/%s/%s/ << %s >>' };

=back


=head2 Logging via C<print>

To write to the log file provided by Log::StdLog, you simple print to the
special filehandle C<*STDLOG>:

    print {*STDLOG} warn => 'Danger, Will Robinson!!!';

The first argument after the filehandle is treated as the severity level of
the log message, and used to determine whether a log entry is actually
generated (depending on the minimum severity level you set when loading the
module). 

If the level is appropriate, then the message is printed (with a newline added
if necessary) to the logfile, in either the format you specified when loading
the module, or the default format (see earlier).

If only a single argument is specified after the filehandle:

    print {*STDLOG} 'Danger, Will Robinson!!!';

then it is treated as a message without an explicit level, and the current
minimum level (default or user-specified) is used. This means that the message
is always printed.

If no argument is specified:

    print {*STDLOG} ();

then the current value of C<$_> is used as the message.

In all cases, the log file is updated atomically, by exclusively locking the
file before the C<print> statement executes. Note that this means a C<print
{*STDLOG}> will block until the file becomes available for writing. Future
versions of this module may employ other synchronization strategies, including
allowing the logging attempt to fail after a timeout.


=head1 DIAGNOSTICS

=over

=item C<< Usage: use Log::StdLog { file=>$filename, level=>$level, format=>sub{...} } >>

You loaded the module, but passed it an argument it didn't understand. The
only argument the module can be passed when it's loaded is a hash reference,
with the keys shown.

=item C<< Unable to open log file '%s' >>

The logfile specified when the module was loaded cannot be opened for
appending. This is usually either a permissions problem or a misspecified
filepath.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Log::StdLog requires no configuration files or environment variables.


=head1 DEPENDENCIES

This module requires the following other modules:

=over

=item *

IO::File

=item *

Fcntl

=item *

version

=back


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-log-stdlog@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Damian Conway C<< <DCONWAY@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


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
