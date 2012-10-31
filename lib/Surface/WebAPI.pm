package Surface::WebAPI;

use strict;
use Mouse;
use Plack::Runner;
use Plack::Request;

has surface => (
    is       => "rw",
    required => 1,
);

no Mouse;

sub psgi_app {
    my $self    = shift;
    sub {
        my $env = shift;
        my $req = Plack::Request->new($env);
        my $ns  = (split "/", $req->path_info)[1];
        my $msg = $req->body_parameters->as_hashref;

        my $result = $self->surface->register($msg);
        if ($result) {
            return [ 200, ["Content-Type" => "text/plain"], [ $result ] ];
        }
        else {
            return [ 500, ["Content-Type" => "text/plain"], [ "Error" ] ];
        }
    };
}

sub run {
    my $self = shift;
    my $runner = Plack::Runner->new;
    $runner->parse_options(@_);
    $runner->run( $self->psgi_app );
}

1;
