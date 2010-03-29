use 5.010;

use MooseX::Declare;

class WWW::StaticBlog::Compendium
    with WWW::StaticBlog::Role::FileLoader
{
    use MooseX::Types::Moose qw(
        ArrayRef
        Undef
    );

    use DateTime;

    use WWW::StaticBlog::Post;

    has posts => (
        is      => 'rw',
        traits  => ['Array'],
        isa     => 'ArrayRef[WWW::StaticBlog::Post]|Undef',
        lazy    => 1,
        builder => '_build_posts',
        handles => {
            add_post      => 'push',
            all_posts     => 'elements',
            clear_posts   => 'clear',
            filter_posts  => 'grep',
            num_posts     => 'count',
            _sorted_posts => 'sort',
        },
    );

    has posts_dir => (
        is        => 'rw',
        isa       => 'Str',
        predicate => 'have_posts_dir',
        clearer   => 'forget_posts_dir',
    );

    method sorted_posts()
    {
        return $self->_sorted_posts(
            sub { DateTime->compare($_[0]->posted_on(), $_[1]->posted_on()) }
        );
    }

    method posts_for_author($author)
    {
        return $self->_posts_for_author_obj($author)
            if (ref $author eq 'WWW::StaticBlog::Author');

        return $self->_posts_for_author_str($author);
    }

    method _posts_for_author_obj($author)
    {
        return $self->filter_posts(
            sub {
                $_->author() =~ $author->name()
                || $_->author() =~ $author->alias()
            }
        );
    }

    method _posts_for_author_str($author)
    {
        return $self->filter_posts(
            sub { $_->author() =~ $author }
        );
    }

    method _build_posts()
    {
        return [] unless $self->have_posts_dir();

        my @posts;
        foreach my $post_file ($self->_find_files_for_dir($self->posts_dir())) {
            push @posts, WWW::StaticBlog::Post->new(filename => $post_file);
        }

        return \@posts;
    }

    method reload_posts()
    {
        $self->clear_posts();
        $self->posts($self->_build_posts());
    }
}

"I don't think there's a punch-line scheduled, is there?";
__END__
=head1 NAME

WWW::StaticBlog::Compendium - Collection of all Authors, and Posts for a blog.


=head1 SYNOPSIS

# TODO - Write the documentation.

=head1 AUTHOR

Jacob Helwig, C<< <jhelwig at cpan.org> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-www-staticblog at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-StaticBlog>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.
    perldoc WWW::StaticBlog
You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-StaticBlog>


=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-StaticBlog>


=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-StaticBlog>


=item * Search CPAN

L<http://search.cpan.org/dist/WWW-StaticBlog>


=back


=head1 COPYRIGHT & LICENSE

Copyright 2010 Jacob Helwig, all rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
