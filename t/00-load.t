#!perl

use Test::More tests => 6;
use Mojolicious::Lite;
use Test::Mojo;

get '/hello' => sub { shift->render_text('hello') };

plugin 'toto';

my $t = Test::Mojo->new();

$t->get_ok('/hello')->status_is(200)->content_is('hello');

$t->get_ok('/toto')->status_is(200)->content_like(qr/welcome/i);

1;


