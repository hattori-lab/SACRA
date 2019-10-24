#!/bin/bash
#Date: 2019/09/03
#Developer: Yuya Kiguchi

fasta=$1        # fasta file
prefix=$2       # prefix
th=50		    # No. of threads for LAST and multithreads

echo -e "***** [$0] start " `date +'%Y/%m/%d %H:%M:%S'` " *****\n"

# Perform LAST alignment
echo -e "lastdb -P $th -R01 -uNEAR $fasta $fasta"
lastdb -P $th -R01 -uNEAR $fasta $fasta
echo -e "lastal -a 8 -A 16 -b 12 -B 5 -S 1 -P $th -f BlastTab+ $fasta $fasta > $fasta.blasttab"
lastal -a 8 -A 16 -b 12 -B 5 -S 1 -P $th -f BlastTab+ $fasta $fasta > $fasta.blasttab
echo -e "DONE"

# PARs
echo -e "PARs detection"
perl SACRA_PARs_depth.pl -i $fasta.blasttab -al 100 -tl 50 -pd 5 -id 75 > $fasta.blasttab.depth
echo -e "DONE"

# PC ratio
echo -e "PC ratio calculation"
perl SACRA_multi.pl $th $fasta.blasttab.depth
for i in `ls  *.depth.split*`;do perl SACRA_PCratio.pl -i $fasta.blasttab -pa $i -ad 50 -id 75 > $i.pcratio & done
wait
cat $fasta*.depth.split*.pcratio > $fasta.blasttab.depth.pcratio
rm -rf $fasta*.depth.split*
echo -e "DONE"

# Split reads
echo -e "Split reads"
perl SACRA_split.pl -i $fasta.blasttab.depth.pcratio -pc 15 -dp 10 -sl 100 > $fasta.blasttab.depth.pcratio.faidx
perl SACRA_multi.pl $th $fasta.blasttab.depth.pcratio.faidx

for i in `ls $fasta.blasttab.depth.pcratio.faidx.split*`
do
    for j in `less $i`
    do
        echo "samtools faidx $fasta $j >> $i.fasta" >> $i.sh
    done
done

samtools faidx $fasta
chmod +x $fasta.blasttab.depth.pcratio.faidx.split*sh
for i in `ls $fasta.blasttab.depth.pcratio.faidx.split*sh`
do
    bash $i &
done
wait
cat $fasta.blasttab.depth.pcratio.faidx.split*fasta > $fasta.split.fasta
rm -rf $fasta.blasttab.depth.pcratio.faidx.split*
echo -e "DONE"

# Output reads
echo -e "Output final reads"
awk -F ":" '{print $1}' $fasta.blasttab.depth.pcratio.faidx | uniq > $fasta.blasttab.depth.pcratio.faidx.id
seqkit grep -v -f $fasta.blasttab.depth.pcratio.faidx.id $fasta > $fasta.non_chimera.fasta

cat $fasta.non_chimera.fasta $fasta.split.fasta > $prefix

echo "***** [$0] end " `date +'%Y/%m/%d %H:%M:%S'` " *****"