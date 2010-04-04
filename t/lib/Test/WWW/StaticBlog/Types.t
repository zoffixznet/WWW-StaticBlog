use Test::Mini::Unit;

class Test::WWW::StaticBlog::Types::TestClass
{
    use WWW::StaticBlog::Types qw(
        DateTime
        TagList
    );

    has tag => (
        is      => 'rw',
        traits  => ['Array'],
        isa     => TagList,
        coerce  => 1,
        handles => {
            num_tags    => 'count',
            sorted_tags => 'sort',
            clear_tags  => 'clear',
        },
    );

    has datetime => (
        is        => 'rw',
        isa       => DateTime,
        coerce    => 1,
        clearer   => 'clear_datetime',
        predicate => 'has_datetime',
    );
}

testcase Test::WWW::StaticBlog::Types
{
    test split_tags_on_whitespace
    {
        my $types = Test::WWW::StaticBlog::Types::TestClass->new(
            tag => 'there should be several tags',
        );

        assert_eq(
            [ $types->sorted_tags() ],
            [qw(
                be
                several
                should
                tags
                there
            )],
        );
    }

    test split_tags_on_whitespace_with_quoting
    {
        my $types = Test::WWW::StaticBlog::Types::TestClass->new(
            tag => 'there should be "several tags"',
        );

        assert_eq(
            [ $types->sorted_tags() ],
            [
                'be',
                'several tags',
                'should',
                'there',
            ],
        );
    }

    test coerce_datetime_from_str
    {
        my $types = Test::WWW::StaticBlog::Types::TestClass->new(
            datetime => '2010-03-22 19:01:10',
        );

        assert_isa(
            $types->datetime(),
            'DateTime',
        );

        assert_eq(
            $types->datetime()->iso8601(),
            '2010-03-22T19:01:10',
        );
    }
}
