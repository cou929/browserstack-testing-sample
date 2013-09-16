use strict;
use warnings;
use Plack::Builder;
use Plack::Request;
use Plack::Response;
use Plack::App::Directory;
use Text::Xslate;
use Text::Xslate::Bridge::TT2Like;
use Path::Class qw/file/;
use Test::BrowserStack;

my $root = $ENV{TEST_HOME} || ".";
my $port = $ENV{Test::BrowserStack::ENV_PORT()} || 5000;

my $app = sub {
    my $env  = shift;
    my $req  = Plack::Request->new($env);
    my $view = Text::Xslate->new(
        path   => file( $root, "server", "templates" ),
        syntax => "TTerse",
        module => [qw/Text::Xslate::Bridge::TT2Like/],
    );

    my $tmpl     = ( ( split '/', $req->path_info )[-1] || "default" ) . ".tt";
    my $hostname = "localhost:$port";
    my $content  = $view->render( $tmpl, { hostname => $hostname } );

    my $res = Plack::Response->new(200);
    $res->content($content);
    $res->finalize;
};

builder {
    mount "/test/" => $app;
    mount "/static/"      => builder {
        my $root_path = file( $root, "server", "static" );
        Plack::App::Directory->new( { root => $root_path } )->to_app;
    };
    mount "/"      => builder {
        my $root_path = file( $root, "dist" );
        Plack::App::Directory->new( { root => $root_path } )->to_app;
    };
};
