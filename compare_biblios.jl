
using DataFrames
using CSV

#parent = bigger/complete bibliography; child = the other, smaller bibliograph
raw_downloads_folder = "/mnt/s/Sync/University/20212022_EPQS/data_files/national_newspapers_09-21/complete_data/raw_downloads/"
raw_downloads_biblio_file = "/mnt/c/Users/trothe/Desktop/c_m/collect_bib/raw_downloads_biblio_combined.csv"

bib_data_parent = DataFrame(CSV.File(raw_downloads_folder*"complete_search_biblio_all.csv"))[!, ["title", "file_attachments2"]]
bib_data_child = DataFrame(CSV.File(raw_downloads_biblio_file))[!, ["title", "file_attachments2"]]

#@show bib_data_parent
#@show bib_data_child

n_parent_entries = nrow(bib_data_parent)
n_child_entries = nrow(bib_data_child)

@show n_parent_entries, n_child_entries

#  bib_data[!, "title"]
bibdata_parent_urns = []
for parent_idx in 1:n_parent_entries
    doc_url = bib_data_parent[parent_idx, "file_attachments2"] #e.g. https://advance.lexis.com/api/document?collection=news&id=urn:contentItem:65GF-7B11-DY4K-800M-00000-00&context=1516831
    doc_urn = split(split(doc_url, "&")[2], ":")[end]
    reduced_doc_urn = doc_urn[1:end-9] #Remove the -00000-00 constant ending
    push!(bibdata_parent_urns, reduced_doc_urn)
end

matching_bibdata_parent_indices = []
for child_idx in 1:n_child_entries
    doc_url = bib_data_child[child_idx, "file_attachments2"] #e.g. https://advance.lexis.com/api/document?collection=news&id=urn:contentItem:65GF-7B11-DY4K-800M-00000-00&context=1516831
    doc_urn = split(split(doc_url, "&")[2], ":")[end]
    reduced_doc_urn = doc_urn[1:end-9] #Remove the -00000-00 constant ending

    matching_indices = findall(p_urn -> p_urn == reduced_doc_urn,bibdata_parent_urns)
    @assert length(matching_indices) == 0 || length(matching_indices) == 1
    if length(matching_indices) == 1
        push!(matching_bibdata_parent_indices, matching_indices[1])
    else
        println(reduced_doc_urn)
    end
end

bib_data_remaining = deepcopy(bib_data_parent)

delete!(bib_data_remaining, sort(matching_bibdata_parent_indices))
@show nrow(bib_data_remaining)
CSV.write("/mnt/c/Users/trothe/Desktop/c_m/collect_bib/missing_biblio_entries.csv", bib_data_remaining)