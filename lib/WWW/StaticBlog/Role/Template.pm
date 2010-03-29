use MooseX::Declare;

role WWW::StaticBlog::Role::Template
{
    use Class::MOP;

    has template_class => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
    );

    has options => (
        is      => 'ro',
        isa     => 'HashRef',
        default => sub { {} },
    );

    has template_engine => (
        is         => 'ro',
        isa        => 'Object',
        lazy_build => 1,
    );

    has fixtures => (
        is      => 'ro',
        isa     => 'HashRef',
        default => sub { {} },
    );

    requires 'render';
    requires 'render_to_file';
    requires '_build_template_engine';
}
