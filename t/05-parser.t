#  -*- perl -*-
#
# Tests the most basic Parser class in Perldoc.
#

use Test::More tests => 3;
use Perldoc::Reader;
use Perldoc::DOM;
use YAML;

BEGIN{ use_ok("Perldoc::Parser"); }

# the base parser class doesn't actually parse anything.  so, we use a
# test parser

BEGIN { use_ok("Perldoc::Parser::XML"); }

my $reader = Perldoc::Reader->new(<<XML);
<?xml version="1.0" encoding="UTF-8"?>
<foo>
  <bar>
    Here are some characters!
  </bar>
</foo>
XML

my $parser = Perldoc::Parser::XML->new(reader => $reader);

my $kwom = Perldoc::DOM->new();

$parser->receiver($kwom);
$parser->send_all();

is_deeply($kwom, Load(<<'YAML'), "test parser worked!")
--- !perl/Perldoc::DOM
root: &1 !perl/Perldoc::DOM::Element
  attr: {}
  attributes: {}
  daughters:
    - !perl/Perldoc::DOM::WS
      attributes: {}
      daughters: []
      mother: *1
      name: ~
      content: "\n  "
    - &2 !perl/Perldoc::DOM::Element
      attr: {}
      attributes: {}
      daughters:
        - !perl/Perldoc::DOM::WS
          attributes: {}
          daughters: []
          mother: *2
          name: ~
          content: "\n    "
        - !perl/Perldoc::DOM::Text
          attributes: {}
          content: Here are some characters!
          daughters: []
          mother: *2
          name: ~
        - !perl/Perldoc::DOM::WS
          attributes: {}
          daughters: []
          mother: *2
          name: ~
          content: "\n  "
      mother: *1
      name: bar
    - !perl/Perldoc::DOM::WS
      attributes: {}
      daughters: []
      mother: *1
      name: ~
      content: "\n"
  mother: ~
  name: foo
YAML
    or diag("Got: ".Dump($kwom));
