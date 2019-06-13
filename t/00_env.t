#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 1;
use Data::Dumper;

system("perl t/90_cleanup.t >/dev/null 2>&1") or note "NOTE: preventative cleanup resulted in an error which might only mean that there was nothing to clean up.";

my $bool = mkdir("data.tmp");
is $bool, 1, "Make the temp directory for testing";

