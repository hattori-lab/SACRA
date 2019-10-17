# SACRA
Split Amplified Chimeric Read Algorithm

# Dependencies

last (version 963)
http://last.cbrc.jp/

seqkit (Version: 0.8.0)
https://bioinf.shenwei.me/seqkit/usage/

samtools (Version: 1.4)
http://www.htslib.org/


# Docker Image

TODO
1. Combine lastdb, lastal, SACRA_PARs_depth.pl and SACRA_PCratio.pl to SACRA.pl, and speed up.
2. Add new option to SACRA.sh for re-running the SACRA after SACRA.pl process.
3. samtools faidx process is too slow, so it is needed to speed up by parallel computing.
