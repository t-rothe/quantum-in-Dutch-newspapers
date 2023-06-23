using FileIO
using XLSX
using DataFrames

#Import to-be-filtered data from excel:
filepath = "/mnt/s/OneDrive - Universiteit Leiden/QSTDN_Quantum&Society/data/national_newspapers_09-21/Coding_Sheet_Metadata.xlsx"
sheetname = "Complete"
dataloc_on_sheet = "A7:L705"

#df = DataFrame(XLSX.readtable(filepath, sheetname))
xlf_mat = XLSX.readdata(filepath, sheetname*"!"*dataloc_on_sheet)
col_names = xlf_mat[1,:]
data = xlf_mat[2:end,:]
df = DataFrame(data, :auto) #convert(DataFrame, data)
@show typeof(df)
rename!(df, names(df) .=> Symbol.(col_names[:]))
@show df

#Look up which entries we need to keep:
sample_files_dir = "/mnt/s/OneDrive - Universiteit Leiden/QSTDN_Quantum&Society/data/national_newspapers_09-21/coding_sample_small/"
sample_files_dir = "/mnt/s/OneDrive - Universiteit Leiden/QSTDN_Quantum&Society/data/national_newspapers_09-21/coding_sample_medium/medium_check_sample/"
sample_filenames = filter(contains(".pdf"), readdir(sample_files_dir))

sample_ids = []
for smpl in sample_filenames
    idurn = split(split(smpl, ".pdf", keepempty=false)[1], "_PS#_")
    id, urn = parse(Int, idurn[1]), idurn[2]
    push!(sample_ids, id)
end

#Filter the data and push back to an xlsx file
sample_df = filter(Symbol(col_names[1]) => art_num -> art_num in sample_ids , df)
#@show sample_df[!, Symbol(col_names[1])]
XLSX.writetable(sample_files_dir*"filtered_metadata_output.xlsx", sample_df,  anchor_cell="B2")

