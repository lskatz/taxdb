#!/usr/bin/env perl

use strict;
use warnings;
use DBI;
use Getopt::Long qw/GetOptions/;
use Data::Dumper;
use List::MoreUtils qw/uniq/;

sub logmsg{print STDERR "$0: @_\n";}

exit(main());

sub main{
  my $settings={};
  GetOptions($settings,qw(help name|scientificName=s@ mode=s sep|separator=s outdir=s taxon|taxa=s@)) or die $!;
  $$settings{outdir} ||= './out';
  $$settings{sep} ||= "\t";
  $$settings{mode}||= "default";
  $$settings{mode} = lc($$settings{mode});

  die usage() if(!@ARGV || $$settings{help});

  if(!$$settings{taxon} && !$$settings{name}){
    die "ERROR: need either --name or --taxon\n".usage();
  }

  my ($dbpath)=@ARGV;

  # TODO foreign keys
  my $dbh = DBI->connect("dbi:SQLite:dbname=$dbpath","","",
    { 
      AutoCommit=> 0,
    }
  );
  $dbh->do("PRAGMA foreign_keys = ON");

  my @descendent = ();
  my @topLevelTaxon = (); # user-specified taxids

  # Separate out the taxa into an array @topLevelTaxon.
  for my $taxlist(@{ $$settings{taxon} }){
    for my $taxid(split(/,/, $taxlist)){
      push(@topLevelTaxon, $taxid);
    }
  }
  
  # Translate names to taxids here, and push them
  # onto @topLevelTaxon
  for my $nameList(@{$$settings{name}}){
    for my $name(split(/,/, $nameList)){
      my $taxid = findTaxonByScientificName($name, $dbh, $settings);
      if(scalar(@$taxid) > 1){
        print STDERR "WARNING: found multiple taxids for $name\n";
      }
      push(@topLevelTaxon, @$taxid);
    }
  }

  if($$settings{mode} eq 'default'){
    dumpTaxa(\@topLevelTaxon, $dbh, $settings);
  } elsif($$settings{mode} eq 'lineage'){
    dumpLineage(\@topLevelTaxon, $dbh, $settings);
  }

  $dbh->disconnect;

  return 0;
}

sub dumpTaxa{
  my($taxa, $dbh, $settings) = @_;

  my $manyQuestionMarks = '?,' x scalar(@$taxa);
  $manyQuestionMarks=~s/,$//;
  my $sth = $dbh->prepare(qq(
    SELECT NODE.*, NAME.*
    FROM NAME LEFT JOIN NODE ON NODE.tax_id = NAME.tax_id
    WHERE NODE.tax_id IN ($manyQuestionMarks)
  ))
    or die "ERROR preparing SELECT statement: ".$dbh->errstr();

  my $res = $sth->execute(@$taxa)
    or die "ERROR querying with @$taxa: ".$dbh->errstr();

  my $sep = $$settings{sep};
  print join($sep, @{ $sth->{NAME_lc} })."\n";
  while(my @row = $sth->fetchrow_array()){
    print join($sep, @row)."\n";
  }

  return 1;
}

sub dumpLineage{
  my($taxa, $dbh, $settings) = @_;

  for my $taxon(@$taxa){
    my $lineage = $taxon;
    my $sth = $dbh->prepare(qq(
      SELECT parent_tax_id
      FROM NODE
      WHERE NODE.tax_id = ?
    ))
      or die "ERROR preparing SELECT statement: ".$dbh->errstr();

    my $res = $sth->execute($taxon)
      or die "ERROR getting parent for $taxon: ".$dbh->errstr();

    my @row = $sth->fetchrow_array();
    my $parent = $row[0];
    while($parent != $taxon){
      $lineage .= "\t$parent";
      $taxon = $parent;

      my $sth2 = $dbh->prepare(qq(
        SELECT parent_tax_id
        FROM NODE
        WHERE NODE.tax_id = ?
      ))
        or die "ERROR preparing SELECT statement: ".$dbh->errstr();

      my $res2 = $sth2->execute($taxon)
        or die "ERROR getting parent for $taxon: ".$dbh->errstr();

      @row = $sth2->fetchrow_array();
      $parent = $row[0];
    }
    print $lineage."\n";
  }

  return 1;
}

sub findTaxonByScientificName{
  my($name, $dbh, $settings) = @_;

  my @taxid;

  my $sth = $dbh->prepare(qq(
    SELECT NODE.tax_id
    FROM NODE LEFT JOIN NAME on NODE.tax_id = NAME.tax_id
    WHERE NAME.name_class = "scientific name"
    AND name_txt = ?
  ))
    or die "ERROR preparing SELECT statement: ".$dbh->errstr();

  my $res = $sth->execute($name)
    or die "ERROR executing SELECT statement for $name: ".$dbh->errstr();

  while(my @row = $sth->fetchrow_array()){
    push(@taxid, $row[0]);
  }
   
  return \@taxid;
}

sub usage{
  "Display the details on any given taxon
  Usage: $0 [options] file.sqlite3
  --taxon     Taxon IDs.  Can specify multiple --taxon or
              comma-separate them, e.g., --taxon 1,2,3
  --name      A scientific name. Quote it if there
              are spaces, e.g., 'Listeria monocytogenes'.
              Multiple names can be specified in the same
              way as --taxon.
  --separator By default, columns are tab-separated.
  --mode      Either: default, lineage
  "
}

