
package AnotherTestClass;

use overload '""' => sub { 'Bill' }, fallback => 1;

package TestChunks;

use strict;
use warnings;

use Test::Base -Base;

our $direction;

our @EXPORT = qw($direction);

package TestChunks::Filter;
use Test::Base::Filter -Base;
    use YAML;

sub yaml {
    my $what = shift;
    # perhaps not the best test
    my $rv;
    my $doing;
    eval {
	if ( ref $what ) {
	    $doing = "Dump";
	    $rv = YAML::Dump($what);
	} else {
	    $doing = "Load";
	    # pamper input for YAML::Load
	    $what .= "\n" unless substr($what, -1) eq "\n";
	    $rv = YAML::Load($what);
	}
    };
    TestChunks::diag("Whoops! error $doing $what; $@"), die if $@;
    return $rv;
}

sub yaml_data {
    my $data = Load ((shift)."\n");
    if ( $TestChunks::direction eq "document" ) {
	return Dump $data;
    } else {
	return $data;
    }
}

sub yaml_document {
    my $document = shift;
    if ( $TestChunks::direction eq "document" ) {
	return $document;
    } else {
	return Load $document;
    }
}

sub trim {
    return $_[0] if ref $_[0];
    my $string = shift;
    $string =~ s{\A\s+}{}s;
    $string =~ s{\s+\Z}{}s;
    $string;
}

sub chill {
    require Perldoc::Data::Chill;
    my $item = shift;

    return $item if $TestChunks::direction eq "data";

    my $chiller = Perldoc::Data::Chill->new(source => $item);

    return $chiller;
}

use Scalar::Util qw(blessed);

sub xml {
    my $item = shift;

    if ( blessed $item ) {
	# going TO XML
	return $item if $TestChunks::direction eq "data";
	require Perldoc::Writer::XML;
	my $doc;
	my $writer = Perldoc::Writer::XML->new( output => \$doc );
	$item->receiver($writer);

	$item->send_all;
	return $doc;

    } else {
	return $item if $TestChunks::direction eq "document";
	# going FROM XML
	require Perldoc::Reader;
	require Perldoc::Parser::XML;

	my $reader = Perldoc::Reader->new(input => $item);

	return Perldoc::Parser::XML->new( reader => $reader );
    }
}

sub thaw {
    my $item = shift;
    return $item if $TestChunks::direction eq "document";

    if ( blessed $item and $item->isa("Perldoc::Sender") ) {
	require Perldoc::Data::Thaw;
	# hmmm ... no way of passing in options?
	my $thawer = Perldoc::Data::Thaw->new( unsafe => 1 );

	$item->receiver($thawer);
	$item->send_all;

	return $thawer;
    }

}


1;


