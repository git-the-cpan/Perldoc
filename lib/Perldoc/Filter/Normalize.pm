
package Perldoc::Filter::Normalize;

use Perldoc::Filter -Base;

sub ignorable_whitespace {

}

sub characters {
    my $data = shift;
    $data =~ s/\s+/ /g;

    $self->send("characters", $data);
}


1;

