###############################################################################
# Part of the Quantum in newspapers project
# By Thomas Rothe
################################################################################
# Takes source files from NexisUni download with headline in filename 
# and matches it with the bibliographic data from the NexisUni provided bibliography file
# Before use, convert the .RIS bibliography files to .CSV using a converter,
# e.g. https://github.com/WeDias/RIS2CSV
#
# Outputs a copy of the pdf source files with filename 
# reformatted "[Article ID]_#_[URN].pdf" to any specified output directory

using DataFrames
using CSV
using StringDistances


function main()
    raw_downloads_folder = "/mnt/s/Sync/University/20212022_EPQS/data_files/national_newspapers_09-21/complete_data/raw_downloads"
    
    bib_data = dropmissing(DataFrame(CSV.File(raw_downloads_folder*"/20xx/_Natxx_csv_bibliography_all.csv"))[!, ["title", "file_attachments2"]])
    @show bib_data
    input_dir = raw_downloads_folder*"/20xx/"
    output_dir = raw_downloads_folder*"/../"
    #output_dir = raw_downloads_folder*"/../2022_singledout/"
    file_id_offset = 2242

    old_filenames = filter(contains(".pdf"), readdir(input_dir))
    
    #mkdir(output_dir)
    @show old_filenames

    n_files = size(old_filenames, 1)
    @show n_files

    succes_file_indices = []
    succes_bibdata_indices = []

    for file_i in 1:n_files
        #row_i = findfirst(contains(old_filenames[file_i]), bib_data[!, "title"])
        val, row_idx = findnearest(old_filenames[file_i], bib_data[!, "title"], DamerauLevenshtein()) #RatcliffObershelp()
        dist_val = evaluate(Overlap(2), old_filenames[file_i], val)

        if row_idx === nothing
            println(file_i)
        end

        println("--------$dist_val--------")
        println(old_filenames[file_i])
        println(bib_data[row_idx, "title"])
        println("----------------")

        if dist_val <= 0.5
            #Rename file to [row_i]_[document_URN].txt
            doc_url = bib_data[row_idx, "file_attachments2"] #e.g. https://advance.lexis.com/api/document?collection=news&id=urn:contentItem:65GF-7B11-DY4K-800M-00000-00&context=1516831
            doc_urn = split(split(doc_url, "&")[2], ":")[end]
            reduced_doc_urn = doc_urn[1:end-9] #Remove the -00000-00 constant ending

            file_id_number = row_idx + file_id_offset
            new_filename = string(file_id_number) * "_#_" * reduced_doc_urn * ".pdf"
            
            try
                cp(input_dir*old_filenames[file_i], output_dir*new_filename)
            catch
                infile = input_dir*old_filenames[file_i]
                outfile =  output_dir*new_filename
                println("Could not copy file $infile to $outfile")
            end
            
            append!(succes_file_indices, file_i )
            append!(succes_bibdata_indices, row_idx ) 
        end
    end

    #Delete entries from dataframe to reduce complexity and show non-matchings afterwards
    delete!(bib_data, sort(succes_bibdata_indices))
    deleteat!(old_filenames, sort(succes_file_indices))

    println("+++++++++ Finished ++++++++++")
    println("We couldn't match the files:")
    println(old_filenames)
    println("with the following bibliography entries:")
    println(bib_data)
end
main()