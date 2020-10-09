# SACRA
Split Amplified Chimeric Read Algorithm  
SACRA splits the chimeric reads to the non-chimeric reads in PacBio long reads of MDA-treated virome sample.

# Dependencies

last (version 963).
http://last.cbrc.jp/

seqkit (Version: 0.8.0).
https://bioinf.shenwei.me/seqkit/usage/

samtools (Version: 1.4).
http://www.htslib.org/

# Workflow of SACRA
SACRA operates in four phases: 1. alignment, 2. pars depth, 3. cal pc ratio, 4. cal mPC ratio, and 5. split.  

## STEP 1. Alignment
SACRA performs all vs all pairwise alignment of input long-read by LAST aligner for constructing aligned read clusters (ARCs).
For obtaining better performance of SACRA, input long-read needs to be highly accurate by error-correction by some tools (e.g. MHAP of canu, HiFi reads of PacBio, etc.). In the original paper, error-corrected long reads had relatively high accuracy with 97% on average. This process takes a time, so we recommend using multithreads.

- The options for using this step is below. You can change these options in the config.yml.
    - `a` : Gap existence cost of LAST aligner (default: 0).
    - `A` : Insertion existence cost of LAST aligner (default: 10).
    - `b` : Gap extension cost of LAST aligner (default: 15).
    - `B` : Insertion extension cost of LAST aligner (default: 7).  

## STEP 2. PARs depth
Detect the partially aligned reads (PARs) and candidate chimeric positions from the alignment result of STEP 1, and obtain the depth of PARs at that positions.

- The options for using this step is below. You can change these options in the config.yml.
    - `al` : Minimum alignment length (default: 100bp).  
    - `tl` : Minimum terminal length of unaligned region of PARs (default: 50bp). For obtaining the PARs, the alignment with start/end position within this threshold from the query or subject read terminus are removed.  
    - `pd` : Minimum depth of PARs (default: 3).  
    - `id` : Alignment identity threshold of PARs (default: 75%).  

## STEP 3. Caluculate PC ratio
Calculate the depth of continuously aligned reads (CARs) and the PARs/CARs ratio (PC ratio) at the candidate chimeric positions.

- The options for using this step is below. You can change these options in the config.yml.
    - `ad` : Minimum length of alignment start/end position from candidate chimeric position (default: 50bp). CARs are detected if it have the alignment with start and end position distant by this threshold or more from the candidate chimeric position.  
    - `id` : Alignment identity threshold of CARs (default: 75%).  

    ![PARs_CARs](https://github.com/hattori-lab/SACRA/blob/master/documentation/images/SACRA.Fig.png)

## STEP 4. Calculate mPC ratio
Calculate the mPC ratio based on the provided spike-in reference genome.

- The options for using this step is below. You can change these options in the config.yml.
    - `sp`  : If the mPC ratio is calculated from spike-in reference genome, set it to true, otherwise, set it false.
    - `rf`  : PATH to the spike-in reference genome.
    - `a`   : Gap existence cost of LAST aligner (default: 8).
    - `A`   : Insertion existence cost of LAST aligner (default: 16).
    - `b`   : Gap extension cost of LAST aligner (default: 12).
    - `B`   : Insertion extension cost of LAST aligner (default: 5).
    - `id`  : Alignment identity threshold (default: 95).
    - `al`  : Minimum alignment length (default: 50).
    - `lt`  : Threshold of the unaligned length for detecting chimeric reads (default: 50).

## STEP 5. Split
Split the chimeric read at the chimeric positions detected by STEP 3.

- The options for using this step is below. You can change these options in the config.yml.
    - `pc` : Minimum PC ratio (default: 8%). SACRA detects the chimeric positions with PC ratio greater than this threshold.  
    - `dp` : Minimum depth of PARs + CARs (default: 0).  
    - `sl` : Sliding windows threshold (default: 100bp). For detecting the most probable chimeric position from a chimeric junction with similar sequence, SACRA detects the chimeric position with highest PARs depth in this threshold windows.  

# Installation
```
git clone https://github.com/hattori-lab/SACRA.git
export PATH=$PATH:/path_on_your_system/SACRA/scripts/
```

# Usage
Run the below command in the directory containing the config.yml.  
```
sh SACRA.sh [-i <input fasta file>] [-p <prefix>] [-t <max no. of cpu cores>] [-c <config.yml>]
```

# Config file
All parameters of four steps are able to change by editting the config.yml.
```
---


alignment:
  R: "01"           : Specify lowercase-marking of lastdb.
  u: "NEAR"         : Specify a seeding scheme of lastdb.
  a: 0              : Gap existence cost.
  A: 10             : Insertion existence cost.
  b: 15             : Gap extension cost.
  B: 7              : Insertion extension cost.
  S: 1              : Specify how to use the substitution score matrix for reverse strands.
  f: "BlastTab+"    : Output format of LAST. SACRA accepts only BlastTab+ format.

parsdepth:
  al: 100           : Minimum alignment length.
  tl: 50            : Minimum terminal length of unaligned region of PARs.
  pd: 3             : Minimum depth of PARs.
  id: 75            : Alignment identity threshold of PARs.

pcratio:
  ad: 50            : Minimum length of alignment start/end position from candidate chimeric position.
  id: 75            : Alignment identity threshold of CARs.

mpc:
  sp: "true"        : Whether the mPC ratio is calculated based on the spike-in reference genome or not.
  rf: "lambda.fasta": PATH to the spike-in reference genome.
  R: "01"           : Specify lowercase-marking of lastdb.
  u: "NEAR"         : Specify a seeding scheme of lastdb.
  a: 8              : Gap existence cost.
  A: 16             : Insertion existence cost.
  b: 12             : Gap extension cost.
  B: 5              : Insertion extension cost.
  S: 1              : Specify how to use the substitution score matrix for reverse strands.
  f: "BlastTab+"    : Output format of LAST. SACRA accepts only BlastTab+ format.
  id: 95            : Alignment identity threshold.
  al: 50            : Minimum alignment length.
  lt: 50            : Threshold of the unaligned length for detecting chimeric reads. 

split:
  pc: 8             : Minimum PC ratio.
  dp: 0             : Minimum depth of PARs + CARs.
  sl: 100           : Sliding windows threshold.
```


# Output
`pcratio`: The results of PC ratio caluculation. The output is tab deliminated file containing six columns. 1. sequence id, 2. read length, 3. candidate chimeric position, 4. depth of PARs, 5. depth of CARs, 6. PC ratio (%).  
`non_chimera.fasta`: Non-chimeric reads.  
`split.fasta`: Splitted reads.  
`output.fasta`: Final sequences combining non-chimeric and split reads.  

# Publication
Preprint is available here.  
https://www.researchsquare.com/article/rs-58640/v1

# Docker Image
TBA
