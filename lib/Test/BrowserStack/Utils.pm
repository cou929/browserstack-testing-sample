package Test::BrowserStack::Utils;
use strict;
use warnings;
use lib 't/js/lib';
use Selenium::Remote::Driver;
use JSON qw//;
use URI::Escape qw/uri_escape/;
use Test::BrowserStack;
use Test::BrowserStack::API;

use constant {
    ENV_PORT   => Test::BrowserStack::ENV_PORT(),
    ENV_TARGET => Test::BrowserStack::ENV_TARGET(),
};

sub new {
    my $class      = shift;
    my %args       = ref $_[0] eq "HASH" ? %{ $_[0] } : @_;
    my $user_name  = $args{user_name} or Carp::croak "user_name is required";
    my $access_key = $args{access_key} or Carp::croak "access_key is required";
    unless ( $ENV{ ENV_PORT() } ) {
        Test::BrowserStack->load;
    }
    my $port = $ENV{ ENV_PORT() };
    my $self = bless {
        user_name  => $args{user_name},
        access_key => $args{access_key},
        port       => $port,
    }, $class;
    $self;
}

sub driver {
    my $self = shift;
    my %args = ref $_[0] eq "HASH" ? %{ $_[0] } : @_;

    my $user_name  = uri_escape $self->{user_name};
    my $access_key = uri_escape $self->{access_key};
    my $port       = $self->{port};
    my $host = sprintf '%s:%s@hub.browserstack.com', $user_name, $access_key;
    my $url  = "http://localhost:$port/test/" . $args{path};

    my $driver = Selenium::Remote::Driver->new(
        remote_server_addr => $host,
        port               => '80',
        extra_capabilities => {
            'browserstack.tunnel' => JSON::true,
            'browserstack.debug'  => JSON::true,
        },
        %{ $args{env} },
    );
    $driver->get($url);
    $driver;
}

sub for_pc_environments {
    shift->_for_envs( "pc", @_ );
}

sub for_mobile_environments {
    shift->_for_envs( "mobile", @_ );
}

sub _for_envs {
    my ( $self, $type, $path, $code, $envs ) = @_;
    $self->_build_environments;
    my $test_all_version = $ENV{ ENV_TARGET() } eq "all";
    my $target = $test_all_version ? "all" : "latests";
    $envs ||= $self->{"envs_${type}_${target}"};

    for my $env ( @{$envs} ) {
        my $driver = $self->driver( path => $path, env => $env );
        $code->( $driver, $env );
    }
}

sub _build_environments {
    my ($self) = @_;

    my $user_name  = $self->{user_name};
    my $access_key = $self->{access_key};
    my $api        = Test::BrowserStack::API->new(
        user_name  => $user_name,
        access_key => $access_key
    );
    my $res = $api->get_browsers;
    Carp::croak "invalid response $res" unless ref $res eq "HASH";

    $self->{browsers_raw} = $res;
    $self->_store_browsers($res);
}

sub _store_browsers {
    my ( $self, $browsers ) = @_;
    my @result;

    my $latests_pc = {};
    my @all_pc;
    for my $os ( ( "OS X", "Windows" ) ) {
        for my $os_version ( keys %{ $browsers->{$os} } ) {
            for ( @{ $browsers->{$os}->{$os_version} } ) {
                my $browser         = $_->{browser};
                my $browser_version = $_->{browser_version};
                next unless $browser_version =~ /^[\d\.]+$/;
                push @all_pc,
                  {
                    _meta      => "$os $os_version $browser $browser_version",
                    os         => $os,
                    os_version => $os_version,
                    browser    => $browser,
                    browser_version => $browser_version,
                  };
                if ( ( $latests_pc->{$os}->{$browser}->{browser_version} || 0 )
                    < $browser_version )
                {
                    $latests_pc->{$os}->{$browser} = {
                        browser_version => $browser_version,
                        os_version      => $os_version
                    };
                }
            }
        }
    }
    $self->{envs_pc_all}     = \@all_pc;
    $self->{envs_pc_latests} = do {
        my @result;
        for my $os ( keys %{$latests_pc} ) {
            for my $browser ( keys %{ $latests_pc->{$os} } ) {
                my $os_version = $latests_pc->{$os}->{$browser}->{os_version};
                my $browser_version =
                  $latests_pc->{$os}->{$browser}->{browser_version};
                push @result,
                  {
                    _meta      => "$os $os_version $browser $browser_version",
                    os         => $os,
                    os_version => $os_version,
                    browser    => $browser,
                    browser_version => $browser_version,
                  };
            }
        }
        \@result;
    };

    my @all_ios;
    my $latests_ios = {};
    for my $os_version ( keys %{ $browsers->{"ios"} } ) {
        my $platform = "MAC";
        for ( @{ $browsers->{"ios"}->{$os_version} } ) {
            for my $device ( @{ $_->{devices} } ) {
                my $browser_name = $device =~ /iPhone/ ? "iPhone" : "iPad";
                push @all_ios,
                  {
                    browserName => $browser_name,
                    platform    => $platform,
                    device      => $device,
                  };
                if ( ( $latests_ios->{os_version} || 0 ) lt $os_version ) {
                    $latests_ios = {
                        _meta        => "iOS $os_version $device",
                        os_version   => $os_version,
                        browser_name => $browser_name,
                        platform     => $platform,
                        device       => $device,
                    };
                }

            }
        }
    }
    $self->{envs_ios_all}     = \@all_ios;
    $self->{envs_ios_latests} = [
        {
            _meta       => $latests_ios->{_meta},
            browserName => $latests_ios->{browser_name},
            platform    => $latests_ios->{platform},
            device      => $latests_ios->{device},
        }
    ];

    my @all_android;
    my $latests_android = {};
    for my $os_version ( keys %{ $browsers->{"android"} } ) {
        my $browser_name = "android";
        my $platform     = "ANDROID";
        for ( @{ $browsers->{"android"}->{$os_version} } ) {
            for my $device ( @{ $_->{devices} } ) {
                push @all_android,
                  {
                    browserName => $browser_name,
                    platform    => $platform,
                    device      => $device,
                  };
                if ( ( $latests_android->{os_version} || 0 ) lt $os_version ) {
                    $latests_android = {
                        _meta        => "Android $os_version $device",
                        os_version   => $os_version,
                        browser_name => $browser_name,
                        platform     => $platform,
                        device       => $device,
                    };
                }
            }
        }
    }
    $self->{envs_android_all}     = \@all_android;
    $self->{envs_android_latests} = [
        {
            _meta       => $latests_android->{_meta},
            browserName => $latests_android->{browser_name},
            platform    => $latests_android->{platform},
            device      => $latests_android->{device},
        }
    ];

    $self->{envs_mobile_all} =
      [ @{ $self->{envs_ios_all} }, @{ $self->{envs_android_all} } ];
    $self->{envs_mobile_latests} =
      [ @{ $self->{envs_ios_latests} }, @{ $self->{envs_android_latests} } ];
}

1;
