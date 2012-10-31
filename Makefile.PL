use inc::Module::Install;
name 'Surface';
all_from 'lib/Surface.pm';

requires "Redis";
requires "Mouse";
requires "Time::HiRes";
requires "JSON";
requires "Log::Minimal";

test_requires "Test::Pretty";
test_requires "Test::RedisServer";
test_requires "Test::More";
test_requires "Test::Pretty";

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
