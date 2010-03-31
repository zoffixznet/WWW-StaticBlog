use Test::Mini::Unit;

testcase WWW::StaticBlog
{
    use Data::Faker;
    use Directory::Scratch;
    use File::Spec;
    use Text::Lorem;

    use WWW::StaticBlog::Author;
    use WWW::StaticBlog::Compendium;
    use WWW::StaticBlog::Post;
    use WWW::StaticBlog::Site;

    use List::MoreUtils qw( uniq          );
    use Text::Outdent   qw( outdent_quote );

    sub _generate_post
    {
        my $self    = shift;
        my %options = @_;

        my $faker = Data::Faker->new();
        my $lorem = Text::Lorem->new();

        return WWW::StaticBlog::Post->new(
            author    => $options{author}    || $faker->name(),
            posted_on => $options{posted_on} || $faker->date(),
            tags      => $options{tags}      || $lorem->words(int(rand(3))),
            title     => $options{title}     || $lorem->sentences(1),
            body      => outdent_quote(
                $options{body} || $lorem->paragraphs(3)
            ),
        );
    }

    sub _generate_author
    {
        my $self    = shift;
        my %options = @_;

        my $faker = Data::Faker->new();

        return WWW::StaticBlog::Author->new(
            name  => $options{name}  || $faker->name(),
            email => $options{email} || $faker->email(),
            alias => $options{alias} || $faker->username(),
        );
    }

    test load_authors_from_dir
    {
        my $tmpdir = Directory::Scratch->new();

        my $site = WWW::StaticBlog::Site->new(
            title          => 'WWW::StaticBlog',
            authors_dir    => "$tmpdir",
            index_template => 'index',
            post_template  => 'post',
        );
        $tmpdir->touch('author1.yaml', split("\n", outdent_quote(q|
            ---
            name: Jacob Helwig
            alias: jhelwig
            email: jhelwig@cpan.org
        |)));
        $tmpdir->touch('author2.yaml', split("\n", outdent_quote(q|
            ---
            name: Tom Servo
            alias: tservo
            email: tservo@satelliteoflove.com
        |)));
        $tmpdir->touch('author3.yaml', split("\n", outdent_quote(q|
            ---
            name: Crow T. Robot
            alias: crobot
            email: crobot@satelliteoflove.com
        |)));

        assert_eq(
            $site->num_authors(),
            3,
            'Loads 3 authors from files',
        );

        assert_eq(
            [
                map { $_->name() } $site->sorted_authors(
                    sub { $_[0]->name() cmp $_[1]->name() }
                )
            ],
            [
                "Crow T. Robot",
                "Jacob Helwig",
                "Tom Servo",
            ],
        );

        $tmpdir->mkdir('more_authors');
        $tmpdir->touch(
            File::Spec->catdir('more_authors', 'author3.yaml'),
            split("\n", outdent_quote(q|
                ---
                name: Gypsy
                alias: gypsy
                email: gypsy@satelliteoflove.com
            |))
        );

        assert($site->reload_authors());

        assert_eq(
            $site->num_authors(),
            4,
            'Loads 4 authors from files',
        );

        assert_eq(
            [
                map { $_->name() } $site->sorted_authors(
                    sub { $_[0]->name() cmp $_[1]->name() }
                )
            ],
            [
                "Crow T. Robot",
                "Gypsy",
                "Jacob Helwig",
                "Tom Servo",
            ],
        )
    }
}
