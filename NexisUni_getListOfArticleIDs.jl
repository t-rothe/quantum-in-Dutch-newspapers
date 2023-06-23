base_path = "/mnt/s/Sync/University/20212022_EPQS/data_files/national_newspapers_09-21"
input_dir = base_path*"/complete_data/"
#input_dir = base_path*"/post_selection_data/"


filenames = filter(contains(".pdf"), readdir(input_dir))

open(input_dir*"temp_id_list.txt", "w") do f
    for temp_old_filename in filenames
            idurn = split(split(temp_old_filename, ".pdf", keepempty=false)[1], "_#_")
            println(f, idurn[1])
    end
end
