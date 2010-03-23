use MooseX::Declare;

class Test::WWW::StaticBlog::Author
{
    use Test::Sweet;
    use WWW::StaticBlog::Author;

    use Test::TempDir qw( tempfile      );
    use Text::Outdent qw( outdent_quote );

    test create_with_explicit_attributes
    {
        my $author = WWW::StaticBlog::Author->new(
            name  => 'Jacob Helwig',
            email => 'jhelwig@cpan.org',
            alias => 'jhelwig',
        );

        is(
            $author->name(),
            'Jacob Helwig',
        );
        is(
            $author->email(),
            'jhelwig@cpan.org',
        );
        is(
            $author->alias(),
            'jhelwig',
        );
    }

    test create_without_alias
    {
        my $author = WWW::StaticBlog::Author->new(
            name  => 'Jacob Helwig',
            email => 'jhelwig@cpan.org',
        );

        is(
            $author->name(),
            'Jacob Helwig',
        );
        is(
            $author->email(),
            'jhelwig@cpan.org',
        );
        is(
            $author->alias(),
            undef,
        );
    }

    test create_without_email
    {
        my $author = WWW::StaticBlog::Author->new(
            name  => 'Jacob Helwig',
            alias => 'jhelwig',
        );

        is(
            $author->name(),
            'Jacob Helwig',
        );
        is(
            $author->email(),
            undef,
        );
        is(
            $author->alias(),
            'jhelwig'
        );
    }

    test create_without_name
    {
        my $author = WWW::StaticBlog::Author->new(
            email => 'jhelwig@cpan.org',
            alias => 'jhelwig',
        );

        is(
            $author->name(),
            undef,
        );
        is(
            $author->email(),
            'jhelwig@cpan.org',
        );
        is(
            $author->alias(),
            'jhelwig',
        );
    }

    test create_from_file
    {
        my ($filename) = $self->_write_config_file(q{
            ---
            name: Jacob Helwig
            email: jhelwig@cpan.org
            alias: jhelwig
        });

        my $author = WWW::StaticBlog::Author->new(
            filename => $filename,
        );

        is(
            $author->name(),
            'Jacob Helwig',
        );
        is(
            $author->email(),
            'jhelwig@cpan.org',
        );
        is(
            $author->alias(),
            'jhelwig',
        );
    }

    test create_from_file_without_alias
    {
        my ($filename) = $self->_write_config_file(q{
            ---
            name: Jacob Helwig
            email: jhelwig@cpan.org
        });

        my $author = WWW::StaticBlog::Author->new(
            filename => $filename,
        );

        is(
            $author->name(),
            'Jacob Helwig',
        );
        is(
            $author->email(),
            'jhelwig@cpan.org',
        );
        is(
            $author->alias(),
            undef,
        );
    }

    test create_from_file_without_email
    {
        my ($filename) = $self->_write_config_file(q{
            ---
            name: Jacob Helwig
            alias: jhelwig
        });

        my $author = WWW::StaticBlog::Author->new(
            filename => $filename,
        );

        is(
            $author->name(),
            'Jacob Helwig',
        );
        is(
            $author->email(),
            undef,
        );
        is(
            $author->alias(),
            'jhelwig',
        );
    }

    test create_from_file_without_name
    {
        my ($filename) = $self->_write_config_file(q{
            ---
            email: jhelwig@cpan.org
            alias: jhelwig
        });

        my $author = WWW::StaticBlog::Author->new(
            filename => $filename,
        );

        is(
            $author->name(),
            undef,
        );
        is(
            $author->email(),
            'jhelwig@cpan.org',
        );
        is(
            $author->alias(),
            'jhelwig',
        );
    }

    method _write_config_file($contents, $suffix = 'yaml')
    {
        my ($config_fh, $config_filename) = tempfile(SUFFIX => ".$suffix");
        $config_fh->autoflush(1);
        print $config_fh outdent_quote($contents);

        return($config_filename, $config_fh);
    }
}
