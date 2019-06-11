#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 3;
use Data::Dumper;
use Archive::Tar;

use IO::Uncompress::AnyUncompress qw/$AnyUncompressError/;

my $taxdumpTar = "data/taxdump-2019-06-11.tar.bz2";
my $z = new IO::Uncompress::AnyUncompress($taxdumpTar)
  or die "Could not uncompress with IO::Uncompress::UnCompress on $taxdumpTar: $AnyUncompressError\n";

is $AnyUncompressError, '', "Read the taxdump file";

my $tar = "data/taxdump-2019-06-11.tar";
my @buffer = ();
my $bufferCount = 0;
open(my $outFh, ">", $tar) or die "ERROR: could not write to $tar: $!";
while(my $line = <$z>){
  push(@buffer, $line);
  
  if(++$bufferCount % 1000000 == 0){
    my $str = join("", @buffer);
    print $outFh $str;
    @buffer = ();
  }
}
print $outFh join("", @buffer);
@buffer=();
close $outFh;

my $tarObj = Archive::Tar->new;
$tarObj->read($tar);
$tarObj->extract_file("nodes.dmp", "data/nodes.dmp");
$tarObj->extract_file("names.dmp", "data/names.dmp");

is((stat("data/nodes.dmp"))[7], 144069593, "File size of nodes.dmp");
is((stat("data/names.dmp"))[7], 181152243, "File size of names.dmp");

