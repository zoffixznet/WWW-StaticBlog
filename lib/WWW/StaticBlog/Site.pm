use 5.010;

use MooseX::Declare;

class WWW::StaticBlog::Site
    with WWW::StaticBlog::Role::FileLoader
    with MooseX::SimpleConfig
    with MooseX::Getopt
{
    use Cwd        qw( getcwd      );
    use File::Path qw( remove_tree );

    use Time::SoFar qw(
        runinterval
        runtime
    );

    use WWW::StaticBlog::Author;
    use WWW::StaticBlog::Compendium;

    has title => (
        is       => 'rw',
        isa      => 'Str',
        required => 1,
    );

    has tagline => (
        is        => 'rw',
        isa       => 'Str',
        predicate => 'has_tagline',
    );

    has authors => (
        is      => 'rw',
        isa     => 'ArrayRef[WWW::StaticBlog::Author]|Undef',
        lazy    => 1,
        builder => '_build_authors',
        traits  => [qw(
            Array
            MooseX::Getopt::Meta::Attribute::Trait::NoGetopt
        )],
        handles => {
            add_authors    => 'push',
            all_authors    => 'elements',
            clear_authors  => 'clear',
            filter_authors => 'grep',
            num_authors    => 'count',
            sorted_authors => 'sort',
        },
    );

    has compendium => (
        is      => 'rw',
        isa     => 'WWW::StaticBlog::Compendium',
        lazy    => 1,
        builder => '_build_compendium',
        traits  => [qw(
            MooseX::Getopt::Meta::Attribute::Trait::NoGetopt
        )],
    );

    has posts_dir => (
        is        => 'rw',
        isa       => 'Str',
        predicate => 'has_posts_dir',
    );

    has authors_dir => (
        is        => 'rw',
        isa       => 'Str',
        predicate => 'has_authors_dir',
    );

    has output_dir => (
        is      => 'rw',
        isa     => 'Str',
        default => sub { getcwd() },
    );

    has template_class => (
        is      => 'ro',
        isa     => 'Str',
        default => '::Template::Toolkit',
    );

    has _template => (
        is         => 'ro',
        isa        => 'Object',
        lazy_build => 1,
    );

    has template_options => (
        is      => 'rw',
        traits  => ['Hash'],
        isa     => 'HashRef',
        lazy    => 1,
        default => sub { {} },
        handles => {
            delete_template_option  => 'delete',
            get_template_option     => 'get',
            has_no_template_options => 'is_empty',
            set_template_option     => 'set',
            template_option_pairs   => 'kv',
        },
    );

    has post_template => (
        is       => 'rw',
        isa      => 'Str',
        required => 1,
    );

    has author_template => (
        is       => 'rw',
        isa      => 'Str',
    );

    method _build_authors()
    {
        return [] unless $self->has_authors_dir();

        my @authors;
        foreach my $author_file ($self->_find_files_for_dir($self->authors_dir())) {
            push @authors, WWW::StaticBlog::Author->new(filename => $author_file);
        }

        return \@authors;
    }

    method _build_compendium()
    {
        return WWW::StaticBlog::Compendium->new(
            posts_dir => $self->posts_dir(),
        );
    }

    method reload_authors()
    {
        $self->clear_authors();
        $self->authors($self->_build_authors());
    }

    method _build__template()
    {
        my $template_class = $self->template_class();
        $template_class =~ s/^::/WWW::StaticBlog::/;

        Class::MOP::load_class($template_class);

        $template_class->new(
            options  => $self->template_options(),
            fixtures => {
                site_title   => $self->title(),
                site_tagline => $self->tagline(),
            },
        );
    }

    method render_posts()
    {
        say "Rendering posts:";
        foreach my $post ($self->compendium()->sorted_posts()) {
            $post->save();
            runinterval();
            print "\t" . $post->title();
            my @path = split('/', $post->url());
            my $out_file = File::Spec->catfile(
                $self->output_dir(),
                @path,
            );

            my @extra_head_sections;
            push @extra_head_sections, {
                name     => 'style',
                attr     => 'type="text/css"',
                contents => $post->inline_css(),
            } if $post->inline_css();

            $self->_template()->render_to_file(
                $self->post_template(),
                {
                    post                => $post,
                    page_title          => $post->title(),
                    extra_head_sections => \@extra_head_sections,
                },
                $out_file,
            );
            say " => $out_file (" . runinterval() . ")";
        }
    }

    method run()
    {
        say "Cleaning up " . $self->output_dir();
        remove_tree( $self->output_dir(), {keep_root => 1} );
        $self->render_posts();
        say "Total time: " . runtime();
    }
}
