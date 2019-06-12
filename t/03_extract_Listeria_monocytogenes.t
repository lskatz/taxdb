#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 3;
use Data::Dumper;

my $taxdb = "Listeria.rebuilt.sqlite";

for(glob("lmono.flat/*")){
  unlink($_);
}
rmdir "lmono.flat";

diag `perl scripts/taxdb_extract.pl --taxon 1639 $taxdb --outdir lmono.flat 2>&1`;
BAIL_OUT("Failed to extract 1639 (Listeria monocytogenes): $!") if $?;

my $taxdb2 = "lmono.sqlite";
unlink($taxdb2); # overwrite
diag `perl scripts/taxdb_create.pl $taxdb2 2>&1`;
BAIL_OUT("Failed to create db $taxdb2: $!") if $?;
diag `perl scripts/taxdb_add.pl $taxdb2 lmono.flat 2>&1`;
BAIL_OUT("Failed to add 1639 (Listeria monocytogenes) to the new database: $!") if $?;

my $numNodes = `sqlite3 $taxdb2 'SELECT count(tax_id) FROM NODE'`;
my $numNames = `sqlite3 $taxdb2 'SELECT count(tax_id) FROM NAME'`;
my $numLmonoNames = `sqlite3 $taxdb 'SELECT count(*) FROM NAME WHERE tax_id = 1639;'`;
chomp($numNodes,$numNames,$numLmonoNames);

is $numNodes, 231, "Number of nodes";
is $numNames, 456, "Number of names";
is $numLmonoNames, 83, "Number of Listeria monocytogenes name entries"

