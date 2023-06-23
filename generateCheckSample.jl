###############################################################################
# Part of the Quantum in newspapers project
# By Thomas Rothe
################################################################################
# Creates a random sample from a directory of .pdf files, given a fixed percentage
#
# Specify the percentage of the (sub)sample, a directory of pdf files and a directory to store the sample.

using StatsBase

#indir = "/mnt/s/Sync/University/20212022_EPQS/data_files/national_newspapers_09-21/complete_data/"
#outdir = "/mnt/s/Sync/University/20212022_EPQS/data_files/national_newspapers_09-21/complete_data/selection_check_sample/"
#indir = "/mnt/s/Sync/University/20212022_EPQS/data_files/national_newspapers_09-21/complete_data/2022_singledout/"
#outdir = "/mnt/s/Sync/University/20212022_EPQS/data_files/national_newspapers_09-21/complete_data/2022_singledout/selection_check_sample/"
#indir = "/mnt/s/Sync/University/20212022_EPQS/data_files/national_newspapers_09-21/complete_data/extra_check_sample/"
#outdir = "/mnt/s/Sync/University/20212022_EPQS/data_files/national_newspapers_09-21/complete_data/extra_check_sample/temp/"

#indir = "/mnt/s/OneDrive - Universiteit Leiden/QSTDN_Quantum&Society/data/national_newspapers_09-21/post_selection_data/"
#outdir = "/mnt/s/OneDrive - Universiteit Leiden/QSTDN_Quantum&Society/data/national_newspapers_09-21/coding_sample_medium/"
#indir = "/mnt/s/OneDrive - Universiteit Leiden/QSTDN_Quantum&Society/data/national_newspapers_09-21/coding_sample_medium/"
#outdir = "/mnt/s/OneDrive - Universiteit Leiden/QSTDN_Quantum&Society/data/national_newspapers_09-21/coding_sample_small/"
#indir = "/mnt/s/OneDrive - Universiteit Leiden/QSTDN_Quantum&Society/data/national_newspapers_09-21/coding_sample_small/"
#outdir = "/mnt/s/OneDrive - Universiteit Leiden/QSTDN_Quantum&Society/data/national_newspapers_09-21/coding_sample_small/small_check_sample/"
residualdir = "/mnt/s/OneDrive - Universiteit Leiden/QSTDN_Quantum&Society/data/national_newspapers_09-21/coding_sample_small/"
indir = "/mnt/s/OneDrive - Universiteit Leiden/QSTDN_Quantum&Society/data/national_newspapers_09-21/coding_sample_medium/"
outdir = "/mnt/s/OneDrive - Universiteit Leiden/QSTDN_Quantum&Society/data/national_newspapers_09-21/coding_sample_medium/medium_check_sample/"


outfilename = "_check_sample_ids.txt"
#sample_percentage = 20 #%
sample_size = 24

#Where to sample from?
sample_space = filter(contains(".pdf"), readdir(indir))
#What to exclude from the sample space? (must overlap!)
neg_sample_space = filter(contains(".pdf"), readdir(residualdir))
#Delete to be excluded samples from the sample space
filter!(el -> !(el in neg_sample_space) ,sample_space)

######### Uncomment & use this section only when extending a smaller sample to bigger one ########
# We don't want to give files in the smaller sample an unfair second chance to be sampled so only sample from the residual of the big and small sample
#outdir = "/mnt/s/OneDrive - Universiteit Leiden/QSTDN_Quantum&Society/data/national_newspapers_09-21/coding_sample_small/"
#smaller_sample = filter(contains(".pdf"), readdir(smaller_sample_dir))
#filter!(el -> !(el in smaller_sample) ,sample_space)
#######################################################################################

@show size(sample_space), size(neg_sample_space)
#sample_size = Int(round((sample_percentage/100) * length(sample_space)) + 1)  #Uncomment when using Percentage-based sampling

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