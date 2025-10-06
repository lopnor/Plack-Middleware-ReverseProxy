use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 1;

use Plack::Builder;
use Plack::Test;
use Plack::Request;
use HTTP::Headers;
use HTTP::Request;
use Data::Dumper;


my $headers = HTTP::Headers->new;
$headers->header( 'x-http-forwarded-port' => '{server_port}' );

my $handler = builder {
    enable sub {
        my $app = shift;
        sub {
            my $env = shift;
            $env->{SERVER_PORT} = 8080;
            return $app->($env);
        }
    };
    enable 'Plack::Middleware::ReverseProxy';
    sub {
        my $env = shift;
        is $env->{SERVER_PORT}, 80, 'port is changed to default port, not x-http-forwarded-port';
        [200, ['Content-Type' => 'text/plain'], [ 'OK' ]];
    }
};

my %test = (
    client => sub {
        my $cb = shift;
        my $res = $cb->(
            HTTP::Request->new(
                GET => 'http://example.com/?foo=bar', $headers,
            )
        );
    },
    app => $handler,
);

test_psgi %test;
