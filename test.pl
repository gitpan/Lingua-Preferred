#!/usr/bin/perl -w

use strict;
my ($numtests, $loaded);

BEGIN { $numtests = 33; $| = 1; print "1..$numtests\n"; } # FIXME
END {print "not ok 1\n" unless $loaded;}
use Lingua::Preferred qw(which_lang);
$loaded = 1;
print "ok 1\n";

use Log::TraceMessages; #$Log::TraceMessages::On = 1; # FIXME
use Data::Dumper;

my $tests_done = 1;
sub check($$$) {
    my ($want, $avail, $ans) = @_;
    my $got = Dumper(which_lang($want, $avail));
    if ($got ne Dumper($ans)) {
	warn "wanted: @$want\navailable: @$avail\nexpected: $ans\ngot: $got";
	print 'not ';
    }
    print 'ok ', ++$tests_done, "\n";
}

check [                             ], [ 'en'                   ], 'en';
check [                             ], [ undef                  ], undef;
check [ 'fr'                        ], [ 'en'                   ], 'en';
check [ 'fr'                        ], [ 'en', 'fr'             ], 'fr';
check [ 'fr'                        ], [ 'en', 'fr_FR'          ], 'fr_FR';
check [ 'fr'                        ], [ 'en', 'fr_FR', 'fr'    ], 'fr';
check [ 'fr'                        ], [ undef                  ], undef;
check [ 'fr', 'en'                  ], [ 'fr'                   ], 'fr';
check [ 'fr', 'en'                  ], [ 'en'                   ], 'en';
check [ 'fr', 'en'                  ], [ 'de'                   ], 'de';
check [ 'fr', 'en'                  ], [ 'de', 'it'             ], 'de';
check [ 'fr', 'en'                  ], [ undef                  ], undef;
check [ 'en_GB'                     ], [ 'en'                   ], 'en';
check [ 'en_GB'                     ], [ 'fr'                   ], 'fr';
check [ 'en_GB'                     ], [ undef                  ], undef;
check [ 'en_GB'                     ], [ 'en_US'                ], 'en_US';
check [ 'en_GB'                     ], [ 'en_US', 'en_IT'       ], 'en_US';
check [ 'en_GB'                     ], [ 'en_US', 'en'          ], 'en';
check [ 'en_GB'                     ], [ 'en_US', 'en', 'en_GB' ], 'en_GB';
check [ 'en', 'en_GB'               ], [ 'en_US'                ], 'en_US';
check [ 'en', 'en_GB'               ], [ 'en_IT', 'en_GB'       ], 'en_GB';
check [ 'en', 'en_GB'               ], [ 'en', 'en_GB'          ], 'en';
check [ 'en_GB', 'en'               ], [ 'en', 'en_GB'          ], 'en_GB';
check [ 'de', 'de_*', 'de_CH'       ], [ 'fr'                   ], 'fr';
check [ 'de', 'de_*', 'de_CH'       ], [ 'de_CH'                ], 'de_CH';
check [ 'de', 'de_*', 'de_CH'       ], [ 'de_CH', 'de_DE'       ], 'de_DE';
check [ 'de', 'de_*', 'fr', 'de_CH' ], [ 'de_CH', 'fr'          ], 'fr';
# The following are probably not something you'd actually use
check [ 'en_*'                      ], [ 'en_GB', 'fr'          ], 'en_GB';
# N.B. en_* implies en_IE, en_CA etc. but not en
check [ 'en_*'                      ], [ 'fr', 'en'             ], 'fr';
check [ 'en_*'                      ], [ undef                  ], undef;
check [ 'de_*', 'de_CH'             ], [ 'de_CH', 'de', 'de_DE' ], 'de_DE';
check [ 'de', 'fr', 'de_*', 'de_CH' ], [ 'de_CH', 'de_AT', 'fr' ], 'fr';

if ($tests_done != $numtests) {
    die "expected to run $numtests tests, but ran $tests_done\n";
}

__END__

# Stuff for randomly generating test cases.  I didn't really use this.
my @l = qw(en en_GB en_US de de_DE de_AT de_CH fr fr_FR fr_CA it it_IT);
my @l2 = qw(en_* fr_* de_* it_*);

sub randomize(@) {
    my @r;
    push @r, splice(@_, (rand @_), 1) while @_;
    @r;
}
sub random_prefix(@) { @_[0 .. (rand @_)] }
sub random_subset(@) { randomize (random_prefix @_) }

for (;;) {
    my @avail = random_subset @l;
    my @want = random_subset (@l, @l2);
    my $which = which_lang(\@want, \@avail);
    print "which_lang([ qw(@want) ], [ qw(@avail) ]) is $which\n\n";
}
