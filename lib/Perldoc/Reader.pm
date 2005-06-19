package Perldoc::Reader;

use Perldoc::Base -Base;
use IO::All;

=head1 NAME

Perldoc::Reader - abstaction for stream-ish data input

=head1 SYNOPSIS

 my $reader = Perldoc::Reader->new($where);

 # or "lines", "characters", or a regex
 $reader->give_me("paragraphs");

 while (!$reader->eof) {
     my $data = $reader->next;

     # do something with $data...

     # if you didn't want a chunk, put it back.
     if ($unwanted) {
         $reader->unget($data);
     }
 }

 # if you want to use it again.
 $reader->reset;


=head1 DESCRIPTION

A Perldoc reader is an abstraction around the job of pulling in data
from a file.  It is here so that other input for information can
choose to emulate an IO::All, or this class.

=cut

use Carp;
use Scalar::Util qw(blessed);

sub new {
    my $thingy = shift;
    $self->SUPER::new(($thingy? (input => $thingy):()),
		      give_me => "paragraphs");
}

sub input {
    if ( @_ ) {
	if ( ref $_[0] and ref $_[0] eq "GLOB" ) {
	    $self->{input} = IO::All->new($_[0]);
	} elsif ( ref $_[0] and blessed $_[0] ) {
	    if ( $_[0]->can("getline") ) {
		$self->{input} = $_[0];
	    } else {
		croak("input needs to be a URI, file body or "
		      ."something that supports ->getline(),"
		      ." why have you given me $_[0]?");
	    }
	} else {
	    # a shocking test, really :).  Supply IO::All objects to
	    # avoid.
	    if ( $_[0] =~ m/\n/ ) {
		$self->{input} = IO::All->new('?');
		$self->{input}->seek(0, 0);
		$self->{input}->write($_[0]);
		$self->{input}->seek(0, 0);
	    } else {
		my $file = shift;
		$self->guess_type($file);
		$self->{input} = IO::All->new($file);
	    }
	}
	$self->{_buffer}="";
    } else {
	return $self->{input};
    }
}

field 'give_me';
field 'type';

field '_buffer';
field '_eof';

sub tip {
    my $line = $self->input->getline;

    if ( !defined($line) ) {
	$self->_eof(1);
    }
    else {
	$self->{_buffer} .= $line;
    }
}

sub eof {
    return ($self->_eof and !length($self->_buffer));
}

sub reset {
    if ( $self->input->can("seek") ) {
	eval { $self->input->seek(0,0); };
	$self->_eof(0);
    } else {
	die "can't reset, because the input can't seek";
    }
}

sub next {
    my $want = $self->give_me;

    my $full;
    if ( $want eq "lines" ) {
	$full = qr/\A.*\n/;
    } elsif ( $want eq "paragraphs" ) {
	$full = qr/\A(.*\n)+\s*\n(?=\s*\S)/;
    } elsif ( $want eq "characters" ) {
	$full = qr/\A./s;
    } else {
	$full = $want;
    }

    $self->tip until $self->{_buffer} =~ m/$full/g or $self->_eof;

    # bad regexes cause madness, sad
    pos($self->{_buffer}) ||= length($self->{_buffer});
    my $chunk = substr $self->{_buffer}, 0, pos($self->{_buffer}), "";

    length($chunk) ? $chunk : undef;
}

sub unget {
    my $chunk = shift;
    $self->{_buffer} = $chunk . $self->{_buffer};
}

# this is a temporary hack, pending something better :)
sub guess_type {
    my $filename = shift;

    if ( $filename =~ m/\.(pod|kwid|xml)/ ) {
	$self->type($1);
    }
}

1;
