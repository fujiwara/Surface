# -*- mode:perl -*-
use strict;
use Redis;
use Test::RedisServer;
use Test::More;
use Test::Pretty;

use_ok "Surface";

my $redis_server;

subtest "setup redis server" => sub {
    eval {
        $redis_server = Test::RedisServer->new;
    } or plan skip_all => 'redis-server is required to this test';
    ok $redis_server;
};

my $surface;
for my $namespace (undef, "testing") {

    subtest "new" => sub {
        $surface = Surface->new(
            redis_options => { $redis_server->connect_info },
            expires       => 3,
        );
        ok $surface;
        $surface->namespace($namespace) if defined $namespace;

        is $surface->expires     => 3;
        is $surface->namespace   => $namespace || "default";
        is $surface->redis->ping => "PONG";
    };

    subtest "register" => sub {
        ok $surface->register({ foo => 1 });
        ok $surface->register({ bar => 2 });
        ok $surface->register({ baz => 3 });

        is_deeply [ $surface->retrieve_all ] => [{ foo => 1 }, { bar => 2 }, { baz => 3 }];
        ok $surface->is_active;
    };

    subtest "dequeue" => sub {
        my $msg;
        ok $msg = $surface->dequeue(1);
        is_deeply $msg => { foo => 1 };
        ok $msg = $surface->dequeue(1);
        is_deeply $msg => { bar => 2 };
        ok $msg = $surface->dequeue(1);
        is_deeply $msg => { baz => 3 };
        ok not $surface->dequeue(1);
    };

    sleep $surface->expires;

    subtest "inactive" => sub {
        ok not $surface->is_active;
        is $surface->cleanup => 0;
        is_deeply [ $surface->retrieve_all ] => [{ foo => 1 }, { bar => 2 }, { baz => 3 }];

        $surface->register({ xxx => 3 });
        $surface->register({ bar => 2 });
        $surface->register({ foo => 1 });
        ok $surface->is_active;
        is $surface->cleanup => 1;
    };

    subtest "enqueue_all" => sub {
        ok $surface->enqueue_all;
        my $msg;
        ok $msg = $surface->dequeue(1);
        is_deeply $msg => { xxx => 3 };
        ok $msg = $surface->dequeue(1);
        is_deeply $msg => { bar => 2 };
        ok $msg = $surface->dequeue(1);
        is_deeply $msg => { foo => 1 };
    };
}

done_testing;
