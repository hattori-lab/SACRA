#!/usr/bin/perl

use Getopt::Long;
use strict;

##### parameters #####
my $h;
my $input;
my $align_length = 50;
my $identity = 95;
my $align_length_th = 50;
######################

GetOptions('help' => \$h, 'i=s' => \$input, 'al=i' => \$align_length, 'id=i' => \$identity, 'lt=i' => \$align_length_th);
if($h || $input eq ""){
    print "Error SACRA_detect_chimera.pl: Error in detecting the chimeric reads for obtaining mPC ratio.
# Arguments :
-i  : input blasttab file
-al : Minimum alignment length of query sequence (default: 50)
-id : Minimum identity of alignment (default: 95)
-lt : Threshold of the unaligned length for detecting chimeric alignments. (default: 50)
      e.g. If it is set to 50, an alignment with ≥50bp unaligned length is determined as chimeric alignment.\n";
    die "\n";
}

open (FILE, $input) or die("Error SACRA_detect_chimera.pl: Error in detecting the chimeric reads for obtaining mPC ratio.\n");
while(<FILE>){
    chomp;
    my @array = split(/\t/, $_);
    if(/^#/){
        next;
    }
    elsif($array[3]>=$align_length && $array[2] >= $identity && ($array[12] - abs($array[6] - $array[7])) >= $align_length_th){
        print "$_\n";
    }
}
