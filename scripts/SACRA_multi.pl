#!/usr/bin/perl

#################################
# Copyright (c) 2019 Yuya Kiguchi
#################################

use strict;
use POSIX;

my $no_files = $ARGV[0];
my $file = $ARGV[1];

open (FILE, $file) || die("Error SACRA_multi.pl: Unable to read the output file of pardepth step.\n");
my @buffers = <FILE>; 
my $lines = @buffers;
my $split_file = $lines/$no_files;
my $ceil = ceil ($split_file);

my $seq;
my @push;
my $count = 0;
my $split = 1;
open (FILE, $file) || die("Error SACRA_multi.pl: Unable to read the output file of pardepth step.\n");
while(<FILE>){
    chomp;
    my @array = split(/\t/, $_);
    if($count == 0){
        $seq = $array[0];
        $count++;
        push (@push, $_);
    }
    elsif(eof){
        push (@push, $_);
        my $file_name = "$file.split$split";
        open (DATAFILE, ">", "$file_name") or die("Error:Cant split the file");
        foreach my $out (@push){
            print DATAFILE "$out\n";
        }
        close (DATAFILE);
    }
    elsif($seq ne $array[0] && $count >= $ceil){
        my $file_name = "$file.split$split";
        open (DATAFILE, ">", "$file_name") or die("Error:Cant split the file");
        foreach my $out (@push){
            print DATAFILE "$out\n";
        }
        close (DATAFILE);
        $seq = $array[0];
        $count = 1;
        $split++;
        @push = ();
        push (@push, $_);
    }
    else{
        $seq = $array[0];
        $count++;
        push (@push, $_);
    }
}
