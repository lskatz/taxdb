#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 3;
use Data::Dumper;

my $taxdb = "data.tmp/Listeria.rebuilt.sqlite";
unlink($taxdb); #force overwrite
note `perl scripts/taxdb_create.pl $taxdb 2>&1`;
BAIL_OUT("ERROR with taxdb_create.pl on $taxdb: $!") if $?;
note `perl scripts/taxdb_add.pl    $taxdb data.tmp/Listeria 2>&1`;
BAIL_OUT("ERROR with taxdb_add.pl $taxdb data.tmp/Listeria: $!") if $?;

my $numNodes = `sqlite3 $taxdb 'SELECT count(tax_id) FROM NODE'`;
my $numNames = `sqlite3 $taxdb 'SELECT count(tax_id) FROM NAME'`;
my $numLmonoNames = `sqlite3 $taxdb 'SELECT count(*) FROM NAME WHERE tax_id = 1639;'`;
chomp($numNodes,$numNames,$numLmonoNames);

is $numNodes, 306, "Number of nodes";
is $numNames, 758, "Number of names";
is $numLmonoNames, 83, "Number of Listeria monocytogenes name entries"

