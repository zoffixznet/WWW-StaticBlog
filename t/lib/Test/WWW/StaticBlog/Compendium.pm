use MooseX::Declare;

class Test::WWW::StaticBlog::Compendium
{
    use Test::Sweet;

    use Data::Faker;
    use Directory::Scratch;
    use File::Spec;
    use Text::Lorem;

    use WWW::StaticBlog::Author;
    use WWW::StaticBlog::Compendium;
    use WWW::StaticBlog::Post;

    use List::MoreUtils qw( uniq          );
    use Test::TempDir   qw( tempfile      );
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

    test constructed_with_values
    {
        my @posts = map { $self->_generate_post() } (1..5);

        my @authors = map { $self->_generate_author(name => $_) }
            uniq(map { $_->author() } @posts);

        my $compendium = WWW::StaticBlog::Compendium->new(
            posts   => [ @posts   ],
            authors => [ @authors ],
        );

        is_deeply(
            [ $compendium->sorted_posts() ],
            [ sort { DateTime->compare($a->posted_on(), $b->posted_on()) } @posts ],
            'sorted_posts sorts by posted_on',
        );
    }

    test find_posts_for_author
    {
        my @posts = map { $self->_generate_post() } (1..5);

        my @authors = map { $self->_generate_author(name => $_) }
            uniq(map { $_->author() } @posts);

        push @posts, $self->_generate_post(author => $authors[0]->alias())
            for (1..3);

        my $compendium = WWW::StaticBlog::Compendium->new(
            posts   => [ @posts   ],
            authors => [ @authors ],
        );

        is_deeply(
            [ $compendium->posts_for_author($authors[0]->alias())  ],
            [ grep { $_->author() eq $authors[0]->alias() } @posts ],
            'posts_for_author finds posts with the same author string',
        );

        is_deeply(
            [ $compendium->posts_for_author($authors[0]) ],
            [
                grep {
                    $_->author() eq $authors[0]->alias()
                    || $_->author() eq $authors[0]->name()
                } @posts
            ],
            'posts_for_author finds posts with the same author, or alias, when given an Author',
        );
    }

    test load_posts_from_dir
    {
        my $tmpdir = Directory::Scratch->new();

        my $compendium = WWW::StaticBlog::Compendium->new(
            posts_dir => "$tmpdir",
        );
        $tmpdir->touch('post1', split("\n", outdent_quote(q|
            Author: jhelwig
            Title: foo
            Post-Date: 2010-03-25 21:19:40

            Here's the post contents.
        |)));
        $tmpdir->touch('post2', split("\n", outdent_quote(q|
            Author: jhelwig
            Title: bar
            Post-Date: 2010-03-25 21:20:00

            Here's the second post's contents.
        |)));
        $tmpdir->touch('post3', split("\n", outdent_quote(q|
            Author: Jacob Helwig
            Title: baz
            Post-Date: 2010-03-25 21:30:00

            Here's the third post's contents.
        |)));

        is(
            $compendium->num_posts(),
            3,
            'Loads 3 posts from files',
        );

        is_deeply(
            [ map { $_->body() } $compendium->sorted_posts() ],
            [
                "Here's the post contents.\n",
                "Here's the second post's contents.\n",
                "Here's the third post's contents.\n",
            ],
        );

        $tmpdir->mkdir('more_posts');
        $tmpdir->touch(
            File::Spec->catdir('more_posts', 'post3'),
            split("\n", outdent_quote(q|
                Author: Jacob Helwig
                Title: qux
                Post-Date: 2010-03-25 22:00:30

                Here's the fourth post's contents.
            |))
        );

        ok($compendium->reload_posts());

        is(
            $compendium->num_posts(),
            4,
            'Loads 4 posts from files',
        );

        is_deeply(
            [ map { $_->body() } $compendium->sorted_posts() ],
            [
                "Here's the post contents.\n",
                "Here's the second post's contents.\n",
                "Here's the third post's contents.\n",
                "Here's the fourth post's contents.\n",
            ],
        )
    }
}
