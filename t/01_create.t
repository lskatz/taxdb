#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 4;
use Data::Dumper;

perl scripts/taxdb_create.pl taxdb.sqlite
perl scripts/taxdb_add.pl    taxdb.sqlite data

my $numNodes = `sqlite3 taxdb.sqlite 'SELECT count(tax_id) FROM NODE'`;
my $numNames = `sqlite3 taxdb.sqlite 'SELECT count(tax_id) FROM NAME'`;

is $numNodes, 2117936, "Number of nodes";
is $numNames, 3001022, "Number of names";

my $numLmonoNames = `sqlite3 taxdb.sqlite 'SELECT count(*) FROM NAME WHERE tax_id = 1639;'`;
is $numLmonoNames, 83, "Number of Listeria monocytogenes name entries"

