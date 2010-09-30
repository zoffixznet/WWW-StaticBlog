use Test::More;
use Test::Spelling;

add_stopwords(qw(
    AnnoCPAN
    blog
    CPAN
    Helwig
    RT
));

all_pod_files_spelling_ok();
