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
  GetOptions($settings,qw(help taxon|taxa=s@)) or die $!;

  die usage() if(!@ARGV || $$settings{help});
  die "ERROR: need --taxon\n".usage() if(!$$settings{taxon});

  my ($dbpath)=@ARGV;

  # TODO foreign keys
  my $dbh = DBI->connect("dbi:SQLite:dbname=$dbpath","","",
    { 
      AutoCommit=> 0,
    }
  );

  my @taxid = (); # results for taxid
  my @topLevelTaxon = (); # user-specified taxids

  for my $taxlist(@{ $$settings{taxon} }){
    for my $taxid(split(/,/, $taxlist)){
      push(@topLevelTaxon, $taxid);
    }
  }

  # Grab all descendents for these taxids
  for my $taxid(@topLevelTaxon){
    my $taxidArr = findDescendents($taxid, $dbh, $settings);
    push(@taxid, $taxid, @$taxidArr);
  }

  # Grab the common lineage for these taxids
  # right up to the root
  my %lineage;
  for my $taxid(@topLevelTaxon){
    die "TODO: ancestor stuff";
    my $ancestorArr = findAncestors($taxid, $dbh, $settings);
    $lineage{$taxid} = $ancestorArr;
  }
  
  $dbh->disconnect();
  return 0;
}

sub findAncestors{
  my($taxid, $dbh, $settings) = @_;
  ...;
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
  "
}
