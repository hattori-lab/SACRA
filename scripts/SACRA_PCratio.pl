#!usr/bin/perl
#Developer: Yuya Kiguchi
#Description: calculate PC ratio

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
    print "Script to calculate depth of PARs
# Arguments :
-i  : input blasttab file
-pa : input depth of PARs
-ad : Alignment start or end position that must be minimally distant from the candidate chimeric position (default: 50)
-id : Minimum identity of alignment (default: 75)\n";
    die "\n";
}

# Input depth of PARs
open (FILE, $par) or die;
my %hash_dep;
while(<FILE>){
    chomp;
    my @array = split(/\t/, $_);
    my $id = $array[0]."_".$array[1];
    $hash_dep{$id} = $array[2];                 # keys: seqid_position, value: end depth
}

my $seq = "first";
my $len;
my $start;          # alignemnt start position of CARs
my $end;            # alignment end position of CARs
my %hash;
open (FILE2, $blasttab) or die;
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
            if(exists($hash_dep{$id})){         # candidate chimeric positionのhashのみ作成
                $hash{$i} = 0;                  # keys: position, value: coverage
            }
        }
        foreach my $keys (keys %hash){
            if($identity >= $identity_th && $keys >= $start + $across_length && $keys + $across_length <= $end){      # alignmentの開始位置と終了位置の間に含まれるpositionのcoverageを加算
                                                                                                        # また、chimeric candidate positionをまたぐalignmentのalignment start位置をcandidate positionより$across_length以上前からに設定するために$start + $across_length
                                                                                                        # さらに、chimeric candidate positionをまたぐalignmentのalignment end位置をcandidate positionより$across_length以上後ろに設定する$keys + $across_length
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
            if($hash{$keys} != 0){                                              # hashのvalue (non chimeric align coverage)が0でない場合=chimeric candidate postitionをまたぐ配列が存在する場合
                my $id = $seq."_".$keys;
                my $prop = 100*$hash_dep{$id}/($hash_dep{$id} + $hash{$keys});  # $prop = 100*chimeric align end coverage/(chimeric align end coverage + non-chimeric align coverage). chimeric candidate positionにおけるchimeric align end coverageが全体のcoverageに占める割合。
                print "$seq\t$len\t$keys\t$hash_dep{$id}\t$hash{$keys}\t$prop\n";
            }
            else{                                                               # hashのvalue (non chimeric align coverage)が0の場合=chimeric candidate postitionをまたぐ配列が存在しない場合
                my $id = $seq."_".$keys;
                my $prop = 100;                                                 # またぐreadが無い場合はchimeric align end coverage 100%となる
                print "$seq\t$len\t$keys\t$hash_dep{$id}\t$hash{$keys}\t$prop\n";
            }
        }
        %hash = ();
        $seq = $array[0];
        $len = $array[12];
        for (my $i=1; $i<$len + 1; $i++){
            my $id = $seq."_".$i;
            if(exists($hash_dep{$id})){         # chimeric candidate positionのhashのみ作成
                $hash{$i} = 0;                  # keys: position, value: coverage
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
