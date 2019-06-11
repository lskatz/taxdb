#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 3;
use Data::Dumper;

$|++;
diag `perl scripts/taxdb_extract.pl --taxon 1639 taxdb.sqlite --outdir lmono.flat 2>&1`;
BAIL_OUT("Failed to extract 1639 (Listeria monocytogenes): $!") if $?;
$|--;

diag `perl scripts/taxdb_create.pl lmono.sqlite 2>&1`;
BAIL_OUT("Failed to create db lmono.sqlite: $!") if $?;
diag `perl scripts/taxdb_add.pl lmono.sqlite lmono.flat 2>&1`;
BAIL_OUT("Failed to add 1639 (Listeria monocytogenes) to the new database: $!") if $?;

