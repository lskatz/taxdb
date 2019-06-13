#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 2;
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

