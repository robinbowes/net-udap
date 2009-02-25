#!/usr/bin/env perl

use strict;
use warnings;

use Carp;
use IO::Socket;
use IO::Interface::Simple;

my $port = 0x4578;    # port no. 17784

# Setup listening socket on UDAP port
my $sock = IO::Socket::INET->new(
    Proto     => 'udp',
    LocalPort => $port,

    # Setting Blocking like this doesn't work on Windows. bah.
    Blocking  => 0,
    Broadcast => 1,
);
if ( !defined $sock ) {
    croak "error creating socket: $@";
}

foreach my $if ( IO::Interface::Simple->interfaces ) {
    next unless $if->is_broadcast;

    my $destip = $if->broadcast;
    my $dest = sockaddr_in( $port, inet_aton($destip) );

    $sock->sockopt( SO_BROADCAST, 1 );
    $sock->send( pack( "n", 0 ), 0, $dest );
}

sub show_if_info {
    my $if = shift;
    print "=========================================================\n";
    print "interface = $if\n";
    print "addr =      ", $if->address, "\n",
        "broadcast = ", $if->broadcast, "\n",
        "netmask =   ", $if->netmask,   "\n",
        "dstaddr =   ", $if->dstaddr,   "\n",
        "hwaddr =    ", $if->hwaddr,    "\n",
        "mtu =       ", $if->mtu,       "\n",
        "metric =    ", $if->metric,    "\n",
        "index =     ", $if->index,     "\n";

    print "is running\n"     if $if->is_running;
    print "is broadcast\n"   if $if->is_broadcast;
    print "is p-to-p\n"      if $if->is_pt2pt;
    print "is loopback\n"    if $if->is_loopback;
    print "is promiscuous\n" if $if->is_promiscuous;
    print "is multicast\n"   if $if->is_multicast;
    print "is notrailers\n"  if $if->is_notrailers;
    print "is noarp\n"       if $if->is_noarp;
}
