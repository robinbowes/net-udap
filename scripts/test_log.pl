#!/usr/bin/env perl

use strict;
use warnings;

use Log::StdLog {
    handle => *STDERR,
    level  => 'debug',
    format => \&std_log_format,
};

my @levels = qw( all trace debug user info warn error fatal none );
my %severity; @severity{@levels} = 1..@levels;

use Data::Dumper;
print Dumper tied *STDLOG;

my $ref = tied *STDLOG;

$ref->{min_severity_name} = 'error';
$ref->{min_severity} = $severity{'error'};

print Dumper tied *STDLOG;


sub log {

    # A wrapper round the Log::StdLog semantics to make logging easier
    # Also, avoids the need to use the complex use statement in
    # all code requiring logging
    print {*STDLOG} (@_);
}

sub std_log_format {
    # a subroutine that Log::StdLog will use  to format log msgs
    my ( $date, $pid, $level, @message ) = @_;
    return "$level: " . join( q{}, @message );
}
