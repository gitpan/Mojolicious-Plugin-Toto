#!perl

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

my $menu = [
    beer => {
        many => [qw/search browse/],
        one  => [qw/picture ingredients pubs/],
    },
    pub => {
        many => [qw/map list search/],
        one  => [qw/info comments/],
    }
];

plugin 'toto' => path => "/app", menu => $menu;

my $t = Test::Mojo->new();
$t->max_redirects(1);

$t->get_ok('/app')->status_is(200)->content_like(qr/welcome/i);
$t->get_ok('/app/beer')->status_is(200)->content_like(qr/search/i);
$t->get_ok('/app/pub')->status_is(200)->content_like(qr/map/i);

while ( my $item = shift @$menu) {
    my %tabs = %{ shift @$menu };
    $t->get_ok("/app/$item/$_")->status_is(200) for @{ $tabs{many} };
    $t->get_ok("/app/$item/$_/20")->status_is(200) for @{ $tabs{one} };
}

done_testing();

1;


