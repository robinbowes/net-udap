use Test::More tests => 5;

BEGIN {
use_ok( 'Net::UDAP' );
use_ok( 'Net::UDAP::Util' );
use_ok( 'Net::UDAP::Constant' );
use_ok( 'Net::UDAP::Message' );
use_ok( 'Net::UDAP::Client' );
}

diag( "Testing Net::UDAP $Net::UDAP::VERSION" );
