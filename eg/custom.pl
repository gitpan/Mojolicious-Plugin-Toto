#!/usr/bin/env perl

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

get '/some/crazy/url' => sub { shift->render_text("hi there"); } => { nav_item => 'beer' } => "beer/search";

get '/beer/browse' => sub { shift->render_text("my name is inigo montoya") } =>{ nav_item => 'beer' } =>  "beer/browse";

get '/house/list' => { controller => 'house', action => 'list', nav_item => 'house' } =>  'house/list';

plugin 'toto' => menu => $menu;

app->start;

