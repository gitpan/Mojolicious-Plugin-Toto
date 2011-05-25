=head1 NAME

Mojolicious::Plugin::Toto - A simple tab and object based site structure

=head1 SYNOPSIS

 cat > ./Beer
 #!/usr/bin/env perl
 use Mojolicious::Lite;

 plugin 'toto' =>
    path => "/toto",
    namespace => "Beer",
    menu => [
        beer    => { one  => [qw/ingredients pubs/],
                     many => [qw/search browse/] },
        brewery => { one  => [qw/directions beers info/],
                     many => [qw/phonelist mailing_list/] },
        pub     => { one  => [qw/info comments/],
                     many => [qw/search map/] },
 #  $controller (object) => { one => [ ..actions on one object ],
 #                          many => [ ..actions on 0 or many objects ]
    ]
 ;
 app->start

 ./Beer daemon

=head1 DESCRIPTION

This is an implementation of a navigational structure
called "toto": "tabs on this object" which is
as follows :

Given a collection of objects (e.g. beers, breweries,
pubs), come up with two types of pages :

    - pages associated with one object (e.g. view, edit)

    - pages associated with zero or more than one object (e.g. search, browse)

Then Toto refers to a screen with three types of tab lists :

    - a list of all the objects

    - a list of all the actions possible on one object

    - a list of all the actions possible on zero or multiple objects

After creating a structure, as in the synopsis, and starting
a mojolicious app, there will be a site as well as sample code
and sample objects.

Actions in controller classes will be called automatically if they
exist (e.g. "Beer::Pub::search()").

A template for a given page may be in either of these two places :

    templates/$controller/$action.html.ep
    templates/$action.html.ep

depending on whether it is generic, or specific to the controller.

=head1 TODO

much more documentation

=cut

package Mojolicious::Plugin::Toto;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream qw/b/;
use Toto;
use strict;
use warnings;

our $VERSION = 0.02;

sub register {
    my ($self, $app, $conf) = @_;

    my $location  = $conf->{path}      || '/toto';
    my $namespace = $conf->{namespace} || $app->routes->namespace || "Toto";
    my @menu = @{ $conf->{menu} || [] };
    my %menu = @menu;

    $app->routes->route($location)->detour(app => Toto::app());
    Toto::app()->routes->namespace($namespace);

    my @controllers = grep !ref($_), @menu;
    for ($app, Toto::app()) {
        $_->helper( toto_path   => sub { $location } );
        $_->helper( model_class => sub { $conf->{model_class} || "Toto::Model" });
        $_->helper( controllers => sub { @controllers } );
        $_->helper(
            actions => sub {
                my $c    = shift;
                my $for  = shift || $c->stash("controller");
                my $mode = defined( $c->stash("key") ) ? "one" : "many";
                @{ $menu{$for}{$mode} || [] };
            }
        );
    }
}

