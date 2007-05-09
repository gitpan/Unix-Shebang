#!/usr/local/bin/perl -w

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Unix::Shebang',
    AUTHOR              => 'Ask Solem <asksh@cpan.org>',
    VERSION_FROM        => 'lib/Unix/Shebang.pm',
    ABSTRACT_FROM       => 'lib/Unix/Shebang.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'IO::File'   => 0,
        'File::Spec' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Unix-Shebang-*' },
);
