use MooseX::Declare;

class WWW::StaticBlog::Types
{
    our $VERSION = '0.001';

    use MooseX::Types
        -declare => [qw(
            DateTime
            TagList
        )],
    ;

    use MooseX::Types::Moose qw(
        ArrayRef
        Object
        Str
    );

    use Date::Parse qw(str2time);

    use DateTime::TimeZone ();
    use Text::CSV ();
    use WWW::StaticBlog::Tag ();

    use aliased 'DateTime' => 'RealDateTime';

    subtype DateTime,
        as Object,
        where { $_->isa('DateTime') };

    coerce DateTime,
        from Str,
        via {
            my $epoch = str2time($_);

            return RealDateTime->now() unless $epoch;

            return RealDateTime->from_epoch(
                epoch     => $epoch,
                time_zone => DateTime::TimeZone->new( name => 'local' ),
            );
        };

    subtype TagList,
        as ArrayRef['WWW::StaticBlog::Tag'];

    coerce TagList,
        from Str,
        via {
            my $csv = Text::CSV->new({sep_char => ' '});
            $csv->parse($_);

            die "Unable to parse tags from '$_'"
                unless $csv->status();

            return [
                map { WWW::StaticBlog::Tag->new($_) }
                grep { /./ } $csv->fields()
            ];
        };
}
