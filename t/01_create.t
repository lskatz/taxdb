#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 3;
use Data::Dumper;

diag `perl scripts/taxdb_create.pl taxdb.sqlite 2>&1`;
BAIL_OUT("ERROR with taxdb_create.pl: $!") if $?;
diag `perl scripts/taxdb_add.pl    taxdb.sqlite data 2>&1`;
BAIL_OUT("ERROR with taxdb_add.pl: $!") if $?;

my $numNodes = `sqlite3 taxdb.sqlite 'SELECT count(tax_id) FROM NODE'`;
my $numNames = `sqlite3 taxdb.sqlite 'SELECT count(tax_id) FROM NAME'`;
my $numLmonoNames = `sqlite3 taxdb.sqlite 'SELECT count(*) FROM NAME WHERE tax_id = 1639;'`;
chomp($numNodes,$numNames,$numLmonoNames);

is $numNodes, 2117936, "Number of nodes";
is $numNames, 3001022, "Number of names";
is $numLmonoNames, 83, "Number of Listeria monocytogenes name entries"

