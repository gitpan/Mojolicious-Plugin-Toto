package Mojolicious::Plugin::Toto::Model;
use Mojo::Base -base;
has 'key';

sub autocomplete {
    my $class  = shift;
    my %args   = @_;
    my $q      = $args{q} or return;
    my $object = $args{object};
    my $c      = $args{c};
    return [
        map +{
            name => "$object $_",
            href => $c->url_for("$object/default", key => $_),
        }, 1..10
    ];
}

1;

