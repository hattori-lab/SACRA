#!/bin/bash

#################################
# Copyright (c) 2019 Yuya Kiguchi
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

echo -e "***** [$0] start " `date +'%Y/%m/%d %H:%M:%S'` " *****\n"

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

echo -e "STEP 2. parsdepth: Detecting the partially aligned reads (PARs)"
parsdepth_cmd="SACRA_PARs_depth.pl -i $i.blasttab -al $parsdepth_al -tl $parsdepth_tl -pd $parsdepth_pd -id $parsdepth_id > $i.blasttab.depth"
echo $parsdepth_cmd
eval $parsdepth_cmd 
echo -e "DONE\n"

echo -e "STEP 3. pcratio: Obtaining the PARs/CARs ratio (PC ratio) at the putative chimeric positions"
pcratio_cmd="SACRA_multi.pl $t $i.blasttab.depth"
echo $pcratio_cmd
eval $pcratio_cmd
for k in `ls $i.blasttab.depth.split*`
do
    SACRA_PCratio.pl -i $i.blasttab -pa $k -ad $pcratio_ad -id $pcratio_id > $k.pcratio & 
done

# wait for all backgroud jobs to finish
wait

cat $i*.depth.split*.pcratio > $i.blasttab.depth.pcratio
rm -rf $i*.depth.split*
echo -e "DONE\n"

echo -e "STEP 4. split: Split chimeras at the chimeric positions"
split_cmd="SACRA_split.pl -i $i.blasttab.depth.pcratio -pc $split_pc -dp $split_dp -sl $split_sl > $i.blasttab.depth.pcratio.faidx"
echo $split_cmd
eval $split_cmd
SACRA_multi.pl $t $i.blasttab.depth.pcratio.faidx

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
    bash $m &
done
# wait for all backgroud jobs to finish
wait

cat $i.blasttab.depth.pcratio.faidx.split*fasta > $i.split.fasta
rm -rf $i.blasttab.depth.pcratio.faidx.split*
echo -e "DONE\n"

# Output reads
echo -e "Output final reads"
awk -F ":" '{print $1}' $i.blasttab.depth.pcratio.faidx | uniq > $i.blasttab.depth.pcratio.faidx.id
seqkit grep -v -f $i.blasttab.depth.pcratio.faidx.id $i > $i.non_chimera.fasta
cat $i.non_chimera.fasta $i.split.fasta > $p

echo "Split reads: $i.split.fasta"
echo "Non-chimeras: $i.non_chimera.fasta"
echo -e "Combined reads: $p\n"

echo "***** [$0] end " `date +'%Y/%m/%d %H:%M:%S'` " *****"
