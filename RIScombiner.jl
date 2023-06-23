

#input_dir = "/mnt/s/Sync/University/20212022_EPQS/data_files/national_newspapers_09-21/complete_data/raw_downloads/"
#input_dir = "/mnt/c/Users/trothe/Desktop/c_m/collect_bib/" #C:\Users\trothe\Desktop\c_m\collect_bib
input_dir = "/mnt/s/Sync/University/20212022_EPQS/data_files/national_newspapers_09-21/complete_data/raw_downloads/20xx/"

function filenumber_year(filename)
    return parse(Int, split(split(filename, "_Nat", keepempty=false)[end],"_",keepempty=false)[1])
end

function filenumber(filename)
    return parse(Int, split(split(filename, ".", keepempty=false)[end-1],"_",keepempty=false)[end])
end

filenames = sort(filter(contains(".RIS"), readdir(input_dir)), by=filenumber)

open(input_dir*"combined.RIS", "w") do outfile
    for filename in filenames
        println("Writing file number $(filenumber(filename))...")
        open(input_dir*filename, "r") do infile
            write(outfile, read(infile))
        end
    end
end