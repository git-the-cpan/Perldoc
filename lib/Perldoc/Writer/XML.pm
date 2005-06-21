
package Perldoc::Writer::XML;

use Perldoc::Writer -Base;
use Maptastic;

field "depth";
field "no_indent";
field "last";

sub start_document {
    $self->write("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n");
    $self->last("");
}

sub start_element {
    my $tagName = shift;
    my $attrs = shift;
    my $string = ("<".join(" ", $tagName, ($attrs ? ( map_each { "$_[0]='".$_[1]."'" } $attrs ) : () ) ));
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
	$self->indent if $self->last eq "end";
	$self->write("</$tagName>");
    }
    $self->depth(undef) if $self->depth == 0;
    $self->last("end");
}

sub characters {
    my $chars = shift;
    $self->write(">") if $self->last eq "start";
    $self->write($chars);
    $self->last("chars");
}

sub indent {
    if ( defined($self->depth) and ! $self->no_indent ) {
	$self->write("\n".("  " x $self->depth));
    }
}

sub end_document {
    die "end of document, but document unbalanced"
	unless $self->last eq "end";
    $self->write("\n");
}

1;
