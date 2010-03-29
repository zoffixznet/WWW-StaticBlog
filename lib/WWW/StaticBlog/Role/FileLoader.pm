use MooseX::Declare;

role WWW::StaticBlog::Role::FileLoader
{
    use File::Find qw(find);
    use File::Spec ();

    method _find_files_for_dir($dir)
    {
        my @files;
        find(
            sub {
                my $file = File::Spec->rel2abs($_);
                push @files, "$file"
                    if -T $file;
            },
            $dir,
        );

        return @files;
    }

}
