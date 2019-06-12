#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 2;
use Data::Dumper;

diag `perl scripts/taxdb_dump.pl data/Listeria-2019-06-12.sqlite --outdir Listeria --force 2>&1`;
BAIL_OUT("ERROR with taxdb_dump.pl: $!") if $?;

my($numNodes, $numNames);

open(my $nodesFh, "Listeria/nodes.dmp") or BAIL_OUT("ERROR: could not open Listeria/nodes.dmp: $!");
while(<$nodesFh>){
  $numNodes++;
}
close $nodesFh;

open(my $namesFh, "Listeria/names.dmp") or BAIL_OUT("ERROR: could not open Listeria/names.dmp: $!");
while(<$namesFh>){
  $numNames++;
}
close $namesFh;

is $numNodes, 306, "Number of nodes";
is $numNames, 758, "Number of names";

