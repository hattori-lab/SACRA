#!/usr/bin/perl

# Description
#                       0                 1020
# alignment 1: upstream |------------------| downstream
#                                      1000             2020
# alignment 2:                 upstream |----------------| downstream
#                                                  1980             3000
# alignment 3:                             upstream |----------------| downstream

use strict;

my $terminal_thresh = 50;   # Length threshold of alignment stop position from the terminus of query sequence.
                            # The alignment stop position greater than this value from the terminus is determined to be the chimera position.
my %hash;                   # key: alignment start position, value: alignment end position.
my $id = "dummy";
my $q_length;
while(<>){
    chomp;
    my @array = split(/\t/, $_);
    my $q_start = $array[6];
    my $q_end = $array[7];
    if($id eq "dummy"){
        $id = $array[0];
        $q_length = $array[12];
        if($q_start > $q_end){          # alignment of minus strand (The alignment start and end positions are output in reverse.)
            my $q_start_id = "$q_end:q_start";
            my $q_end_id = "$q_start:q_end";
            $hash{$q_start_id} = $q_end_id;
        }
        else{                           # alignment of plus strand
            my $q_start_id = "$q_start:q_start";
            my $q_end_id = "$q_end:q_end";
            $hash{$q_start_id} = $q_end_id;
        }
        $id = $array[0];
    }
    elsif(eof){
        if($id eq $array[0]){
            if($q_start > $q_end){          # alignment of minus strand
                my $q_start_id = "$q_end:q_start";
                my $q_end_id = "$q_start:q_end";
                $hash{$q_start_id} = $q_end_id;
            }
            else{                           # alignment of plus strand
                my $q_start_id = "$q_start:q_start";
                my $q_end_id = "$q_end:q_end";
                $hash{$q_start_id} = $q_end_id;
            }
            for my $key (sort {$a <=> $b} keys %hash) {
                my $q_start_value = $key;
                $q_start_value =~ s/:q_start//;
                if($q_start_value >= $terminal_thresh){
                    print "$id\t$q_start_value\tdownstream\n";
                }
                my $q_end_value = $hash{$key};
                $q_end_value =~ s/:q_end//;
                my $end_thresh = $q_length - $terminal_thresh;
                if($q_end_value <= $end_thresh){
                    print "$id\t$q_end_value\tupstream\n";
                }
            }
        }
        else{
            for my $key (sort {$a <=> $b} keys %hash) {
                my $q_start_value = $key;
                $q_start_value =~ s/:q_start//;
                if($q_start_value >= $terminal_thresh){
                    print "$id\t$q_start_value\tdownstream\n";
                }
                my $q_end_value = $hash{$key};
                $q_end_value =~ s/:q_end//;
                my $end_thresh = $q_length - $terminal_thresh;
                if($q_end_value <= $end_thresh){
                    print "$id\t$q_end_value\tupstream\n";
                }
            }
            $id = $array[0];
            $q_length = $array[12];
            my $q_start_value;
            my $q_end_value;
            if($q_start > $q_end){
                $q_start_value = $q_end;
                $q_end_value = $q_start;
            }
            else{
                $q_start_value = $q_start;
                $q_end_value = $q_end;
            }
            if($q_start_value >= $terminal_thresh){
                print "$id\t$q_start_value\tdownstream\n";
            }
            my $end_thresh = $q_length - $terminal_thresh;
            if($q_end_value <= $end_thresh){
                print "$id\t$q_end_value\tupstream\n";
            }
        }
    }
    elsif($id eq $array[0]){
        if($q_start > $q_end){          # alignment of minus strand
            my $q_start_id = "$q_end:q_start";
            my $q_end_id = "$q_start:q_end";
            $hash{$q_start_id} = $q_end_id;
        }
        else{                           # alignment of plus strand
            my $q_start_id = "$q_start:q_start";
            my $q_end_id = "$q_end:q_end";
            $hash{$q_start_id} = $q_end_id;
        }
    }
    elsif($id ne $array[0]){
        for my $key (sort {$a <=> $b} keys %hash) {
            my $q_start_value = $key;
            $q_start_value =~ s/:q_start//;
            if($q_start_value >= $terminal_thresh){
                print "$id\t$q_start_value\tdownstream\n";
            }
            my $q_end_value = $hash{$key};
            $q_end_value =~ s/:q_end//;
            my $end_thresh = $q_length - $terminal_thresh;
            if($q_end_value <= $end_thresh){
                print "$id\t$q_end_value\tupstream\n";
            }
        }
        $id = $array[0];
        $q_length = $array[12];
        %hash = ();
        if($q_start > $q_end){          # alignment of minus strand
            my $q_start_id = "$q_end:q_start";
            my $q_end_id = "$q_start:q_end";
            $hash{$q_start_id} = $q_end_id;
        }
        else{                           # alignment of plus strand
            my $q_start_id = "$q_start:q_start";
            my $q_end_id = "$q_end:q_end";
            $hash{$q_start_id} = $q_end_id;
        }
    }
}
