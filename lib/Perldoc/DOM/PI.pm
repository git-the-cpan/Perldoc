package Perldoc::DOM::PI;

use Perldoc::DOM::AttrNode -Base;

=head1 NAME

Perldoc::DOM::PI - a processing instruction in a Perldoc::DOM tree

=head1 SYNOPSIS

See L<Perldoc::DOM::Node>.

=head1 DESCRIPTION

These nodes can be used to, eg, note to the L<Pod::Writer> that an
upcoming closing node is to be represented in a certain non-normative
way in the source.

=head2 SUB-CLASS PROPERTIES

A processing instruction is represented very much like an element,
except that it cannot contain sub-nodes like an element can.

Note: this restriction is currently not enforced by the DOM interface.

=cut

sub event_type {
    "processing_instruction"
}
