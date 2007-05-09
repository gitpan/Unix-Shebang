use strict;
use warnings;
use Module::Build;

sub YES { 1 };
sub NO  { 0 };

my $builder = Module::Build->new(
    module_name          => 'Unix::Shebang',
    license              => 'perl',
    dist_author          => 'Ask Solem <asksh@cpan.org>',
    dist_version_from    => 'lib/Unix/Shebang.pm',
    all_from             => 'lib/Unix/Shebang.pm',
    dynamic_config       => NO,
    sign                 => NO, # asksh: have to find out why my signature fails.
    recursive_test_files => YES,
    requires             => {
        'IO::File'              => 0,
        'File::Spec'            => 0,
        'Getopt::Long'          => 0,
    },
    build_requires       => {
        'Test::More'            => 0.42,
    },
    add_to_cleanup       => [ qw(
        a.out
        test.pl
        test.c
        test.cpp
        test.m
        *.swp
        .gdb_history
        install.cache
        t/cache
    ) ],
);

$builder->create_build_script( );

