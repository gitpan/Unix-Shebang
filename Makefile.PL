use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Unix::Shebang',
    AUTHOR              => 'Ask Solem <asksh@cpan.org>',
    VERSION_FROM        => 'lib/Unix/Shebang.pm',
    ABSTRACT_FROM       => 'lib/Unix/Shebang.pm',
    PL_FILES            => {},
    INST_BIN            => 'bin/',
    PREREQ_PM => {
        'Test::More'    => 0,
        'IO::File'      => 0,
        'File::Spec'    => 0,
        'Getopt::Long'  => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Unix-Shebang-*' },
);
