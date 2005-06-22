#  -*- perl -*-
#

# Tests the Linking support to points within Perldoc.  Based in
# concept and style from XPath, but with some classic POD L<...>
# syntax thrown in for good measure

use Test::More skip_all => "not written yet - feedback on interface required";
use Perldoc;

my $doc = Perldoc->new( parser => "XML", data => <<XML );
<foo>
  <bar>
    <baz id="one" />
  </bar>
  <bar attr="frop">
    <baz id="two" />
  </bar>
</foo>
XML

sub test_lookup {
    my ($doc, $path, $wanted) = @_;

    my @nodes = $doc->lookup($path);

    is_deeply( [ map { $_->attr("id") || "<".$_->name.">" } @nodes ],
	       $wanted, "lookup - q{$path}");

}

# Plink queries
test_lookup($doc, "/foo/bar/baz", [ qw(one two) ]);
test_lookup($doc, "/foo/bar[1]/baz", [ qw(two) ]);
test_lookup($doc, "//baz", [ qw(one two) ]);
test_lookup($doc, "//baz[id='one']", [ qw(one) ]);
test_lookup($doc, "//bar[attr='frop']/baz", [ qw(two) ]);

# a couple of corner cases...
test_lookup($doc, "//bar[attr='']/baz", [ ]);
test_lookup($doc, "//bar[!attr]/baz", [ qw(one) ]);
test_lookup($doc, "//bar[attr ~ 'f.*']/baz", [ qw(two) ]);

# We'd expect the following to work in Perl 6:

#  1. retrieve all "test" nodes via the DOM object
#     $*POD->lookup("//test");
#
#  2. retrieve a named section
#     %*POD<section>
#

# so, xpath is great, as many have found.  But how does it relate to
# good old POD links?

#  you might recall the following forms:
#    L<perldocpage>
#    L<manpage(N)>
#    L<name/section>
#    L</section>
#
#  and maybe these modern variants were news to you too:
#    L<linktext|anyoftheabove>
#
#  and of course this general one:
#    L<http://www.rotten.com>

# for instance, using the example document in test 6, you would write
# a link to a heading as:
#
#    L<//head2[title/%pcdata="sectionname"]>
#
# or something like that (I don't have the spec handy) But that would
# suck.

# This could be worked around by:
#
#  1. requiring that relevant anchors be added by the dialect parser
#     (eg, normal POD would put them in for headings).
#
#  2. making them visibly distinct, to differentiate between XPath
#     style links; making them more HTML-style:
#        L<#section>
#
#  or
#
#  2. Using another character for XPath-style links, like "="
#
#  or
#
#  3. Using a different link syntax, like X<> for XLinks
#
# Then, traditional POD links and newer XLink-style linking could
# co-exist quite happily.
#


