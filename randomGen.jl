using StatsBase

check_sample = sort(sample(1:1364, 210, replace=false))
outdir = "/mnt/s/Sync/University/20212022_EPQS/data_files/national_newspapers_09-21/raw_src/"
outfilename = "_check_sample_ids.txt"

open(outdir*outfilename, "w") do f
  for id in check_sample 
    println(f, id)
  end
end