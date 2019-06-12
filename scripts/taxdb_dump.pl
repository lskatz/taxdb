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
  GetOptions($settings,qw(help force outdir|outpath=s format=s)) or die $!;
  $$settings{format}||="NCBI";
  $$settings{outdir}||=die "ERROR: need --outdir\n".usage();

  die usage() if(!@ARGV || $$settings{help});

  my $dbpath=$ARGV[0];

  my $dbh = DBI->connect("dbi:SQLite:dbname=$dbpath","","");
  $dbh->do("PRAGMA foreign_keys = ON");

  if($$settings{format} eq 'NCBI'){
    dumpNCBI($dbh, $$settings{outdir}, $settings);
  }

  return 0;
}

sub dumpNCBI{
  my($dbh, $outdir, $settings) = @_;

  if(!-d $outdir){
    mkdir $outdir or die "ERROR: could not mkdir $outdir: $!";
  } else {
    if(!$$settings{force}){
      die "ERROR: $outdir already exists. Overwrite with --force";
    }
  }

  my $sth = $dbh->prepare(qq(
    SELECT tax_id,parent_tax_id,rank,embl_code,division_id,inherited_div_flag,genetic_code_id,inherited_gc_flag,mitochondrial_genetic_code_id,inherited_mgc_flag,genbank_hidden_flag,hidden_subtree_root_flag,comments
    FROM NODE
  ));

  $sth->execute()
    or die "ERROR: could not dump NODE table: ".$dbh->errstr();

  open(my $nodesFh, ">", "$outdir/nodes.dmp") or die "ERROR: could not write to $outdir/nodes.dmp: $!";
  while(my @row = $sth->fetchrow_array()){
    print $nodesFh join("\t|\t", @row)."\n";
  }
  close $nodesFh;

  my $sth2 = $dbh->prepare(qq(
    SELECT tax_id,name_txt,unique_name,name_class
    FROM NAME
  ));

  $sth2->execute()
    or die "ERROR: could not dump NAME table: ".$dbh->errstr();

  open(my $namesFh, ">", "$outdir/names.dmp") or die "ERROR: could not write to $outdir/names.dmp: $!";
  while(my @row = $sth2->fetchrow_array()){
    print $namesFh join("\t|\t", @row)."\n";
  }
  close $namesFh;

  return 0; # exit status 0
}

sub usage{
  "Dump a taxdb to flatfiles
  Usage: $0 [options] file.sqlite
  --outdir    output directory
  "
}

