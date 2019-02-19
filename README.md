# NAME

Plack::Middleware::ReverseProxy - Supports app to run as a reverse proxy backend

# SYNOPSIS

    builder {
        enable_if { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' } 
            "Plack::Middleware::ReverseProxy";
        $app;
    };

# DESCRIPTION

Plack::Middleware::ReverseProxy resets some HTTP headers, which changed by
reverse-proxy. You can specify the reverse proxy address and stop fake requests
using 'enable\_if' directive in your app.psgi.

# LICENSE

This software is licensed under the same terms as Perl itself.

# AUTHOR

This module is originally written by Kazuhiro Osawa as [HTTP::Engine::Middleware::ReverseProxy](https://metacpan.org/pod/HTTP::Engine::Middleware::ReverseProxy) for [HTTP::Engine](https://metacpan.org/pod/HTTP::Engine).

Nobuo Danjou

Masahiro Nagano

Tatsuhiko Miyagawa

# SEE ALSO

[HTTP::Engine::Middleware::ReverseProxy](https://metacpan.org/pod/HTTP::Engine::Middleware::ReverseProxy) 

[Plack](https://metacpan.org/pod/Plack)

[Plack::Middleware](https://metacpan.org/pod/Plack::Middleware)

[Plack::Middleware::Conditional](https://metacpan.org/pod/Plack::Middleware::Conditional)
