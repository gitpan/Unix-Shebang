#!perl
use strict;
use warnings;
use File::Spec;
use Test::More;
use FindBin;
use English qw(-no_match_vars);

if (! $ENV{SHEBANG_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{SHEBANG_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

if (!require Test::Perl::Critic) {
    Test::More::plan(
        skip_all => "Test::Perl::Critic required for testing PBP compliance"
    );
}

my $rcfile = File::Spec->catfile( $FindBin::Bin, 'perlcriticrc' );
Test::Perl::Critic->import( -profile => $rcfile );

Test::Perl::Critic::all_critic_ok();
