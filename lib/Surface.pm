package Surface;

use strict;
use warnings;
use Redis;
use Mouse;
use JSON;
use Log::Minimal;
use Time::HiRes qw/ time /;
use POSIX;

our $VERSION = "0.1";

has redis => (
    is      => "rw",
    lazy    => 1,
    default => sub {
        my $self = shift;
        my %options = %{ $self->redis_options };
        $options{reconnect} = 1 unless defined $options{reconnect};
        Redis->new(%options);
    },
);

has redis_options => (
    is      => "rw",
    isa     => "HashRef",
    default => sub { +{} },
);

has expires => (
    is      => "rw",
    isa     => "Int",
    default => 300,
);

has namespace => (
    is      => "rw",
    isa     => "Str",
    default => "default",
);

no Mouse;

sub register {
    my $self = shift;
    my $msg  = shift;
    my $str  = JSON::encode_json($msg);
    my $now  = time;
    my $key  = $self->namespace;
    debugf("register %s => %s", $key, $str);

    $self->redis->set( "LAST_UPDATED:$key", $now );
    $self->redis->zadd( $key, $now, $str );
    $self->redis->rpush( "QUEUE:$key", $str );
}

sub dequeue {
    my $self = shift;
    my $key  = $self->namespace;
    debugf("fetch %s using blpop", $key);
    my (undef, $str) = $self->redis->blpop("QUEUE:$key", 1);
    if (defined $str) {
        return JSON::decode_json($str);
    }
    return;
}

sub last_updated {
    my $self = shift;
    my $key  = $self->namespace;
    my $t = $self->redis->get("LAST_UPDATED:$key");
    debugf("LAST_UPDATED:$key = %s", $t);
    $t;
}

sub is_active {
    my $self = shift;
    my $expired = time - $self->expires;
    my $lu = $self->last_updated;
    debugf("%s > %s", $lu, $expired);
    $self->last_updated > $expired;
}

sub cleanup {
    my $self = shift;
    my $key  = $self->namespace;

    my $last_updated = $self->last_updated;
    unless ($last_updated) {
        warnf("can't get LAST_UPDATED:%s", $key);
        return 0;
    }

    my $n = $self->redis->zremrangebyscore(
        $key,
        0,
        ($last_updated - $self->expires)
    );
    debugf(
        "%d messages expired by cleanup (before %s)",
        $n, scalar localtime( $last_updated - $self->expires )
    );
    $n;
}

sub retrieve_all {
    my $self = shift;
    my $key  = $self->namespace;

    return map { JSON::decode_json($_) }
        $self->redis->zrange($key, 0, POSIX::ceil(time));
}

sub enqueue_all {
    my $self = shift;
    my $key  = $self->namespace;

    my $n = 0;
    for my $str ( $self->redis->zrange($key, 0, POSIX::ceil(time)) ) {
        $self->redis->rpush( "QUEUE:$key", $str );
        $n++;
    }
    $n;
}

1;

__END__
