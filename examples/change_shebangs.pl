#!/usr/bin/perl
use strict;
use warnings;
use Unix::Shebang;

# ### Easy way:

#Unix::Shebang->run;

# Explicit way:

my $shebang = Unix::Shebang->new({
    interpreter => '/usr/local/bin/perl',
    must_match  => 'perl',
});

foreach my $file (@ARGV) {
    if ($shebang->has_shebang($file)) {
        $shebang->set_shebang($file, '/usr/local/bin/perl');
        print {*STDERR} "Changed shebang for file $file to /usr/local/bin/perl\n";
    }
}
