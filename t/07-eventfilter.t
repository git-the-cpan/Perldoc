#!perl
#
#  test some simple event filters
#
use Test::More tests => 8;

# test buffering and null filtering
BEGIN {
    use_ok("Perldoc");
    use_ok("Perldoc::EventBuffer");
}
my $doc = Perldoc->new( type => "XML", input => "t/data/test.xml" );

# if you only want to parse once, uncomment this
# $doc->to_dom;

my $buffer1 = Perldoc::EventBuffer->new();
isa_ok($buffer1, "Perldoc::EventBuffer", "Perldoc::EventBuffer->new()");
$doc->receiver($buffer1);
$doc->send_all;

is(scalar @{$buffer1->events}, 69,
   "Perldoc::EventBuffer catches events");

#use YAML;
#diag(YAML::Dump([$buffer1->events]));

my $buffer2 = Perldoc::EventBuffer->new();

use_ok("Perldoc::Filter");
my $filter = Perldoc::Filter->new(receiver => $buffer2);
isa_ok($filter, "Perldoc::Filter", "Perldoc::Filter->new()");

$doc->restart;
$doc->receiver($filter);
$doc->send_all;

is(scalar @{$buffer2->events}, 69, "Perldoc::Filter transmits events");
is_deeply($buffer1, $buffer2, "Filter passes through events OK");



