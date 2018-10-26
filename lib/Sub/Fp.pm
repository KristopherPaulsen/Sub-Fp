package Sub::Fp;
use strict;
use warnings;
use Carp;
use List::Util;
use Data::Dumper qw(Dumper);
use Exporter qw(import);
our @EXPORT_OK = qw(
    incr         reduces  flatten
    drop_right  drop     take_right  take
    assoc       maps     dec         chain
    first       end   subarray    partial
    __          find     filter      some
    none        uniq     bool        spread
    len         to_keys  to_vals     is_array
    is_hash     every    noop        identity
);

our $VERSION = '0.02';

use constant ARG_PLACE_HOLDER => {};

sub __ { ARG_PLACE_HOLDER };

# -----------------------------------------------------------------------------#

#TODO DROP/ TAKE/ more than size
#TODO Change to use carp instead of warn/die
#TODO fill
#TODO nth
#TODO memoize
#TODO forEach array AND hash
#TODO remove / reject

sub noop { return undef }

sub identity {
    my $args = shift // undef;

    return $args;
}

sub is_array {
    my $coll       = shift;
    my $extra_args = [@_];

    if (len($extra_args)) {
        return 0;
    }

    return bool(ref $coll eq 'ARRAY');
}

sub is_hash {
    my $coll = shift;

    return bool(ref $coll eq 'HASH');
}

sub to_vals {
    my $coll = shift // [];

    if (is_array($coll)) {
        return $coll;
    }

    if (is_hash($coll)) {
        return [values %{ $coll }];
    }

    return [spread($coll)];
}

sub to_keys {
    my $coll = shift // [];

    #Backwards compatibility < v5.12
    if (is_array($coll)) {
        return maps(sub {
            my (undef, $idx) = @_;
            return $idx;
        }, $coll);
    }

    if (is_hash($coll)) {
        return [keys %{ $coll }];
    }

    return maps(sub {
        my (undef, $idx) = @_;
        return $idx;
    }, [spread($coll)])
}

sub len {
    my $coll = shift || [];

    if (ref $coll eq 'ARRAY') {
        return scalar spread($coll);
    }

    if (ref $coll eq 'HASH') {
        return scalar (keys %{ $coll });
    }

    return length($coll);
}

#TODO unit tests;
sub is_empty {
    my $coll = shift;
    return bool(len($coll) == 0);
}

sub uniq {
    my $coll = shift;

    my @vals = do {
        my %seen;
        grep { !$seen{$_}++ } @$coll;
    };

    return [@vals];
}

sub find {
    my $fn   = shift;
    my $coll = shift // [];

    return List::Util::first {
        $fn->($_)
    } @$coll;
}

sub filter {
    my $fn   = shift;
    my $coll = shift // [];

    return [grep { $fn->($_) } @$coll];
}

sub some {
    my $fn   = shift;
    my $coll = shift // [];

    return find($fn, $coll) ? 1 : 0
}

sub every {
    my $fn   = shift;
    my $coll = shift // [];

    my $bool = List::Util::all {
        $fn->($_);
    } @$coll;

    return $bool ? 1 : 0;
}

sub none {
    my $fn   = shift;
    my $coll = shift // [];

    my $bool = List::Util::none {
        $fn->($_)
    } @$coll;

    return $bool ? 1 : 0;
}

sub incr {
    my $num = shift;
    return $num + 1;
}

sub dec {
    my $num = shift;
    return $num - 1;
}

sub first {
    my $coll = shift;
    return @$coll[0];
}

sub end {
    my $coll = shift // [];
    my $len = scalar @$coll;

    return @$coll[$len - 1 ];
}

sub flatten {
    my $coll = shift;

    return [
        map {
            ref $_ ? @{$_} : $_;
        } @$coll
    ];
}

sub drop {
    my $args     = [@_];
    my $count    = len($args) > 1 ? $args->[0] : 1;
    my $coll     = len($args) > 1 ? $args->[1] : $args->[0];
    my $coll_len = len($coll);

    return [@$coll[$count .. $coll_len - 1]];
}

sub drop_right {
    my $args     = [@_];
    my $count    = len($args) > 1 ? $args->[0] : 1;
    my $coll     = len($args) > 1 ? $args->[1] : $args->[0];
    my $coll_len = len($coll);

    return [@$coll[0 .. ($coll_len - ($count + 1))]];
}

sub take {
    my $args     = [@_];
    my $count    = len($args) > 1 ? $args->[0] : 1;
    my $coll     = len($args) > 1 ? $args->[1] : $args->[0];
    my $coll_len = len($coll);

    if (!$coll_len) {
        return [];
    }

    if ($count >= $coll_len ) {
        return $coll;
    }

    return [@$coll[0 .. $count - 1]];
}

sub take_right {
    my $args     = [@_];
    my $count    = len($args) > 1 ? $args->[0] : 1;
    my $coll     = len($args) > 1 ? $args->[1] : $args->[0];
    my $coll_len = len($coll);

    if (!$coll_len) {
        return [];
    }

    if ($count >= $coll_len ) {
        return $coll;
    }

    return [@$coll[($coll_len - $count) .. ($coll_len - 1)]];
}

sub assoc {
    my ($obj, $key, $item) = @_;

    if (!defined $key) {
        return $obj;
    }

    if (ref $obj eq 'ARRAY') {
        return [
            @{(take($key, $obj))},
            $item,
            @{(drop($key + 1, $obj))},
        ];
    }

    return {
        %{ $obj },
        $key => $item,
    };
}

sub maps {
    my $func = shift;
    my $coll = shift;

    my $idx = 0;

    my @vals = map {
      $idx++;
      $func->($_, $idx - 1, $coll);
    } @$coll;

    return [@vals];
}

sub reduces {
    my $func           = shift;
    my ($accum, $coll) = spread(_get_reduces_args([@_]));

    my $idx = 0;

    return List::Util::reduce {
        my ($accum, $val) = ($a, $b);
        $idx++;
        $func->($accum, $val, $idx - 1, $coll);
    } ($accum, @$coll);
}

sub _get_reduces_args {
    my $args = shift;

    if (equal(len($args), 1)) {
        return chain(
            $args,
            \&flatten,
            sub {
                return [first($_[0]), drop($_[0])]
            }
        )
    }

    return [first($args), flatten(drop($args))];
}

sub partial {
    my $func    = shift;
    my $oldArgs = [@_];

    if (ref $func ne 'CODE') {
        carp("Expected a function as first argument");
    }

    return sub {
        my $newArgs = [@_];
        my $no_placeholder_args = _fill_holders($oldArgs, $newArgs);
        return $func->(@$no_placeholder_args);
    }
}

#TODO DO this without mutation?
sub _fill_holders {
    my ($oldArgs, $newArgs) = @_;

    if (none(sub { equal($_[0], __) }, $oldArgs)) {
        return [@$oldArgs, @$newArgs];
    }

    return reduces(sub {
        my ($args, $arg) = @_;

        if (!equal($arg, __)) {
            return [spread($args), $arg]
        }

        return [spread($args), shift @{ $newArgs }]
    }, [], [spread($oldArgs), spread($newArgs)]);
}

sub subarray {
    my $coll  = shift || [];
    my $start = shift;
    my $end   = shift // scalar @$coll;

    if (!$start) {
        return $coll;
    }

    if ($start == $end) {
        return [];
    }

    return [
       @$coll[$start .. ($end - 1)],
    ];
}

sub chain {
    no warnings 'once';
    my ($val, @funcs) = @_;

    return List::Util::reduce {
        my ($accum, $func) = ($a, $b);
        $func->($accum);
    } (ref($val) eq 'CODE' ? $val->() : $val), @funcs;
}

#TODO write le unit tests
sub equal {
    my ($arg1, $arg2) = @_;

    if (ref $arg1 ne ref $arg2) {
        return 0;
    }

    if(ref $arg1 eq 'String' &&
       ref $arg2 eq 'String') {
        return bool($arg1 eq $arg2);
    }

    return bool($arg1 == $arg2);
}

#TODO Unit Tests
sub bool {
    my ($val) = @_;

    return $val ? 1 : 0;
}

#TODO Unit tests, WORKS FOR STRINGS?
sub spread {
    my $coll = shift // [];

    if (ref $coll eq 'ARRAY') {
        return @{ $coll };
    }

    if (ref $coll eq 'HASH') {
        return %{ $coll }
    }

    return split('', $coll);
}

=head1 NAME

Sub::Fp - A Clojure / Python Toolz / Lodash inspired Functional Utility Library

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

This library provides numerous functional programming utility methods,
as well as functional varients of native in-built methods, to allow for consistent,
concise code.

=head1 SUBROUTINES/METHODS

=head2 inc

Increments the supplied number by 1

    inc(1)

    # => 2

=cut

=head2 dec

Decrements the supplied number by 1

    dec(2)

    # => 1

=cut

=head2 maps

Creates an array of values by running each element in collection thru iteratee.
The iteratee is invoked with three arguments:
(value, index|key, collection).

    maps(sub {
        my $num = shift;
    }, [1,1,1]);

    # 3

=cut

=head2 reduces

Reduces collection to a value which is the accumulated result of running each element in collection thru iteratee,
where each successive invocation is supplied the return value of the previous.
If accumulator is not given, the first element of collection is used as the initial value.
The iteratee is invoked with four arguments:
(accumulator, value, index|key, collection).

    # Implicit Accumulator

    reduces(sub {
        my ($sum, $num) = @_;

        return $sum + $num;
    }, [1,1,1]);

    # 3


    # Explict Accumulator

    reduces(sub {
        my ($accum, $num) = @_;
        return {
            %{ $accum },
            key => $num,
        }
    }, {}, [1,2,3]);

    # {
        key => 1,
        key => 2,
        key => 3,
    }
=cut

=head2 flatten

Flattens array a single level deep.

    flatten([1,1,1, [2,2,2]]);

    # [1,1,1,2,2,2];

=cut

=head2 drop

Creates a slice of array with n elements dropped from the beginning.

    drop([1,2,3])

    # [2,3];

    drop([1,2,3], 2)

    # [3]

    drop([1,2,3], 5)

    # []

    drop([1,2,3], 0)

    # [1,2,3]
=cut



=head2 drop_right

Creates a slice of array with n elements dropped from the end.

    drop_right([1,2,3]);

    # [1,2]

    drop_right([1,2,3], 2)

    # [1]

    drop_right([1,2,3], 5)

    # []

    drop_right([1,2,3], 0)

    #[1,2,3]
=cut

=head2 take

Creates a slice of array with n elements taken from the beginning.

    take([1, 2, 3);

    # [1]

    take([1, 2, 3], 2);

    # [1, 2]

    take([1, 2, 3], 5);

    # [1, 2, 3]

    take([1, 2, 3], 0);

    # []

=cut

=head2 take_right

Creates a slice of array with n elements taken from the end.

    take_right([1, 2, 3]);

    # [3]

    tak_right([1, 2, 3], 2);

    # [2, 3]

    take_right([1, 2, 3], 5);

    # [1, 2, 3]

    take_right([1, 2, 3], 0);

    # []

=cut

=head2 first

Returns the first item in an array

    first(["I", "am", "a", "string"])

    # "I"

    first([5,4,3,2,1])

    # 5

=cut

=head2 end

Returns the end, or last item in an array

    end(["I", "am", "a", "string"])

    # "string"

    end([5,4,3,2,1])

    # 1

=cut

=head2 len

Returns the length of the collection.
If an array, returns the number of items.
If a hash, the number of key-val pairs.
If a string, the number of chars (following built-in split)

    len([1,2,3,4])

    # 4

    len("Hello")

    # 5

    len({ key => 'val', key2 => 'val'})

    #2

    len([])

    # 0

=cut

=head2 noop

A function that does nothing (like our government), and returns undef

    noop()

    # undef

=cut

=head2 identity

A function that returns its first argument

    identity()

    # undef

    identity(1)

    # 1

    # identity([1,2,3])

    # [1,2,3]

=cut

=head2 is_array

Returns 0 or 1 if the argument is an array

    is_array()

    # 0

    is_array([1,2,3])

    # 1

=head2 is_hash

Returns 0 or 1 if the argument is a hash

    is_hash()

    # 0

    is_hash({ key => 'val' })

    # 1

=cut

=head2 spread

Destructures an array / hash into non-ref context.
Destructures a string into an array of chars (following in-built split)

    spread([1,2,3,4])

    # 1,2,3,4

    spread({ key => 'val' })

    # key,'val'

    spread("Hello")

    # 'H','e','l','l','o'

=cut

=head2 bool

Returns 0 or 1 based on truthiness of argument, following
internal perl rules based on ternary coercion

    bool([])

    # 1

    bool("hello!")

    # 1

    bool()

    # 0

    bool(undef)

    # 0

=cut

=head2 to_keys

Creates an array of the key names in a hash,
indicies of an array, or chars in a string

    to_keys([1,2,3])

    # [0,1,2]

    to_keys({ key => 'val', key2 => 'val2' })

    # ['key', 'key2']

    to_keys("Hey")

    # [0, 1, 2];

=cut

=head2 to_vals

Creates an array of the values in a hash, of an array, or string.

    to_vals([1,2,3])

    # [0,1,2]

    to_vals({ key => 'val', key2 => 'val2' })

    # ['val', 'val2']

    to_vals("Hey");

    # ['H','e','y'];

=cut

=head2 uniq

Creates a duplicate-free version of an array,
in which only the first occurrence of each element is kept.
The order of result values is determined by the order they occur in the array.

    uniq([2,1,2])

    # [2,1]

    uniq(["Hi", "Howdy", "Hi"])

    # ["Hi", "Howdy"]

=cut

=head2 assoc

Returns new hash, or array, with the updated value at index / key.
Shallow updates only

    assoc([1,2,3,4,5,6,7], 0, "item")

    # ["item",2,3,4,5,6,7]

    assoc({ name => 'sally', age => 26}, 'name', 'jimmy')

    # { name => 'jimmy', age => 26}

=cut

=head2 subarray

Returns a subset of the original array, based on
start index (inclusive) and end idx (not-inclusive)

    subarray(["first", "second", "third", "fourth"], 0,2)

    # ["first", "second"]

=cut

=head2 find

Iterates over elements of collection, returning the first element predicate returns truthy for.

    my $people = [
        {
            name => 'john',
            age => 25,
        },
        {
            name => 'Sally',
            age => 25,
        }
    ]

    find(sub {
        my $person = shift;
        return equal($person->{'name'}, 'sally')
    }, $people);

    # { name => 'sally', age => 25 }

=cut

=head2 filter

Iterates over elements of collection, returning only elements the predicate returns truthy for.

    my $people = [
        {
            name => 'john',
            age => 25,
        },
        {
            name => 'Sally',
            age => 25,
        },
        {
            name => 'Old Greg',
            age => 100,
        }
    ]

    filter(sub {
        my $person = shift;
        return $person->{'age'} < 30;
    }, $people);

    # [
        {
            name => 'john',
            age => 25,
        },
        {
            name => 'Sally',
            age => 25,
        }
    ]

=cut

=head2 none

If one element is found to return truthy for the given predicate, none returns 0


    my $people = [
        {
            name => 'john',
            age => 25,
        },
        {
            name => 'Sally',
            age => 25,
        },
        {
            name => 'Old Greg',
            age => 100,
        }
    ]

    none(sub {
        my $person = shift;
        return $person->{'age'} > 99;
    }, $people);

    # 0

    none(sub {
        my $person = shift;
        return $person->{'age'} > 101;
    }, $people);

    # 1

=cut

=head2 every

Itterates through each element in the collection, and checks if element makes predicate
return truthy. If all elements cause predicate to return truthy, every returns 1;

    every(sub {
        my $num = shift;
        $num > 0;
    }, [1,2,3,4]);

    # 1

    every(sub {
        my $num = shift;
        $num > 2;
    }, [1,2,3,4]);

    # 0

=cut

=head2 some

Checks if predicate returns truthy for any element of collection.
Iteration is stopped once predicate returns truthy.

    some(sub {
        my $num = shift;
        $num > 0;
    }, [1,2,3,4]);

    # 1

    some(sub {
        my $num = shift;
        $num > 2;
    }, [1,2,3,4]);

    # 1

=cut

=head2 partial

Creates a function that invokes func with partials prepended to the arguments it receives.
(funcRef, args)

    my $add_three_nums = sub {
        my ($a, $b, $c) = @_;

        return $a + $b + $c;
    };

    my $add_two_nums = partial($add_three_nums, 1);

    $add_two_nums->(1,1)

    # 3


    # Can also use __ to act as a placeholder

    my $add_four_strings = sub {
        my ($a, $b, $c, $d) = @_;

        return $a . $b . $c . $d;
    };

    my $add_two_strings = partial($add_four_strings, "first ", __, "third ", __);

    $add_two_strings->("second ", "third ")

    # "first second third fourth"

=cut

=head2 chain

Composes functions, left to right, and invokes them, returning
the result. Accepts an expression as the first argument, to be passed
as the first argument to the proceding function

    chain(
        [1,2,3, [4,5,6]],
        sub {
            my $array = shift;
            return [spread($array), 7]
        },
        \&flatten,
    );

    # [1,2,3,4,5,6,7]


    # Invokes first function, and uses that as start value for next func
    chain(
        sub { [1,2,3, [4,5,6]] },
        sub {
            my $array = shift;
            return [spread($array), 7]
        },
        \&flatten,
    )

    # [1,2,3,4,5,6,7]

=cut

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

    inc         reduces  flatten
    drop_right  drop     take_right  take
    assoc       maps     dec         chain
    first       end   subarray    partial
    __          find     filter      some
    none        uniq     bool        spread
    len         to_keys  to_vals     is_array
    is_hash     every    noop        identity

=cut

=head1 AUTHOR

Kristopher C. Paulsen, C<< <kristopherpaulsen+cpan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sub-fp at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sub-Fp>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sub::Fp


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sub-Fp>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sub-Fp>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sub-Fp>

=item * Search CPAN

L<https://metacpan.org/release/Sub-Fp>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Kristopher C. Paulsen.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;
