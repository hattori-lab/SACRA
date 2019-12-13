#!/usr/bin/perl

#################################
# Copyright (c) 2019 Yuya Kiguchi
#################################

use Getopt::Long;
use strict;

##### parameters #####
my $h;
my $par;
my $blasttab;
my $across_length = 50;
my $identity_th = 75;
######################

GetOptions('help' => \$h, 'pa=s' => \$par, 'i=s' => \$blasttab, 'ad=i' => \$across_length, 'id=i' => \$identity_th);
if($h || $par eq "" || $blasttab eq ""){
    print "Error SACRA_PCratio.pl: Unable to read the output file of SACRA_multi.pl or alignment step.
# Arguments :
-i  : input blasttab file
-pa : input depth of PARs
-ad : Alignment start or end position that must be minimally distant from the putative chimeric position (default: 50)
-id : Minimum identity of alignment (default: 75)\n";
    die "\n";
}

# Input depth of PARs
open (FILE, $par) or die("Error SACRA_PCratio.pl: Unable to read the output file of SACRA_multi.pl at pcratio step.\n");
my %hash_dep;
while(<FILE>){
    chomp;
    my @array = split(/\t/, $_);
    my $id = $array[0]."_".$array[1];
    $hash_dep{$id} = $array[2];                 # keys: seqid_position, value: end depth
}

my $seq = "first";
my $len;            # query length
my $start;          # alignemnt start position of CARs
my $end;            # alignment end position of CARs
my %hash;           # keys: position, value: depth of CRAs

open (FILE2, $blasttab) or die("Error SACRA_PCratio.pl: Unable to read the output file of alignment step.\n");
while(<FILE2>){
    chomp;
    my @array = split(/\t/, $_);
    my $identity = $array[2];
    if(/^#/ || $array[0] eq $array[1]){
        next;
    }
    elsif($array[7] - $array[6] < 0){
        $start = $array[7];
        $end = $array[6];
    }
    elsif($array[7] - $array[6] > 0){
        $start = $array[6];
        $end = $array[7];
    }    
    if($seq eq "first"){
        $seq = $array[0];
        $len = $array[12];
        for (my $i=1; $i<=$len; $i++){
            my $id = $seq."_".$i;
            if(exists($hash_dep{$id})){
                $hash{$i} = 0;
            }
        }
        foreach my $keys (keys %hash){
            if($identity >= $identity_th && $keys >= $start + $across_length && $keys + $across_length <= $end){    # Add depth of CARs if all threshold are satisfied.
                my $count = $hash{$keys} + 1;
                $hash{$keys} = $count;
            }
        }
    }
    elsif(eof){
        foreach my $keys (keys %hash){
            if($identity >= $identity_th && $keys >= $start + $across_length && $keys + $across_length <= $end){
                my $count = $hash{$keys} + 1;
                $hash{$keys} = $count;
            }
        }
        for my $keys (sort {$a <=> $b} keys %hash){
            if($hash{$keys} != 0){
                my $id = $seq."_".$keys;
                my $prop = 100*$hash_dep{$id}/($hash_dep{$id} + $hash{$keys});
                print "$seq\t$len\t$keys\t$hash_dep{$id}\t$hash{$keys}\t$prop\n";
            }
            else{
                my $id = $seq."_".$keys;
                my $prop = 100;
                print "$seq\t$len\t$keys\t$hash_dep{$id}\t$hash{$keys}\t$prop\n";
            }
        }        
    }
    elsif($seq ne $array[0]){
        for my $keys (sort {$a <=> $b} keys %hash){
            if($hash{$keys} != 0){                                              # Clculate PC ratio if there is CARs.
                my $id = $seq."_".$keys;
                my $prop = 100*$hash_dep{$id}/($hash_dep{$id} + $hash{$keys});
                print "$seq\t$len\t$keys\t$hash_dep{$id}\t$hash{$keys}\t$prop\n";
            }
            else{                                                               # Print 100% of PC ratio if there is not CARs.
                my $id = $seq."_".$keys;
                my $prop = 100;
                print "$seq\t$len\t$keys\t$hash_dep{$id}\t$hash{$keys}\t$prop\n";
            }
        }
        %hash = ();
        $seq = $array[0];
        $len = $array[12];
        for (my $i=1; $i<$len + 1; $i++){
            my $id = $seq."_".$i;
            if(exists($hash_dep{$id})){
                $hash{$i} = 0;
            }
        }
        foreach my $keys (keys %hash){
            if($identity >= $identity_th && $keys >= $start + $across_length && $keys + $across_length <= $end){
                my $count = $hash{$keys} + 1;
                $hash{$keys} = $count;
            }
        }
    }
    else{
        foreach my $keys (keys %hash){
            if($identity >= $identity_th && $keys >= $start + $across_length && $keys + $across_length <= $end){
                my $count = $hash{$keys} + 1;
                $hash{$keys} = $count;
            }
        }
    }
}
