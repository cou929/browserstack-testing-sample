package Test::BrowserStack;
use strict;
use warnings;
use Test::TCP qw/empty_port wait_port/;
use Proc::Guard qw/proc_guard/;
use Plack::Util;
use File::Which qw/which/;
use IPC::Open3 qw/open3/;
use POSIX;
use Config::YAML;
use Test::BrowserStack::API;

use constant {
    ENV_PORT   => "TEST_BROWSERSTACK_SERVER_PORT",
    ENV_TARGET => "TEST_BROWSERSTACK_TARGET",
};

our $PLACKUP;
our $BROWSORSTACK_TUNNEL_PID;

sub load {
    my ( $class, $p ) = @_;
    my $args   = $p->{args};
    my $config = $class->_init_config;

    $ENV{ ENV_TARGET() } =
      ( ref $args eq "ARRAY" && $args->[0] && $args->[0] eq "all" ) ? "all" : "";
    my $plack_port = $ENV{ ENV_PORT() } = empty_port;

    $PLACKUP = $class->start_plackup(
        app  => $config->{psgi_app_path},
        port => $plack_port
    );
    wait_port($plack_port);

    $BROWSORSTACK_TUNNEL_PID = $class->start_browserstack_tunnel(
        jar  => $config->{browserstack_jar_path},
        key  => $config->{access_key},
        port => $plack_port,
    );
}

sub _init_config {
    my ($class) = @_;

    my $filename = "config_test.yaml";
    Carp::croak "config file not found" unless -f $filename;
    my $config = Config::YAML->new( config => $filename );
    $config->read($filename);

    return $config;
}

sub start_plackup {
    my $class = shift;
    my %args  = @_;
    my $app   = $args{app};
    my $port  = $args{port} || empty_port;
    my @proc  = (
        "plackup", ( map { ( "-I" => $_ ) } @INC ),
        "-p" => $port,
        "-E" => "development",
        "-a" => $app,
    );
    proc_guard(@proc);
}

sub start_browserstack_tunnel {
    my $class = shift;
    my %args  = @_;
    my $jar   = $args{jar};
    my $key   = $args{key};
    my $port  = $args{port};
    my @proc  = (
        scalar( which("java") ),
        "-jar" => $jar,
        $key,
        "localhost,$port,0",
    );

    my ( $wtr, $rdr, $err );
    my $pid = open3( $wtr, $rdr, $err, @proc );
    close $wtr;

    my $connected = 0;
    while ( my $line = <$rdr> ) {
        print $line;
        if ( $line =~ /Press Ctrl-C to exit/ ) {
            $connected = 1;
            last;
        }
    }

    unless ($connected) {
        kill POSIX::SIGTERM, $pid;
        Carp::croak "cannot connect to BrowserStack";
    }

    return $pid;
}

END {
    undef $PLACKUP;
    kill POSIX::SIGTERM, $BROWSORSTACK_TUNNEL_PID if $BROWSORSTACK_TUNNEL_PID;

    $ENV{ ENV_PORT() }   = undef;
    $ENV{ ENV_TARGET() } = undef;
}

1;
