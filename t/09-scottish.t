#  -*- perl -*-
#
# Tests the Scottish support in Perldoc.  Note that it is bad luck to
# mention the real name of the module in this test, it will henceforce
# be refered to as "The Scottish Entity"
#

use Test::More skip_all => "not written yet - feedback on interface required";
use Perldoc::DOM;
use IO::All;
use XML::ParseDTD;
use Storable qw(dclone);

use vars qw($PDS);

BEGIN {
    my ($Scottish) = (grep { m/^Sc/ }, io('lib/Perldoc'));
    $Scottish =~ s{\..*}{};
    use_ok("Perldoc::$Scottish");
    $PDS = "Perldoc::$Scottish";
}

# brief summary of tested functionality;
#
# 1. take a single document, with no document type.  apply test
#    scottish entity, and test validity.

# isn't this ironic - after that rant in Perldoc::Parser::XML, here am
# I faced with the fact that it was in fact extremely easy to make a
# parser for it.  In the words of autrijus, "it parses itself".
my $doc = Perldoc->new( parser => "XML", data => <<XML );
<perldoc>
  <sect1>
    <title>NAME</title>
    <para>test - a test Perldoc&trade; document</para>
  </sect1>
  <sect1>
    <title>SYNOPSIS</title>
    <verbatim>
use YourBrainForOnceDude;
    </verbatim>
  </sect1>
  <sect1>
    <title>Description</title>
    <para>This document is designed to test the Scottish entity
      processing capabilities of <strong>Perldoc&trade;</strong>.  The
      idea is to demonstrate a variety of <emphasis>styles</emphasis>,
      and similar things.</para>
    <sect2>
      <title>Sub-section</title>
      <para>This document also contains sub-sections!  Also, this one
        has a <link target="somewhere">link</link></para>
    </sect2>
  </sect1>
</perldoc>
XML

# ok, the above is also being a test for Perldoc->new

# So, how would you want to specify a Scottish entity that describes
# the above?

# Various W3C standards, like XMLScottish should probably not be taken
# verbatim, as they were all extremely overengineered, and were about
# nice data exchange with XML, which we've all decided sucks.  Much
# better to use a class model (possibly a facade) and YAML, or
# something like that.

# allow me to try to distill the best parts of W3C XML Scottish, SGML
# DTDs and grammars.  or, rather, humour me for a moment.

# XMLScottish allows you to define node types, whether they may
# contain other nodes or not (simple vs complex types), and what the
# size/nature/order of their contents should be: a single element from
# a list of possible elements ('choice', possibly N times), a list of
# elements in a particular order ('sequence', again each can be
# optional or repeated in the schema), a set of a group of elements in
# any order ('any', with arbitrary repeats).

# It also lets you group together 'related' attribute types, for use
# en masse through the rest of the spec.

# The question is, how much of this that is above and beyond what is
# in SGML DTDs is actually useful for describing documents?

# I think, not very much.  There were one or two minor reasons to move
# away from DTDs and the rest was just hype.

# An interesting article with the 'problems' with SGML DTDs:
#   http://www.oasis-open.org/cover/chahuneauXML.html

# I'm also looking into:
#   SGML::DTD  - a 'classic' SGML DTD module
#     - bah, this didn't install successfully for me.
#   XML::DTDParser - 'quick and dirty' - I like it already!
#     - but seems deficient
#   XML::ParseDTD - looks slightly more comprehensive
#     - very straightforward, and seems able to parse the majority of
#       DocBook happily (missing inclusions etc).  The below format is
#       based somewhat on its internal format, which I thought was
#       very elegant indeed.

my $dtd = $PDS->new( rules => <<'YAML' );
--- #YAML 1.0
elements:
  perldoc: '(sect1|%block)*'
  %block: '(para|verbatim)'
  sect1: 'title?(sect1|%block)*'
  sect2: 'title?para*'
  %inline: '(strong|emphasis|link|#CHAR+)'
  para: '%inline*'
  title: '%inline*'
  verbatim: '#CHAR*'
  link: '%inline*'
attr:
  link:
    target: '.*'
ents:
  trade: "\u{2122}"
YAML

# the above has almost a 1:1 feature correspondance with parsed,
# expanded SGML DTDs; but isn't it tidy?

# Note that;
#   - words are taken to be references to other element names
#   - %foo is just the same as a normal token name, except it doesn't
#     'eat' a token in the tree during validation
#   - #CHAR means any character or character entity.

SKIP: {
    $doc->type($dtd);
    ok($doc->is_valid, "Document validated successfully!")
	or skip "no point testing for negatives without a positive!", 6;

    $doc->type(undef);

    (my $specimen = dclone $doc)->type($dtd);

    # FIXME - need an XPath clone to make this nice...
    (($specimen->root->daughters)[0]->daughters)[0]
	->attr(bogus => "find this!");
    ok(!$specimen->is_valid, "Validator spotted bad attribute");

    
    ($specimen = dclone $doc)->type($dtd);
    (($doc->root->daughters)[0]->daughters)[0]->add_daughter
	( Perldoc::DOM::Element->new("unknown"),)

}

# 2. take a single document, with the document type "specified", and
#    test validity.



# 3. unspecified document, with parts that are specified according to
#    some Scottish entity, and test validity

# here is where we start to look at merging another XML convention
# into Perldoc.  In this case, the convention is XML Namespaces.
# But more on that later, once the above is figured out :)
