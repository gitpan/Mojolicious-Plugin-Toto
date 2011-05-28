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

 get '/my/url/to/search/for/beers' => sub {
      shift->render_text("here is my awesome beer search page");
 } => "beer/search";

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

Route names of the form "controller/action" will automatically
be placed into the toto navigational structure.

Controller classes may also be used; they will be automatically
called if they exist (e.g. "Beer::Pub::search()").

A template for a given page may be in either of these two places :

    templates/$controller/$action.html.ep
    templates/$action.html.ep

=head1 TODO

much more documentation

=cut

package Mojolicious::Plugin::Toto;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream qw/b/;
use Toto;
use strict;
use warnings;

our $VERSION = 0.03;

our $mainRoutes;
sub _main_routes {
     my $c = shift;
     our $mainRoutes;
     $mainRoutes ||= { map { ( $_->name => 1 ) }
          grep { $_->name && $_->name =~ m[/] }
          @{ $c->main_app->routes->children || [] }
     };
     return $mainRoutes;
}

sub _toto_url {
     my ($c,$controller,$action,$key) = @_;
     if ( $controller && $action && _main_routes($c)->{"$controller/$action"} ) {
        $c->app->log->debug("found a route for $controller/$action");
        return $c->main_app->url_for( "$controller/$action",
            { controller => $controller, action => $action, key => $key } );
     }
     $c->app->log->debug("default route for $controller".($action ? "/$action" : ""));
     # url_for "plural" or "single" doesn't work for the first http
     # request for some reason (toto_path is excluded)
     my $url = $c->req->url->clone;
     $url->path->parts([$c->toto_path, $controller]);
     push @{ $url->path->parts }, $action if $action;
     push @{ $url->path->parts }, $key if $action && defined($key);
     return $url;
}

sub register {
    my ($self, $app, $conf) = @_;

    my $path  = $conf->{path}      || '/toto';
    my $namespace = $conf->{namespace} || $app->routes->namespace || "Toto";
    my @menu = @{ $conf->{menu} || [] };
    my %menu = @menu;

    $app->routes->route($path)->detour(app => Toto::app());
    Toto::app()->routes->namespace($namespace);
    Toto::app()->renderer->default_template_class("Toto");

    my @controllers = grep !ref($_), @menu;
    for ($app, Toto::app()) {
        $_->helper( main_app => sub { $app } );
        $_->helper( toto_url => \&_toto_url );
        $_->helper( toto_path   => sub { $path } );
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

    $app->hook(before_render => sub {
            my $c = shift;
            my $name = $c->stash("template"); # another method for name?
            return unless $name && _main_routes($c)->{$name};
            my ($controller,$action) = $name =~ m{^(.*)/(.*)$};
            $c->app->log->info("found $action, $controller");
            $c->stash->{template_class} = "Toto";
            $c->stash->{layout} = "toto";
            $c->stash->{action} = $action;
            $c->stash->{controller} = $controller;
            my $key = $c->stash("key") or return;
            $c->stash(instance => $c->model_class->new(key => $key));
        });
}

1;

