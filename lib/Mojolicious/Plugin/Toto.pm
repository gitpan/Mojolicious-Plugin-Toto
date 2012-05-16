=head1 NAME

Mojolicious::Plugin::Toto - A simple tab and object based site structure

=head1 SYNOPSIS

    use Mojolicious::Lite;

    plugin 'toto'
         => menu => $menu;

    app->start;

OR
    use Mojolicious::Lite;

    plugin 'toto'
         => nav => $nav,
            sidebar => $sidebar,
            tabs => $tabs;

    app->start;


=head1 DESCRIPTION

This plugin provides a navigational structure and a default set
of routes for a Mojolicious or Mojolicious::Lite app

The navigational structure is a slight variation of this
example used by twitter's bootstrap :

    http://twitter.github.com/bootstrap/examples/fluid.html

The plugin provides a sidebar, a nav bar, and also a
row of tabs underneath the name of an object.

The row of tabs is an extension of BREAD or CRUD -- in a BREAD
application, browse and add are operations on zero or many objects,
while edit, add, and delete are operations on one object.  In
the toto structure, these two types of operations are distinguished
by placing the former in the side nav bar, and the latter in
a row of tabs underneath the object to which the action applies. 

Additionally, a top nav bar contains menu items to take the user
to a particular side bar.

=head1 HOW DOES IT WORK

After loading the toto plugin, the default layout is set to 'toto'.

Defaults routes are generated for every sidebar entry and tab entry.

The names of the routes are of the form "controller/action", where
controller is both the controller class and the model class.

Templates in the directory templates/<controller>/<action>.html.ep will be used when
they exist.

The stash values "object" and "tab" are set for each auto-generated route.
Also "noun" is set as an alias to "object".

A version of twitter's bootstrap (<http://twitter.github.com/bootstrap>) is
included in this distribution.

=head1 OPTIONS

In addition to "menu", "nav/sidebar/tabs", the following options are recognized :

=over

=item prefix

    prefix => /my/subpath

A prefix to prepend to the path for the toto routes.

=item model_namespace

    model_namespace => "Myapp::Model'

A namespace for model classes : the model class will be camelized and appended to this.

=back

=head1 EXAMPLE

=head2 Simple structure

The "menu" format can be used to automatically generate
the nav bar, side bar and rows of tabs, using actions
which correspond to many objects or actions which
correspond to one object.

    #!/usr/bin/env perl

    use Mojolicious::Lite;

    plugin 'toto' =>
         menu => [
            beer => {
                many => [qw/search browse/],
                one  => [qw/picture ingredients pubs/],
            },
            pub => {
                many => [qw/map list search/],
                one  => [qw/info comments/],
            }
        ];

    app->start;

=head2 Complex structure

The "nav/sidebar/tabs" format can be used
for a more versatile structure, in which the
nav bar and side bar are less constrained.

     use Mojolicious::Lite;

     get '/my/url/to/list/beers' => sub {
          shift->render_text("Here is a page for listing beers.");
     } => "beer/list";

     get '/beer/create' => sub {
        shift->render_text("Here is a page to create a beer.");
     } => "beer/create";

     plugin 'toto' =>

          # top nav bar items
          nav => [
              'brewpub',          # Refers to a sidebar entry below
              'beverage'          # Refers to a sidebar entry below
          ],

          # possible sidebars, keyed on nav entries
          sidebar => {
            brewpub => [
                'brewery/phonelist',
                'brewery/mailing_list',
                'pub/search',
                'pub/map',
                'brewery',        # Refers to a "tab" entry below
                'pub',            # Refers to a "tab" entry below
            ],
            beverage =>
              [ 'beer/list',      # This will use the route defined above named "beer/list"
                'beer/create',
                'beer/search',
                'beer/browse',    # This will use the controller at the top (Beer::browse)
                'beer'            # Refers to a "tab" entry below
               ],
          },

          # possible rows of tabs, keyed on sidebar entries without a /
          tabs => {
            brewery => [ 'view', 'edit', 'directions', 'beers', 'info' ],
            pub     => [ 'view', 'info', 'comments', 'hours' ],
            beer    => [ 'view', 'edit', 'pictures', 'notes' ],
          };
     ;

     app->start;


=head1 NOTES

To create pages outside of the toto framework, just set the layout to
something other than "toto', e.g.

    get '/no/toto' => { layout => 'default' } => ...

This module is experimental.  The API may change without notice.  Feedback is welcome!

=head1 AUTHOR

Brian Duggan C<bduggan@matatu.org>

=head1 SEE ALSO

http://twitter.github.com/bootstrap/examples/fluid.html
http://www.beer.dotcloud.com

=cut

package Mojolicious::Plugin::Toto;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream qw/b/;
use File::Basename 'dirname';
use File::Spec::Functions 'catdir';
use Mojolicious::Plugin::Toto::Model;
use Cwd qw/abs_path/;

use strict;
use warnings;

our $VERSION = 0.11;

sub _render_static {
    my $c = shift;
    my $what = shift;
    $c->render_static($what);
}

sub _cando {
    my ($namespace,$controller,$action) = @_;
    my $package = join '::', ( $namespace || () ), b($controller)->camelize;
    return $package->can($action) ? 1 : 0;
}

sub _to_noun {
    my $word = shift;
    $word =~ s/_/ /g;
    $word;
}

sub _add_sidebar {
    my $self = shift;
    my $app = shift;
    my ($prefix, $nav_item, $object, $tab) = @_;
    die "no tab for $object" unless $tab;
    die "no nav item" unless $nav_item;

    my @found_template = (
        ( map { glob "$_/$tab.*" } @{ $app->renderer->paths } ),
        ( map { glob "$_/$object/$tab.*" } @{ $app->renderer->paths } ),
    );

    my $found_controller = _cando($app->routes->namespace,$object,$tab);

    $app->log->debug("Adding sidebar route for $prefix/$object/$tab");
    $app->log->debug("nav item: $nav_item, template: @found_template, controller? ".($found_controller // 'no') );

    my $r = $app->routes->under(
        "$prefix/$object/$tab" => sub {
            my $c = shift;
            $c->stash(template => ( @found_template ? $tab : "plural" ));
            $c->stash(object     => $object);
            $c->stash(noun       => $object);
            $c->stash(tab        => $tab);
            $c->stash(nav_item   => $nav_item);
          })->any;
    $r = $r->to("$object#$tab") if $found_controller;
    $r->name("$object/$tab");
}

sub _add_tab {
    my $self = shift;
    my $app = shift;
    my ($prefix, $nav_item, $object, $tab) = @_;
    my @found_object_template = map { glob "$_/$object/$tab.*" } @{ $app->renderer->paths };
    my @found_template = map { glob "$_/$tab.*" } @{ $app->renderer->paths };
    my $found_controller = _cando($app->routes->namespace,$object,$tab);
    $app->log->debug("Adding route for $prefix/$object/$tab/*key");
    $app->log->debug("Found controller class for $object/$tab/key") if $found_controller;
    $app->log->debug("Found template for $object/$tab/key") if @found_template || @found_object_template;
    my $r = $app->routes->under("$prefix/$object/$tab/(*key)"  =>
            sub {
                my $c = shift;
                $c->stash(object => $object);
                $c->stash(noun => _to_noun($object));
                $c->stash(tab => $tab);
                my $key = lc $c->stash('key');
                my @found_instance_template = map { glob "$_/$object/$key/$tab.*" } @{ $app->renderer->paths };
                $c->stash(
                    template => (
                          0 + @found_instance_template ? "$object/$key/$tab"
                        : 0 + @found_object_template ? "$object/$tab"
                        : 0 + @found_template        ? $tab
                        : "single"
                    )
                );
                my $instance = $c->current_instance;
                $c->stash( instance => $instance );
                $c->stash( nav_item => $nav_item );
                $c->stash( $object  => $instance );
                1;
              }
            )->any;
      $r = $r->to("$object#$tab") if $found_controller;
      $r->name("$object/$tab");
}

sub _menu_to_nav {
    my $self = shift;
    my ($conf,$menu) = @_;
    my $nav;
    my $sidebar;
    my $tabs;
    my $object;
    for (@$menu) {
        unless (ref $_) {
            $object = $_;
            push @$nav, $object;
            next;
        }
        for my $action (@{ $_->{many} || [] }) {
            push @{$sidebar->{$object}}, "$object/$action";
        }
        push @{$sidebar->{$object}}, $object;
        for my $action (@{ $_->{one} || [] }) {
            push @{$tabs->{$object}}, $action;
        }
    }
    $conf->{nav} = $nav;
    $conf->{sidebar} = $sidebar;
    $conf->{tabs} = $tabs;
}

sub register {
    my ($self, $app, $conf) = @_;
    $app->log->debug("registering plugin");

    if (my $menu = $conf->{menu}) {
        $self->_menu_to_nav($conf,$menu);
    }
    for (qw/nav sidebar tabs/) {
        die "missing $_" unless $conf->{$_};
    }
    my ($nav,$sidebar,$tabs) = @$conf{qw/nav sidebar tabs/};

    my $prefix = $conf->{prefix} || '';

    my $base = catdir(abs_path(dirname(__FILE__)), qw/Toto Assets/);
    my $default_path = catdir($base,'templates');
    push @{$app->renderer->paths}, catdir($base, 'templates');
    push @{$app->static->paths},   catdir($base, 'public');
    $app->defaults(layout => "toto", toto_prefix => $prefix);

    $app->log->debug("Adding routes");

    my %tab_done;

    die "toto plugin needs a 'nav' entry, please read the pod for more information" unless $nav;
    for my $nav_item ( @$nav ) {
        $app->log->debug("Adding routes for $nav_item");
        my $first;
        my $items = $sidebar->{$nav_item} or die "no sidebar for $nav_item";
        for my $subnav_item ( @$items ) {
            $app->log->debug("routes for $subnav_item");
            my ( $object, $action ) = split '/', $subnav_item;
            if ($action) {
                $first ||= $subnav_item;
                $self->_add_sidebar($app,$prefix,$nav_item,$object,$action);
            } else {
                my $first_tab;
                my $tabs = $tabs->{$subnav_item} or
                     do { warn "# no tabs for $subnav_item"; next; };
                die "tab row for '$subnav_item' appears more than once" if $tab_done{$subnav_item}++;
                for my $tab (@$tabs) {
                    $first_tab ||= $tab;
                    $self->_add_tab($app,$prefix,$nav_item,$object,$tab);
                }
                $app->log->debug("Will redirect $prefix/$object/default/key to $object/$first_tab/\$key");
                $app->routes->get("$prefix/$object/default/*key" => sub {
                    my $c = shift;
                    my $key = $c->stash("key");
                    $c->redirect_to("$object/$first_tab/$key");
                    } => "$object/default ");
            }
        }
        die "Could not find first route for nav item '$nav_item' : all entries have tabs\n" unless $first;
        $app->routes->get(
            $nav_item => sub {
                my $c = shift;
                $c->redirect_to($first);
            } => $nav_item );
    }

    my $first_object = $conf->{nav}[0];
    $app->routes->get("$prefix/" => sub { shift->redirect_to($first_object) } );

    for ($app) {
        $_->helper( toto_config => sub { $conf } );
        $_->helper( model_class => sub {
                my $c = shift;
                if (my $ns = $conf->{model_namespace}) {
                    return join '::', $ns, b($c->current_object)->camelize;
                }
                $conf->{model_class} || "Mojolicious::Plugin::Toto::Model"
             }
         );
        $_->helper(
            tabs => sub {
                my $c    = shift;
                my $for  = shift || $c->current_object or return;
                @{ $conf->{tabs}{$for} || [] };
            }
        );
        $_->helper( current_object => sub {
                my $c = shift;
                $c->stash('object') || [ split '\/', $c->current_route ]->[0]
            } );
        $_->helper( current_tab => sub {
                my $c = shift;
                $c->stash('tab') || [ split '\/', $c->current_route ]->[1]
            } );
        $_->helper( current_instance => sub {
                my $c = shift;
                my $key = $c->stash("key") || [ split '\/', $c->current_route ]->[2];
                return $c->model_class->new(key => $key);
            } );
        $_->helper( printable => sub {
                my $c = shift;
                my $what = shift;
                $what =~ s/_/ /g;
                $what } );
    }

    $self;
}

1;
