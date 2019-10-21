# SACRA
Split Amplified Chimeric Read Algorithm

# Dependencies

last (version 963)
http://last.cbrc.jp/

seqkit (Version: 0.8.0)
https://bioinf.shenwei.me/seqkit/usage/

samtools (Version: 1.4)
http://www.htslib.org/

# Workflow of SACRA
SACRA operates in four phases: pairwise alignment, PARs detection, PC ratio calculation and split chimeras.  

1. All vs all pairwise alignment of long-read by LAST aligner.  
First, SACRA performs all vs all alignment of input long-read multi-fasta. For obtaining better performance of SACRA, input long-read needs to be highly accurate by error-correction by some tools (e.g. MHAP of canu, CCs reads of PacBio, etc.). This process takes a time, so we recommend using multithreads.  

The options for using this process is below.  
-a  Gap existence cost of LAST aligner. (default: 8)  
-A  Insertion existence cost of LAST aligner. (default: 16)  
-b  Gap extension cost of LAST aligner. (default: 12)  
-B  Insertion extension cost of LAST aligner. (default: 5)  
-P  Number of threads. (default: 50)  

2. Detecting the partial aligned reads (PARs) and obtaining the depth of PARs at the putative chimeric positions.
Second, SACRA detects PARs and obtains the depth of PARs at putative chimeric positions.

The options for using this process is below.
XXX Minimum alignment coverage length threshold. (default: 100bp) 
XXX Minimum length of alignment start/end position from terminus of query or subject reads. (default: 50bp)
    For obtaining the PARs, the alignment with start/end position within threshold from the query or subject read terminus are removed. 
XXX Mimimum depth of PARs. (default: 5)
XXX Alignment identity threshold. (default: 75%)

3. Detecting the completely aligned reads (CARs) and obtaining the PARs/CArs patio (PC ratio) at the putative chimeric positions.
Third, SACRA calculate the depth of CARs at the putative chimeric positions obtained by STEP2.

The options for using this process is below.
XXX Minimum length of alignment start/end position from putative chimeric position. (default: 50bp)
    For obtaining the CARs, the alignments which have an alignment start and end position distant by threshold or more from the putative chimeric position are detected as CARs. 
XXX Alignment identity threshold. (default: 75%)

4. Split the putative chimeric positions with PC ratio higher than threshold.
Finally, SACRA split the chimeras at the putative chimeric positions detected by STEP3.

The options for using this process is below.
XXX Minimum PC ratio (default: 10%)
    SACRA detects the chimeric positions with PC ratio greater than threshold.
XXX Mimimum depth of PARs + CARs. (default: 10)
XXX Sliding windows threshold. (default: 100bp)
    For detecting the most probable chimeric position from a chimeric junction with similar sequence, SACRA detects the chimeric position with highest PARs deoth in threshold windows.

Output files
~.pcratio: The results of calculation of PARs, CARs and PC ratio. The out put file is composed by tab deliminated.
            1. sequence id, 2. read length, 3. putative chimeric position, 4. depth of PARs, 5. depth of CARs, 6. PC ratio (%)
~.non_chimera.fasta: Non-chimeras sequences.
~.split.fasta: Split Split sequences.
~.sacra.fasta: Final sequences combining non-chimeras and split sequences.

# Docker Image

TODO
1. Combine lastdb, lastal, SACRA_PARs_depth.pl and SACRA_PCratio.pl to SACRA.pl, and speed up.
2. Add new option to SACRA.sh for re-running the SACRA after SACRA.pl process.
3. samtools faidx process is too slow, so it is needed to speed up by parallel computing.
