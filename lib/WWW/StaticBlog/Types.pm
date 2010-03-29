use MooseX::Declare;

class WWW::StaticBlog::Types
{
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

    use DateTime::Format::Natural;
    use Text::CSV;

    subtype DateTime,
        as Object,
        where { $_->isa('DateTime') };

    coerce DateTime,
        from Str,
        via {
            my $parser = DateTime::Format::Natural->new();
            my $dt = $parser->parse_datetime($_);

            unless ($parser->success()) {
                warn $parser->error();
                return;
            }

            return $dt;
        };

    subtype TagList,
        as ArrayRef[Str];

    coerce TagList,
        from Str,
        via {
            my $csv = Text::CSV->new({sep_char => ' '});
            $csv->parse($_);
            return unless $csv->status();

            return [ $csv->fields() ];
        };
}
