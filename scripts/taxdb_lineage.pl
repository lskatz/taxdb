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
  GetOptions($settings,qw(help rank|ranks translate outdir=s taxon|taxa=s@)) or die $!;

  die usage() if(!@ARGV || $$settings{help});
  die "ERROR: need --taxon\n".usage() if(!$$settings{taxon});

  my ($dbpath)=@ARGV;

  # TODO foreign keys
  my $dbh = DBI->connect("dbi:SQLite:dbname=$dbpath","","",
    { 
      AutoCommit=> 1, # no commits are happening, so no worries
    }
  );
  $dbh->do("PRAGMA foreign_keys = ON");

  my @taxon;
  for my $taxlist(@{ $$settings{taxon} }){
    for my $taxid(split(/,/, $taxlist)){
      push(@taxon, $taxid);
    }
  }

  # Grab lineages these taxids
  my @possibleRankField = (qw(domain superkingdom kingdom subkingdom phylum subphylum superclass class subclass infraclass parvclass superorder order suborder superfamily family subfamily supergenus genus species subspecies variety subvariety forma subform));
  my @rankField = ();
  my $headerHasBeenPrinted = 0;
  for my $taxid(@taxon){
    my $taxidArr = findLineage($taxid, $dbh, $settings);
    if($$settings{rank}){
      my %taxon; # rank => taxid
      for (@$taxidArr){
        my $rankName = getRank($_, $dbh, $settings);
        $taxon{$rankName} = $_;
      }
      if(!@rankField){
        @rankField = keys(%taxon);
      }
      # Print taxids in the order of possible ranks
      for my $rankName(@possibleRankField){
        if($taxon{$rankName}){
          my $value = $taxon{$rankName};
          $value = translate($value,$dbh,$settings) if($$settings{translate});
          print "$value\t";
        }
      }
      print "\n";
    } else {
      print join("\t", @$taxidArr)."\n";
    }
  }

  $dbh->disconnect();
  return 0;
}

sub findLineage{
  my($taxid, $dbh, $settings) = @_;

  my @lineage = (); # array of taxids

  my $currTaxid     = $taxid;
  my $ancestorTaxid = -1;
  while($currTaxid != $ancestorTaxid && @lineage < 1000){
    push(@lineage, $currTaxid);
    my $ancestorTaxid = findAncestor($currTaxid, $dbh, $settings);
    if(!defined($ancestorTaxid)){
      die "ERROR: no taxon with taxid $currTaxid (started with taxid $taxid)";
    }
    last if($ancestorTaxid == $currTaxid);
    if(@lineage > 999){
      die "ERROR: for taxid $taxid, the number of ancestors went over 999";
    }
    $currTaxid = $ancestorTaxid;
  }

  return \@lineage;
} 

sub findAncestor{
  my($taxid, $dbh, $settings) = @_;
  
  my $sth = $dbh->prepare(qq(
    SELECT parent_tax_id
    FROM NODE
    WHERE tax_id = ?;
  ));
  
  my $res = $sth->execute($taxid)
    or die "ERROR: could not query for tax_id = $taxid: ".$dbh->errstr();

  my @row = $sth->fetchrow_array();
  return $row[0];
}

sub getRank{
  my($taxid, $dbh, $settings) = @_;

  my $sth = $dbh->prepare(qq(
    SELECT rank
    FROM NODE
    WHERE tax_id = ?;
  ));
  
  my $res = $sth->execute($taxid)
    or die "ERROR: could not query for tax_id = $taxid: ".$dbh->errstr();

  my @row = $sth->fetchrow_array();
  return $row[0];
}

sub translate{
  my($taxid, $dbh, $settings) = @_;

  my $sth = $dbh->prepare(qq(
    SELECT name_txt 
    FROM NAME
    WHERE tax_id = ?
      AND name_class = "scientific name";
  ));
  
  my $res = $sth->execute($taxid)
    or die "ERROR: could not query for tax_id = $taxid: ".$dbh->errstr();

  my @row = $sth->fetchrow_array();
  return $row[0];
}

sub usage{
  "Get the lineage of taxa up to the root
  Usage: $0 [options] file.sqlite3 > lineage.tsv
  --taxon     Taxon IDs.  Can specify multiple --taxon or
              comma-separate them, e.g., --taxon 1,2,3
  --rank      Print a header of named ranks (e.g., species)
              and only print taxids that match named ranks.
  --translate Turn taxids into words (e.g., 662 => Vibrio)
  "
}

