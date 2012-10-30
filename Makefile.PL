use inc::Module::Install;
name 'Surface';
all_from 'lib/Surface.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
