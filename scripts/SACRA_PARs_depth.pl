#!/usr/bin/perl

#################################
# Copyright (c) 2019 Yuya Kiguchi
#################################

use Getopt::Long;
use strict;

##### parameters #####
my $h;
my $input;
my $align_length = 100;
my $terminal_length = 50;
my $par_th = 5;
my $identity_th = 75;
######################

GetOptions('help' => \$h, 'i=s' => \$input, 'al=i' => \$align_length, 'tl=i' => \$terminal_length, 'pd=i' => \$par_th, 'id=i' => \$identity_th);
if($h || $input eq ""){
    print "Error SACRA_PARs_depth.pl: Unable to read the output file of alignment step.
# Arguments :
-i  : input blasttab file
-al : Minimum alignment length of query sequence (default: 100)
-tl : Minimum terminal length of unaligned region of PARs (default: 50)
-pd : Minimum depth of PARs (default: 5)
-id : Minimum identity of alignment (default: 75)\n";
    die "\n";
}

my $seq = "first";
my %hash_end;       # key: start/end position of PARs, value: depth
my $length;         # alignment length of query sequence
my $end;            # alignment end position of PARs
my $start;          # alignemnt start position of PARs

open (FILE, $input) or die("Error SACRA_PARs_depth.pl: Unable to read the output file of alignment step.\n");
while(<FILE>){
    chomp;
    my @array = split(/\t/, $_);
    my $identity = $array[2];
    if(/^#/ || $array[0] eq $array[1]){
        next;
    }
    elsif($array[7] - $array[6] < 0){
        $length = $array[6] - $array[7] + 1; # + 1bp since 1-based coordinates
        $start = $array[7];
        $end = $array[6];
    }
    elsif($array[7] - $array[6] > 0){
        $length = $array[7] - $array[6] + 1; # + 1bp since 1-based coordinates
        $start = $array[6];
        $end = $array[7];
    }
    if($seq eq "first"){
        if($identity >= $identity_th && $length >= $align_length && $array[12] - $terminal_length >= $end && $array[13] - $terminal_length >= $array[9]){
            $hash_end{$end} = 1;
        }
        if($identity >= $identity_th && $length >= $align_length && $start - $terminal_length >= 0 && $array[8] - $terminal_length >= 0){
            $hash_end{$start} = 1;
        }
        $seq = $array[0];
    }
    elsif(eof){
        if($seq eq $array[0]){
            if(exists($hash_end{$end}) && $identity >= $identity_th && $length >= $align_length){
                my $count_s = $hash_end{$end} + 1;
                $hash_end{$end} = $count_s;
            }
            if(exists($hash_end{$start}) && $identity >= $identity_th && $length >= $align_length){
                my $count_s = $hash_end{$start} + 1;
                $hash_end{$start} = $count_s;
            }
            for my $position (sort keys %hash_end){
                if($hash_end{$position} >= $par_th){
                    print "$seq\t$position\t$hash_end{$position}\n";
                }
            }
        }
        else{
            for my $position (sort keys %hash_end){
                if($hash_end{$position} >= $par_th){
                    print "$seq\t$position\t$hash_end{$position}\n";
                }
            }
        }
    }
    elsif($seq eq $array[0]){
        if(exists($hash_end{$end}) && $identity >= $identity_th && $length >= $align_length){
            my $count_s = $hash_end{$end} + 1;
            $hash_end{$end} = $count_s;
        }
        elsif($identity >= $identity_th && $length >= $align_length && $array[12] - $terminal_length >= $end && $array[13] - $terminal_length >= $array[9]){
            $hash_end{$end} = 1;
        }
        if(exists($hash_end{$start}) && $identity >= $identity_th && $length >= $align_length){
            my $count_s = $hash_end{$start} + 1;
            $hash_end{$start} = $count_s;
        }
        elsif($identity >= $identity_th && $length >= $align_length && $start - $terminal_length >= 0 && $array[8] - $terminal_length >= 0){
            $hash_end{$start} = 1;
        }
        $seq = $array[0];
    }
    elsif($seq ne $array[0]){
        for my $position (sort keys %hash_end){
            if($hash_end{$position} >= $par_th){
                print "$seq\t$position\t$hash_end{$position}\n";
            }
        }
        %hash_end = ();
        if($identity >= $identity_th && $length >= $align_length && $array[12] - $terminal_length >= $end && $array[13] - $terminal_length >= $array[9]){
            $hash_end{$end} = 1;
        }
        if($identity >= $identity_th && $length >= $align_length && $start - $terminal_length >= 0 && $array[8] - $terminal_length >= 0){
            $hash_end{$start} = 1;
        }
        $seq = $array[0];
    }
}
