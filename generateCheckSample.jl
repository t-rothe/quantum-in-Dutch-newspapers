###############################################################################
# Part of the Quantum Science & Technology in Dutch Newspapers (QSTDN) project
###############################################################################
# By Thomas Rothe 
# Copyright (c) 2022 Leiden University
################################################################################
# Creates a random sample from a directory of .pdf files, given a fixed percentage
#
# Specify the percentage of the (sub)sample, a directory of pdf files and a directory to store the sample.

using StatsBase

indir = "$DATA_PATH/national_newspapers_09-21/complete_data/"
outdir = "$DATA_PATH/national_newspapers_09-21/complete_data/selection_check_sample/"

outfilename = "_check_sample_ids.txt"
sample_percentage = 20 #%

#Where to sample from?
sample_space = filter(contains(".pdf"), readdir(indir))
#What to exclude from the sample space? (must overlap!)
neg_sample_space = filter(contains(".pdf"), readdir(residualdir))
#Delete to be excluded samples from the sample space
filter!(el -> !(el in neg_sample_space) ,sample_space)

@show size(sample_space), size(neg_sample_space)
sample_size = Int(round((sample_percentage/100) * length(sample_space)) + 1) 

#Happy sampling!
check_sample = sample(sample_space, sample_size, replace=false)
@show size(sample_size), size(check_sample)

#Copy all sampled files from input to output folder
for smpl in check_sample
  samplefilename = smpl
  try
    cp(indir*samplefilename, outdir*samplefilename)
  catch
      infile = indir*samplefilename
      outfile =  outdir*samplefilename
      println("Could not copy file $infile to $outfile")
  end
end

#Write for reference the article ids to a file:
check_sample_idurns = []
for smpl in check_sample 
  idurn = split(split(smpl, ".pdf", keepempty=false)[1], "_#_")
  id, urn = idurn[1], idurn[2]
  push!(check_sample_idurns, (id, urn))
end


check_sample_idurns = sort(check_sample_idurns, by = first)

open(outdir*outfilename, "w") do f
  for idurn in check_sample_idurns
    println(f, idurn)
  end
end