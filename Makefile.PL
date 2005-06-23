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
    IO::All 0.33
    Spiffy 0
    YAML 0
));

build_requires(qw(
    Test::More 0.54
    Test::Base 0.42
));

check_nmake();

clean_files("t/kwom.pm3");

&WriteAll();
