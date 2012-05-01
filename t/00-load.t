#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Template::Plain' ) || print "Bail out!
";
}

diag( "Testing Template::Plain $Template::Plain::VERSION, Perl $], $^X" );
