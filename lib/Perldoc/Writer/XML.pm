
package Perldoc::Writer::XML;

use Perl6::Junction qw(any);
use Perldoc::Writer -Base;
use Maptastic;

field "depth";
field "no_indent";
field "just_left_compact";
field "last";

sub start_document {
    $self->write("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n");
    $self->last("");
}

sub start_element {
    my $tagName = shift;
    my $attrs = shift;
    my $string = ("<".join(" ", xml_check_tag($tagName), ($attrs ? ( map_each { xml_check_attr($_[0])."='".xml_escape_single($_[1])."'" } $attrs ) : () ) ));
    $self->write(">") if $self->last eq "start";
    $self->indent;
    $self->write($string);
    $self->depth(($self->depth||0)+1);
    $self->last("start");
}

sub end_element {
    my $tagName = shift;
    $self->depth($self->depth-1);
    my $last = $self->last;
    if ( $last eq "start") {
	$self->write("/>");
    } else {
	$self->indent if $self->last eq any("end", "pi");
	$self->write("</$tagName>");
    }
    $self->depth(undef) if $self->depth == 0;
    $self->last("end");
}

sub characters {
    my $chars = shift;
    $self->write(">") if $self->last eq "start";
    $self->write(xml_escape_ent($chars));
    $self->last("chars");
}

sub processing_instruction {
    my $name = shift;
    my $attrs = shift;
    if ( $name eq "perldoc" ) {
	# that's us!
	while ( my ($attr, $value) = each %$attrs ) {
	    if ( $attr eq "whitespace" ) {
		if ( $value eq "compact" ) {
		    $self->no_indent(1);
		}
		else {
		    $self->no_indent(0);
		    $self->just_left_compact(1);
		}
	    }
	}
    } else {
	my $string = ("<?".join(" ", $name, ($attrs ? ( map_each { "$_[0]='".$_[1]."'" } $attrs ) : () ) )."?>");
	$self->write(">") if $self->last eq "start";
	$self->indent;
	$self->write($string);
	$self->last("pi");
    }

}

sub indent {
    if ( defined($self->depth) and (! $self->no_indent or $self->just_left_compact) ) {
	$self->write("\n".("  " x $self->depth));
    }
    $self->just_left_compact(0);
}

sub end_document {
    die "end of document, but document unbalanced"
	unless $self->last eq any("end", "pi");
    $self->write("\n") unless $self->no_indent;
}

sub xml_check_tag
{
    my $x = $self;
    die "bad tag name: `$x'" unless $x =~ m/^(?:\w+:)?\w+$/;
    $x;
}

sub xml_check_attr
{
    my $x = $self;
    die "bad attribute name: `$x'" unless $x =~ m/^(?:\w+:)?\w+$/;
    $x;
}

our %ent = qw(& amp < lt > gt ' quot);

sub xml_escape_single
{
    my $x = $self;
    $x =~ s{[&']}{&$ent{$1};}g;
    $x;
}

sub xml_escape_ent
{
    my $x = $self;
    $x =~ s{[&<>]}{&$ent{$1};}g;
    $x;
}

1;

