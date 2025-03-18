# Quantum Science & Technology in Dutch Newspapers (QSTDN)

Code used in the "Quantum Science & Technology in Dutch Newspapers" project; See our paper: https://doi.org/10.1177/10755470251318300 (Preprint: https://arxiv.org/abs/2403.05597)

This repo primarily provides scripts to extract & process information from news articles in the LexisNexis® Uni database:
- _NexisUni_titleFiles2urnFiles.jl_: Automatically renames NexisUni files (i.e. "HEADLINE.pdf") to systematic & indexed filename (i.e. "ArticleID_#_URN.pdf")
- _NexisUni_extractMetadata.jl_: Takes NexisUni data files and tries to extract common metadata for each news article. This script can generate a (rough) csv/excel tabel of the metadata and prepare it for further analysis.
- _NexisUni_checkDuplicates.jl_: Identifies potentially duplicate news articles in a NexisUni dataset to enhance the efficiency of comparing news articles by hand.
- _NexisUni_analyzeMetadata.jl_: Plotting / Visualization methods for metadata extracted from NexisUni data (Incl. Positive-aware counting of keyword occurences).

Minimum requirements (all scripts): Julia ≥ v1.6.7 <br>
!! Note that all of these scripts only work with NexisUni data in the formatting specified below. For copyright reasons, we do not provide our own NexisUni dataset. !!

Additional scripts used for the paper:
- _pdf2txt_batch.ps1_: A PowerShell script (Windows 10/11 only) that was used to convert NexisUni .pdf files to .txt files.
- _generateCheckSample.jl_: Script used to sample the 20% of news articles ("check sample") on which the inter-coder reliability (ICR) was computed. 
- _interrater_reliability.ipynb_: Notebook to compute inter-coder reliability (Cohen's Kappa, Krippendorf's Alpha and Percent Agreement) between two coders for an arbitrary number of codings/coding features. (Additionally requires: R ≥ v4.0.3, with the "irr" & "psych" packages installed)

## Basic usage:

### Preparing NexisUni data

The scripts starting with "NexisUni_" expect a dataset of NexisUni news articles. This is just a dedicated folder with individual .txt files, whereby each file represents the textual content of a single news article in the dataset. While the folder name can be abitrary, the filenames must be formated as: "ArticleID_#_URN.txt". Here "ArticleID" just refers to a unique number for easy reference, and "URN" is the Unique Resource Name (URN) provided by NexisUni (without the trailing zeros and the "URN"-prefix). <p>

1. NexisUni does (currently) not allow the download of articles as .txt files so you'll have to download the articles as .pdf's. Put all .pdf files of your dataset into a separate folder and rename the files to the above format. <br>
You may automate this renaming using "NexisUni_titleFiles2urnFiles.jl". However, for this you need, apart from the .pdf files, also the bibliographic metadata from NexisUni as a .csv file. This is easy to obtain: <br>
- After selecting news articles in NexisUni you can click on the bookshelf icon and use "Citation Export" to obtain such a .RIS file of the bibliographic easily. 
- You need to convert this .RIS file to .csv. There are plenty tools available to do this; E.g. see https://github.com/WeDias/RIS2CSV
- Now, using the "NexisUni_titleFiles2urnFiles.jl" script, you can automatically rename all the .pdf files into the required format!
<p>
2. Unfortunately, .pdf files are not very accesible in programming environments. So you'll have to convert the .pdf files to .txt files. <br>
On Windows 10/11 we can do this efficiently with MS Word via PowerShell. First make sure all .pdf files are in a separate folder and have the filename format from above. In "pdf2txt_batch.ps1" you can just specify the folder with .pdf files and run the script. On first run, you may be prompted with "Word will now convert your PDF to an editable....". If so, please check the checkbox "Don't show this message again" and hit OK. <br>

### Automatic metadata extraction
NexisUni data files are tremendously inconsistently formatted so it is hard to extract metadata or the article body text, even when using .txt files. To make the data processing & analysis more convenient, we want to standardize the NexisUni data into a consistent and structured dataset. <p>
The "NexisUni_extractMetadata.jl" script provides functions to automatically extract the metadata from all .txt files in a specified folder. By construction the script is able to identify and mitigate the most common inconsisenties in the layout of NexisUni data. (That's why it looks so messy ;)) <p>
Nevertheless, some layouting errors in the .txt files will let the script crash, particularly when linebreaks are misssing. This behavior is meant to ensure the correctness of any extracted metadata. So to proceed, the layout/formatting of the .txt files needs be corrected by hand. Fortunately, the terminal output of the script always shows the last (i.e. problematic) article ID before the script crashed.  The manual correction has to be repeated for (probably) many articles, until the script runs smoothly through all .txt files in the pre-specified folder. <p>
The script is stable enough to allow some flexibility in the formatting/layouting of .txt files, but we recommend sticking to the following format if the script keeps crashing:

```
[ARTICLE HEADLINE; MUST BE ON A SINGLE LINE]
[NEWSPAPER BRAND]
[DAY OF MONTH] [MONTH; WRITTEN OUT; MIGHT BE ENGLISH/DUTCH = ok] [YEAR] [DAY OF WEEK; MIGHT BE MISSING = ok; MIGHT BE ENGLISH/DUTCH = ok]
Copyright [YEAR] [PUBLISHING COMPANY] All Rights Reserved

Section: [NEWSPAPER SECTION TITLE; IF FOLLOWED BY A ";" AND OTHER INFO, e.g. "Blz.", WILL BE IGNORED = ok]
Length: [WORDCOUNT] words
Byline: [AUTHOR NAME; WARNING: IF MULTIPLE AUTHORS, SEPARATED BY ";", ONLY THE FIRST AUTHOR WILL BE IDENTIFIED]
Highlight: [HIGHLIGHT TEXT; MIGHT BE MISSING = ok; MIGHT SPAN MULTIPLE LINES = ok]
Body
[ARTICLE BODY TEXT; TAKES SEVERAL LINES; DON'T WORRY ABOUT UGLY FORMATTING, e.g. double newlines/spaces, ...]
Classification
[IF ANYTHING IS WRITTEN HERE, DON'T WORRY, IT IS IGNORED ANYWAY ...]
End of Document
```

When the metadata extraction runs smoothly, the data(set) is finally in an accesible format and ready to be used with any of the other "NexisUni_" scripts! 

### Visualizing metadata

Plotting and visualizing metadata as a form of exploring the descriptives of your newspaper data is now easily done. We implemented a couple of straightforward example plots in the "NexisUni_analyzeMetadata.jl" script. (It also includes position-aware keyword counting throughout the dataset!)

### Duplicate Check
The effort of converting the NexisUni data into a machine-readable format is not only justified by avoiding the manual extraction of metadata. It also enables us to find duplicate news articles throughout the dataset more efficiently.  <p>
The "NexisUni_checkDuplicates.jl" script does this by using textual similarity metrics. In our workflow edit-distances are used complementary to overlap distances to detect multiple types of news article duplicates. To reduce runtime of the script significantly, especially when using edit-distances, we only looked for duplicates in article subsets with the same year of publication. We think this is a reasonable assumption since two equal articles would never be published by accident in different years. <br>
For details on how we defined duplicates and applied these similarity metrics, we refer to the appendix of our paper.  <p>

The script outputs a list of all duplicate pairs of articles into the terminal and writes them into a .txt file for later reference. Along each pair also the associated similarity score/distance is specified to prioritize the manual check of certain article pairs over others. <p>
Please note that the only purpose of this script was to reduce the manual search space for duplicates from $Ω(n^2)$ to $Ω(n)$ by excluding the trivial non-duplicates. Any duplicates found by the script are only duplicate candidates and need to be checked manually! <p> 
Testing through multiple metrics and significance levels is an important calibaration step as we need to make sure that we don't discard article pairs too early. Therefore, we chose the significance level always rather conservatively to avoid false-negatives. Of course, this comes at the cost of having to filter out more false-positives by hand. In any case, you may want to adapt the significance level and specific metric to your data.

### Batched computation of Inter-Coder Reliability (ICR) for multiple coding features
We refer to the Jupyter notebook, "interrater_reliability.ipynb", for how to use R-packages from within Julia to simultaneously compute the Cohen's Kappa, Krippendorf's Alpha and Percent Agreement for an abitrary number of coding features (/codings) between two coders. <p>
The codings from both coders (A & B) should be provided as a table on an MS Excel sheet. The table rows should correspond to different samples, while the columns should be combinations of coder label and the coding feature label separated by a full stop character ".". <p>
Let's assume our codebook contains 42 codings / coding features, labelled "1", "2", ..., "42". Then our table should look like:
| Article ID | 1.A | ... | 42.A | 1.B | ... | 42.B |
|:---------- |:--- |:--- |:---- |:--- |:--- |:---- |
| 1          | ~   | ... | ~    | ~   | ... | ~    |
| 2 | ~   | ... | ~    | ~   | ... | ~    |
| $\vdots$   |  ~  | ... |  ~  |  ~  | ... |   ~  |  

The codings/coding features are assumed to be categorical. Missing values can be specified by coding a "~", "-9" or "-1". <br>
The generalization of the script and table structure to > 2 coders is straightforward. 






