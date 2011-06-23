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

plugin 'toto' => menu => $menu;

my $t = Test::Mojo->new();
$t->max_redirects(2);

$t->get_ok('/')->status_is(200)->content_like(qr/search/i);
$t->get_ok('/beer')->status_is(200)->content_like(qr/search/i);
$t->get_ok('/pub')->status_is(200)->content_like(qr/map/i);

while ( my $item = shift @$menu) {
    my %tabs = %{ shift @$menu };
    $t->get_ok("/$item/$_")->status_is(200) for @{ $tabs{many} };
    $t->get_ok("/$item/$_/20")->status_is(200) for @{ $tabs{one} };
}

done_testing();

1;


