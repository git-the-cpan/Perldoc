
package Perldoc::Writer::XML;

use Perldoc::Writer -Base;
use Maptastic;

field "depth";
field "no_indent";

sub start_element {
    my $tagName = shift;
    my $attrs = shift;
    my $string = ("<".join(" ", $tagName, ($attrs ? ( map_each { "$_[0]='".$_[1]."'" } $attrs ) : () ) ).">");
    $self->indent;
    $self->write($string);
    $self->depth(($self->depth||0)+1);
}

sub end_element {
    my $tagName = shift;
    $self->depth($self->depth-1);
    $self->indent;
    $self->write("</$tagName>");
    $self->depth(undef) if $self->depth == 0;
}

sub characters {
    my $chars = shift;
    $self->write($chars);
}

sub indent {
    if ( defined($self->depth) and ! $self->no_indent ) {
	$self->write("\n".("  " x $self->depth));
    }
}

1;
