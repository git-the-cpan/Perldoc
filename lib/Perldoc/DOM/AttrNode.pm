
=head1 NAME

Perldoc::DOM::AttrNode - nodes with name and attributes in a Perldoc::DOM tree

=head1 SYNOPSIS

See L<Perldoc::DOM::Node>.

=head1 DESCRIPTION

An abstract node that provides the `name' and `attr' properties.
Currently only C<Perldoc::DOM::Element> and C<Perldoc::DOM::PI> derive
from this class.

All meta-information provided by dialects should be stored in this
tree as an attribute.  The property C<attr> is used for this.

=cut

package Perldoc::DOM::AttrNode;
use Perldoc::DOM::Node -Base;

# is there a Spiffy field way to do this?
sub attr {
    if ( @_ ) {
	if ( defined(my $attr = shift) ) {
	    if ( ref $attr eq "HASH" ) {
		$self->{attr} = $attr;
	    } else {
		if ( @_ ) {
		    if ( defined( my $value = shift ) ) {
			$self->{attr}{$attr} = $value;
		    } else {
			delete $self->{attr}{$attr};
		    }
		} else {
		    return $self->{attr}{$attr};
		}
	    }
	} else {
	    delete $self->{attr};
	}
    } else {
	return $self->{attr};
    }
}

sub _init {
    my $o = shift;

    $self->attr($o->{attr}||{});
    super($o);
}

sub dom_attr {
    my $att = super() or die;
    (%{$att}) = (%$att, %{$self->attr});
    $att;
}

1;
