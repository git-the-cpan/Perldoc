use strict;
use inc::Module::Install;

name('Perldoc');
author('Sam Vilain <samv@cpan.org>');
abstract('Perl 6 Documentation System');
license('perl');
version_from('lib/Perldoc.pm');

requires(qw(
    perl 5.6.1
    Data::Dumper 0
    Scalar::Util 0
    Set::Object 1.10
    Maptastic 1.00
    Tree::DAG_Node 0
    Spiffy 0
    YAML 0
));

build_requires(qw(
    Test::More 0.54
));

check_nmake();

&WriteAll();
