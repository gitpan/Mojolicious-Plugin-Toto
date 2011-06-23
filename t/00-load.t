#!perl

use Test::More tests => 3;
use Mojolicious::Lite;
use Test::Mojo;

get '/hello' => sub { shift->render_text('hello') };

plugin 'toto' => menu => [
    thing => {
        many => [qw/one two/],
        one  => [qw/thing1 thing2/]
    }
];

my $t = Test::Mojo->new();

$t->get_ok('/hello')->status_is(200)->content_is('hello');

1;


