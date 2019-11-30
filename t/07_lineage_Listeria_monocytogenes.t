#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Test::More tests=>1;
use File::Basename qw/basename/;

# Dump to data.tmp/Listeria-dump
note "Getting the lineage of Listeria monocytogenes (taxid: 1639)";
my @lineage = `perl scripts/taxdb_lineage.pl ncbi.sqlite --taxa 1639`;
if($?){
  BAIL_OUT("ERROR finding lineage for Lmono");
}
for(@lineage){
  $_ = [split(/\s+/, $_)];
}

my @expected = [qw(1639 1637 186820 1385 91061 1239 1783272 2 131567 1)];

is_deeply(\@lineage, \@expected, "lineage found correctly");

