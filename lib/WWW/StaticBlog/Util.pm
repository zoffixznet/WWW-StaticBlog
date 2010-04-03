use MooseX::Declare;

class WWW::StaticBlog::Util
{
    use Moose::Exporter;

    method sanitize_for_dir_name($text)
    {
        my $new_text = $text;

        $new_text =~ s|[:/?#[\]@!\$&'()*+,;=. ]|_|g;

        return $new_text;
    }

    Moose::Exporter->setup_import_methods(
        with_meta => [qw(
            sanitize_for_dir_name
        )],
    );
}
