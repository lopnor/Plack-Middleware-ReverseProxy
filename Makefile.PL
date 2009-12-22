use inc::Module::Install;
name 'Plack-Middleware-ReverseProxy';
all_from 'lib/Plack/Middleware/ReverseProxy.pm';

# requires '';
requires 'parent';
requires 'Plack::Middleware';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
build_requires 'Plack::Request';
use_test_base;
auto_include;
auto_set_repository;
WriteAll;
