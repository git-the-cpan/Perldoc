#  -*- perl -*-
#
# Tests building documents in one step
#

use Test::More tests => 4;
use Storable qw(nstore);

BEGIN {
    use_ok("Perldoc");
}

# isn't this ironic - after that rant in Perldoc::Parser::XML, here am
# I faced with the fact that it was in fact extremely easy to make a
# parser for it.  In the words of autrijus, "it parses itself".
my $doc = Perldoc->new( type => "XML", input => "t/data/test.xml" );
isa_ok($doc, "Perldoc", "Perldoc->new");

# ah, you might be saying - but what state is the above it, shouldn't
# it have been a constructor on Perldoc::DOM?

# well, it isn't actually a DOM yet.  It's a Perldoc document.  such
# an entity doesn't even have a form or a state, but that doesn't
# matter, because you can easily get a dom tree out of it;

my $dom = $doc->to_dom;

# perhaps it was not until you did that that Perldoc actually cranked
# up its reader.  I guess you'll never know, unless you read the
# source.  But who cares, anyway?  :)
isa_ok($dom, "Perldoc::DOM", "Perldoc->dom");

isa_ok($doc->root, "Perldoc::DOM::Node", "Perldoc->root");


