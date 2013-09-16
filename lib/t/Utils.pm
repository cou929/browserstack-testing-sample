package t::Utils;
use strict;
use warnings;
use Config::YAML;

sub load_config {
    my $filename = "config_test.yaml";
    Carp::croak "config file not found" unless -f $filename;
    my $config = Config::YAML->new( config => $filename );
    $config->read($filename);
    return $config;
}

1;
