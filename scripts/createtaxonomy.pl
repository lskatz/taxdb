#!/usr/bin/env perl

use strict;
use warnings;
use DBI;
use Getopt::Long qw/GetOptions/;
use Data::Dumper;

sub logmsg{print STDERR "$0: @_\n";}

exit(main());

sub main{
  my $settings={};
  GetOptions($settings,qw(help dbpath=s)) or die $!;
  $$settings{dbpath}||="taxonomy.db3";

  die usage() if(!@ARGV || $$settings{help});

  my $dbpath=$ARGV[0];

  my $dbh = DBI->connect("dbi:SQLite:dbname=$dbpath","","");

  my $sth = $dbh->prepare(qq(
    CREATE TABLE NODE(
      tax_id                         INTEGER  PRIMARY KEY,
      parent_tax_id                  INTEGER,
      rank                           TEXT,
      embl_code                      INTEGER,
      division_id                    INTEGER,
      inherited_div_flag             INTEGER,
      genetic_code_id                INTEGER,
      inherited_gc_flag              INTEGER,
      mitochondrial_genetic_code_id  INTEGER,
      inherited_mgc_flag             INTEGER,
      genbank_hidden_flag            INTEGER,
      hidden_subtree_root_flag       INTEGER,
      comments                       TEXT
    );
  ));
  $sth->execute();

  my $sth2 = $dbh->prepare(qq(
    CREATE TABLE NAME(
      tax_id        INTEGER PRIMARY KEY,
      name_txt      TEXT,
      unique_name   TEXT,
      name_class    TEXT
    );
  ));
  $sth2->execute();

  return 0; # exit status 0
}

sub usage{
  "This script creates a blank taxonomy database
  Usage: $0 file.sqlite
  "
}
