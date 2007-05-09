#!/usr/bin/perl
use strict;
use warnings;
# $Id: 01.shebang.t,v 1.2 2007/05/09 17:50:43 ask Exp $
# $Source: /opt/CVS/shebang/t/01.shebang.t,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.2 $
# $Date: 2007/05/09 17:50:43 $

BEGIN {
    use Test::More;
    use English    qw( -no_match_vars );
    eval 'require File::Temp';
    if ($EVAL_ERROR) {
        plan( skip_all => 'This test requires File::Temp' );
    }

    eval 'require File::Copy';
    if ($EVAL_ERROR) {
        plan( skip_all => 'This test requires File::Copy' );
    }

    eval 'require Unix::Shebang';
    if ($EVAL_ERROR) {
        plan( skip_all => 'Unix::Shebang is not installed or built. run `make` first.' );
    }
}

use File::Spec;
use File::Temp;
use File::Copy;
use FindBin;

use Unix::Shebang;

# The number of tests in this test program.
my $THIS_FILE_HAS_TESTS = 35;


# Name of directory in the same directory as the program was run
# that contains our test files.
my $TEST_FILES_DIR = 'test-files';

# List of test files in the directory above.
my %TEST_FILES = (
    no_args     => 'no_args.pl',
    no_shebang  => 'no_shebang.pl',
    relative    => 'relative.pl',
    with_args   => 'with_args.pl',
    with_space  => 'with_space.pl',
    shellscript => 'shellscript.sh',
    binary      => 'binaryfile.gif',
    noperms     => 'unreachable.file',
);
   

# List of copies of our test files in a temporary directory.
my %files;

# Find our test files.
my $bin_dir         = $FindBin::Bin;
my $test_files_dir  = File::Spec->catdir($bin_dir, 'test-files');
my $temp_dir        = File::Temp::tempdir( CLEANUP => 1 );

plan( skip_all => "File::Temp couldn't create a temporary directory: $OS_ERROR" )
    if not $temp_dir;

while (my($alias, $filename) = each %TEST_FILES) {

    # Find the full path to the file.
    my $orig_file    = File::Spec->catfile($test_files_dir, $filename);
    if (! $orig_file) {
        plan( skip_all => "Could not find our test files in $test_files_dir" )
    }

    # Copy the file to our temp directory.
    my $copy_of_file = File::Spec->catfile($temp_dir, $filename);
    my $ret          = copy($orig_file, $copy_of_file);

    # Skip if copy was not successful.
    if (! $ret) {
        plan( skip_all => "Couldn't copy file $orig_file => $copy_of_file" );
    }

    # Set the new file writable. (Where chmod is available).
    chmod 0644, $copy_of_file;

    # Skip if the resulting file is not writable.
    if (! -w $copy_of_file) {
        plan( skip_all => "Copied our test files, but $copy_of_file is not writable." );
    }
   
 
    $files{$alias} = $copy_of_file;
}

plan( tests => $THIS_FILE_HAS_TESTS );

my $s = Unix::Shebang->new( );
isa_ok($s, 'Unix::Shebang');

my $interpreter = $s->_find_perl( );
ok( $interpreter, '_find_perl( )' );
$s->set_interpreter($interpreter);

my $sx = Unix::Shebang->new({interpreter=>'/bin/sh'});
is( $sx->_find_perl, '/bin/sh',
    '_find_perl does not do anything if interpreter already set'
);
$sx = Unix::Shebang->new({interpreter=>'sh'});
is( $sx->_find_perl, 'sh',
    '_find_perl does not do anything if interpreter already set'
);

my $shebang = $s->has_shebang($files{no_args});
ok( $shebang, "$files{no_args} has shebang" );
ok( $s->set_shebang($files{no_args}), "set shebang for $files{no_args}" );
ok( $s->has_shebang($files{no_args}), "confirm set shebang" );

ok(! $s->has_shebang($files{no_shebang}), '$files{no_shebang} has no shebang' );
ok(! $s->set_shebang($files{no_shebang}), 'do not set shebang if not previously set' );
ok(! $s->has_shebang($files{no_shebang}), 'confirm not set shebang' );

$shebang = $s->has_shebang($files{relative});
ok( $shebang, "$files{relative} has shebang" );
ok( $s->set_shebang($files{relative}), "set shebang for $files{relative}" );
ok( $s->has_shebang($files{relative}), "confirm set shebang" );

$shebang = $s->has_shebang($files{with_args});
ok( $shebang, "$files{with_args} has shebang" );
ok( $s->set_shebang($files{with_args}), "set shebang for $files{with_args}" );
ok( $s->has_shebang($files{with_args}), "confirm set shebang" );

ok(! $s->has_shebang($files{with_space}), "$files{with_space} has no shebang" );
ok(! $s->set_shebang($files{with_space}), 'do not set shebang if not previously set' );
ok(! $s->has_shebang($files{with_space}), 'confirm not set shebang' );

my $s2 = Unix::Shebang->new({
    interpreter => '/usr/bin/bash',
    must_match  => 'sh',
});

# perl shebang changer does not change shellfile
ok(!$s->set_shebang($files{shellscript}), 'perl changer does not change bash file');

ok( $s2->has_shebang($files{shellscript}), 'shellscript.sh has shebang');
ok( $s2->set_shebang($files{shellscript}), 'shellscript.sh set shebang');
ok( $s2->has_shebang($files{shellscript}), 'shellscript.sh has shebang');

ok(! $s->has_shebang($files{binary}), 'has_shebang: skip binary files');
ok(! $s->set_shebang($files{binary}), 'set_shebang: skip binary files');
ok(! $s2->has_shebang($files{binary}), 'has_shebang: skip binary files');
ok(! $s2->set_shebang($files{binary}), 'set_shebang: skip binary files');

my $nonexisting_file = File::Spec->catfile($test_files_dir, 'THISFILEDOESNOTEXIST.null');
ok(! $s->has_shebang($nonexisting_file), 'has_shebang: skip non-existing files');
ok(! $s->set_shebang($nonexisting_file), 'set_shebang: skip non-existing files');

chmod 0000, $files{noperms};
ok(! $s->has_shebang($files{noperms}), 'has_shebang: no permissions' );
ok(! $s->set_shebang($files{noperms}), 'set_shebang: no permissions' );
chmod 0644, $files{noperms};


# Thesee tests outputs messages to stderr, so we close it.
close STDERR;

@ARGV = ($files{with_space}, $files{with_args}, $files{relative}, $files{no_shebang});
ok( Unix::Shebang->run, 'Unix::Shebang->run' );
ok( set_shebangs, 'set_shebangs, Exported and working' );

@ARGV = ( );

ok( Unix::Shebang->run, 'Unix::Shebang->run with ARGV empty' );

ok(!Unix::Shebang::_carp(q{}), '_carp returns false');


exit 0;
