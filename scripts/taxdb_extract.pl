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
  GetOptions($settings,qw(help outdir=s taxon|taxa=s@)) or die $!;
  $$settings{outdir} ||= './out';

  die usage() if(!@ARGV || $$settings{help});
  die "ERROR: need --taxon\n".usage() if(!$$settings{taxon});

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

  for my $taxlist(@{ $$settings{taxon} }){
    for my $taxid(split(/,/, $taxlist)){
      push(@topLevelTaxon, $taxid);
    }
  }

  # Grab all descendents for these taxids
  for my $taxid(@topLevelTaxon){
    my $taxidArr = findDescendents($taxid, $dbh, $settings);
    push(@descendent, $taxid, @$taxidArr);
  }

  # Grab the common lineage for these taxids
  # right up to the root
  my %lineage;
  my @ancestor;
  for my $taxid(@topLevelTaxon){

    # Get the lineage array by finding one ancestor at
    # a time, climbing up until we reach the root.
    # The root is defined as a taxon whose parent tax id
    # is the same as its tax id.
    my @lineage = ();
    my $parent_tax_id;
    my $current_tax_id = $taxid;
    $parent_tax_id = findAncestor($taxid, $dbh, $settings);
    push(@lineage, $current_tax_id);
    while($parent_tax_id != $current_tax_id){
      $current_tax_id = $parent_tax_id;
      push(@lineage, $current_tax_id);
      $parent_tax_id = findAncestor($current_tax_id, $dbh, $settings);
    }
    
    $lineage{$taxid} = \@lineage;
    push(@ancestor, @lineage);
  }

  # Now get the database corresponding to all descendent
  # and ancestor IDs
  
  my $outdir = $$settings{outdir};
  mkdir $outdir or die "ERROR: could not mkdir $outdir: $!";
  my @uniqTaxa = sort {$a<=>$b} uniq(@descendent, @ancestor);
  dumpTaxa(\@uniqTaxa, $dbh, $outdir, $settings);

  $dbh->disconnect();
  return 0;
}

sub dumpTaxa{
  my($taxa, $dbh, $outdir, $settings)=@_;

  my $manyQuestionMarks = '?,' x scalar(@$taxa);
  $manyQuestionMarks =~ s/,$//;

  my $sth = $dbh->prepare(qq(
    SELECT NAME.*
    FROM NAME
    WHERE NAME.tax_id IN ($manyQuestionMarks)
  ));
  my $res = $sth->execute(@$taxa)
    or die "ERROR: could not query NAME for tax_id = @$taxa: ".$dbh->errstr();

  open(my $namesFh, ">", "$outdir/names.dmp") or die "ERROR writing to $outdir/names.dmp: $!";
  while(my @row = $sth->fetchrow_array()){
    print $namesFh join("\t|\t", @row)."\n";
  }
  close $namesFh;


  my $sth2 = $dbh->prepare(qq(
    SELECT NODE.*
    FROM NODE
    WHERE NODE.tax_id IN ($manyQuestionMarks)
  ));
  my $res2 = $sth2->execute(@$taxa)
    or die "ERROR: could not query NODE for tax_id = @$taxa: ".$dbh->errstr();

  open(my $nodesFh, ">", "$outdir/nodes.dmp") or die "ERROR writing to $outdir/nodes.dmp: $!";
  while(my @row = $sth2->fetchrow_array()){
    print $nodesFh join("\t|\t", @row)."\n";
  }
  close $nodesFh;

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

sub findDescendents{
  my($taxid, $dbh, $settings)=@_;

  my @taxid = ();

  my $sth = $dbh->prepare(qq(
    SELECT tax_id
    FROM NODE
    WHERE parent_tax_id = ?
  ));
  my $res = $sth->execute($taxid)
    or die "ERROR: could not query for parent_tax_id = $taxid: ".$dbh->errstr();

  while(my @row = $sth->fetchrow_array()){
    logmsg "$taxid -> $row[0]";
    my $subTaxid = findDescendents($row[0], $dbh, $settings);
    push(@taxid, ($row[0], @$subTaxid));
  }

  return \@taxid;
}

sub usage{
  "Extract a taxon or taxa from the database and dump them
  Usage: $0 [options] file.sqlite3
  --taxon     Taxon IDs.  Can specify multiple --taxon or
              comma-separate them, e.g., --taxon 1,2,3
  --outdir    Output directory for flat files
  "
}

