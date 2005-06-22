package Perldoc::Data::Thaw;

# this is a class that takes perldoc events and converts them to
# a data structure.

use strict;
use warnings;

use Carp;
use YAML;
use Maptastic;

use Perldoc::Receiver -Base;

our $DEBUG = 0;

sub DEBUG { $DEBUG }

# the "classmap" is a mapping from a tag name to a class name.
# tags must be present in this hash to become objects.
field "classmap";

sub _init {
    $self->classmap({}) unless $self->classmap;
}

# an alternative to explicitly listing every possible final tag name
# with its namespace and the corresponding Perl class is to use a
# Scottish.
field "scottish";

# allow unmarshalled classes
field "unsafe";

# a state var; whether getting characters now fits the model or
# not.
field 'chars_ok';

# we construct a stack that contains the objects to be created first
# on top
field 'stack' => undef;

# the final target of the constructor stack
field 'object' => undef;

sub start_document {
    print STDERR "$self: reset\n" if DEBUG;
    $self->reset;
}

sub reset {
    #$self->SUPER::reset;
    $self->stack([
		  # target stack
		  [ \($self->{object}=undef) ],

		  # constructor/properties stack
		  [ ],

		  # type stack
		  [ "!top" ],
		 ]);
}

# this mapper is used to determine what to do with a particular node.
# I started out making this the interface to customise the thaw
# process, then decided that transforming events was the more sensible
# option.

# this is still pretty flexible, and can be customised by setting a
# scottish, which is expected to respond to the "element_class"
# method.  To handle mixed documents, the Scottish object might be a
# proxy object for several Scottish objects that are in effect in the
# document.

sub mapper {
    my $node_name = shift;
    my $last_was = shift;

    my @rv = do {
	# unadorned "item" tags aren't objects...
	if ( $node_name eq "item" ) {
	    if ( @_ ) {
		die "incorrect number of attributes for hash item"
		    if @_ != 2;
		"!hash_element", $_[1];
	    } else {
		"!array_element";
	    }
	} elsif ( $last_was and $last_was !~ /^!/ ) {
	    "!property";
	} else {

	    my $cm;
	    if ( $cm = $self->classmap and $cm->{$node_name} ) {
		$cm->{$node_name}, "new";
	    }
	    elsif ( $self->scottish
		    and $self->scottish->can("element_class") ) {

		# the scottish is passed the node_name and resolves it
		# to a class
		my $ns = $self->scottish->element_class($node_name)
		    or die("Scottish couldn't resolve or rejected "
			   ."'$node_name'");

		$self->classmap->{$node_name} = $ns;

		($ns, "new");
	    }
	    elsif ( $self->unsafe ) {
		die "Unsafe mode, but no such function $node_name->new"
		    unless UNIVERSAL::can($node_name, "new");
		($node_name, "new");

	    }
	    else {
		# er, no.  We'll die here :)
		die "don't know what to do with $node_name";
	    }
	}
    };

    print STDERR "  Mapper for $node_name(last: $last_was) => @rv\n"
	if DEBUG;
    return @rv;

}

# There's still a lot of debugging in this code.  If you find yourself
# debugging this, and end up altering the debug output to make more
# sense to you, please send a patch in; such improvements do make the
# module better for everyone.

sub start_element {
    my ($el, $attributes) = @_;

    my @attributes = %{$attributes||{}};

    print STDERR "<$el".(@attributes
			 ? (" $attributes[0]='$attributes[1]'"
			    .(@attributes > 2 ?
			      " ..." : "") )
			 :"")
	.">\n" if DEBUG;

    # these "cursors" to the head of the construction stack allows
    # altering the resultant representation state... there is a single
    # stack of "Targets", "Constructor lists" and "types"

    my ($TS, $CS, $types) = @{ $self->stack };

    my %sizes;
    if (DEBUG) {
	print STDERR "TYPES: ".join(",", @$types)."\n";

	(%sizes) = ( TS    => scalar(@$TS),
		     CS    => scalar(@$CS),
		     types => scalar(@$types),
		   );
    }

    # the "target" stack contains references of where the constructed
    # objects are to end up
    my $topTarget = $TS->[$#$TS];

    # the "constructor" stack contains a list, that will be "Class",
    # "method", @list, this list will be "executed" as the stack is
    # popped off
    my $topCS = $CS->[$#$CS];
    $sizes{topCS} = (ref $topCS ? @$topCS : undef);

    # the "types" stack is just the return values of the mapper, used
    # to provide the "last_type" variable.
    my $last_type = $types->[$#$types];
    my ($type, @extra) = $self->mapper($el, $last_type, @attributes);
    push @$types, $type;

    #print STDERR "   mapper(): $el => $type (last was $last_type)\n"
	#if DEBUG;

    print STDERR "   action: $type".(@extra?" (@extra)":"")."\n"
	if DEBUG;

    if ( $type eq "!hash_element" ) {

	# the return "hash_element" means that we have an item in a
	# hash, or else this node starts a new hash.

	unless ( ref $$topTarget eq "HASH" ) {
	    print STDERR "   new collection (hash)\n" if DEBUG;
	    warn "clobbering `$$topTarget' with a hash"
		if ($$topTarget and
		    (ref $$topTarget
		     or $$topTarget =~ /\S/));
	    $$topTarget = {};
	}
	#kill 2, $$;
	print STDERR "   item: push TS, \( topTarget->{$extra[0]} )\n"
	    if DEBUG;
	push @$CS, "dummy";
	push @$TS, \(${$topTarget}->{$extra[0]} = undef);
	$self->chars_ok(1);
    }
    elsif ( $type eq "!array_element" ) {

	# the return "array_parent" means that we have an item in an
	# array, or else this node starts a new array.

	unless ( ref $$topTarget eq "ARRAY" ) {
	    print STDERR "   new collection (array)\n" if DEBUG;
	    warn "clobbering `$$topTarget' with an array"
		if ($$topTarget and
		    (ref $$topTarget
		     or $$topTarget =~ /\S/));
	    $$topTarget = [];
	}
	push @$CS, "dummy";
	#kill 2, $$;
	my $c = $#{$$topTarget}+1;
	print STDERR "   item: push TS, \( topTarget->[$c] )\n" if DEBUG;
	push @$TS, \(${$topTarget}->[$c] = undef);
	$self->chars_ok(1);
    }

    elsif ( $type eq "Hash" ) {

	# the return "hash" means that this node starts a normal hash
	# collection.
	warn "clobbering `$$topTarget' with a hash"
	    if ($$topTarget and
		(ref $$topTarget
		 or $$topTarget =~ /\S/));
	push @$TS,undef;
	push @$CS,{};
	#$$topTarget = \@$CS{};

    }
    elsif ( $type eq "Array" ) {

	# the return "array" means that this node starts a normal array
	# collection.
	warn "clobbering `$$topTarget' with an array"
	    if ($$topTarget and
		(ref $$topTarget
		 or $$topTarget =~ /\S/));
	$$topTarget = [];
	push @$TS,\($$topTarget->[0]);
	push @$CS,"array";

    }
    elsif ( $type eq "!property" ) {

	my $property = shift @extra || $el;

	if ( !ref $$topTarget or ref $$topTarget !~ /^(HASH|ARRAY)$/ ) {

	    #kill 2, $$;
	    print STDERR "   property: push topCS, $property => undef\n"
		if DEBUG;
	    push(@$topCS, $property, undef);
	    print STDERR "   item: push TS, \(that undef)\n" if DEBUG;
	    push @$CS, "dummy";
	    push @$TS, \($topCS->[$#$topCS]);
	    $self->chars_ok(1);

	} else {

	    # just stick the values into a hash/array
	    if ( ref $$topTarget eq "HASH" ) {
		$$topTarget->{$extra[0]} = $extra[1];
	    }
	    elsif ( ref $$topTarget eq "ARRAY" ) {
		push @{$$topTarget}, $extra[0];
	    }

	}
    }

    elsif ( defined $type ) {

	# object constructor
	print STDERR "   object: $type->$extra[0](@...[0..$#attributes])\n" if DEBUG;
	push @$CS, [ $type, $extra[0], @attributes ];
	push @$TS, $topTarget;
	$self->chars_ok(0);

    }

    if ( DEBUG and DEBUG > 2 ) {
	print STDERR "the lot: ".YAML::Dump($self->stack)."...\n";
    }
    elsif ( DEBUG and DEBUG > 1 ) {
	my %new;
	if ( @$TS != $sizes{TS} ) {
	    my $i = $sizes{TS};
	    $new{TS} = [ map { $i++ => \$_ }
			 @$TS[$sizes{TS}..$#$TS] ];
	}
	if ( @$CS != $sizes{CS} ) {
	    my $i = $sizes{CS};
	    $new{CS} = [ map { $i++ => \$_ }
			 @$CS[$sizes{CS}..$#$CS] ];
	}
	if ( ref $topCS and @$topCS != $sizes{topCS} ) {
	    my $i = $sizes{topCS};
	    $new{topCS} = [ map { $i++ => \$_ }
			    @$topCS[$sizes{topCS}..$#$topCS] ];
	}
	if ( @$types != $sizes{types} ) {
	    my $i = $sizes{types};
	    $new{types} = [ map { $i++ => $_ }
			   @$types[$sizes{types}..$#$types] ];
	}
	if ( keys %new ) {
	    my $text = YAML::Dump(\%new);
	    $text =~ s{^}{      }mg;
	    print STDERR "   pushed:\n$text";
	}
	else {
	    print STDERR "   no action\n";
	}
    } elsif ( DEBUG ) {
	print STDERR "   (TS: ".@$TS.", CS: ".@$CS.", types: ".@$types.")\n" if DEBUG;
    }
}

sub characters {
    my ($char) = @_;

    defined $char or confess "? undef characters event!";

    if (DEBUG) {
	(my $disp = $char) =~ s{\n}{\\n}sg;
	print STDERR "`$disp'\n";
    }

    if (!$self->chars_ok) {
	if ($char =~ /\S/s) {
	    warn "character data in bad place";
	    print STDERR "   ignoring\n" if DEBUG;
	} else {
	    print STDERR "   blank\n" if DEBUG;
	}
	return;
    }

    my ($TS, $CS, $types) = @{ $self->stack };
    my $topTarget = $TS->[$#$TS];
    my $topCS = $CS->[$#$CS];

    my $ws = ($char =~ /\S/ ? "" : " (all whitespace)");

    if ( defined $$topTarget and !ref $$topTarget ) {
	print STDERR "   appending: ".length($char)." char(s)$ws\n" if DEBUG;
	$$topTarget .= $char;
    } else {
	print STDERR "   setting: ".length($char)." char(s)$ws\n" if DEBUG;
	$$topTarget = $char;
    }
}

sub end_element {
    my ($el) = @_;

    $el ||= "(undef)";
    print STDERR "</$el>\n" if DEBUG;

    kill 2, $$ if DEBUG && DEBUG > 2;
    my ($TS, $CS, $types) = @{ $self->stack };
    my %sizes = ( TS => scalar(@$TS),
		  CS => scalar(@$CS),
		  types => scalar(@$types) );
    my $topTarget = pop @$TS;
    my $topCS = pop @$CS;
    pop @$types;

    if ( ref $topCS ) {
	(my ($pkg, $method, @args), @$topCS) = @$topCS;
	if ( $pkg and UNIVERSAL::can($pkg, $method) ) {
	    print STDERR "   constructor: $pkg->$method(@args)\n" if DEBUG;
	    $$topTarget = $pkg->$method(@args);
	} else {
	    print STDERR "stacks: ".YAML::Dump
		({ TS => \$TS,
		   CS => \$CS,
		   types => \$types,
		   topTarget => $topTarget,
		   topCS => [ $pkg, $method, @args ],
		 }) if DEBUG;
	    no warnings 'uninitialized';  # hack!
	    die "bad constructor ($pkg -> $method(@args) ?)\n"
	}
    } elsif ( $topCS and $topCS eq "array" ) {
	#kill 2, $$;
	pop @{${$TS->[$#$TS]}};
	pop @$TS;
    } else {
	print STDERR "   no constructor.\n" if DEBUG;
	# nothing to do!
    }

    $topCS = $CS->[$#$CS];
    if ( $topCS and $topCS eq "array" ) {
	$topTarget = pop @$TS;
	my $topArray = ${$TS->[$#$TS]};
	push @$TS, \($topArray->[$#$topArray+1]);
    }
    elsif ( $topCS and $topCS eq "hash" ) {
	$topTarget = pop @$TS;
	my $topHash = ${$TS->[$#$TS]};
	push @$TS, undef;
    }

    if ( DEBUG and DEBUG > 2 ) {
	print STDERR "the lot: ".YAML::Dump($self->stack)."...\n";
    }
    elsif ( DEBUG and DEBUG > 1) {
	my %changes;
	if ( $sizes{TS} != @$TS ) {
	    my $n = $sizes{TS} - @$TS;
	    $changes{TS} = join ",", ($sizes{TS}..($sizes{TS}+$n-1));
	}
	if ( $sizes{CS} != @$TS ) {
	    my $n = $sizes{CS} - @$CS;
	    $changes{CS} = join ",", ($sizes{CS}..($sizes{CS}+$n-1));
	}
	if ( $sizes{types} != @$types ) {
	    my $n = $sizes{types} - @$types;
	    $changes{types} = join ",", ($sizes{types}..($sizes{types}+$n-1));
	}
	if ( keys %changes ) {
	    print STDERR "   (popped @{[%changes]})\n";
	}
	else {
	    print STDERR "   (no pop!)";
	}
    } elsif ( DEBUG ) {
	print STDERR "   (TS: ".@$TS.", CS: ".@$CS.", types: ".@$types.")\n" if DEBUG;
    }
}

#our $AUTOLOAD;
#
#sub AUTOLOAD {
    #my $self = shift;
    #$AUTOLOAD =~ s{${\(__PACKAGE__)}::}{};
    #print STDERR __PACKAGE__."::$AUTOLOAD(@_)\n";
##
    ##$self->SUPER::$AUTOLOAD(@_);
#}

1;
