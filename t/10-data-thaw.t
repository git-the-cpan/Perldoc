# -*- perl -*-

# the actual test data for this test is in t/data/03-perldocparser.yaml

use YAML;

use Perldoc::Parser::XML;
use Perldoc::Reader;
use vars qw($testdata $tests);
use lib "t";
use TestClasses;

BEGIN {
    $testdata = YAML::LoadFile("t/data/10-data-thaw.yaml");
    $tests = 2;
    for my $test ( @$testdata ) {
	if ( $test->{yaml} ) {
	    $tests += 2;
	} else {
	    $tests += 1;
	}
    }
}

use Test::More tests => $tests;
use Scriptalicious;
use Maptastic;

BEGIN { use_ok("Perldoc::Data::Thaw") }

my $todata = Perldoc::Data::Thaw->new();
isa_ok($todata, "Perldoc::Data::Thaw", "new Perldoc::Data::Thaw");

my $parser = Perldoc::Parser::XML->new ( receiver => $todata );

my @times;

for my $test ( @$testdata ) {

    local($Perldoc::Data::Thaw::DEBUG) = $test->{debug};
    local($Perldoc::Sender::DEBUG) = $test->{debug};

    $parser->reader(Perldoc::Reader->new($test->{xml}));

    if ( $test->{unsafe} ) {
	$todata->unsafe(1);
    } else {
	$todata->unsafe(0);
    }
	#$parser->set_mapper(eval "sub {
## line 1 \"nowhere.pl\"
#$test->{mapper} }");
    #}

    my $object;

    start_timer;
    eval { $parser->send_all; $object = $todata->object };

    push @times, $test->{name} => show_elapsed;

    if ( $@ ) {
	if ( ! $test->{yaml} ) {
	    pass("`$test->{name}' failed as expected");
	} else {
	    fail("`$test->{name}' failed");
	    diag("exception: $@");
	SKIP:{
		skip "(carried failure)", 1;
	    }
	}
    } else {
	if ( $test->{yaml} ) {
	    pass("`$test->{name}' parsed OK");
	    is_deeply($object, $test->{yaml},
		      "`$test->{name}' parsed to correct structure")
		or diag("full got is:\n",Dump($object),
			"expected:\n",Dump($test->{yaml}));
	} else {
	    fail("`$test->{name}' shouldn't have parsed");
	    diag("parsed to: ".Dump($object));
	}
    }
}

my $c = 1;
diag("Times:\n",
     (map_each(sub { sprintf("%5d  %8s %s\n", $c++, $_[1], $_[0]) },
	       { @times })));
