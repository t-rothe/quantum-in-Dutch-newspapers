# Quantum Science & Technology in Dutch Newspapers (QSTDN)

Code used in the "Quantum Science & Technology in Dutch Newspapers" project, see our paper: [LINK TO PUBLISHED PAPER]

This repo primarily provides scripts to extract & process information from news articles in the LexisNexis® Uni database:
- NexisUni_checkDuplicates.jl:
- NexisUni_txt2dataset.jl: 
- NexisUni_extractMetadata.jl:
- NexisUni_analyzeMetadata.jl:

Minimum requirements (all scripts): Julia ≥ v1.6.7 <br>
!! Note that all of these scripts only work with NexisUni data in the formatting specified below. For copyright reasons, we do not provide our own NexisUni dataset. !!

Additional scripts used for the paper:
- pdf2txt_batch.ps1: A PowerShell script (Windows 10/11 only) that was used to convert NexisUni .pdf files to .txt files.
- generateCheckSample.jl: Script used to sample the 20% of news articles ("check sample") on which the inter-coder reliability (ICR) was computed. 
- interrater_reliability.ipynb: Notebook to compute inter-coder reliability (Cohen's Kappa, Krippendorf's Alpha and Percent Agreement) between two coders for an arbitrary number of codings/coding features. (Additionally requires: R ≥ v4.0.3, with the "irr" & "psych" packages installed)

## Basic usage:

txt2dataset: Note: This script is constructed to catch many of the layouting inconsisenties resulting from converting NexisUni .pdf files to .txt. Nevertheless, some layouting errors will let the script crash, particularly when linebreaks are misssing linebreaks. 
# The script logs, however, always show the last considered article ID such that the .txt files can be corrected by hand. If the metadata can't be determined with certainty, the script will crash such that the correctness of extracted metadata is ensured. 






