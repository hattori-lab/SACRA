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
SACRA operates in four phases: 1. alignment, 2. parsdepth, 3. pcratio and 4. split.  
<!-- ![ARCs](https://user-images.githubusercontent.com/38690620/70684422-7985f000-1ce9-11ea-82d5-79addb16c248.png) -->

## STEP 1. alignment
SACRA performs all vs all pairwise alignment of input long-read by LAST aligner for constructing aligned read clusters (ARCs).
For obtaining better performance of SACRA, input long-read needs to be highly accurate by error-correction by some tools (e.g. MHAP of canu, HiFi reads of PacBio, etc.). In the original paper, error-corrected long reads had relatively high accuracy with 97% on average. This process takes a time, so we recommend using multithreads.

- The options for using this step is below. You can change these options in the config.yml.
    - `a` : Gap existence cost of LAST aligner (default: 8).
    - `A` : Insertion existence cost of LAST aligner (default: 16).
    - `b` : Gap extension cost of LAST aligner (default: 12).
    - `B` : Insertion extension cost of LAST aligner (default: 5).  

## STEP 2. parsdepth
Detects the partially aligned reads (PARs) and candidate chimeric positions from the alignment result of STEP 1, and obtains the depth of PARs at that positions.

- The options for using this step is below. You can change these options in the config.yml.
    - `al` : Minimum alignment length (default: 100bp).  
    - `tl` : Minimum terminal length of unaligned region of PARs (default: 50bp). For obtaining the PARs, the alignment with start/end position within this threshold from the query or subject read terminus are removed.  
    - `pd` : Mimimum depth of PARs (default: 5).  
    - `id` : Alignment identity threshold of PARs (default: 75%).  

## STEP 3. pcratio
Calculates the depth of continuously aligned reads (CARs) and the PARs/CARs ratio (PC ratio) at the candidate chimeric positions.

- The options for using this step is below. You can change these options in the config.yml.
    - `ad` : Minimum length of alignment start/end position from candidate chimeric position (default: 50bp). For obtaining the CARs, the alignments which have an alignment start and end position distant by this threshold or more from the candidate chimeric position are detected as CARs.  
    - `id` : Alignment identity threshold of CARs (default: 75%).  
      
    https://github.com/hattori-lab/SACRA/blob/development/documentation/images/PARs_CARs.png

## STEP 4. split
Split the chimeric read at the chimeric positions detected by STEP 3.

- The options for using this step is below. You can change these options in the config.yml.
    - `pc` : Minimum PC ratio (default: 10%). SACRA detects the chimeric positions with PC ratio greater than this threshold.  
    - `dp` : Mimimum depth of PARs + CARs (default: 10).  
    - `sl` : Sliding windows threshold (default: 100bp). For detecting the most probable chimeric position from a chimeric junction with similar sequence, SACRA detects the chimeric position with highest PARs depth in this threshold windows.  


# Installation


# Usage
Run the below command in the directory containing the config.yml.  
```
./SACRA.sh [-i <input fasta file>] [-p <prefix>] [-t <max no. of cpu cores>]
```

# Config file
```
---

alignment:
  R: "01"
  u: "NEAR"
  a: 8 
  A: 16 
  b: 12 
  B: 5 
  S: 1  
  f: "BlastTab+"

parsdepth:
  al: 100 
  tl: 50 
  pd: 5 
  id: 75

pcratio:
  ad: 50 
  id: 75

split:
  pc: 10 
  dp: 10 
  sl: 100
```


# Output
`pcratio`: The results of PC ratio caluculation. The output is tab deliminated file containing six columns. 1. sequence id, 2. read length, 3. candidate chimeric position, 4. depth of PARs, 5. depth of CARs, 6. PC ratio (%).  
`non_chimera.fasta`: Non-chimeric reads.  
`split.fasta`: Splitted reads.  
`output.fasta`: Final sequences combining non-chimeric and split reads.  

# Publication
TBA  

# Docker Image
