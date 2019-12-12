# SACRA
Split Amplified Chimeric Read Algorithm

# Dependencies

last (version 963).
http://last.cbrc.jp/

seqkit (Version: 0.8.0).
https://bioinf.shenwei.me/seqkit/usage/

samtools (Version: 1.4).
http://www.htslib.org/

# Workflow of SACRA
SACRA operates in four phases: pairwise alignment, PARs detection, PC ratio calculation and split chimeras.  

## STEP 1. alignment
SACRA performs all vs all pairwise alignment of input long-read by LAST aligner. For obtaining better performance of SACRA, input long-read needs to be highly accurate by error-correction by some tools (e.g. MHAP of canu, HiFi reads of PacBio, etc.). In the original paper, error-corrected long reads had relatively high accuracy with 96% on average. This process takes a time, so we recommend using multithreads.  

## STEP 2. parsdepth
Detects the partially aligned reads (PARs) and putative chimeric positions from the alignment result of STEP 1, and obtains the depth of PARs at that positions.

## STEP 3. pcratio
Calculates the depth of continuously aligned reads (CARs) and the PARs/CARs ratio (PC ratio) at the candidate chimeric positions.

## STEP 4. split
Split the chimeras at the putative chimeric positions detected by STEP 3.

# Usage
```
./SACRA.sh [-i <input fasta file>] [-p <prefix>] [-t <max no. of cpu cores>]
```

# Config file

# Output
`pcratio`: The results of calculation of PARs, CARs and PC ratio. The output is tab deliminated file containing six columns. 1. sequence id, 2. read length, 3. putative chimeric position, 4. depth of PARs, 5. depth of CARs, 6. PC ratio (%).  
`non_chimera.fasta`: Non-chimeras sequences.  
`split.fasta`: Split sequences.  
`output.fasta`: Final sequences combining non-chimeras and split sequences.  

# Citation
XXXXXXXXXXXXXXXXX  

# Docker Image
