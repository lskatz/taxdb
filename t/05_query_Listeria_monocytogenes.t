#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 4;
use Data::Dumper;

my $taxdb = "data/Listeria-2019-06-12.sqlite";

my @stdout = `perl scripts/taxdb_query.pl --taxon 1639 $taxdb 2>data.tmp/query.log`;
is scalar(@stdout), 84, "83 results for Listeria monocytogenes + 1 header";
if(!@stdout){
  note `cat data.tmp/query.log`;
}

my $sciNameLine = (grep {$_ =~ /scientific name/} @stdout)[0];
my @sciNameLineArr = split(/\t/, $sciNameLine);
is $sciNameLineArr[14], "Listeria monocytogenes", "Found the scientific name for taxid = 1639 (Listeria monocytogenes)";

my $lineage = join("\t", qw(1639  1637    186820  1385    91061   1239    1783272 2       131567  1));
my $obsLineage = `perl scripts/taxdb_query.pl --taxon 1639 $taxdb --mode lineage 2>data.tmp/query.log`;
chomp($obsLineage);
is $lineage, $obsLineage, "Lineage for Listeria monocytogenes, by tax_id";

my $obsLineage2 = `perl scripts/taxdb_query.pl --name "Listeria monocytogenes" $taxdb --mode lineage 2>data.tmp/query.log`;
chomp($obsLineage2);
is $lineage, $obsLineage2, "Lineage for Listeria monocytogenes, by scientific name";
