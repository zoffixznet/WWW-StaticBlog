use MooseX::Declare;

class Test::WWW::StaticBlog::Compendium
{
    use Test::Sweet;

    use Data::Faker;
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
            posts   => [ @posts ],
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
            posts   => [ @posts ],
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

    method _write_file_contents($contents)
    {
        my ($post_fh, $post_filename) = tempfile();
        $post_fh->autoflush(1);
        print $post_fh outdent_quote($contents);

        return($post_filename, $post_fh);
    }
}
