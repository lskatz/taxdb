#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Test::More tests=>1;
use File::Basename qw/basename/;

# Dump to data.tmp/Listeria-dump
note "Dumping data/Listeria-2019-06-12.sqlite => data.tmp/Listeria-dump/";
note `perl scripts/taxdb_dump.pl data/Listeria-2019-06-12.sqlite --outdir data.tmp/Listeria-dump --force 2>&1`;
if($?){
  BAIL_OUT("ERROR dumping Listeria database");
}

# Create sqlite database Listeria-remake.sqlite
note "data.tmp/Listeria-dump/ => data.tmp/Listeria-remake.sqlite";
unlink("data.tmp/Listeria-remake.sqlite");
note `perl scripts/taxdb_create.pl data.tmp/Listeria-remake.sqlite 2>&1`;
if($?){
  BAIL_OUT("ERROR creating new database data.tmp/Listeria-remake.sqlite");
}
# Add contents
note `perl scripts/taxdb_add.pl data.tmp/Listeria-remake.sqlite data.tmp/Listeria-dump 2>&1`;
if($?){
  BAIL_OUT("ERROR adding data from data.tmp/Listeria-dump to data.tmp/Listeria-remake.sqlite");
}

# Dump the database again
note "Dumping data.tmp/Listeria-remake.sqlite => data.tmp/Listeria-dump-remake/";
note `perl scripts/taxdb_dump.pl data.tmp/Listeria-remake.sqlite --outdir data.tmp/Listeria-dump-remake --force 2>&1`;
if($?){
  BAIL_OUT("ERROR dumping data.tmp/Listeria-remake.sqlite");
}

#is( (stat("data/Listeria-2019-06-12.sqlite"))[7], (stat("data.tmp/Listeria-remake.sqlite"))[7], "File size of new sqlite dump");

#is( `md5sum < data/Listeria-2019-06-12.sqlite`, `md5sum < data.tmp/Listeria-remake.sqlite`, "md5sum of sqlite databases");

subtest 'dump filesizes and md5sums' => sub{
  plan tests => 4;
  opendir(my $dh, "data.tmp/Listeria-dump-remake") or die "ERROR opening data.tmp/Listeria-dump-remake/: $!";
  while (my $file = readdir($dh)){
    my $file1 = "data.tmp/Listeria-dump-remake/$file";
    my $file2 = "data.tmp/Listeria-dump/$file";
    next if(!-f $file1 || $file1 !~ /\.dmp$/);
    is( (stat($file1))[7], (stat($file2))[7], "Filesize of $file1");
    is( `md5sum < $file1`, `md5sum < $file2`, "md5sum of $file1");
  }
  closedir $dh;
};

