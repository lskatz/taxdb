#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 3;
use Data::Dumper;
use File::Copy qw/cp/;

my $taxdb = "Listeria-noLmono.rebuilt.sqlite";
cp("Listeria.rebuilt.sqlite", $taxdb) or BAIL_OUT("ERROR: could not copy Listeria-noLmono.rebuilt.sqlite => $taxdb: $!");

note `perl scripts/taxdb_delete.pl --taxon 1639 $taxdb 2>&1`;
BAIL_OUT("Failed to delete 1639 (Listeria monocytogenes): $!") if $?;

my $numNodes = `sqlite3 $taxdb 'SELECT count(tax_id) FROM NODE'`;
my $numNames = `sqlite3 $taxdb 'SELECT count(tax_id) FROM NAME'`;
my $numLmonoNames = `sqlite3 $taxdb 'SELECT count(*) FROM NAME WHERE tax_id = 1639;'`;
chomp($numNodes,$numNames,$numLmonoNames);

is $numNodes, 305, "Number of nodes";
is $numNames, 675, "Number of names";
is $numLmonoNames, 0, "Number of Listeria monocytogenes name entries"

