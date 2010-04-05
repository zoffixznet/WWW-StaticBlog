use MooseX::Declare;

class WWW::StaticBlog::Template::Toolkit
{
    our $VERSION = '0.001';

    use Hash::Merge qw(merge);

    method render($template, HashRef $contents)
    {
        my $output = '';
        $self->template_engine($template, $contents, \$output)
            || die $self->template_engine()->error();

        return $output;
    }

    method render_to_file($template, HashRef $contents, Str $out_file_name)
    {
        $self->template_engine->process(
            $template,
            merge(
                { constants => $self->fixtures},
                $contents,
            ),
            $out_file_name,
            binmode => ':utf8',
        ) || die $self->template_engine()->error();

        return 1;
    }

    method _build_template_engine()
    {
        Class::MOP::load_class($self->template_class());

        return $self->template_class()->new(
            $self->options()
        );
    }

    with 'WWW::StaticBlog::Role::Template';

    has '+template_class' => (default => 'Template');
}
