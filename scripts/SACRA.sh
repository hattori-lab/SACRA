#!/bin/bash
#Date: 2019/09/03
#Developer: Yuya Kiguchi

fasta=$1        # fasta file
prefix=$2       # prefix
th=50		# No. of threads for LAST aligner

lastdb -P $th -R01 -uNEAR $fasta $fasta
lastal -a 8 -A 16 -b 12 -B 5 -S 1 -P $th -f BlastTab+ $fasta $fasta > $fasta.blasttab

perl SACRA_PARs_depth.pl -i $fasta.blasttab -al 100 -tl 50 -pd 5 -id 75 > $fasta.blasttab.depth
perl SACRA_PCratio.pl -i $fasta.blasttab -pa $fasta.blasttab.depth -ad 50 -id 75 > $fasta.blasttab.depth.pcratio
perl SACRA_split.pl -i $fasta.blasttab.depth.pcratio -pc 15 -dp 10 -sl 100 > $fasta.blasttab.depth.pcratio.faidx
awk -F ":" '{print $1}' $fasta.blasttab.depth.pcratio.faidx | uniq > $fasta.blasttab.depth.pcratio.faidx.id
seqkit grep -v -f $fasta.blasttab.depth.pcratio.faidx.id $fasta > $fasta.non_chimera.fasta

for i in `less $fasta.blasttab.depth.pcratio.faidx`
do
echo "samtools faidx $fasta $i >> $fasta.split.fasta" >> $fasta.faidx.sh
done

chmod +x $fasta.faidx.sh
bash $fasta.faidx.sh

cat $fasta.non_chimera.fasta $fasta.split.fasta > $prefix
