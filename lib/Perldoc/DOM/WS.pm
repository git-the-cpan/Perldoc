package Perldoc::DOM::WS;

use Carp;
use Perldoc::DOM::Node -Base;

=head1 NAME

Perldoc::DOM::WS - ignorable whitespace in a Perldoc::DOM tree

=head1 SYNOPSIS

See L<Perldoc::DOM::Node>.

=head1 DESCRIPTION

Sometimes you need to put in a little whitespace to fill an XML
document.  This node type is for that.

=head2 SUB-CLASS PROPERTIES

This node type keeps the C<source> property, and adds C<content>,
which is the whitespace to be represented in the normative XML.

=cut

sub _init {
    my $o = shift;
    $self->content($o->{content}) if exists $o->{content};
    super($o);
}

sub new {
    #print STDERR "WS: new with '$_[0]'\n";
    if ( ref $_[0] ) {
	super(@_);
    } else {
	my $text = shift;
	my $o = shift || {};
	$o->{content} = $text;
	super($o);
    }
}

sub content {
    if ( @_ ) {
	# FIXME - unicode :)
	my $content = shift;
	$content =~ /\S/
	    && croak "tried to put non-whitespace in a whitespace node";
	$self->{content} = $content;
    } else {
	$self->{content};
    }
}

sub dom_fields {
    super, qw(content);
}

sub event_type {
    "ignorable_whitespace"
}

1;
