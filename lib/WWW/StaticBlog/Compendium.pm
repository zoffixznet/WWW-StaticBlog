use 5.010;

use MooseX::Declare;

class WWW::StaticBlog::Compendium
{
    use MooseX::Types::Moose qw(
        ArrayRef
        Undef
    );

    use DateTime;
    use WWW::StaticBlog::Author;
    use WWW::StaticBlog::Post;

    has posts => (
        is      => 'rw',
        traits  => ['Array'],
        isa     => 'ArrayRef[WWW::StaticBlog::Post]|Undef',
        handles => {
            add_post      => 'push',
            num_posts     => 'count',
            _sorted_posts => 'sort',
            clear_posts   => 'clear',
            filter_posts  => 'grep',
        },
    );

    has authors => (
        is      => 'rw',
        traits  => ['Array'],
        isa     => 'ArrayRef[WWW::StaticBlog::Author]|Undef',
        handles => {
            add_authors    => 'push',
            num_authors    => 'count',
            clear_authors  => 'clear',
            filter_authors => 'grep',
        },
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
