#!/usr/bin/env perl

use strict;
use warnings;
use DBI;
use Getopt::Long qw/GetOptions/;
use Data::Dumper;
use List::Util qw/uniq/;

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

  deleteTaxa(\@topLevelTaxon, $dbh, $settings);

  $dbh->disconnect;

  return 0;
}

sub deleteTaxa{
  my($taxa, $dbh, $settings) = @_;

  my $manyQuestionMarks = '?,' x scalar(@$taxa);
  $manyQuestionMarks =~ s/,$//;

  my $sth = $dbh->prepare(qq(
    DELETE
    FROM NODE
    WHERE tax_id IN ($manyQuestionMarks)
  )) 
    or die "ERROR: with preparing DELETE from NODE with @$taxa: ".$dbh->errstr();

  my $res = $sth->execute(@$taxa)
    or die "ERROR: with deleting from NODE with @$taxa: ".$dbh->errstr();

  my $sth2 = $dbh->prepare(qq(
    DELETE
    FROM NAME
    WHERE tax_id IN ($manyQuestionMarks)
  )) 
    or die "ERROR: with preparing DELETE from NAME with @$taxa: ".$dbh->errstr();

  my $res2 = $sth2->execute(@$taxa)
    or die "ERROR: with deleting from NODE with @$taxa: ".$dbh->errstr();

  $dbh->commit();

  return $res;
}

sub usage{
  "Delete a taxon from the database. Edits in-place.
  Usage: $0 [options] file.sqlite3
  --taxon     Taxon IDs.  Can specify multiple --taxon or
              comma-separate them, e.g., --taxon 1,2,3
  "
}

