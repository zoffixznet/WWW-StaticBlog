use MooseX::Declare;

class Test::WWW::StaticBlog::Post
{
    use Test::Sweet;
    use WWW::StaticBlog::Post;

    use Test::TempDir qw( tempfile      );
    use Text::Outdent qw( outdent_quote );

    test constructed_with_values
    {
        my $post = WWW::StaticBlog::Post->new(
            author    => 'jhelwig',
            posted_on => '2010-03-22 22:05:10',
            tags      => 'First post! "Aw, jeah."',
            title     => 'The very first post!',
            body      => outdent_quote(q|
                {{{ Markdown }}}
                A paragraph.

                One with some *bold*, and **stronger** emphasis.

                 * It's got
                 * a list.

                Some more text.

                 1. Or
                 2. Two

                {{{ Code lang=Perl }}}

                map { $_->thing() } @stuff;
            |),
        );

        is(
            $post->author(),
            'jhelwig',
            'author',
        );
        is(
            $post->posted_on()->iso8601(),
            '2010-03-22T22:05:10',
            'posted_on',
        );
        is_deeply(
            $post->tags(),
            [
                'First',
                'post!',
                'Aw, jeah.',
            ],
            'tags',
        );
        is(
            $post->title(),
            'The very first post!',
            'title',
        );
        is(
            $post->body(),
            outdent_quote(q|
                {{{ Markdown }}}
                A paragraph.

                One with some *bold*, and **stronger** emphasis.

                 * It's got
                 * a list.

                Some more text.

                 1. Or
                 2. Two

                {{{ Code lang=Perl }}}

                map { $_->thing() } @stuff;
            |),
            'body',
        );
        is(
            $post->rendered_body(),
            outdent_quote(q|
                <div class="text-multi text-multi-markdown">
                <p>A paragraph.</p>

                <p>One with some <em>bold</em>, and <strong>stronger</strong> emphasis.</p>

                <ul>
                <li>It's got</li>
                <li>a list.</li>
                </ul>

                <p>Some more text.</p>

                <ol>
                <li>Or</li>
                <li>Two</li>
                </ol>

                </div>
                <pre class="text-multi text-multi-code text-multi-code-perl">
                <span class="Normal">
                </span><span class="Function">map</span><span class="Normal">&nbsp;{&nbsp;</span><span class="Variable">$_</span><span class="Normal">-&gt;thing()&nbsp;}&nbsp;</span><span class="DataType">@stuff</span><span class="Normal">;</span>
                </pre>
            |),
            'rendered_body',
        );
        is(
            $post->rendered_body(1),
            outdent_quote(q|
                <!-- A paragraph.

                One with some *bold*, and **stronger** emphasis.

                 * It's got
                 * a list.

                Some more text.

                 1. Or
                 2. Two
                 -->
                <div class="text-multi text-multi-markdown">
                <p>A paragraph.</p>

                <p>One with some <em>bold</em>, and <strong>stronger</strong> emphasis.</p>

                <ul>
                <li>It's got</li>
                <li>a list.</li>
                </ul>

                <p>Some more text.</p>

                <ol>
                <li>Or</li>
                <li>Two</li>
                </ol>

                </div>
                <!-- 
                map { $_->thing() } @stuff; -->
                <pre class="text-multi text-multi-code text-multi-code-perl">
                <span class="Normal">
                </span><span class="Function">map</span><span class="Normal">&nbsp;{&nbsp;</span><span class="Variable">$_</span><span class="Normal">-&gt;thing()&nbsp;}&nbsp;</span><span class="DataType">@stuff</span><span class="Normal">;</span>
                </pre>
            |),
            'detailed rendered_body',
        );
        is(
            $post->inline_css(),
            outdent_quote(q|
                .text-multi-code {
                        white-space: pre;
                        background: #0a0a0a;
                        color: #cccccc;
                        font-family: monospace;
                        font-size: .95em;
                        border: 1px solid #555555;
                        overflow: auto;
                        padding: 2em;
                        width: 46em;
                }
                .text-multi-code span.Alert { color: #0000ff; }
                .text-multi-code span.BaseN { color: #007f00; }
                .text-multi-code span.BString { color: #c9a7ff; }
                .text-multi-code span.Char { color: #ff00ff; }
                .text-multi-code span.Comment { color: #cc9900; }
                .text-multi-code span.DataType { color: #00ff55; }
                .text-multi-code span.DecVal { color: #00ffff; }
                .text-multi-code span.Error { color: #ff0000; }
                .text-multi-code span.Float { color: #5599ff; }
                .text-multi-code span.Function { color: #3344ff; }
                .text-multi-code span.IString { color: #ff0000; }
                .text-multi-code span.Keyword { color: #11ffff; font-weight: bold; }
                .text-multi-code span.Operator { color: #00ff33; font-weight: bold; }
                .text-multi-code span.Others { color: #b03060; }
                .text-multi-code span.RegionMarker { color: #96b9ff; }
                .text-multi-code span.Reserved { color: #9b30ff; font-weight: bold; }
                .text-multi-code span.String { color: #ffaa55; }
                .text-multi-code span.Variable { color: #ffff00; }
                .text-multi-code span.Warning { color: #0000ff; }
                .text-multi-code span.LineNo {
                    color:          #fff;
                    font-weight:    bold;
                    padding-right:  1em;
                }
            |),
            'inline_css',
        );
        like(
            join(':', $post->files_for_css()),
            qr|Text/Multi/Block/Code\.css$|,
            'files_for_css',
        );
    }

    test read_from_file
    {
        my ($file) = $self->_write_post(outdent_quote(q|
            Author: jhelwig
            Post-Date: 2010-03-22 22:05:10
            Tags: First post! "Aw, jeah."
            Title: The very first post!

            {{{ Markdown }}}
            A paragraph.

            One with some *bold*, and **stronger** emphasis.

             * It's got
             * a list.

            Some more text.

             1. Or
             2. Two

            {{{ Code lang=Perl }}}

            map { $_->thing() } @stuff;
        |));
        my $post = WWW::StaticBlog::Post->new(
            filename => $file,
        );

        is(
            $post->author(),
            'jhelwig',
            'author',
        );
        is(
            $post->posted_on()->iso8601(),
            '2010-03-22T22:05:10',
            'posted_on',
        );
        is_deeply(
            $post->tags(),
            [
                'First',
                'post!',
                'Aw, jeah.',
            ],
            'tags',
        );
        is(
            $post->title(),
            'The very first post!',
            'title',
        );
        is(
            $post->body(),
            outdent_quote(q|
                {{{ Markdown }}}
                A paragraph.

                One with some *bold*, and **stronger** emphasis.

                 * It's got
                 * a list.

                Some more text.

                 1. Or
                 2. Two

                {{{ Code lang=Perl }}}

                map { $_->thing() } @stuff;
            |),
            'body',
        );
        is(
            $post->rendered_body(),
            outdent_quote(q|
                <div class="text-multi text-multi-markdown">
                <p>A paragraph.</p>

                <p>One with some <em>bold</em>, and <strong>stronger</strong> emphasis.</p>

                <ul>
                <li>It's got</li>
                <li>a list.</li>
                </ul>

                <p>Some more text.</p>

                <ol>
                <li>Or</li>
                <li>Two</li>
                </ol>

                </div>
                <pre class="text-multi text-multi-code text-multi-code-perl">
                <span class="Normal">
                </span><span class="Function">map</span><span class="Normal">&nbsp;{&nbsp;</span><span class="Variable">$_</span><span class="Normal">-&gt;thing()&nbsp;}&nbsp;</span><span class="DataType">@stuff</span><span class="Normal">;</span>
                </pre>
            |),
            'rendered_body',
        );
        is(
            $post->rendered_body(1),
            outdent_quote(q|
                <!-- A paragraph.

                One with some *bold*, and **stronger** emphasis.

                 * It's got
                 * a list.

                Some more text.

                 1. Or
                 2. Two
                 -->
                <div class="text-multi text-multi-markdown">
                <p>A paragraph.</p>

                <p>One with some <em>bold</em>, and <strong>stronger</strong> emphasis.</p>

                <ul>
                <li>It's got</li>
                <li>a list.</li>
                </ul>

                <p>Some more text.</p>

                <ol>
                <li>Or</li>
                <li>Two</li>
                </ol>

                </div>
                <!-- 
                map { $_->thing() } @stuff; -->
                <pre class="text-multi text-multi-code text-multi-code-perl">
                <span class="Normal">
                </span><span class="Function">map</span><span class="Normal">&nbsp;{&nbsp;</span><span class="Variable">$_</span><span class="Normal">-&gt;thing()&nbsp;}&nbsp;</span><span class="DataType">@stuff</span><span class="Normal">;</span>
                </pre>
            |),
            'detailed rendered_body',
        );
        is(
            $post->inline_css(),
            outdent_quote(q|
                .text-multi-code {
                        white-space: pre;
                        background: #0a0a0a;
                        color: #cccccc;
                        font-family: monospace;
                        font-size: .95em;
                        border: 1px solid #555555;
                        overflow: auto;
                        padding: 2em;
                        width: 46em;
                }
                .text-multi-code span.Alert { color: #0000ff; }
                .text-multi-code span.BaseN { color: #007f00; }
                .text-multi-code span.BString { color: #c9a7ff; }
                .text-multi-code span.Char { color: #ff00ff; }
                .text-multi-code span.Comment { color: #cc9900; }
                .text-multi-code span.DataType { color: #00ff55; }
                .text-multi-code span.DecVal { color: #00ffff; }
                .text-multi-code span.Error { color: #ff0000; }
                .text-multi-code span.Float { color: #5599ff; }
                .text-multi-code span.Function { color: #3344ff; }
                .text-multi-code span.IString { color: #ff0000; }
                .text-multi-code span.Keyword { color: #11ffff; font-weight: bold; }
                .text-multi-code span.Operator { color: #00ff33; font-weight: bold; }
                .text-multi-code span.Others { color: #b03060; }
                .text-multi-code span.RegionMarker { color: #96b9ff; }
                .text-multi-code span.Reserved { color: #9b30ff; font-weight: bold; }
                .text-multi-code span.String { color: #ffaa55; }
                .text-multi-code span.Variable { color: #ffff00; }
                .text-multi-code span.Warning { color: #0000ff; }
                .text-multi-code span.LineNo {
                    color:          #fff;
                    font-weight:    bold;
                    padding-right:  1em;
                }
            |),
            'inline_css',
        );
        like(
            join(':', $post->files_for_css()),
            qr|Text/Multi/Block/Code\.css$|,
            'files_for_css',
        );
    }

    method _write_post($contents)
    {
        my ($post_fh, $post_filename) = tempfile();
        $post_fh->autoflush(1);
        print $post_fh outdent_quote($contents);

        return($post_filename, $post_fh);
    }
}
