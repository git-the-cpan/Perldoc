
=head1 NAME

Perldoc::EventBuffer - collect streaming API events

=head1 SYNOPSIS

 my $buffer = Perldoc::EventBuffer->new();

 $sender->receiver($buffer);
 $sender->send_all;

 my @events = $buffer->events;

=head1 DESCRIPTION



=cut

package Perldoc::EventBuffer;

use Perldoc::Receiver -Base;
use Perldoc::Sender -Base;
use Perldoc qw(receiver_methods);

#field 'events';

BEGIN {
    no strict 'refs';
    for my $event ( @{( receiver_methods )} ) {
	*$event = sub {
	    my $self = shift;
	    push @{$self->events}, [$event, @_];
	};
    }
}

# DWIM'y array accessor
sub events {
    if ( @_ > 1 ) {
	$self->{events} = [ @_ ];
    } elsif ( @_ == 1 ) {
	my $arg = shift;
	if ( ref $arg ) {
	    $self->{events} = shift;
	} else {
	    return ${ $self->events }[$arg];
	}
    } else {
	if ( wantarray ) {
	    return @{ $self->events };
	} else {
	    return $self->{events} ||= [];
	}
    }
}

sub send_one {
    my $event = shift @{ $self->events };
    $self->send(@$event);
}

1;
