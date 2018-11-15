package Sub::Fp::Test;
use warnings;
use strict;
use parent qw(Test::Class);
use Data::Dumper qw(Dumper);
use Test::More;
use Sub::Fp qw(
incr         reduces   flatten
drop_right  drop      take_right  take
assoc       maps      decr      chain
first       end       subarray    partial
__          find      filter      some
none        uniq      bool        spread   every
len         is_array  is_hash     to_keys  to_vals
noop        identity  is_empty    flow     eql
is_sub
);

sub is_sub__returns_0_when_args_undef :Tests {
    is(is_sub(), 0);
}

sub is_sub__returns_0_when_args_explicit_undef :Tests {
    is(is_sub(undef), 0);
}

sub is_sub__returns_0_when_args_hash :Tests {
    is(is_sub({}), 0);
}

sub is_sub__returns_0_when_args_array :Tests {
    is(is_sub([]), 0);
}

sub is_sub__returns_0_when_args_string :Tests {
    is(is_sub(''), 0);
}

sub is_sub__returns_0_when_args_number :Tests {
    is(is_sub(1), 0);
}

sub is_sub__returns_1_when_args_is_code_ref :Tests {
    is(is_sub(sub {}), 1);
}

sub eql__returns_0_when_args_incomplete :Tests {
    is(eql([]), 0);
}

sub eql__returns_0_when_different_refs :Tests {
    my $obj1 = {};
    my $obj2 = {};

    is(eql($obj1, $obj2), 0);
}

sub eql__returns_0_when_different_types :Tests {
    my $obj = {};
    my $string = "I am a string!";

    is(eql($obj, $string), 0);
}

sub eql__returns_0_when_different_types_with_num :Tests {
    my $num = 123;
    my $string = "I am a string!";

    is(eql($num, $string), 0);
}

# Same as internal perl engine
sub eql__returns_1_when_string_and_num_but_same_value :Tests {
    my $num = 123;
    my $string = "123";

    is(eql($num, $string), 1);
}

sub eql__returns_1_when_args_are_equal_undef :Tests {
    is(eql(), 1);
}

sub eql__returns_1_when_args_are_equal_ref :Tests {
    my $obj = {};

    is(eql($obj, $obj), 1);
}

sub eql__returns_1_when_args_are_equal_hash :Tests {
    my $obj = {};

    is(eql($obj, $obj), 1);
}

sub eql__returns_1_when_args_are_equal_array :Tests {
    my $obj = [];

    is(eql($obj, $obj), 1);
}

sub eql__returns_1_when_args_are_equal_strings :Tests {
    my $string = "Hello world!";

    is(eql($string, $string), 1);
}

sub eql__returns_1_when_args_are_equal_nums :Tests {
    is(eql(100, 100), 1);
}

sub flow__returns_empty_sub_when_args_empty :Tests {
    my $func = flow();

    is($func->(), undef);
}

sub flow__throws_warning_when_not_given_sub_as_argument :Tests {
    local $SIG{__WARN__} = sub { die $_[0] };

    eval {
        flow()
    };

    like($@, qr/Expected a function/);
}

sub flow__returns_func_ref_composed_of_passed_in_args :Tests {
    my $func = flow(\&incr, \&incr);

    is(ref $func, 'CODE');
}

sub flow__returns_func_that_evaluates_to_composition_of_funcs :Tests {
    my $func = flow(\&incr, \&incr);

    is($func->(1), 3);
}

sub is_empty__returns_1_when_args_undef :Tests {
    is(is_empty(), 1);
}

sub is_empty__returns_1_when_args_empty_array :Tests {
    is(is_empty([]), 1)
}

sub is_empty__returns_1_when_args_empty_string :Tests {
    is(is_empty(''), 1)
}

sub is_empty__returns_1_when_args_empty_hash :Tests {
    is(is_empty({}), 1)
}

sub is_empty__returns_0_when_args_not_a_collection :Tests {
    is(is_empty(1), 0)
}

sub is_empty__returns_0_when_args_an_array :Tests {
    is(is_empty([1,2,3]), 0)
}

sub is_empty__returns_0_when_args_a_hash :Tests {
    is(is_empty({ key => 'value' }), 0);
}

sub is_empty__returns_0_when_args_a_string :Tests {
    is(is_empty("I am not empty!"), 0);
}

sub partial__throws_no_func_error_if_no_args :Tests {
    local $SIG{__WARN__} = sub { die $_[0] };

    eval {
        partial();
    };

    like($@, qr/Expected a function/);
}

sub partial__throws_no_func_error_if_wrong_args :Tests {
    local $SIG{__WARN__} = sub { die $_[0] };

    eval {
        partial([]);
    };

    like($@, qr/Expected a function/);
}

sub partial__returns_func_ref :Tests {
    is(ref partial(sub {}), 'CODE');
}

sub partial__returns_partially_applied_func :Tests {
    my $add_three_nums = sub {
        my ($a, $b, $c) = @_;

        return $a + $b + $c;
    };

    my $add_two_nums = partial($add_three_nums, 1);

    is($add_two_nums->(1,1), 3);
}

sub partial__returns_partially_applied_func_two_args_applied :Tests {
    my $add_three_nums = sub {
        my ($a, $b, $c) = @_;

        return $a + $b + $c;
    };

    my $add_two_nums = partial($add_three_nums, 1, 1);

    is($add_two_nums->(1), 3);
}

sub partial__returns_partially_applied_func_all_args_applied :Tests {
    my $add_three_nums = sub {
        my ($a, $b, $c) = @_;

        return $a + $b + $c;
    };

    my $add_two_nums = partial($add_three_nums, 1, 1, 1);

    is($add_two_nums->(), 3);
}


sub partial__returns_partially_applied_func_using_placeholder_and_implict_last_arg :Tests {
    my $add_three_nums = sub {
        my ($a, $b, $c) = @_;

        return $a + $b + $c;
    };

    my $add_two_nums = partial($add_three_nums, 1, __,);

    is($add_two_nums->(1,1), 3);
}

sub partial__returns_partially_applied_func_using_placeholder_and_explict_last_arg :Tests {
    my $add_three_nums = sub {
        my ($a, $b, $c) = @_;

        return $a + $b + $c;
    };

    my $add_two_nums = partial($add_three_nums, 1, __, __);

    is($add_two_nums->(1,1), 3);
}

sub partial__returns_partially_applied_func_with_placeholders_inbetween :Tests {
    my $add_four_strings = sub {
        my ($a, $b, $c, $d) = @_;

        return $a . $b . $c . $d;
    };

    my $add_two_strings = partial($add_four_strings, "first ", __, "third ", __);

    is_deeply(
        $add_two_strings->("second ", "fourth "),
        "first second third fourth "
    );
}

sub partial__returns_partially_applied_func_with_placeholders_odd_placement :Tests {
    my $add_four_strings = sub {
        my ($a, $b, $c, $d) = @_;

        return $a . $b . $c . $d;
    };

    my $add_two_strings = partial($add_four_strings, __ , __, "third ", __);

    is_deeply(
        $add_two_strings->("first ", "second ", "fourth "),
        "first second third fourth "
    );
}

sub to_vals__returns_empty_array_when_args_undef :Tests {
    is_deeply(to_vals(), []);
}

sub to_vals__returns_empty_array_when_empty_array :Tests {
    is_deeply(to_vals([]), []);
}

sub to_vals__returns_array_of_values :Tests {
    is_deeply(to_vals([1,2,3]), [1,2,3]);
}

sub to_vals__returns_array_of_values_from_hash :Tests {
    my $result = to_vals({ key => 'val', key2 => 'val2' }),

    my $expected = ['val', 'val2'];

    is_deeply(
        [sort @$result],
        [sort @$expected],
    );
}

sub to_vals__returns_array_of_values_shallow_from_hash :Tests {

    my $result = to_vals({
        key => 'val',
        key2 => 'val2',
        key3 => {
            key4 => 'val3'
        }
    });

    my $expected = ['val', 'val2', { key4 => 'val3' }];

    is_deeply(
        [sort @$result],
        [sort @$expected],
    );
}

sub to_vals__returns_array_of_values_from_string :Tests {

    my $result = to_vals('Hello');

    my $expected = ['H','e','l','l','o'];

    is_deeply(
        [sort @$result],
        [sort @$expected],
    );
}

sub identity__returns_undef_when_args_undef :Tests {
    is(identity(), undef)
}

sub identity__returns_first_arg :Tests {
    is_deeply(identity([1,2,3]), [1,2,3])
}

sub identity__returns_only_first_arg :Tests {
    is_deeply(
        identity([1,2,3], "someOtherArgs"),
        [1,2,3]
    )
}

sub noop__returns_undef_when_args_undef :Tests {
    is(noop(), undef)
}

sub noop__returns_undef_when_args_filled :Tests {
    is_deeply(noop("some", "args"), undef);
}


sub maps__returns_empty_array_when_args_undef :Tests {
    is_deeply(maps(), []);
}

sub maps__returns_empty_array_when_args_incomplete :Tests {
    is_deeply(maps([]), []);
}

sub maps__returns_values_inc_by_one :Tests {
    is_deeply(
        maps(\&incr, [1,2,3]),
        [2,3,4]
    );
}

sub maps__returns_item_plus_idx :Tests {
    my $result = maps(sub {
        my ($str, $idx) = @_;
        return "$str $idx";
    }, ["index is", "index is"]),

    my $expected = ["index is 0", "index is 1"];

    is_deeply($result, $expected);
}

sub maps__returns_collection_as_arg :Tests {
    my $result = maps(sub {
        my (undef, undef, $coll) = @_;
        return $coll;
    }, [1,1,1]);

    my $expected = [[1, 1, 1,], [1,1,1], [1,1,1,]];

    is_deeply($expected, $result);
}

sub len__returns_0_when_args_undef :Tests {
    is(len(), 0);
}

sub len__returns_0_when_empty_array :Tests {
    is(len([]), 0);
}

sub len__returns_0_when_empty_hash :Tests {
    is(len({}), 0);
}

sub len__returns_0_when_empty_string :Tests {
    is(len(''), 0);
}

sub len__returns_length_of_array :Tests {
    is(len([1,2,3,4,5]), 5);
}

sub len__returns_length_of_hash :Tests {
    is(
        len({ key1 => 'val', key2 => 'val', key3 => 'val' }),
        3
    );
}

sub len__returns_length_of_string :Tests  {
    is(len('abcd'), 4);
}


sub len__returns_length_of_string_including_spaces :Tests  {
    is(len('abcd  '), 6);
}


sub is_array__returns_0_when_args_undef :Tests {
    is(is_array(), 0);
}

sub is_array__returns_0_when_hash :Tests {
    is(is_array({}), 0)
}

sub is_array__returns_0_when_string :Tests {
    is(is_array("String here"), 0)
}

sub is_array__returns_0_when_list_but_not_array :Tests {
    is(
        is_array(("hello", "Item", "here")),
        0
    );
}

sub is_array__returns_0_when_list_containg_array_and_misc :Tests {
    is(
        is_array([], "too", "many", "items"),
        0
    );
}

sub is_array__returns_1_when_array_ref :Tests {
    is(is_array([]), 1)
}


sub is_hash__returns_0_when_args_undef :Tests {
    is(
        is_hash(),
        0
    );
}

sub is_hash__returns_0_when_args_not_hash :Tests {
    is(
        is_hash('val', 'val'),
        0,
    )
}

sub is_hash__returns_1_when_hash :Tests {
    is(
        is_hash({}),
        1,
    )
}


sub to_keys__returns_empty_array_when_args_undef :Tests {
    is_deeply(
        to_keys(),
        [],
    )
}


sub to_keys__returns_empty_array_when_args_empty_array :Tests {
    is_deeply(
        to_keys([]),
        [],
    )
}

sub to_keys__returns_empty_array_when_args_empty_hash :Tests {
    is_deeply(
        to_keys(),
        [],
    )
}

sub to_keys__returns_indices_in_array :Tests {
    my $result = to_keys(["Item", "secondItem", "thirdItem"]);

    my $expected = [0,1,2];
}

sub to_keys__returns_keys_in_hash :Tests {

    my $result = to_keys({
        key1 => 'val',
        key2 => 'val'
    });

    my $expected = ['key1', 'key2'];

    is_deeply(
        [sort @$result],
        [sort @$expected],
    );
}

sub to_keys__returns_keys_in_hash_shallow_only :Tests {

    my $result = to_keys({
        key1 => 'val',
        key2 => 'val',
        key3 => {
            key4 => 'nested',
        }
    });

    my $expected = ['key1', 'key2', 'key3'];

    is_deeply(
        [sort @$result],
        [sort @$expected],
    );
}

sub to_keys__returns_array_of_indicies_from_string :Tests {
    my $result = to_keys('Hey');

    my $expected = [0,1,2];

    is_deeply($result, $expected);
}

sub reduces__returns_undef_when_no_args :Tests {
    is(reduces(), undef);
}

sub reduces__returns_undef_when_incomplete_args :Tests {
    is(reduces([]), undef);
}

sub reduces__returns_new_val_from_collection :Tests {
       my $result = reduces(sub {
        my ($accum, $val) = @_;
        return $accum + $val
    }, [1,2,3,4]);

    is($result, 10);
}

sub reduces__returns_new_val_from_collection_using_accum :Tests {
    my $result = reduces(sub {
        my ($accum, $val) = @_;
        return $accum + $val
    }, 100, [1,2,3,4]);

    is($result, 110);
}

sub reduces__returns_new_val_from_collection_using_accum_with_new_type :Tests {
    my $result = reduces(sub {
        my ($accum, $val) = @_;
        return {
            spread($accum),
            $val => "The val became a key!"
        }
    }, {}, ["first", "second", "third"]);

    my $expected = {
        first  => "The val became a key!",
        second => "The val became a key!",
        third  => "The val became a key!",
    };

    is_deeply($result, $expected);
}

sub reduces__returns_new_val_using_idx_arg :Tests {
    my $result = reduces(sub {
        my ($accum, undef, $idx) = @_;
        return [spread($accum), $idx];
    }, [], ["item", "item", "item", "item"]);

    my $expected = [0,1,2,3];

    is_deeply($result, $expected);
}

sub reduces__returns_sum_of_indicies :Tests {
    my $result = reduces(sub {
        my ($accum, undef, $idx) = @_;
        return $accum + $idx
    }, 0, [0, 0, 0]);

    my $expected = 3;

    is_deeply($result, $expected);
}

sub reduces__returns_collection_as_arg :Tests {
    my $result = reduces(sub {
        my ($accum, undef, undef, $coll) = @_;

        return [spread($accum), $coll];
    }, [], [1,1,1]);

    my $expected = [[1,1,1], [1,1,1], [1,1,1]];

    is_deeply($result, $expected);
}

sub every__returns_1_when_undef :Tests {
    is(every(), 1)
}

sub every__returns_1_when_empty :Tests {
    is(every(sub {}, []), 1)
}

sub every__returns_1_when_predicate_matches_everything :Tests {
    is(
        every(sub { $_[0] eq 'test'}, ['test','test','test','test']),
        1,
    )
}

sub every__returns_0_when_predicate_only_matches_some :Tests {
    is(
        every(sub { $_[0] eq 'test'}, ['test','test','test','nontest']),
        0,
    )
}

sub every__returns_true_when_all_items_matche_iteratee_shorthand :Tests {
    my $people = [
        {
            name    => 'sally',
            details => {
                favorite_foods => ["cheese", "bread", "oranges"],
                occupation     => 'teacher',
            }
        },
        {
            name    => 'Bob',
            details => {
                favorite_foods => ["cheese", "bread", "oranges"],
                occupation     => 'wrestler',
            }
        },
        {
            name    => 'Robert',
            details => {
                favorite_foods => ["cheese", "bread", "oranges"],
                occupation     => 'unemployed',
            }
        },
    ];

    my $all_teachers_like_cheese = every(
        {
            details => {
                favorite_foods => ['cheese'],
            }
        },
        $people,
    );

    is ($all_teachers_like_cheese, 1);
}

sub bool__returns_0_when_undef :Tests {
    is(bool(), 0)
}

sub bool__returns_0_when_falsy :Tests {
    is(bool(''), 0)
}

sub bool__returns_1_when_truthy :Tests {
    is(bool([]), 1);
}

sub bool__returns_1_when_string_truthy :Tests {
    is(bool("string"), 1);
}

sub uniq__returns_empty_array_when_array_empty :Tests {
    is_deeply(uniq([]), []);
}

sub uniq__returns_empty_array_when_args_undef :Tests {
    is_deeply(uniq(), []);
}

sub uniq__returns_unique_array_when_duplicates :Tests {
    is_deeply(uniq([1,1,2,2,3,4,5]), [1,2,3,4,5]);
}

sub uniq__returns_unique_array_in_same_order_when_duplicates :Tests {
    is_deeply(
        uniq(["cheese", "is", "very", "very", "tasty"]),
        ["cheese", "is", "very", "tasty"]
    );
}

sub uniq__returns_new_array :Tests {
    ok( uniq([1,1,2,2,3,3]) != [1,2,3] );
}


sub some__returns_false_when_empty_args :Tests {
    is(some(sub {}, []), 0)
}

sub some__returns_false_when_args_undef :Tests {
    is(some(), 0)
}

sub some__returns_true_if_one_matches_predicate :Tests {
    is(
        some(sub { $_[0] > 2}, [1,1,1,1,3]),
        1
    );
}

sub some__returns_false_if_none_match_predicate :Tests {
    is(
        some(sub { $_[0] > 10}, [1,1,1,1,3]),
        0
    );
}

sub some__returns_true_when_atleast_one_item_matches_iteratee_shorthand :Tests {
    my $people = [
        {
            name    => 'sally',
            details => {
                favorite_foods => ["cheese", "bread", "oranges"],
                occupation     => 'teacher',
            }
        },
        {
            name    => 'Bob',
            details => {
                favorite_foods => ["cheese", "bread", "oranges"],
                occupation     => 'wrestler',
            }
        },
        {
            name    => 'Robert',
            details => {
                favorite_foods => ["cheese", "bread", "oranges"],
                occupation     => 'unemployed',
            }
        },
    ];

    my $a_teacher_is_named_sally = some(
        { name => 'sally' },
        $people,
    );

    is ($a_teacher_is_named_sally, 1);
}

sub some__returns_false_when_no_items_match_iteratee_shorthand :Tests {
    my $people = [
        {
            name    => 'Black Bart',
            details => {
                favorite_foods => ["cheese", "bread", "oranges"],
                occupation     => 'teacher',
            }
        },
        {
            name    => 'Other Black Bart',
            details => {
                favorite_foods => ["cheese", "bread", "oranges"],
                occupation     => 'wrestler',
            }
        },
        {
            name    => 'El Barto',
            details => {
                favorite_foods => ["cheese", "bread", "oranges"],
                occupation     => 'unemployed',
            }
        },
    ];

    my $a_teacher_is_named_sally = some(
        { details => { favorite_foods => ["brussel sprouts"] } },
        $people,
    );

    is ($a_teacher_is_named_sally, 0);
}


sub none__returns_true_when_empty_args :Tests {
    is(none(sub{}, []), 1);
}

sub none__returns_true_when_args_undef :Tests {
    is(none(), 1);
}

sub none__returns_true_when_none_match_predicate :Tests {
    is(
        none(sub { $_[0] > 3 }, [1,2,3,3,3,3,3]),
        1
    )
}

sub none__returns_false_when_one_matches_predicate :Tests {
    is(
        none(sub { $_[0] > 3 }, [1,2,3,3,3,3,5]),
        0
    )
}

sub none__returns_false_when_multi_matches_predicate :Tests {
    is(
        none(sub { $_[0] > 3 }, [1,2,3,3,3,5,10]),
        0
    )
}

sub none__returns_true_when_no_items_match_iteratee_shorthand :Tests {
    my $people = [
        {
            name    => 'sally',
            details => {
                favorite_foods => ["cheese", "bread", "oranges"],
                occupation     => 'teacher',
            }
        },
        {
            name    => 'Bob',
            details => {
                favorite_foods => ["cheese", "bread", "oranges"],
                occupation     => 'wrestler',
            }
        },
        {
            name    => 'Robert',
            details => {
                favorite_foods => ["cheese", "bread", "oranges"],
                occupation     => 'unemployed',
            }
        },
    ];

    my $nobody_likes_brussel_sprouts = none(
        {
            details => {
                favorite_foods => ['brussel sprouts'],
            }
        },
        $people,
    );

    is($nobody_likes_brussel_sprouts, 1);
}

sub none__returns_false_when_an_item_matches_iteratee_shorthand :Tests {
    my $people = [
        {
            name    => 'sally',
            details => {
                favorite_foods => ["cheese", "bread", "oranges"],
                occupation     => 'teacher',
            }
        },
        {
            name    => 'Bob',
            details => {
                favorite_foods => ["cheese", "bread", "oranges"],
                occupation     => 'wrestler',
            }
        },
        {
            name    => 'Robert',
            details => {
                favorite_foods => ["cheese", "bread", "oranges", "brussel sprouts"],
                occupation     => 'unemployed',
            }
        },
    ];

    my $nobody_likes_brussel_sprouts = none(
        {
            details => {
                favorite_foods => ["brussel sprouts"],
            }
        },
        $people,
    );

    is($nobody_likes_brussel_sprouts, 0);
}

sub spread__returns_empty_list_when_args_undef :Tests {
    is_deeply(
        [ spread() ],
        []
    );
}

sub spread__returns_empty_key_val_when_args_undef :Tests {
    is_deeply(
        { spread() },
        {}
    );
}

sub spread__returns_empty_key_val_when_args_empty :Tests {
    is_deeply(
        { spread({}) },
        {}
    );
}

sub spread__returns_list_when_args_empty :Tests {
    is_deeply(
        [ spread([]) ],
        []
    );
}

sub spread__returns_destructured_list :Tests {
    is_deeply(
        [1, 2, spread([3, 4])],
        [1, 2, 3, 4],
    );
}

sub spread__returns_destructured_key_vals :Tests {
    my $keyval = { key3 => 'val3' };
    is_deeply(
        {
            key => 'val',
            key2 => 'val2',
            spread($keyval)
        },
        {
            key => 'val',
            key2 => 'val2',
            key3 => 'val3',
        }
    );
}

sub find__returns_undef_when_empty_args :Tests {
    is_deeply(find([]), undef);
}

sub find__returns_undef_when_not_found_in_array :Tests {
    is_deeply(
        find(sub { $_[0] > 100}, [1,2,3,4,5]),
        undef,
    );
}

sub find__returns_item_when_found_in_array :Tests {
    is_deeply(
        find(sub { $_[0] > 4}, [1,2,3,4,5]),
        5,
    );
}

sub find__returns_item_based_on_iteratee_shorthand :Tests {
    my $people = [
        {
            name    => 'sally',
            details => {
                favorite_foods => ["cheese", "bread", "oranges"],
                occupation     => 'teacher',
            }
        },
        {
            name    => 'Bob',
            details => {
                favorite_foods => ["cheese", "bread", "oranges"],
                occupation     => 'wrestler',
            }
        },
        {
            name    => 'Robert',
            details => {
                favorite_foods => ["cheese", "bread", "oranges"],
                occupation     => 'unemployed',
            }
        },
    ];

    my $teachers = find(
        {
            details => {
                occupation => 'teacher',
            }
        },
        $people,
    );

    is_deeply(
        $teachers,
        {
            name    => 'sally',
            details => {
                favorite_foods => ["cheese", "bread", "oranges"],
                occupation     => 'teacher',
            }
        },
    );
}


sub filter__returns_empty_when_empty_args :Tests {
    is_deeply(
        filter([]),
        [],
    );
}

sub filter__returns_empty_when_not_found_in_array :Tests {
    is_deeply(
        filter(sub { $_[0] > 100}, [1,2,3,4,5]),
        [],
    );
}

sub filter__returns_multi_items_that_match_predicate :Tests {
    is_deeply(
        filter(sub { $_[0] > 2}, [1,2,3,4,5]),
        [3,4,5]
    );
}

sub filter__returns_items_based_on_iteratee_shorthand :Tests {
    my $people = [
        {
            name    => 'sally',
            details => {
                favorite_foods => ["cheese", "bread", "oranges"],
                occupation => 'teacher',
            }
        },
        {
            name    => 'Bob',
            details => {
                favorite_foods => ["cheese", "bread", "oranges"],
                occupation     => 'teacher',
            }
        },
        {
            name    => 'Robert',
            details => {
                favorite_foods => ["cheese", "bread", "oranges"],
                occupation     => 'unemployed',
            }
        },
    ];

    my $teachers = filter(
        {
            details => {
                occupation => 'teacher',
            }
        },
        $people,
    );

    print Dumper $teachers;

    is_deeply(
        $teachers,
        [
            {
                name    => 'sally',
                details => {
                    favorite_foods => ["cheese", "bread", "oranges"],
                    occupation => 'teacher',
                }
            },
            {
                name    => 'Bob',
                details => {
                    favorite_foods => ["cheese", "bread", "oranges"],
                    occupation     => 'teacher',
                }
            },
        ]
    );
}

sub drop__returns_empty_array_when_empty_array :Tests {
    is_deeply(drop([]), []);
}

sub drop__returns_empty_array_when_args_undef :Tests {
    is_deeply(drop(), []);
}

sub drop__returns_empty_array_when_array_empty_and_args :Tests {
    is_deeply(drop(1, []), []);
}

sub drop__returns_empty_array_when_args_greater_than_size :Tests {
    is_deeply(drop(5, [1,2,3,]), []);
}


sub drop__removes_first_item_if_no_num_given :Tests {
    is_deeply(drop(["first", "second", "third", "fourth"]), ["second", "third", "fourth"]);
}

sub drop__removes_number_of_items_from_beginning :Tests {
    is_deeply(
        drop(2, ["first","second", "third", "fourth", "fifth"]),
        ["third", "fourth", "fifth"]
    )
}

sub drop__removes_no_items_if_num_is_zero :Tests {
    is_deeply(
        drop(0, ["first","second", "third", "fourth", "fifth"]),
        ["first","second", "third", "fourth", "fifth"],
    )
}

sub drop__returns_new_array :Tests {
    my $array = [1,2,3];

    ok($array != drop($array));
}


sub drop_right__returns_empty_array_when_empty_array :Tests {
    is_deeply(drop_right([]), []);
}

sub drop_right__returns_empty_array_when_args_undef :Tests {
    is_deeply(drop_right(), []);
}

sub drop_right__returns_empty_array_when_incomplete_args :Tests {
    is_deeply(drop_right(2, []), []);
}

sub drop_right__returns_empty_array_args_greater_than_size :Tests {
    is_deeply(drop_right(5, [1,2,3]), []);
}

sub drop_right__drops_last_item_if_no_num_given :Tests {
    is_deeply(drop_right([1,2,3,4,5,6,7]), [1,2,3,4,5,6]);
}

sub drop_right__drops_item_if_num_given :Tests {
    is_deeply(drop_right(1, [1,2,3,4,5,6,7]), [1,2,3,4,5,6]);
}

sub drop_right__drops_multi_items_from_end :Tests {
    is_deeply(drop_right(2, [1,2,3,4,5,6,7]), [1,2,3,4,5]);
}

sub drop_right__returns_new_array :Tests {
    my $array = [1,2,3];

    ok($array != drop_right($array));
}


sub take__returns_empty_array_when_empty_array :Tests {
    is_deeply(take([]), []);
}

sub take__returns_empty_array_when_args_undef :Tests {
    is_deeply(take(), []);
}

sub take__returns_empty_array_when_incomplete_args :Tests {
    is_deeply(take(2, []), []);
}

sub take__returns_entire_array_when_args_greater_than_size :Tests {
    is_deeply(
        take(5, [1,2,3]),
        [1,2,3]
    );
}

sub take__returns_first_item_from_array_default :Tests {
    is_deeply(take([1,2,3,4,5,6,7]), [1]);
}

sub take__returns_num_of_items_from_array :Tests {
    is_deeply(take(1, [1,2,3,4,5,6,7]), [1])
}

sub take__multi_items_from_array :Tests {
    is_deeply(take(2, [1,2,3,4,5,6,7]), [1,2])
}

sub take__returns_new_array :Tests {
    my $array = [];
    ok($array != take($array))
}



sub take_right__returns_empty_array_when_empty_array :Tests {
    is_deeply(take_right([]), []);
}

sub take_right__returns_empty_array_when_args_undef :Tests {
    is_deeply(take_right(), []);
}

sub take_right__returns_empty_array_when_incomplete_args :Tests {
    is_deeply(take_right(1, []), []);
}

sub take_right__returns_entire_array_when_args_greater_than_size :Tests {
    is_deeply(
        take_right(5, [1,2,3]),
        [1,2,3]
    );
}

sub take_right__returns__last_item_if_no_num_given :Tests {
    is_deeply(take_right([1,2,3,4,5,6,7]), [7])
}

sub take_right__returns_num_of_items_from_array :Tests {
    is_deeply(take_right(1, [1,2,3,4,5,6,7]), [7]);
}

sub take_right__returns_multi_items_from_array :Tests {
    is_deeply(take_right(3, [1,2,3,4,5,6,7]), [5,6,7]);
}

sub take_right__returns_new_array :Tests {
    my $array = [];
    ok($array != take($array))
}


sub assoc_returns_undef_when_args_undef :Tests {
    is_deeply(assoc(), undef);
}

sub assoc__returns_original_array_when_no_args :Tests {
    is_deeply(assoc([1,2,3,4,5,6,7]), [1,2,3,4,5,6,7]);
}

sub assoc__adds_undef_when_item_explicit_undef :Tests {
    is_deeply(assoc([1,2,3,4,5,6,7], 0, undef), [undef,2,3,4,5,6,7]);
}

sub assoc__adds_undef_when_item_implicit_undef :Tests {
    is_deeply(assoc([1,2,3,4,5,6,7], 0), [undef,2,3,4,5,6,7]);
}

sub assoc__returns_new_array_with_item_at_idx :Tests {
    is_deeply(assoc([1,2,3,4,5,6,7], 0, "item"), ["item",2,3,4,5,6,7]);
}

sub assoc__returns_new_array_with_item_at_diff_indx :Tests {
    is_deeply(assoc([1,2,3], 1, "item"), [1,"item",3]);
}

sub assoc__returns_new_array :Tests {
    my $array = [1,2,3];
    ok(assoc([1,2,3], 1, "item") != $array);
}

sub assoc__returns_new_hash_with_item_at_key :Tests {
    is_deeply(
        assoc({ key => 'foobar' }, 'key', 'item'),
        { key => 'item' }
    );
}

sub assoc__returns_new_hash_multi_item_at_key :Tests {
    is_deeply(
        assoc({ key => 'foobar', other => 'value'}, 'key', 'item'),
        { key => 'item' , other => 'value'}
    );
}

sub assoc__returns_new_hash :Tests {
    my $hash = { key => 'value' };
    ok(assoc($hash, 'key', 'newValue') != $hash);
}


sub chain__accepts_expression_as_first_arg :Tests {
    my $addThree = sub { (shift) + 3 };

    my $result = chain(
        100,
        $addThree,
    );

    is($result, 103);
}

sub chain__accepts_func_as_first_arg :Tests {
    my $addThree = sub { (shift) + 3 };

    my $result = chain(
        sub { 100 },
        $addThree,
    );

    is($result, 103);
}

sub chain__accepts_anon_func :Tests {
    my $result = chain(
        100,
        sub { (shift) + 3 },
    );

    is($result, 103);
}

sub flatten__returns_empty_array_when_empty_array :Tests {
    is_deeply(flatten([]), []);
}

sub flatten__returns_empty_array_when_args_undef :Tests {
    is_deeply(flatten(), []);
}

sub flatten__returns_array_if_already_flat :Tests {
    is_deeply(flatten([1,2,3]), [1,2,3]);
}

sub flatten__returns_flattened_array :Tests {
    is_deeply(flatten([[1], 2, [3]]), [1,2,3]);
}

sub flatten__returns_single_level_flattened :Tests {
    is_deeply(flatten([[1], 2, [[3]]]), [1,2,[3]]);
}


sub subarray__returns_empty_array_if_args_undef :Tests {
    is_deeply(subarray(), []);
}

sub subarray__returns_orignal_array_if_incomplete_args :Tests {
    is_deeply(subarray([1,2,3,4,5,6,7]), [1,2,3,4,5,6,7]);
}

sub subarray__returns_remaining_array_from_start_idx :Tests {
    is_deeply(subarray([1,2,3,4,5,6,7], 3), [4,5,6,7]);
}

sub subarray__returns_items_between_idxs_non_inclusive_end :Tests {
    is_deeply(subarray([1,2,3,4,5,6,7], 3,5), [4,5]);
}

sub subarray__returns_empty_array_when_start_end_same :Tests {
    is_deeply(subarray([1,2,3,4,5,6,7], 3,3), []);
}

sub subarray__returns_new_array {
    my $array = [1,2,3];

    ok($array != subarray($array, 1))
}


sub first__returns_undefined_if_no_args :Tests {
    is(first(), undef);
}

sub first__returns_first_item_in_list_of_one :Tests {
    is(first([1]), 1);
}

sub first__returns_first_item_in_list_of_many_items :Tests {
    is(first([1,2,3,4]), 1);
}


sub end__returns_undefined_if_no_args :Tests {
    is(end(), undef);
}

sub end__returns_last_item_in_list_of_one :Tests {
    is(end([1]), 1);
}

sub end__returns_last_item_in_list_of_many_items :Tests {
    is(end(["item", "another", "lastItem"]), "lastItem");
}

sub incr__throws_warning_if_non_num_as_arg :Tests {

    local $SIG{__WARN__} = sub {
        die shift;
    };

    eval { incr("string") };

    like($@, qr/isn't numeric in/);
}

sub incr__returns_num_plus_one :Tests {
    is(incr(100), 101);
}


sub decr__throws_warning_if_non_num_as_arg :Tests {

    local $SIG{__WARN__} = sub {
        die shift;
    };

    eval{ decr("string") };

    like($@, qr/isn't numeric in/);
}

sub decr__returns_num_minus_one :Tests {
    is(decr(100), 99);
}

sub decr__returns_num_minus_one_when_zero :Tests {
    is(decr(0), -1);
}

__PACKAGE__->runtests;
