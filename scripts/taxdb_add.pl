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
  GetOptions($settings,qw(help)) or die $!;

  die usage() if(!@ARGV || $$settings{help});

  my ($dbpath,$dbdir)=@ARGV;

  #my $names = readDmpHashOfArr("$dbdir/names.dmp",$settings);
  my $names = readNamesDmp("$dbdir/names.dmp",$settings);
  logmsg "Done reading names.  Now reading nodes and inserting.";

  # TODO foreign keys
  my $dbh = DBI->connect("dbi:SQLite:dbname=$dbpath","","",
    { 
      AutoCommit=> 0,
    }
  );
  $dbh->do("PRAGMA foreign_keys = ON");

  # Don't save the nodes.dmp in memory but instead iterate
  # over each line.
  my $node_counter=0;
  my $manyQuestionmarkStr = '?,' x 13;
  $manyQuestionmarkStr=~s/,$//; # remove last comma
  open(my $nodesFh,"$dbdir/nodes.dmp") or die "ERROR: could not read nodes.dmp: $!";
  while(my $nodesArr=taxonomyIterator($nodesFh,$settings)){
    my $taxid = $$nodesArr[0];
    my $sth = $dbh->prepare(qq(
      INSERT INTO NODE(tax_id,parent_tax_id,rank,embl_code,division_id,inherited_div_flag,genetic_code_id,inherited_gc_flag,mitochondrial_genetic_code_id,inherited_mgc_flag,genbank_hidden_flag,hidden_subtree_root_flag,comments)
      VALUES($manyQuestionmarkStr)
    ));
    $sth->execute(@$nodesArr)
      or die "ERROR: with @$nodesArr ".$dbh->errstr();

    for my $namesEntry(@{ $$names{$taxid} }){
      my $sth2 = $dbh->prepare(qq(
        INSERT INTO NAME(tax_id,name_txt,unique_name,name_class)
        VALUES(?,?,?,?);
      ));
      $sth2->execute($taxid, @$namesEntry)
        or die "ERROR: ".$dbh->errstr();
    }

    $node_counter++;

    #last if($node_counter > 10);
    if($node_counter % 100000 == 0){
      logmsg "Added $node_counter";
      $dbh->commit();
    }
  }
  close $nodesFh;
  $dbh->commit();
  
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

# Modified from readDmpHashOfArr() b/c tax_id is not unique
# in names.dmp.
sub readNamesDmp{
  my($dmp, $settings) = @_;
  my %tax;
  open(my $dmpFh,$dmp) or die "ERROR reading $dmp: $!";
  while(my $F=taxonomyIterator($dmpFh,$settings)){
    # The entry's value will be an array with the ID
    # lopped off.
    my $taxid = shift(@$F);
    push(@{ $tax{$taxid} }, $F);
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
  while(my $F=taxonomyIterator($dmpFh,$settings)){
    # The entry's value will be an array with the ID
    # lopped off.
    my $taxid = shift(@$F);
    $tax{$taxid} = $F;
  }
  close $dmpFh;
  return \%tax;
}

sub taxonomyIterator{
  my($fh,$settings)=@_;
  if(eof($fh)){
    return undef;
  }

  my @taxArr;
  my $line=<$fh>;
  chomp($line);
  while($line=~/\t?([^\|]+)\t?\|?/g){
    my $field = $1;
    $field =~ s/^\t|\t$//g;
    push(@taxArr, $field);
  }
  return \@taxArr;
}

sub usage{
  "Add a taxonomy flat file to an existing taxdb database
  You can obtain the flat file db from ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz
  Usage: $0 file.sqlite3 taxonomydir/
  "
}
