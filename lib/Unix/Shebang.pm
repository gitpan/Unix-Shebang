package Unix::Shebang;

# $Id: Shebang.pm,v 1.1.1.1 2007/05/09 17:41:40 ask Exp $
# $Source: /opt/CVS/shebang/lib/Unix/Shebang.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.1.1.1 $
# $Date: 2007/05/09 17:41:40 $

use warnings;
use strict;
use Carp;
use Config;
use English qw( -no_match_vars );
use Exporter 'import';
use IO::File;
use File::Spec;
use Getopt::Long;

use vars qw($VERSION @EXPORT);
$VERSION = '0.314';
@EXPORT = qw( &set_shebangs ); ## no critic

if (!caller() || caller() eq 'PAR') {
    exit __PACKAGE__->run();
}

sub run {
    my $self = shift;
    
    my $interpreter;
    GetOptions(
        'interpreter|i=s' => \$interpreter,
    );

    my @files = @ARGV;
    if (not scalar @files) {
        my $myself = $0;
           $myself =~ s{^.*/}{}xms;
        print {*STDERR} "Usage: $myself [-i /path/to/perl ] file1 file2 ... fileN\n";
        return 1;
    }


    if (!ref $self) {
        $self = __PACKAGE__->new();
    }
    if ($interpreter) {
        $self->set_interpreter($interpreter);
    }
    my $perl  = $self->_find_perl( );
    croak 'Could not find perl interpreter!' if not $perl;

    for my $file (@files) {
        if ($self->has_shebang($file)) {
            $self->set_shebang($file, $perl);
            print {*STDERR} "++ Changed interpreter for file $file to $perl\n";
        }
        else {
            print {*STDERR} "-- File '$file' has no interpreter or is a binary or block special file.\n";
        }
    }

    return 1;
}

sub set_shebangs {
    my ($opt_interpreter, $opt_match) = @_;
    my $s = __PACKAGE__->new({
        interpreter => $opt_interpreter,
        must_match  => $opt_match,
    });
    return $s->run(@_);
}

sub new {
    my ($class, $options_ref) = @_;
    my $self = {};
    bless $self, $class;

    if ($options_ref->{interpreter}) {
        $self->set_interpreter( $options_ref->{interpreter} );
    }

    # By default, the shebang must match perl before we change anything.
    my $match_pat   = $options_ref->{must_match};
    $match_pat ||= 'perl';
    $self->set_must_match($match_pat);

    return $self;
}

sub get_interpreter {
    my ($self) = @_;
    return $self->{_PERL_};
}

sub set_interpreter {
    my ($self, $perl) = @_;
    $self->{_PERL_} = $perl;
    return;
}

sub get_must_match {
    my ($self) = @_;
    return $self->{_MUST_MATCH_};
}

sub set_must_match {
    my ($self, $match) = @_;
    $self->{_MUST_MATCH_} = $match;
    return;
}

sub has_shebang {
    my ($self, $file) = @_;
    my $has_shebang;

    # File must be an ASCII text file.
    return if not -T $file;

    my $file_fh = IO::File->new($file, q{<})
        or return _carp("Couldn't open file $file for reading: $OS_ERROR");
    my $first_line = <$file_fh>;

    if ($first_line =~ m/^\#\!/xms) {
        $has_shebang = $first_line;
        $has_shebang =~ s/^\#\!//xms;
    }

    close $file_fh
        or return _carp("Couldn't close file $file: $OS_ERROR");

    return $has_shebang;
}

sub set_shebang {
    my ($self, $file, $interpreter) = @_;
    $interpreter    ||= $self->get_interpreter();
    $interpreter    ||= $self->_find_perl();
    my $match_pattern = $self->get_must_match();
    return if not -T $file;

    my $has_shebang;
    my $in_fh = IO::File->new($file, q{r})
        or return _carp("Couldn't open file $file for reading: $OS_ERROR");

    # Get the first line from the file.
    my $first_line = <$in_fh>;

    # File must have a shebang before we continue.
    if ($first_line !~ m/^\#\!/xms) {
        return;
    }

    # It must mach our interpreter pattern (default: perl)
    if (index($first_line, $match_pattern) == -1) {
        return;
    }

    # rewind the file back to start.
    seek $in_fh, 0, 0;

    # slurp the contents of the file.
    my $file_contents = do {
        local $INPUT_RECORD_SEPARATOR = undef;
        <$in_fh>
    };

    # Find arguments
    my ($oldi, $arguments) = split m/\s+/xms, $first_line, 2;

    # there's a newline left over at the end of arguments.
    chomp $arguments;

    # Create a new shebang with the arguments of the old (if any)
    my $new_shebang = q{#!} . $interpreter . q{ } . $arguments;

    # remove the first line
    $file_contents = substr $file_contents, length $first_line,
        length $file_contents;

    # attach our new shebang
    $file_contents = $new_shebang . qq{\n} . $file_contents;

    close $in_fh
        or return _carp("Couldn't close $file: $OS_ERROR\n");

    my $out_fh = IO::File->new($file, q{w})
        or return _carp("Couldn't open file $file for writing: $OS_ERROR");

    print {$out_fh} $file_contents;

    close $out_fh
        or return _carp("Couldn't close file $file after writing: $OS_ERROR");

    return 1;
}

sub _find_perl {
    my ($self) = @_;

    # ## first check if user has specified his own interpreter.
    my $perl_interpreter = $self->get_interpreter;
    return $perl_interpreter if $perl_interpreter;

    # ## then check the perl we are running under.
    $perl_interpreter = $EXECUTABLE_NAME;

    # if the path is relative, try to find the full path.
    if (!File::Spec->file_name_is_absolute($perl_interpreter)) {
        $perl_interpreter = $Config{perlpath};
    }
    return $perl_interpreter;
}

# Carp returns a true value,
# so this is just a helper function to let
# us return after carp and not giving a true value.
sub _carp {
    carp shift;
    return;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Unix::Shebang - Utility module for Unix shebang lines.


=head1 VERSION

This document describes Unix::Shebang version 0.3

=head1 SYNOPSIS

You can use Unix::Shebang from the command line like this:

    perl -MUnix::Shebang -e'set_shebangs' file1.pl file2.pl ... fileN.pl

Or like this:

    perl Shebang.pm file1.pl file2.pl fileN.pl

With custom interpreter path:

    perl -MUnix::Shebang -e'set_shebangs("/opt/bin/bash", "bash")' file1.pl file2.pl ... fileN.pl

Or you can use the object-oriented interface:

    use Unix::Shebang ( );

    # This object is using the defaults, which is to replace any shebangs
    # that matches /perl to the path of the currently running interpreter.
    my $shebang = Unix::Shebang->new( );

    # This object is configured to add a /opt/bin/sh shebang on files
    # that has a shebang that matches /sh.
    my $sh_shebang = Unix::Shebang->new({
        interpreter => '/opt/bin/sh',
        must_match  => '/sh',
    });

    # This object is configured to add a /opt/bin/perl shebang on files
    # that has a shebang that matches /perl.
    my $perl_shebang = Unix::Shebang->new({
        interpreter => '/opt/bin/perl',
        must_match  => 'perl',
    });

    my $file = './blib/scripts/my_wicked_perl_script';
    my $interpreter_for_file = $shebang->has_shebang($file);
    if ($interpreter_for_file) {
        print "$file is a script using $interpreter_for_file as interpreter.\n";

        # set shebang to path of the perl we are running under,
        # (which is according to the config for the $shebang object above).
        $shebang->set_shebang($file); 
    }
    else {
        print "$file has no interpreter set, or is not a script.";
    }


=head1 DESCRIPTION


B<Shebang> you say?
Also commonly and well, uncommonly referred to as C<hashbang> or C<hashpling>.


B<Huh?>

    #!/usr/bin/perl

B<A> C<shebang> is the pair of characters in the first line of a script file
that causes Unix-like operating systems to execute the file using
the interpreter specified by the rest of the line.

A shebang consists of the two characters, C<#> and C<!> followed
by the full path of the C<interpreter> program and it's C<arguments>.
    
This is a great feature for us interpreter-loving creatures as it makes
our scripts behave as compiled programs, but it has its limitations.

One common problem when juggling different perl installations on the same system,
or even when using a different perl location than the more common C</usr/bin/perl>
is the tedious job of changing shebangs.

This module can be used by module authors and end users alike to set the interpreter
to the running perl (or a custom perl interpreter) upon installation of a distribution.

C<In short, this module is an example of the art of laziness :-)>

=head1 SUBROUTINES/METHODS

=head2 CONSTRUCTOR

=over 4

=item C<Unix::Shebang-E<gt>new(\%options)>

Create a new Unix::Shebang object.
Valid options are:
    
    interpreter -  The new interpreter to be used.
    must_match  -  Previous shebang must match this string for us to change it.

If the interpreter is not set, the currently running perl
will be used when changing files.

=back

=head2 ATTRIBUTES

=over 4

=item C<Unix::Shebang-E<gt>get_interpreter>

=item C<Unix::Shebang-E<gt>set_interpreter>

This is the new interpreter the scripts will change to
when sending files to C<change_shebang>.

=item C<Unix::Shebang-E<gt>get_must_match>

=item C<Unix::Shebang-E<gt>set_must_match>

This is a text string pattern (not regular expression), that
any existing shebang must contain if we're going to change it.

=back

=head2 METHODS

=over 4

=item C<Unix::Shebang-E<gt>has_shebang($file)>

Returns the interpreter path if the file has a shebang.

=item C<Unix::Shebang-E<gt>set_shebang($file)>

Set the shebang for a file. Will add a shebang if the file has no shebang,
but tests if the file is a text file first. In general it's a smart move to check
if the file already has a shebang with C<has_shebang> first.

The interpreter path in the C<interpreter> attribute will be used,
if it does not exist the path of the currently running perl will be used.

=back

=head2 PRIVATE METHODS

=over 4

=item C<Unix::Shebang-E<gt>_find_perl( )>
   
Try to find the path of the running perl interpreter.
Will return the custom interpreter if it is set.

=back

=head2 SUBROUTINES

=over 4

=item C<Unix::Shebang-E<gt>run(@ARGV)>

This is the function that is run if this module is run as a script.

=item C<set_shebangs($opt_interpreter, $opt_must_match>

This is a function that is exported by default so we can use this module
on the command line. It is just a shortcut to run.

EXAMPLE USAGE

Change to the path of the running perl:

    $ perl -MUnix::Shebang -e'set_shebangs' file1 file2 ... fileN

Change to another perl:

    $ perl -MUnix::Shebang -e'set_shebangs("/opt/bin/perl") file1 file2 ... fileN

Change bourne scripts interpreter to /usr/local/sh: (previous file's shebang has to match '/sh')

    $ perl -MUnix::Shebang -e'set_shebangs("/usr/local/sh", "/sh")' file1 file2 ... fileN

=back

=head1 EXPORT

This module exports the function C<set_shebangs> by default.
See description for the function above.

=head1 DIAGNOSTICS

=over 4

=item C<< Couldn't open file %s for reading: %s >>

An error occured when trying to open a file for reading. This is likely
to be a problem with insufficient permissions to access the file or with the
underlying operating system.

=item C<< Couldn't close file %s: %s >>

An error occured when closing the file. Probably an error with the underlying
operating system. Consult the documentation of your operating system.

=item C<< Couldn't open file %s for writing: %s >>

An error occured while trying to open a file for writing. Do you have
sufficient privileges to write to the file? See the end of the error
message for a possible explaination and look up the error in your
operating systems documentation.


=item C<< Couldn't close file %s after writing: %s >>

An error occured when closing the file. Probably an error with the underlying
operating system. Consult the documentation of your operating system.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Unix::Shebang requires no configuration files or environment variables.

=head1 DEPENDENCIES


=over 4

=item IO::File

=item File::Spec

=back


=head1 INCOMPATIBILITIES

This module has little purpose on non Unix operating systems,
but we do not take any action when running under i.e Win32.
This is because someone might still have a perfectly good reason for changing
shebangs. :-)

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-unix-shebang@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 COVERAGE

    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    blib/lib/Unix/Shebang.pm       99.1   77.8   62.5  100.0  100.0  100.0   93.4
    Total                          99.1   77.8   62.5  100.0  100.0  100.0   93.4
    ---------------------------- ------ ------ ------ ------ ------ ------ ------


=head1 SEE ALSO

=over 4

=item L<perlsetshebang>

The script version of this module. It's just a small wrapper that looks like this:

    #!/usr/bin/perl
    use strict;
    use warnings;
    use Unix::Shebang;

    Unix::Shebang->run;

=back

=head1 AUTHOR

Ask Solem  C<< <asksh@cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007, Ask Solem C<< <asksh@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
