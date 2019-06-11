#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 3;
use Data::Dumper;
use Archive::Tar;
use File::Copy qw/mv/;

use IO::Uncompress::AnyUncompress qw/$AnyUncompressError/;

my $taxdumpTar = "data/taxdump-2019-06-11.tar.bz2";
my $z = new IO::Uncompress::AnyUncompress($taxdumpTar)
  or die "Could not uncompress with IO::Uncompress::UnCompress on $taxdumpTar: $AnyUncompressError\n";

is $AnyUncompressError, '', "Read the taxdump file";

my $tar = "data/taxdump-2019-06-11.tar";
if(! -e $tar){
  my @buffer = ();
  my $bufferCount = 0;
  open(my $outFh, ">", "$tar.tmp") or die "ERROR: could not write to $tar.tmp: $!";
  while(my $line = <$z>){
    push(@buffer, $line);
    
    if(++$bufferCount % 1000000 == 0){
      my $str = join("", @buffer);
      print $outFh $str;
      @buffer = ();
      note "Wrote ".length($str)." bytes from bz2 file";
    }
  }
  note "Writing the final bytes from the bz2 file into $tar";
  print $outFh join("", @buffer);
  @buffer=();
  close $outFh;

  mv("$tar.tmp", $tar) or die "ERROR moving $tar.tmp to $tar: $!";
}

my $tarObj = Archive::Tar->new;
$tarObj->read($tar);
note "Decompressing nodes.dmp => data/nodes.dmp";
$tarObj->extract_file("nodes.dmp", "data/nodes.dmp");
note "Decompressing names.dmp => data/names.dmp";
$tarObj->extract_file("names.dmp", "data/names.dmp");

is((stat("data/nodes.dmp"))[7], 144069593, "File size of nodes.dmp");
is((stat("data/names.dmp"))[7], 181152243, "File size of names.dmp");

