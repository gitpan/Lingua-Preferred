package Lingua::Preferred;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;
use Log::TraceMessages qw(t d);

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw(); @EXPORT_OK = qw(which_lang);
$VERSION = '0.1';

=pod

=head1 NAME

Lingua::Preferred - Perl extension to choose a language

=head1 SYNOPSIS

  use Lingua::Preferred qw(which_lang);
  my @wanted = qw(en de fr it de_CH);  
  my @available = qw(fr it de);
  my $which = which_lang(\@wanted, \@available);

=head1 DESCRIPTION

Often human-readable information is available in more than one
language.  Which should you use?  This module provides a way for the
user to specify possible languages in order of preference, and then to
pick the best language of those available.  Different 'dialects' given
by the 'territory' part of the language specifier (such as en, en_GB,
and en_US) are also supported.

One routine is provided, called C<which_lang()>.  The two
arguments are:

=over 

=item

a reference to a list of preferred languages (first is best).  Here, a
language is a string like C<'en'> or C<'fr_CA'>.  (C<'fr_*'> can also
be given - see below.)

=item

a reference to non-empty list of available languages.  Here, a
language can be like C<'en'>, C<'en_CA'>, or C<undef> meaning 'unknown'.

=back

The return code is which language to use.  This will always be an
element of the available languages list.

The cleverness of this module (if you can call it that) comes from
inferring implicit language preferences based on the explicit list
passed in.  For example, if you say that en is acceptable, then en_IE
and en_DK will presumably be acceptable too (but not as good as just
plain en).  If you give your language as en_US, then en is almost as
good, with the other dialects of en following soon afterwards.

If there is a tie between two choices, as when two dialects of the
same language are available and neither is explicitly preferred, or
when none of the available languages appears in the userE<39>s list,
then the choice appearing earlier in the available list is preferred.

Sometimes, the automatic inferring of related dialects is not what you
want, because a language dialect may be very different to the 'main'
language, for example Swiss German or some forms of English.  For this
case, the special form 'XX_*' is available. If you dislike Mexican
Spanish (as a completely arbitrary example), then C<[ 'es', 'es_*',
'es_MX' ]> would rank this dialect below any other dialect of es (but
still acceptable).  You donE<39>t have to explicitly list every other
dialect of Spanish before es_MX.

So for example, supposing C<@avail> contains the languages available:

=over

=item

You know English and prefer US English:

    $which = which_lang([ 'en_US' ], \@avail);

=item
 
You know English and German, German/Germany is preferred:

    $which = which_lang([ 'en', 'de_DE' ], \@avail);

=item

You know English and German, but preferably not Swiss German:

    $which = which_lang([ 'en', 'de', 'de_*', 'de_CH' ], \@avail);

Here any dialect of German (eg de_DE, de_AT) is preferable to de_CH.

=cut 
sub which_lang($$) {
    die 'usage: which_lang(listref of preferred langs, listref of available)'
      if @_ != 2;
    my ($pref, $avail) = @_;
    t '$pref=' . d $pref;
    t '$avail=' . d $avail;

    my (%explicit, %implicit);
    my $pos = 0;

    # This seems like the best way to make block-nested subroutines
    my $add_explicit = sub {
	my $l = shift;
	die "preferred language $l listed twice"
	  if defined $explicit{$l};
	if (delete $implicit{$l}) { t "moved implicit $l to explicit" }
	else { t "adding explicit $l" }
	$explicit{$l} = $pos++;
    };
    my $add_implicit = sub {
	my $l = shift;
	if (defined $explicit{$l}) {
	    t "$l already explict, not adding implicitly";
	}
	else {
	    if (defined $implicit{$l}) { t "replacing implicit $l" }
	    else { t "adding implicit $l" }
	    $implicit{$l} = $pos++
	}
    };
    
    foreach (@$pref) {
	$add_explicit->($_);

	if (/^[a-z][a-z]$/) {
	    # 'en' implies any dialect of 'en' also
	    $add_implicit->($_ . '_*');
	}
	elsif (/^([a-z][a-z])_([A-Z][A-Z])$/) {
	    # 'en_GB' implies 'en', and secondly any other dialect
	    $add_implicit->($1);
	    $add_implicit->($1 . '_*');
	}
	elsif (/^([a-z][a-z])_\*$/) {
	    # 'en_*' doesn't imply anything - it shouldn't be used
	    # except in odd cases.
	    # 
	}
	else { die "bad language '$_'" } # FIXME support 'English' etc
    }

    my %ranking = reverse (%explicit, %implicit);
    if ($Log::TraceMessages::On) {
	t 'ranking:';
	foreach (sort { $a <=> $b } keys %ranking) {
	    print "$_\t$ranking{$_}\n";
	}
    }
	  
    my @langs = @ranking{sort { $a <=> $b } keys %ranking};
    my %avail;
    foreach (@$avail) {
	next if not defined;
	$avail{$_}++ && die "available language $_ listed twice";
    }

    while (defined (my $lang = shift @langs)) {
	if ($lang =~ /^([a-z][a-z])_\*$/) {
	    # Any dialect of $1 (but not standard).  Work through all
	    # of @$avail in order trying to find a match.  (So there
	    # is a slight bias towards languages appearing earlier in
	    # @$avail.)
	    # 
	    my $base_lang = $1;
	  AVAIL: foreach (@$avail) {
		next if not defined;
		if (/^\Q$base_lang\E_/) {
		    # Well, it matched... but maybe this dialect was
		    # explicitly specified with a lower priority.
		    # 
		    foreach my $lower_lang (@langs) {
			next AVAIL if (/^\Q$lower_lang\E$/);
		    }
		    
		    return $_;
		}
	    }
	}
	else {
	    # Exact match
	    return $lang if $avail{$lang};
	}
    }
    
    # Couldn't find anything - pick first available language.
    return $avail->[0];
}

=pod

=head1 AUTHOR

Ed Avis, epa98@doc.ic.ac.uk

=head1 SEE ALSO

perl(1).

=cut

1;
__END__
