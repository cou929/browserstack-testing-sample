use strict;
use warnings;
use Test::More;
use Test::BrowserStack::Utils;
use t::Utils;

my $config = t::Utils::load_config;

my $browserstack = Test::BrowserStack::Utils->new(
    user_name  => $config->{user_name},
    access_key => $config->{access_key},
);

$browserstack->for_pc_environments(
    "test_sample",
    sub {
        my ( $driver, $env ) = @_;
        subtest $env->{_meta} => sub {
            is $driver->get_title, "test sample";

            note $driver->get_page_source;

            my $element = $driver->find_element( "#result", "css" );
            like $element->get_text, qr{http://.*?/widget.js\?url=http.*?&type=BLAHBLAH&status=123};
        };
    }
);

done_testing;
