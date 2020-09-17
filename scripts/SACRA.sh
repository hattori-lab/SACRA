#!/bin/bash

#################################
# Copyright (c) 2019 Yuya Kiguchi
Version="2.0"
#################################

function parse_yaml {
  local prefix=$2
  local s='[[:space:]]*' w='[a-zA-Z0–9_]*' fs=$(echo @|tr @ '\034')
  sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
  -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" $1 |
  awk -F$fs '{
    indent = length($1)/2;
    vname[indent] = $2;
    for (i in vname) {if (i > indent) {delete vname[i]}}
    if (length($3) > 0) {
      vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
      printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
    }
   }'
}

while getopts ":i:p:t:" o; do
    case "${o}" in
        i)
            i=${OPTARG}
            ;;
        p)
            p=${OPTARG}
            ;;
        t)
            t=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))


if [ -z "${i}" ] || [ -z "${p}" ] || [ -z "${t}" ]; then
    echo "Usage: $0 [-i <input fasta file>] [-p <prefix>] [-t <max no. of cpu cores>]" 1>&2;
    exit 1;
fi

eval $(parse_yaml config.yml)

echo -e "***** [$0, Version: $Version] start " `date +'%Y/%m/%d %H:%M:%S'` " *****\n"

########## STEP1 ##########
echo "STEP 1. alignment: All vs all pairwise alignment of long-read by LAST aligner"
makedb_cmd="lastdb8 -P $t -R $alignment_R -u $alignment_u $i $i"

echo $makedb_cmd
eval $makedb_cmd

alignment_cmd="lastal8 -a $alignment_a -A $alignment_A -b $alignment_b -B $alignment_B -S $alignment_S -P $t -f $alignment_f $i $i > $i.blasttab"
echo $alignment_cmd
eval $alignment_cmd
id=`grep -v "#" $i.blasttab  | shuf -n 1000 | awk '{m+=$3} END{print m/NR}'`
echo "Average read-vs-read identity (%): $id"
echo -e "DONE\n"
###########################

########## STEP2 ##########
echo -e "STEP 2. parsdepth: Detecting the partially aligned reads (PARs)"
parsdepth_cmd="perl SACRA_PARs_depth.pl -i $i.blasttab -al $parsdepth_al -tl $parsdepth_tl -pd $parsdepth_pd -id $parsdepth_id > $i.blasttab.depth"
echo $parsdepth_cmd
eval $parsdepth_cmd 
echo -e "DONE\n"
###########################

########## STEP3 ##########
echo -e "STEP 3. pcratio: Obtaining the PARs/CARs ratio (PC ratio) at the putative chimeric positions"
pcratio_cmd="perl SACRA_multi.pl $t $i.blasttab.depth"
echo $pcratio_cmd
eval $pcratio_cmd
for k in `ls $i.blasttab.depth.split*`
do
    echo "SACRA_PCratio.pl -i $i.blasttab -pa $k -ad $pcratio_ad -id $pcratio_id > $k.pcratio"
    perl SACRA_PCratio.pl -i $i.blasttab -pa $k -ad $pcratio_ad -id $pcratio_id > $k.pcratio & 
done
# wait for all backgroud jobs to finish
wait

cat="cat $i*.depth.split*.pcratio > $i.blasttab.depth.pcratio"
echo $cat
eval $cat
rm -rf $i*.depth.split*
echo -e "DONE\n"
###########################

########## STEP4 ##########
echo -e "STEP 4. cal mPC: Calculate mPC ratio based on spike-in reference genome"
if [ $mpc_sp = true ]; then
    echo "mPC ratio was calculated based on provided spike-in reference genome."
    echo "Spike-in reference genome: $mpc_rf"

    rfdb_cmd="lastdb8 -P $t -R $mpc_R -u $mpc_u $mpc_rf $mpc_rf"
    echo $rfdb_cmd
    eval $rfdb_cmd

    rfalign_cmd="lastal8 -a $mpc_a -A $mpc_A -b $mpc_b -B $mpc_B -S $mpc_S -P $t -f $mpc_f $mpc_rf $i > $i.spike-in.blasttab"
    echo $rfalign_cmd
    eval $rfalign_cmd
    grep -v "#" $i.spike-in.blasttab | awk -v "id=$mpc_id" '$3>=id' | awk -v "al=$mpc_al" '$4>=al' > $i.spike-in.blasttab.aligned
    awk '{print $1}' $i.spike-in.blasttab.aligned | sort | uniq > $i.spike-in.blasttab.aligned.id

    chimera_cmd="perl SACRA_detect_chimera.pl -i $i.spike-in.blasttab -id $mpc_id -al $mpc_al -lt $mpc_lt > $i.spike-in.blasttab.chimera"
    echo $chimera_cmd
    eval $chimera_cmd

    chimera_pos_cmd="perl SACRA_detect_chimeric_position.pl $i.spike-in.blasttab.chimera > $i.spike-in.blasttab.chimera.position"
    echo $chimera_pos_cmd
    eval $chimera_pos_cmd

    cal_mpc="perl SACRA_reference_PC.pl $i.spike-in.blasttab.aligned.id $i.blasttab.depth.pcratio $i.spike-in.blasttab.chimera.position"
    echo $cal_mpc
    eval $cal_mpc

    split_pc=`sort -k4,4nr $i.blasttab.depth.pcratio.mPC | awk '{print $1}' | sed 's/mPC=//g' | head -n 1`
    echo "Calculated mPC ratio: $split_pc"
    echo -e "DONE\n"
else
    echo "Spike-in reference genome is not provided."
    echo "mPC ratio in the config file was used."
    echo "Calculated mPC ratio: $split_pc"
    echo -e "DONE\n"
fi
###########################

########## STEP5 ##########
echo -e "STEP 5. split: Split chimeras at the chimeric positions"
split_cmd="perl SACRA_split.pl -i $i.blasttab.depth.pcratio -pc $split_pc -dp $split_dp -sl $split_sl > $i.blasttab.depth.pcratio.faidx"
echo $split_cmd
eval $split_cmd
perl SACRA_multi.pl $t $i.blasttab.depth.pcratio.faidx

for n in `ls $i.blasttab.depth.pcratio.faidx.split*`
do
    for j in `less $n`
    do
        echo "samtools faidx $i $j >> $n.fasta" >> $n.sh
    done
done

samtools faidx $i
chmod +x $i.blasttab.depth.pcratio.faidx.split*sh
for m in `ls $i.blasttab.depth.pcratio.faidx.split*sh`
do
    echo $m
    bash $m &
done
# wait for all backgroud jobs to finish
wait

cat="cat $i.blasttab.depth.pcratio.faidx.split*fasta > $i.split.fasta"
echo $cat
eval $cat
rm -rf $i.blasttab.depth.pcratio.faidx.split*
echo -e "DONE\n"
###########################

########## Output ##########
echo -e "Output final reads"
awk -F ":" '{print $1}' $i.blasttab.depth.pcratio.faidx | uniq > $i.blasttab.depth.pcratio.faidx.id
seqkit grep -v -f $i.blasttab.depth.pcratio.faidx.id $i > $i.non_chimera.fasta
cat $i.non_chimera.fasta $i.split.fasta > $p

echo "Split reads: $i.split.fasta"
echo "Non-chimeras: $i.non_chimera.fasta"
echo -e "Combined reads: $p\n"
###########################

echo "***** [$0, Version: $Version] end " `date +'%Y/%m/%d %H:%M:%S'` " *****"
