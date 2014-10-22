#!perl

package House;
use Mojo::Base 'Mojolicious::Controller';

sub list {
    shift->render_text("in the house");
}

package main;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

my $menu = [
    beer => {
        many => [qw/search browse/],
        one  => [qw/ingredients/],
    },
    house => {
        many => [qw/list/]
    }
];

get '/some/crazy/url' => sub { shift->render_text("hi there"); } => "beer/search";

get '/beer/browse' => sub { shift->render_text("my name is inigo montoya") } => "beer/browse";

get '/house/list' => { controller => 'House', action => 'list' } => 'house/list';

plugin 'toto' => menu => $menu;

my $t = Test::Mojo->new();
$t->ua->max_redirects(1);

my @hrefs;
$t->get_ok('/some/crazy/url')->status_is(200)->content_like(qr/hi there/i);
$t->tx->res->dom->find("a[href]")->each(sub { push @hrefs, "$_[0]" } );

$t->get_ok('/beer')->status_is(200);

my @again;
$t->get_ok('/some/crazy/url')->status_is(200)->content_like(qr/hi there/i);
$t->tx->res->dom->find("a[href]")->each(sub { push @again, "$_[0]" } );

is_deeply(\@hrefs,\@again);

$t->get_ok('/beer/browse')->status_is(200)->content_like(qr/inigo montoya/);

$t->get_ok('/house/list')->status_is(200)->content_like(qr/in the house/);

done_testing();

1;

__DATA__
@@ not_found.html.ep
NOT FOUND : <%= $self->req->url->path %>

