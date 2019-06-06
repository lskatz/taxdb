#!/usr/bin/env perl

use strict;
use warnings;
use BerkeleyDB;
use Getopt::Long qw/GetOptions/;
use Data::Dumper;

sub logmsg{print STDERR "$0: @_\n";}

exit(main());

sub main{
  my $settings={};
  GetOptions($settings,qw(help dbpath=s)) or die $!;
  $$settings{dbpath}||="taxonomy.db3";

  die usage() if(!@ARGV || $$settings{help});

  my $dbdir=$ARGV[0];


  my @nodesKeys=qw(tax_id parent_tax_id rank embl_code division_id inherited_div_flag genetic_code_id inherited_gc_flag mitochondrial_genetic_code_id inherited_mgc_flag genbank_hidden_flag hidden_subtree_root_flag comments);
  my @namesKeys=qw(tax_id name_txt unique_name name_class);

  # The subroutines strip away the tax_id
  shift(@nodesKeys);
  shift(@namesKeys);

  my $names = readDmpHashOfArr("$dbdir/names.dmp",$settings);

  my %nodesDb;
  tie %nodesDb, "BerkeleyDB::Hash",
      -Filename => $$settings{dbpath},
      -Flags    => DB_TRUNCATE | DB_CREATE | DB_TXN_NOSYNC
      or die "Cannot open file $$settings{dbpath}: $! $BerkeleyDB::Error\n" ;
  
  # Don't save the nodes.dmp in memory but instead iterate
  # over each line.
  open(my $nodesFh,"$dbdir/nodes.dmp") or die "ERROR: could not read nodes.dmp: $!";
  while(my $nodesArr=taxonomyIterator($nodesFh,$settings)){
    my $taxid=shift(@$nodesArr);
    if(!defined($$names{$taxid})){
      logmsg "Warning: tax_id $taxid not defined in names.dmp";
      $$names{$taxid}=[];
    }
    my $line=join("\t",@$nodesArr,@{$$names{$taxid}});
    $nodesDb{$taxid}=$line;
  }
  close $nodesFh;
  untie %nodesDb; # deletes the hash in memory but flushes db
  
  return 0; # exit status 0
}
# Read a dmp file into a hash whose values are an array
# of each element in the dmp, except the first which is
# used as the hash key.
sub readDmpHashOfHash{
  my($dmp,$keys,$settings)=@_;
  my %tax;
  my @keys=@$keys; # copy into local space in case it helps speed up
  open(my $dmpFh,$dmp) or die "ERROR reading $dmp: $!";
  while(<$dmpFh>){
    s/(\s*\|\s*)+$//g; # right trim
    my %F;
    @F{@keys} = split /\t\|\t/;
    my $id=$F{tax_id};
    delete($F{tax_id}); # reduce memory footprint

    # The entry's value will be an array with the ID
    # lopped off.
    $tax{$id}=\%F;
  }
  close $dmpFh;
  return \%tax;
}

# Read a dmp file into a hash whose values are an array
# of each element in the dmp, except the first which is
# used as the hash key.
sub readDmpHashOfArr{
  my($dmp,$settings)=@_;
  my %tax;
  open(my $dmpFh,$dmp) or die "ERROR reading $dmp: $!";
  while(<$dmpFh>){
    s/(\s*\|\s*)+$//g; # right trim
    my @F = split /\t\|\t/;

    # The entry's value will be an array with the ID
    # lopped off.
    $tax{$F[0]} = [@F[1..$#F]];
  }
  close $dmpFh;
  return \%tax;
}

sub taxonomyIterator{
  my($fh,$settings)=@_;
  if(eof($fh)){
    return undef;
  }

  my $line=<$fh>;
  $line=~s/(\s*\|\s*)+$//g; # right trim
  return [split /\t\|\t/,$line];
}

sub readTaxonomyDb{
  my($db,$settings)=@_;

  my %nodes;

  tie %nodes, "BerkeleyDB::Hash",
      -Filename => $db,
      -Flags    => DB_RDONLY
      or die "Cannot open file $db: $! $BerkeleyDB::Error\n" ;

  return \%nodes;
}

sub usage{
  "This script is a proof of concept for creating a BerkeleyDb out of a taxonomy database
  You can obtain the db from ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz
  Usage: $0 taxonomydir/
  --dbpath   taxonomy.db3  The path to the database
  "
}
