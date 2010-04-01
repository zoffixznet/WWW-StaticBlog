use 5.010;

use MooseX::Declare;

class WWW::StaticBlog::Site
    with WWW::StaticBlog::Role::FileLoader
    with MooseX::SimpleConfig
    with MooseX::Getopt
{
    use Cwd                   qw( getcwd      );
    use File::Copy::Recursive qw( rcopy       );
    use File::Slurp           qw( write_file  );
    use List::MoreUtils       qw( uniq        );

    use File::Path qw(
        make_path
        remove_tree
    );
    use Time::SoFar qw(
        runinterval
        runtime
    );

    use DateTime ();
    use File::Spec ();
    use WWW::StaticBlog::Author ();
    use WWW::StaticBlog::Compendium ();
    use XML::Atom::SimpleFeed ();

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

    has static_dir => (
        is        => 'rw',
        isa       => 'Str',
        predicate => 'has_static_dir',
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

    has index_template => (
        is       => 'rw',
        isa      => 'Str',
        required => 1,
    );

    has index_post_count => (
        is      => 'rw',
        isa     => 'Int',
        default => 10,
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

    has debug => (
        is      => 'rw',
        isa     => 'Bool',
        default => 0,
    );

    has post_feed => (
        is  => 'rw',
        isa => 'Str|Undef',
    );

    has post_feed_count => (
        is      => 'rw',
        isa     => 'Int',
        default => 10,
    );

    has url => (
        is      => 'rw',
        isa     => 'Str',
        lazy    => 1,
        default => sub {
            my $self = shift;
            die "url required with post_feed"
                if $self->post_feed();
            return '';
        },
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
                debug        => $self->debug(),
                site_tagline => $self->tagline(),
                site_title   => $self->title(),
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

    method render_index()
    {
        runinterval();
        print "Rendering index... ";

        my @posts = $self->compendium()->newest_n_posts($self->index_post_count());
        my @extra_style_head_sections;
        foreach my $post (@posts) {
            push @extra_style_head_sections, $post->inline_css()
                if $post->inline_css();
        }

        @extra_style_head_sections = map +{
                name     => 'style',
                attr     => 'type="text/css"',
                contents => $_,
        }, uniq @extra_style_head_sections;

        my $out_file = File::Spec->catfile(
            $self->output_dir(),
            'index.html',
        );
        $self->_template()->render_to_file(
            $self->index_template(),
            {
                posts               => [ @posts                     ],
                extra_head_sections => [ @extra_style_head_sections ],
            },
            $out_file,
        );

        say "(" . runinterval() . ")";
    }

    method render_post_feed()
    {
        return unless $self->post_feed();
        runinterval();
        print "Generating post feed... ";

        my $feed = XML::Atom::SimpleFeed->new(
            title     => $self->title(),
            subtitle  => $self->tagline(),
            updated   => DateTime->now()->iso8601(),
            generator => 'WWW::StaticBlog',
            link      => $self->url(),
            link      => {
                rel  => 'self',
                href => $self->url() . $self->post_feed(),
            },
        );

        foreach my $post (reverse $self->compendium()->newest_n_posts($self->post_feed_count())) {
            $feed->add_entry(
                title     => $post->title(),
                link      => $self->url() . $post->url(),
                id        => $self->url() . $post->url(),
                author    => $post->author(),
                content   => $post->body(),
                published => $post->posted_on(),
                updated   => $post->updated_on(),
                (map {
                    (category => $_)
                } ($post->sorted_tags())),
            );
        }

        my $out_file = File::Spec->catfile(
            $self->output_dir(),
            $self->post_feed(),
        );

        my (undef, $out_dir, undef) = File::Spec->splitpath($out_file);
        die "Could not create $out_dir"
            unless make_path($out_dir);

        write_file(
            $out_file,
            $feed->as_string(),
        );

        say $self->post_feed() . "(" . runinterval() . ")";
    }

    method copy_static_files()
    {
        return unless $self->has_static_dir();

        runinterval();
        print "Copying static files... ";
        rcopy($self->static_dir(), $self->output_dir());
        say "(" . runinterval() . ")";
    }

    method run()
    {
        say "Enabling debug mode." if $self->debug();
        say "Cleaning up... " . $self->output_dir();
        remove_tree( $self->output_dir(), {keep_root => 1} );

        $self->render_posts();
        $self->render_index();
        $self->render_post_feed();
        $self->copy_static_files();

        say "Total time: " . runtime();
    }
}
