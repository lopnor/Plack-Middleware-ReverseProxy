use strict;
use warnings;
use Test::Base;
plan tests => 25*2;

use Plack::Builder;
use Plack::Test;
use Plack::Request;
use HTTP::Headers;
use HTTP::Request;

filters { input => [qw/yaml/] };

run {
    my $block = shift;
    local %ENV = ();
    $ENV{REQUEST_METHOD} = 'GET';
    $ENV{SERVER_PORT}    = 80;
    $ENV{HTTP_HOST}      = 'example.com';
    $ENV{QUERY_STRING}   = 'foo=bar';
    $ENV{HTTPS}          = delete $block->input->{https} if $block->input->{https};

    my $headers = HTTP::Headers->new;
    $headers->header( %{ $block->input } );

    my %args;
    my $code = sub {
        my $error = shift;
        my $handler = builder {
            enable 'Plack::Middleware::ReverseProxy';
            sub {
                my $req = Plack::Request->new(shift);
                for my $attr (qw/url_scheme address/) {
                    if ( $block->$attr ) {
                        if ($error && $block->is_secure_error) {
                            isnt( $req->$attr, $block->$attr, $block->name . " of $attr isnt" );
                        } else {
                            is( $req->$attr, $block->$attr, $block->name . " of $attr" );
                        }
                    }
                }
                for my $url (qw/uri base /) {
                    if ( $block->$url ) {
                        if ($error && $block->is_url_error) {
                            isnt( $req->$url->as_string, $block->$url, $block->name . " of $url isnt" );
                        } else {
                            is( $req->$url->as_string, $block->$url, $block->name . " of $url" );
                        }
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
                        %args,
                    )
                );
            },
            app => $handler,
        );

        test_psgi %test;
    };

    # allow host
    $args{address} = $ENV{REMOTE_ADDR} = $block->allow_host || '127.0.0.1';
    $code->();
    # deny host
    $args{address} = $ENV{REMOTE_ADDR} = $block->deny_host || '0.0.0.0';
    $code->(1);
};

__END__

=== with https
--- input
x-forwarded-https: on
--- url_scheme: https
--- base: https://example.com:80/
--- uri:  https://example.com:80/?foo=bar
--- deny_host: 10.0.0.1
--- is_secure_error: 1
--- is_url_error: 1

=== without https
--- input
x-forwarded-https: off
--- url_scheme: http
--- base: http://example.com/
--- uri:  http://example.com/?foo=bar
--- allowed_remote: 192.168.0.1
--- allow_host: 192.168.0.1
--- deny_host: 10.0.0.1
--- is_secure_error: 1

===
--- input
dummy: 1
--- url_scheme: http
--- base: http://example.com/
--- uri: http://example.com/?foo=bar
--- allowed_remote: 192.168.0.\d+
--- allow_host: 192.168.0.99
--- deny_host: 10.0.0.1

=== https with HTTP_X_FORWARDED_PROTO
--- input
x-forwarded-proto: https
--- secure: 1
--- base: https://example.com:80/
--- uri:  https://example.com:80/?foo=bar
--- allowed_remote: 192.168.0.\d
--- allow_host: 192.168.0.1
--- deny_host: 192.168.0.11
--- is_secure_error: 1
--- is_url_error: 1

=== with HTTP_X_FORWARDED_FOR
--- input
x-forwarded-for: 192.168.3.2
--- address: 192.168.3.2
--- base: http://example.com/
--- uri:  http://example.com/?foo=bar
--- is_secure_error: 1

=== with HTTP_X_FORWARDED_HOST
--- input
x-forwarded-host: 192.168.1.2:5235
--- base: http://192.168.1.2:5235/
--- uri:  http://192.168.1.2:5235/?foo=bar
--- is_url_error: 1

=== default port with HTTP_X_FORWARDED_HOST
--- input
x-forwarded-host: 192.168.1.2
--- base: http://192.168.1.2/
--- uri:  http://192.168.1.2/?foo=bar
--- is_url_error: 1

=== default https port with HTTP_X_FORWARDED_HOST
--- input
x-forwarded-https: on
x-forwarded-host: 192.168.1.2
--- base: https://192.168.1.2/
--- uri:  https://192.168.1.2/?foo=bar
--- is_secure_error: 1
--- is_url_error: 1

=== default port with HOST
--- input
host: 192.168.1.2
--- base: http://192.168.1.2/
--- uri:  http://192.168.1.2/?foo=bar
--- is_url_error: 1

=== default https port with HOST
--- input
host: 192.168.1.2
https: ON
--- base: https://192.168.1.2/
--- uri:  https://192.168.1.2/?foo=bar
--- is_secure_error: 1
--- is_url_error: 1

=== with HTTP_X_FORWARDED_HOST and HTTP_X_FORWARDED_PORT
--- input
x-forwarded-host: 192.168.1.5
x-forwarded-port: 1984
--- base: http://192.168.1.5:1984/
--- uri:  http://192.168.1.5:1984/?foo=bar
--- is_url_error: 1
