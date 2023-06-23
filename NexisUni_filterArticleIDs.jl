base_path = "/mnt/s/Sync/University/20212022_EPQS/data_files/national_newspapers_09-21"
#subset_input_dir = base_path*"/complete_data/"
#superset_input_dir = base_path*"/complete_data/txt_backup/"
#output_dir = base_path*"/complete_data/txt/"
subset_input_dir = base_path*"/post_selection_data/"
superset_input_dir = base_path*"/post_selection_data/txt_backup/"
output_dir = base_path*"/post_selection_data/txt/"
#input_dir = base_path*"/post_selection_data/"


subset_filenames = filter(contains(".pdf"), readdir(subset_input_dir ))
superset_filenames = filter(contains(".txt"), readdir(superset_input_dir))

@show length(subset_filenames), length(superset_filenames)

for super_filename in superset_filenames
    super_idurn = split(split(super_filename, ".txt", keepempty=false)[1], "_PS#_")
    for sub_filename in subset_filenames
        sub_idurn = split(split(sub_filename, ".pdf", keepempty=false)[1], "_PS#_")
        if super_idurn[end] == sub_idurn[end]
            try
                #cp(superset_input_dir*super_filename, output_dir*super_filename)
                cp(superset_input_dir*super_filename, output_dir*sub_idurn[1]*"_PS#_"*super_idurn[end]*".txt")             
            catch
                infile = superset_input_dir*super_filename
                outfile = output_dir*super_filename
                println("Could not copy file $infile to $outfile")
            end
        end
    end
end