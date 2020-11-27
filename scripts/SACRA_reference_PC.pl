#!/usr/bin/perl
# Developer: Yuya Kiguchi
# Description: calculate PC ratio of chimeric position

my $id = $ARGV[0];      # Reference-aligned sequence ID
my $ratio = $ARGV[1];   # Calculated PC ratio
my $chimera = $ARGV[2]; # List of detected chimeric position
my $threshold = 25;     # The range (+/-) from the chimeric position to get the PC ratio of the chimeric junction.

# Input the reference-aligned sequence ID
open (FILE, $id) or die "Can't open file: $id";
my %hash;
while(<FILE>){
	chomp;
	$hash{$_} = $_;
}

# Input the PC ratio of reference-aligned sequence
open (FILE2, $ratio) or die "Can't open file: $ratio";
my @array_ref;
while(<FILE2>){
	my @array = split(/\t/, $_);
	if(exists($hash{$array[0]})){
		push (@array_ref, $_);
	}
	else{
		next;
	}
}

# Obtaining the PC rario of chimeric and non-chimeric positions from reference-aligned sequence
open (FILE3, $chimera) or die "Can't open file: $chimera";
my %hash_chi;    # key: seqID_chimeric-position, value: chimeric position
while(<FILE3>){
	chomp;
	my @array = split(/\t/, $_);
    if($array[2] eq "upstream"){                            # chimeric position of upstream segment
        for (my $i = $array[1] - $threshold; $i<=$array[1]; $i++){
            my $id_posi = $array[0]."_".$i;
            $hash_chi{$id_posi} = $i;
        }
    }
    if($array[2] eq "downstream"){                          # chimeric position of downstream segment
        for (my $i = $array[1]; $i<=$array[1] + $threshold; $i++){
            my $id_posi = $array[0]."_".$i;
            $hash_chi{$id_posi} = $i;
        }
    }
}
my @array_chi;
my @array_non_chi;
foreach my $out (@array_ref){
    my @array = split(/\t/, $out);
    my $id = $array[0]."_".$array[2];
    if(exists $hash_chi{$id}){
        push (@array_chi, $out);
    }
    else{
        push (@array_non_chi, $out);
    }
}

# Calculate the optimized minimum PC (mPC) ratio
my $all_TP = @array_chi;        # Number of all true positives
my $all_TN = @array_non_chi;    # Number of all true negatives
my $TP;                         # Number of true positives
my $TN;                         # Number of true negatives
my @array_mPC;                  # mPC ratio
for (my $i = 1; $i<=99; $i++){
    foreach my $out (@array_chi){
        my @array = split(/\t/, $out);
        if($array[5] >= $i){
            $TP++;
        }
    }
    foreach my $out (@array_non_chi){
        my @array = split(/\t/, $out);
        if($array[5] <= $i){
            $TN++;
        }
    }
    my $sensitivity = 100*$TP/$all_TP;
    my $specificity = 100*$TN/$all_TN;
    my $average = ($sensitivity + $specificity)/2;
    push (@array_mPC, "mPC=$i\t$sensitivity\t$specificity\t$average");
    $TP = 0;
    $TN = 0;
}

# Output the results
open (my $info, "> $ratio.chimera") or die "Can't open file: $ratio.chimera";
foreach my $out (@array_chi){
            print $info "$out";
}
close($info);

open (my $info, "> $ratio.non-chimera") or die "Can't open file: $ratio.non-chimera";
foreach my $out (@array_non_chi){
            print $info "$out";
}
close($info);

open (my $info, "> $ratio.mPC") or die "Can't open file: $ratio.mPC";
print $info "mPC ratio\tsensitivity\tspecificity\taverage\n";
foreach my $out (@array_mPC){
            print $info "$out\n";
}
close($info);
