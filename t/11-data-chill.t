#  -*- perl -*-

use strict;
use warnings;

use YAML;
use Test::More tests => 5;

use Perldoc::EventBuffer;

BEGIN { use_ok("Perldoc::Data::Chill"); }

my $structure = Load <<YAML;
 some:
  big:
   - data
   - structure
  with:
   - lots
   - ~
   - of
   - stuff
 and: more
YAML

my $eb = Perldoc::EventBuffer->new;

my $chiller = Perldoc::Data::Chill->new
    ( source => $structure,
      receiver => $eb
    );

isa_ok($chiller, "Perldoc::Data::Chill", "new P::D::Chill");

$chiller->send_all;

is_deeply(scalar $eb->events, Load(<<YAML), "got right events out");
- [ start_document ]
- [ start_element, Hash ]
- [ start_element, item, { name: and }]
- [ characters, more ]
- [ end_element, item ]
- [ start_element, item, { name: some }]
- [ start_element, item, { name: big }]
- [ start_element, item ]
- [ characters, data ]
- [ end_element, item ]
- [ start_element, item ]
- [ characters, structure ]
- [ end_element, item ]
- [ end_element, item ]
- [ start_element, item, { name: with }]
- [ start_element, item, ]
- [ characters, lots ]
- [ end_element, item ]
- [ start_element, item ]
- [ end_element, item ]
- [ start_element, item ]
- [ characters, of ]
- [ end_element, item ]
- [ start_element, item ]
- [ characters, stuff ]
- [ end_element, item ]
- [ end_element, item ]
- [ end_element, item ]
- [ end_element, Hash ]
- [ end_document ]
YAML

# may as well test the XML writer too
use_ok("Perldoc::Writer::XML");

my $writer = Perldoc::Writer::XML->new();

$eb->receiver($writer);
$eb->send_all;

my $io = $writer->output;
$io->seek(0,0);
my $doc = $io->slurp;

my $wanted = <<XML;
<?xml version="1.0" encoding="utf-8"?>
<Hash>
  <item name='and'>more</item>
  <item name='some'>
    <item name='big'>
      <item>data</item>
      <item>structure</item>
    </item>
    <item name='with'>
      <item>lots</item>
      <item/>
      <item>of</item>
      <item>stuff</item>
    </item>
  </item>
</Hash>
XML

use IO::All;
if ( $doc ne $wanted ) {
    fail "didn't get what we wanted.";
    io("/tmp/wanted.$$")->assert->print($wanted);
    io("/tmp/got.$$")->assert->print($doc);
    my $diffs = `diff -wu /tmp/wanted.$$ /tmp/got.$$`;
    if ( !$? ) {
	$diffs = `diff -u /tmp/wanted.$$ /tmp/got.$$`;
    }
    diag("#### DIFFS: ####");
    diag($diffs);
    unlink("/tmp/wanted.$$","/tmp/got.$$");
} else {
    pass "output XML doc matched.";
}

