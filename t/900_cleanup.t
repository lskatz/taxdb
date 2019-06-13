#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 1;
use Data::Dumper;
use File::Path qw/remove_tree/;

remove_tree('data.tmp', {result=>\my $rm_result, error=>\my $rm_error});

is scalar(@$rm_error), 0, "Cleanup using remove_tree";

if($rm_error && @$rm_error){
  for my $diag(@$rm_error){
    my($file, $message) = %$diag;
    if($file eq ''){
      diag "General error: $message";
    } else {
      diag "Problem unlinking $file: $message";
    }
  }
}

