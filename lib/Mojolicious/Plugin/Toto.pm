=head1 NAME

Mojolicious::Plugin::Toto - A simple tab and object based site structure

=head1 SYNOPSIS

 use Mojolicious::Lite;

 get '/my/url/to/list/beers' => sub {
      shift->render_text("Here is a page for listing beers.");
 } => "beer/list";

 get '/beer/create' => sub {
    shift->render_text("Here is a page to create a beer.");
 } => "beer/create";

 plugin 'toto' =>
    menu => [
        beer    => { one  => [qw/view edit pictures notes/],
                     many => [qw/list create search browse/] },
        brewery => { one  => [qw/view edit directions beers info/],
                     many => [qw/phonelist mailing_list/] },
        pub     => { one  => [qw/view info comments hours/],
                     many => [qw/search map/] },
    ],
    themeswitcher => 1,
 ;

 app->start

 ./Beer daemon

=head1 DESCRIPTION

This plugin provides a navigational structure and a default set
of routes for a Mojolicious or Mojolicious::Lite app.

It extends the idea of BREAD or CRUD -- in a BREAD application,
browse and add are operations on aggregate (0 or many) objects, while
edit, add, and delete are operations on 1 object.

Toto groups all pages into two categories : either they act on one
object, or they act on 0 or many objects.

One set of tabs provides a way to change between types of objects.
Another row of tabs provides a way to change actions.

The actions displayed depend on context -- the type of object, and
whether or not an object is selected determine the list of actions
that are displayed.

The toto menu data structure is used to generate default routes of
the form controller/action, for each controller+action pair.
It is also used to generate the menu and tabs.

By loading the plugin after creating routes, any routes created
manually which use this naming convention will take precedence over
the default ones.

For Mojolicious (not lite) apps, methods in controller classes will
be used if they exist.

Because routes are created automatically, creating a page may be
done by just adding a file named templates/controller/action.html.ep.

Styling is done (mostly) with jquery css.

=head1 SEE ALSO

http://www.beer.dotcloud.com

=cut

package Mojolicious::Plugin::Toto;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream qw/b/;
use Toto;
use strict;
use warnings;

our $VERSION = 0.07;

sub register {
    my ($self, $app, $conf) = @_;

    my @menu = @{ $conf->{menu} || [] };
    my %menu = @menu;

    $app->routes->get('/jq.css')->to("Toto");
    $app->routes->get('/toto.css')->to("Toto");
    $app->routes->get('/toto/images/:which.png')->to("Toto");

    for my $controller (keys %menu) {

        my $first;
        for my $action (@{ $menu{$controller}{many} || []}) {
            # TODO skip existing routes
            $first ||= $action;
            $app->log->debug("Adding route for $controller/$action");
            $app->routes->get(
                "/$controller/$action" => sub {
                    my $c = shift;
                    my $root = $c->app->renderer->root;
                    my @found = glob "$root/$controller/$action.*";
                    return if @found;
                    $c->stash->{template}       = "plural";
                    $c->stash->{template_class} = 'Toto';
                  } => {
                    controller => $controller,
                    action     => $action,
                    layout     => "toto"
                  } => "$controller/$action"
            );
        }
        my $first_action = $first;
        $app->routes->get(
            "/$controller" => sub {
                shift->redirect_to("$controller/$first_action");
              } => "$controller"
        );
        $first = undef;
        for my $action (@{ $menu{$controller}{one} || [] }) {
            # TODO skip existing routes
            $first ||= $action;
            $app->routes->get(
                "/$controller/$action/(*key)" => sub {
                    my $c = shift;
                    $c->stash(instance => $c->model_class->new(key => $c->stash('key')));
                    my $root = $c->app->renderer->root;
                    my @found = glob "$root/$controller/$action.*";
                    return if @found;
                    $c->stash->{template}       = "single";
                    $c->stash->{template_class} = 'Toto';
                  } => {
                      controller => $controller,
                      action     => $action,
                      layout => "toto",
                  } => "$controller/$action"
            );
        }
        my $first_key = $first;
        $app->routes->get(
            "/$controller/default/(*key)" => sub {
                my $c = shift;
                my $key = $c->stash("key");
                $c->redirect_to("$controller/$first_key/$key");
              } => "$controller/default"
        );

    }
    my @controllers = grep !ref($_), @menu;
    my $first_controller = $controllers[0];
    $app->routes->get('/' => sub { shift->redirect_to($first_controller) } );

    for ($app, Toto::app()) {
        $_->helper( toto_config => sub { $conf } );
        $_->helper( model_class => sub { $conf->{model_class} || "Toto::Model" });
        $_->helper( controllers => sub { @controllers } );
        $_->helper(
            actions => sub {
                my $c    = shift;
                my $for  = shift || $c->stash("controller") || die "no controller";
                my $mode = defined( $c->stash("key") ) ? "one" : "many";
                @{ $menu{$for}{$mode} || [] };
            }
        );
    }

    $app->hook(
        before_render => sub {
            my $c    = shift;
            my $args = shift;
            return if $args->{partial};
            return if $args->{no_toto} or $c->stash("no_toto");
            return unless $c->match && $c->match->endpoint;
            my $name = $c->match->endpoint->name;
            my ( $controller, $action ) = $name =~ m{^(.*)/(.*)$};
            return unless $controller && $action;
            $c->stash->{template_class} = "Toto";
            $c->stash->{layout}         = "toto";
            $c->stash->{action}         = $action;
            $c->stash->{controller}     = $controller;
            my $key = $c->stash("key") or return 1;
            $c->stash( instance => $c->model_class->new( key => $key ) );
        }
    );
}

1;

