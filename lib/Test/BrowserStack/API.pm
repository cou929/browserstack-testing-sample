package Test::BrowserStack::API;
use Furl;
use MIME::Base64 qw/encode_base64/;
use JSON qw/decode_json/;
use Carp;

our $VERSION = "0.01";

use constant {
    API_HOST    => 'api.browserstack.com',
    API_VERSION => 3,
    GET         => 'get',
    POST        => 'post',
    DELETE      => 'delete',
};

use constant PATH => {
    BROWSERS => '/browsers',
    WORKER   => '/worker',
    WORKERS  => '/workers',
    STATUS   => '/status',
};

sub new {
    my $class      = shift;
    my %args       = ref $_[0] eq "HASH" ? %{ $_[0] } : @_;
    my $user_name  = $args{user_name} or Carp::croak "user_name is required";
    my $access_key = $args{access_key} or Carp::croak "access_key is required";
    my $self       = {
        user_name  => $user_name,
        access_key => $access_key,
        user_agent => $class->_build_user_agent( $user_name, $access_key ),
    };
    my $self = bless $self, $class;
    $self;
}

sub get_browsers {
    my ($self) = @_;
    $self->_request( GET, PATH->{BROWSERS} );
}

sub get_status {
    my ($self) = @_;
    $self->_request( GET, PATH->{STATUS} );
}

sub _build_user_agent {
    my ( $class, $user_name, $access_key ) = @_;
    Furl->new(
        agent   => __PACKAGE__ . '/' . $VERSION,
        headers => [
            Authorization => 'Basic '
              . encode_base64( $user_name . ':' . $access_key ),
        ],
    );
}

sub _build_api_location {
    my ( $self, $path ) = @_;
    sprintf 'http://%s/%d%s', API_HOST, API_VERSION, $path;
}

sub _request {
    my ( $self, $method, $path, $options ) = @_;
    $path .= '?' . join '&',
      map { $_ . '=' . $options->{$_} } keys %{ $options // +{} };
    my $ua  = $self->{user_agent};
    my $res = $ua->$method( $self->_build_api_location($path) );
    if ( $res->code == 200 ) {
        decode_json $res->content;
    }
    else {
        ( $res->headers->{'content-type'}->[0] || '' ) =~ m/json/
          ? decode_json $res->content
          : $res->message;
    }
}

1;
