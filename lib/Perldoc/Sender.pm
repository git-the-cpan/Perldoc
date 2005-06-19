
package Perldoc::Sender;

use Perldoc::Base -Base;
use Carp;

=head1 NAME

Perldoc::Sender - a description of how to `send' parse events

=head1 SYNOPSIS

  # get a sender from a sub-class constructor, like a Parser
  my $reader = Perldoc::Reader->new( file => $filename );
  my $sender = Perldoc::Parser->new( reader => $reader );
  my $receiver = Perldoc::DOM->new();

  # either plumb it up first;
  $sender->receiver($receiver);
  $sender->send_all;

  $sender->restart;

  1 while $sender->send_one;

  # or specify the receiver immediately
  $sender->send_all_to($receiver);

  1 while $sender->send_one_to($receiver);

=head1 DESCRIPTION

This class provides utility functions and defines the API for `sending'
Perldoc parse events.

Minimally, all a Sender sub-class has to define is the C<send_one>
method (plus whatever it needs to get the source of information).  It
is up to the sub-class how many events are actually sent; however a
filter could easily marshall these event bursts to single events if
absolutely required.

Senders are always started with the C<send_all> method.

If you use the sub-class API provided in this module, then the events
you send will automatically be correctly balanced.  This does mean
that C<send_one()> might actually send more that one event at a time
as those extra events are inserted into the event stream.

Also, the utility functions provided by this module do not give you a
re-entrant sender.  Even the C<send_all> method cannot be safely used
re-entrantly.  That means you must not try to use the same object in
more than one stream simultaneously; wait for it to finish, you
impatient lout!  :)

Of course, you don't need to use this module to successfully send
events to C<Perldoc::Receiver> classes.  See L<Perldoc::Receiver> for more.

This module requires C<Spiffy>, and uses C<Spiffy> to create accessors
- but does not turn sub-classes of this module into C<Spiffy>
sub-classes.

=head1 METHODS

=over

=item B<receiver($object)>

Sends all events to the specified place.  $object must be a
(C<-E<gt>isa>) Perldoc::Receiver.  Sub-classes should provide this
method.

=cut

field 'receiver';

=item B<send_all([$from])>

This sends all events that this sender can possibly send.  If C<$from>
is passed, the events will appear to come I<from> that object.

=cut

sub send_all {
    1 while $self->send_one(@_);
}

=back

=head2 SUB-CLASS API

=over

=item $self->send_one([$from])

This message asks the sender to send one event.  If C<$from> is
passed, the events will appear to come I<from> that object (this is
important, as only one sender's "send state" can be active at one
time).

=item $self->send($event, @args)

The below method is used by sub-classes of this module to send events
to the receiver.

Sends an event to the configured receiver.

Allowable events are;

=item $self->sendpad([$int])

This method returns a temporary scratch area, which is preserved while
the current parent node remains the same.  As new elements are output,
new scratch areas will be made, and they are closed off, the previous
elements' scratch areas are available.

You may optionally pass C<sendpad()> an integer, which tells it to
look that many levels up, or return an empty hash that is discarded if
you go beyond the "top".

You must have sent at least one element to use C<sendpad()>.

This method is most useful for stream-based filters, that need to
remember small pieces of state at each logical level and output events
accordingly.

=cut

field 'sendstate';

field 'sendpadstack';
field 'sendstack';
our $DEBUG = 0;

use Maptastic;

sub _format {
    my @args = @_;
    return join (", ", map {
	(defined $_
	 ? (ref $_ eq "HASH"
	    ? ("{".(join(", ", map_each {
		$self->_format($_[0]) . " => " .
		    $self->_format($_[1])
		} $_ ))
	       ."}")
	    : (ref $_ eq "ARRAY"
	       ? ( "[".$self->_format(@$_)."]")
	       : (map {
		   s/\\/\\/g; s/\n/\\n/g; s/\r/\\r/g;
		   my $has_quotes = s/'/\'/g;
		   (m/^\d+$/ ? $_ : "'$_'")
	       } $_ )))
	 : "undef")
    } @args );
}


# this is the API that the sender sub-classes use
sub send {
    my $event = shift;

    print STDERR "$self: preparing to emit $event ".$self->_format(@_)." (ss=".($self->sendstate||"pu").")\n" if $DEBUG && $DEBUG > 1;

    $event and $event =~ m/^(?:(?:start|end)_(?:document|element)|characters|processing_instruction|ignorable_whitespace|comment)$/x
	or croak "$self sent bad event `$event'";

    return if $event eq "ignorable_whitespace" and $self->sendstate ne "body";

    if ( $event eq "start_document" and $self->sendstate ) {
	$self->send("end_document");
    }
    if ( $event eq "end_document" and !$self->sendstate ) {
	return undef;
    }

    # check to see if we need to start a document
    $self->send("start_document")
	if ( ! $self->sendstate and $event ne "start_document" );

    $self->send("start_element", "perldoc")
	if ( $self->sendstate and
	     $self->sendstate eq "start" and
	     $event ne "start_element" );

    # check to see if any dummy events are needed
    if ( $event eq "end_element" ) {
	my $stack = $self->sendstack;
	if ( defined(my $name = $_[0]) ) {
	    my $top;
	    croak "can't close unseen element `$name'"
		unless grep { $_ eq $name } @$stack;

	    $self->send("end_element", $top)
		while ( ($top = $stack->[$#$stack]) ne $name );
	} else {
	    shift;
	    unshift @_, $stack->[$#$stack];
	}
    }

    $self->send("end_element", $self->sendstack->[0])
	if ( $event eq "end_document" and
	     $self->sendstack and @{$self->sendstack});

    # ok, enough state sanity - send.
    my $receiver = $self->receiver or croak "no receiver!";
    if ( $event eq "start_element" ) {
	defined(my $name = $_[0])
	    or croak "start_element event with no name";
	push @{ $self->sendstack }, $name;
	push @{ $self->sendpadstack }, undef;
    }

    print STDERR "$self: emitting $event ".$self->_format(@_)."\n" if $DEBUG;
    if ( $receiver->can($event) ) {
	$receiver->$event(@_);
    }
    if ( $event eq "end_element" ) {
	pop @{ $self->sendstack };
	pop @{ $self->sendpadstack };
    }

    # fixme - add more checking...
    my $ss = $self->sendstate;
    if ( ! $ss ) {
	$self->sendstate("start");
	$self->sendstack([]);
	$self->sendpadstack([undef]);
    } elsif ( $ss eq "start" ) {
	$self->sendstate("body");
    } elsif ( $ss eq "body" and !@{ $self->sendstack } ) {
	$self->sendstate("end");
    } elsif ( $ss eq "end" ) {
	$self->restart;
    }

}

sub restart {
    $self->sendstate(undef);
    $self->sendstack(undef);
    $self->sendpadstack(undef);
}

sub sendpad {
    my $num = shift || 0;
    my $aref = $self->sendpadstack;
    my $idx = $#$aref - $num;
    return {} if $idx < 0;
    $aref->[$idx] ||= {};
}

sub final_receiver {
    if ( $self->receiver ) {
	if ( $self->receiver->can("final_target") ) {
	    $self->receiver->final_target;
	} else {
	    $self->receiver;
	}
    } else {
	$self;
    }
}

sub final_sender {
    if ( $self->receiver && $self->receiver->can("final_sender") ) {
	print STDERR "Self is $self, asking ".$self->receiver." for final sender\n";
	$self->receiver->final_sender;
    } else {
	print STDERR "Self is $self, returning ".$self." as final sender\n";
	$self;
    }
}

=over

=item B<start_document({})>

This should start the stream.  pass a hash of options.

=item B<end_document>

=item B<start_element(name, { name => "foo", ...})>

Start a L<POD::DOM::Element>.  C<name> must be set.  Note that the

=item B<end_element(name)>

Close a L<POD::DOM::Element>.  

=item B<characters(text)>

=item B<processing_instruction({})>

=item B<ignorable_whitespace(text)>

=item B<comment>

=back

=cut

1;
