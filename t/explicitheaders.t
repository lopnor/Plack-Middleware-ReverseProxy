use strict;
use warnings;
use Test::Base;
use lib 't/lib';
plan tests => 24;

use Plack::Builder;
use Plack::Test;
use Plack::Request;
use HTTP::Headers;
use HTTP::Request;

filters { input => [qw/yaml/] };

run {
    my $block = shift;

    my $headers = HTTP::Headers->new;
    $headers->header( %{ $block->input } );

    my $handler = builder {
        enable 'Plack::Middleware::MangleEnv', %{$block->input};
        enable 'ReverseProxy', headers => [qw(
            HTTP_X_FORWARDED_PROTO
            HTTP_X_FORWARDED_FOR
            HTTP_X_FORWARDED_SCRIPT_NAME
            HTTP_X_FORWARDED_PATH_INFO
        )];
        sub {
            my $req = Plack::Request->new(shift);
            if ( $block->address ) {
                is( $req->address, $block->address, $block->name . " of address" );
            }
            if ( $block->secure ) {
                is( ($req->env->{'psgi.url_scheme'} eq 'https'), $block->secure, $block->name . " of secure" );
            }
            for my $url (qw/uri base /) {
                if ( $block->$url ) {
                    is( $req->$url->as_string, $block->$url, $block->name . " of $url" );
                }
            }
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
};

__END__

=== with https
--- input
x-forwarded-https: on
--- secure: 0
--- base: http://example.com/
--- uri:  http://example.com/?foo=bar

=== without https
--- input
x-forwarded-https: off
--- secure: 0
--- base: http://example.com/
--- uri:  http://example.com/?foo=bar

===
--- input
dummy: 1
--- secure: 0
--- base: http://example.com/
--- uri: http://example.com/?foo=bar

=== https with HTTP_X_FORWARDED_PROTO
--- input
x-forwarded-proto: https
--- secure: 1
--- base: https://example.com:80/
--- uri:  https://example.com:80/?foo=bar

=== with HTTP_X_FORWARDED_FOR
--- input
x-forwarded-for: 192.168.3.2
--- address: 192.168.3.2
--- base: http://example.com/
--- uri:  http://example.com/?foo=bar

=== with ignored HTTP_X_FORWARDED_HOST
--- input
x-forwarded-host: 192.168.1.2:5235
--- base: http://example.com/
--- uri:  http://example.com/?foo=bar

=== default port with HOST
--- input
host: 192.168.1.2
--- base: http://192.168.1.2/
--- uri:  http://192.168.1.2/?foo=bar

=== default https port with HOST
--- input
host: 192.168.1.2
https: ON
--- base: https://192.168.1.2/
--- uri:  https://192.168.1.2/?foo=bar

=== with ignored HTTP_X_FORWARDED_HOST and HTTP_X_FORWARDED_PORT
--- input
x-forwarded-host: 192.168.1.5
x-forwarded-port: 1984
--- base: http://example.com/
--- uri:  http://example.com/?foo=bar

=== ignored HTTP_X_FORWARDED_PORT to secure port
--- input
x-forwarded-host: 192.168.1.2
x-forwarded-port: 443
--- secure: 0

=== with ignored HTTP_X_FORWARDED_SCRIPT_NAME
--- input
x-forwarded-script-name: /foo
--- base: http://example.com/foo
--- uri:  http://example.com/foo/?foo=bar

=== with ignored HTTP_X_FORWARDED_PATH_INFO
--- input
x-forwarded-script-name: /foo
--- base: http://example.com/foo
--- uri:  http://example.com/foo/?foo=bar

