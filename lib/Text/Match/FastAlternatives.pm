package Text::Match::FastAlternatives;

use strict;
use warnings;

our $VERSION = '1.02';
use base qw<DynaLoader>;

__PACKAGE__->bootstrap($VERSION);

1;

__END__

=head1 NAME

Text::Match::FastAlternatives - efficient search for many strings

=head1 SYNOPSIS

    use Text::Match::FastAlternatives;

    my $expletives = Text::Match::FastAlternatives->new(@naughty);
    while (my $line = <>) {
        print "Do you email your mother with that keyboard?\n"
            if $expletives->match($line);
    }

=head1 DESCRIPTION

This module allows you to search for any of a list of substrings ("keys") in a
larger string.  It is particularly efficient when the set of keys is large.

This efficiency comes at the cost of some flexibility: if you want
case-insensitive matching, you have to fold case yourself:

    my $expletives = Text::Match::FastAlternatives->new(
        map { lc } @naughty);
    while (my $line = <>) {
        print "Do you email your mother with that keyboard?\n"
            if $expletives->match(lc $line);
    }

This module is designed as a drop-in replacement for Perl code of the following
form:

    my $expletives_regex = join '|', map { quotemeta } @naughty;
    $expletives_regex = qr/$expletives_regex/;
    while (my $line = <>) {
        print "Do you email your mother with that keyboard?\n"
            if $line =~ $expletives_regex;
    }

Text::Match::FastAlternatives can easily perform this test a hundred times
faster than the equivalent regex, if you have enough keys.  The more keys it
searches for, the faster it gets compared to the regex.

Modules like Regexp::Trie can build an optimised version of such a regex,
designed to take advantage of the niceties of perl's regex engine.  With a
large number of keys, this module will substantially outperform even an
optimised regex like that.  In one real-world situation with 339 keys,
running on Perl 5.8, Regexp::Trie produced a regex that ran 857% faster than
the naive regex (according to L<Benchmark>), but using
Text::Match::FastAlternatives ran 18275% faster than the naive regex, or
twenty times faster than Regexp::Trie's optimised regex.

The enhancements to the regex engine in Perl 5.10 include algorithms similar
to those in Text::Match::FastAlternatives.  However, even with very small
sets of keys, Perl has to do extra work to be fully general, so
Text::Match::FastAlternatives is still faster.  The difference is greater
for larger sets of keys.  For one test with only 5 keys,
Text::Match::FastAlternatives was 21% faster than perl-5.10.0; with 339 keys
(as before), the difference was 111% (that is, slightly over twice as fast).

=head1 METHODS

=over 4

=item Text::Match::FastAlternatives->new(@keys)

Constructs a matcher that can efficiently search for all of the @keys in
parallel.  Throws an exception if any of the keys are undefined.

=item $matcher->match($target)

Returns a boolean value indicating whether the $target string contains any of
the keys in $matcher.

=item $matcher->match_at($target, $pos)

Returns a boolean value indicating whether the $target string contains any
of the keys in $matcher at position $pos.  Returns false (without emitting
any warning) if $pos is larger than the length of $string.

=item $matcher->exact_match($target)

Returns a boolean value indicating whether the $target string is exactly
equal to any of the keys in $matcher.

=back

=head1 CAVEATS

=head2 Subclassing

Text::Match::FastAlternatives has a C<DESTROY> method implemented in XS.  If
you write a subclass with its own destructor, you will need to invoke the base
destructor, or you will leak memory.

=head2 Interaction with Perl internals

Text::Match::FastAlternatives may change the Perl-internal encoding of
strings passed to C<new> or to its C<match> methods.  This is not considered
a bug, as the Perl-internal encoding of a string is not normally of interest
to Perl code (as opposed to Perl internals).  However, you may encounter
situations where preserving a string's existing encoding is important
(perhaps to work around a bug in some other module).  If so, you may need to
copy scalar variables before matching them:

    $matches++ if $tmfa->match(my $temporary_copy = $original);

=head1 IMPLEMENTATION

Text::Match::FastAlternatives manages to be so fast by using a trie internally.
The time to find a match at a given position in the string (or determine that
there is no match) is independent of the number of keys being sought;
worst-case match time is linear in the length of the longest key.  Since a
match must be attempted at each position in the target string, total worst-case
search time is O(I<mn>) where I<m> is the length of the target string and I<n>
is the length of the longest key.

The C<match_at> and C<exact_match> methods only need to find a match at one
position, so they have worst-case running time of O(min(I<n>, I<m>)).

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Trie>, L<Regexp::Trie>, L<Regexp::Optimizer>,
L<Regexp::Assemble>, L<perl5100delta>, L<perlunitut>, L<perlunifaq>.

=head1 AUTHOR

Aaron Crane E<lt>arc@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2006, 2007, 2008 Aaron Crane.

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License, or (at your option) under the terms of the
GNU General Public License version 2.

=cut
