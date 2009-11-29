package Plack::Middleware::MangleEnv;
use strict;
use warnings;
use parent 'Plack::Middleware';

__PACKAGE__->mk_accessors(qw(address));

sub call {
    my ($self, $env) = @_;
    $env->{REMOTE_ADDR} = $self->address;
    $self->app->($env);
}

1;
