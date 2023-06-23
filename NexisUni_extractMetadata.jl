###############################################################################
# Part of the Quantum in newspapers project
# By Thomas Rothe
################################################################################
# Takes NexisUni data files with filename in format "[Article ID]_#_[URN].txt"
# and tries to extract common metadata from the file.
# Conversion of the .pdf, .docx or .rtf data files from NexisUni to .txt is required before use!
# e.g. See the accompanying MS Powershell script "pdf2txt_batch.ps1"
#
# This script can be used to generate a (rough) csv/excel tabel of the metadata
# or used to get metadata for other data processing tasks by including this script in your own.
#
# For any Parsing, Key or Bounds-errors, refer to the (assumed) format of TXT files
# in this code and correct them manually
#

using FileIO
using CSV
using XLSX
using DataFrames
using StringEncodings

newspaperNameKeywordList =  ["NRC Handelsblad","NRC.NEXT", "NRC","de Volkskrant", "Trouw", "AD/Algemeen Dagblad", "De Telegraaf", "Het Parool"]

monthCoding = Dict("januari" => 1,"january" => 1,
"februari" => 2, "february" => 2, 
"maart" => 3,"march" => 3,
"april" => 4, "april" => 4,
"mei" => 5, "may" => 5,
"juni" => 6, "june" => 6,
"juli" => 7, "july" => 7,
"augustus" => 8,"august" => 8,
"september" => 9, "september" => 9,
"oktober" => 10, "october" => 10,
"november" => 11, "november" => 11,
"december" => 12, "december" => 12,
)

weekdayCoding = Dict("maandag" => 1, "monday" => 1,
"dinsdag" => 2, "tuesday" => 2,
"woensdag" => 3, "wednesday" => 3,
"donderdag" => 4, "thursday" => 4, "donderda" => 4,
"vrijdag" => 5, "friday" => 5,
"zaterdag" => 6, "saturday" => 6,
"zondag" => 7, "sunday" => 7,
)

dayNormalCoding = merge(Dict(" $d " => d for d in range(1, 31, step=1)), Dict(" $d," => d for d in range(1, 31, step=1)))
day0Coding = merge(Dict(" 0$d " => d for d in range(1, 9, step=1)), Dict(" 0$d," => d for d in range(1, 9, step=1)))
dayCoding = merge(dayNormalCoding, day0Coding)

yearCoding = Dict("$y" => y for y in range(1990, 2022,step=1))

rm_whitespace(input) = filter(x -> !isspace(x), input)


function parse_third_meta_line(metadata_dict, third_meta_line)
    weekday_idx = [] #First and last indices of the respective features in the line-string
    day_idx = []
    month_idx = []
    newspaper_name_idx = []

    metadata_dict["Publication Weekday"] = 0
    for key in keys(weekdayCoding)
        if occursin(lowercase(key), lowercase(third_meta_line))
            weekday_idx_range = findfirst(lowercase(key), lowercase(third_meta_line)) 
            weekday_idx = first(weekday_idx_range):last(weekday_idx_range)
            metadata_dict["Publication Weekday"] = weekdayCoding[lowercase(third_meta_line[weekday_idx])]
        end
    end

    third_meta_line = join([" ", third_meta_line]) #Need to add whitespace to line, to detect day of month correctly

    for key in keys(dayCoding)
        if occursin(lowercase(key), lowercase(third_meta_line))
            day_idx_range = findfirst(lowercase(key), lowercase(third_meta_line)) 
            day_idx = first(day_idx_range):last(day_idx_range)
            metadata_dict["Publication Day"] = dayCoding[lowercase(third_meta_line[day_idx])]
        end
    end

    for key in keys(monthCoding)
        if occursin(lowercase(key), lowercase(third_meta_line))
            month_idx_range = findfirst(lowercase(key), lowercase(third_meta_line)) 
            month_idx = first(month_idx_range):last(month_idx_range)
            metadata_dict["Publication Month"] = monthCoding[lowercase(third_meta_line[month_idx])]
        end
    end

    for key in keys(yearCoding)
        if occursin(lowercase(key), lowercase(third_meta_line))
            year_idx_range = findfirst(lowercase(key), lowercase(third_meta_line)) 
            year_idx = first(year_idx_range):last(year_idx_range)
            metadata_dict["Publication Year"] = yearCoding[lowercase(third_meta_line[year_idx])]
        end
    end

    return metadata_dict
end

function parse_last_meta_lines(metadata_dict, meta_line)
    newspaper_section_idx = []
    author_name_idx = []
    article_length = []

    #Check which features/information occurs in this metaline:
    feature_indicator_pairs = [("Newspaper Section", "Section: "), ("Author Name", "Byline: "), ("Word Count", "Length: ")]
    
    #If features missing; set them to 0 / "Missing" string respectively
    metadata_dict["Word Count"] = 0
    metadata_dict["Newspaper Section"] = "Missing"
    metadata_dict["Author Name"] = "Missing"

    for (feature, indicator) in feature_indicator_pairs
        if occursin(rm_whitespace(lowercase(indicator)), rm_whitespace(lowercase(meta_line))) #Only consider if section information exists in line
            remain_line = split(meta_line, indicator)[2] #everything beyond the section keyword
    
            remain_line_components = split(remain_line, " ")
            next_feature_idx = findfirst(contains(':'), remain_line_components)
            if next_feature_idx === nothing #i.e. No other feature exists in this line
                remain_line = remain_line
            else # If other feature exists cutt out the string part before its indicator.
                remain_line = join(remain_line_components[1:next_feature_idx-1], " ")
            end

            if feature == "Word Count"
                metadata_dict[feature] = parse(Int, split(lowercase(rm_whitespace(remain_line)), "w")[1]) #Get rid of the "words" substring
            else
                values = split(remain_line, "; ", keepempty=false) #If multiple values for this feature mentioned, split into an array
                metadata_dict[feature] = values[1] #Only store the first value that is mentioned
            end
        end
    end
    #findfirst(lowercase("Byline: "), lowercase(third_meta_line))
    #findfirst(lowercase("Section:"), lowercase(third_meta_line))
    #findfirst(lowercase("Length:"), lowercase(third_meta_line))
    
    return metadata_dict
end

function extract_metadata(file, filepath,encoding)
    metadata_dict = Dict()

    #Look whether Filename is in format ID_#_URN or ID_PS#_URN
    #seperator = "_#_"
    seperator = "_PS#_"
    metadata_dict["Filename"] = split(split(filepath ,".txt", keepempty=false)[1], "/", keepempty=false)[end]
    metadata_dict["URN"] = ""
    metadata_dict["Article ID"] = 0
    if contains(metadata_dict["Filename"], seperator) && length(split(metadata_dict["Filename"],seperator,keepempty=false)[end]) == length("XXXX-XXXX-XXXX-XXXX")
        idurn = split(metadata_dict["Filename"],seperator,keepempty=false)
        metadata_dict["URN"] = idurn[end]
        metadata_dict["Article ID"] = parse(Int, idurn[1])
    end

    #Read out file content
    file_content_lines = readlines(file, encoding) #readlines(file, keep=false)
    filter!(x -> (x != "" && x != " "), file_content_lines) #Remove linebreaks
    filter!(x -> !contains(x, r"Page\s\d\sof\s\d"), file_content_lines) #Remove Page indicators
    
    line_cnt = 1

    #Exception handling
    if !occursin(lowercase("Copyright"), lowercase(file_content_lines[4])) && occursin(lowercase("Copyright"), lowercase(file_content_lines[3])) #Headline and newspaper name mixed up
        metadata_dict["Newspaper Name"] = nothing
        for name_keyword in newspaperNameKeywordList
            if occursin(rm_whitespace(lowercase(name_keyword)), rm_whitespace(lowercase(file_content_lines[1])))
                metadata_dict["Newspaper Name"] = name_keyword
                file_content_lines[1] = chop(file_content_lines[1], head = 0, tail = length(name_keyword))
                insert!(file_content_lines, 2, name_keyword)
            end
        end
        if metadata_dict["Newspaper Name"] === nothing
            throw(ParseError("Newspaper Unknown / not in list"))
        end
    elseif !occursin(lowercase("Copyright"), lowercase(file_content_lines[4])) && occursin(lowercase("Copyright"), lowercase(file_content_lines[5])) #Headline takes multiple lines
        if occursin(lowercase("Editie"), lowercase(file_content_lines[4]))
            deleteat!(file_content_lines, 4)
        else
            file_content_lines[1] = join([file_content_lines[1], file_content_lines[2]], " ")
            deleteat!(file_content_lines, 2)
        end
    end

    #First line is always Newspaper headline:
    first_meta_line = file_content_lines[line_cnt]
    metadata_dict["Headline"] = first_meta_line 
    line_cnt += 1

    #Second line is formatted: [Newspaper Name]
    newspaper_name = file_content_lines[line_cnt]
    metadata_dict["Newspaper Name"] = newspaper_name

    for name_keyword in newspaperNameKeywordList
        if rm_whitespace(lowercase(name_keyword)) == rm_whitespace(lowercase(newspaper_name))
            metadata_dict["Newspaper Name"] = name_keyword
        end
    end
    line_cnt += 1


    #Third line = [Date; inconsistent format and language] [weekday] [time] [AM/PM] [Timezone, default=GMT]
    third_meta_line = file_content_lines[line_cnt]
    metadata_dict = parse_third_meta_line(metadata_dict, third_meta_line)
    line_cnt += 1

    #Fourth line = Copyright notice with publisher mentioned = Discard
    fourth_meta_line = file_content_lines[line_cnt]
    @assert occursin(lowercase("Copyright"), lowercase(fourth_meta_line))
    line_cnt += 1

    #From fifth line = Last metaline OR Body keyword 
    reached_body_section = false

    while !reached_body_section
        c_meta_line = file_content_lines[line_cnt]
        
        if occursin(lowercase("body"), lowercase(c_meta_line))
            if lowercase("body") == rm_whitespace(lowercase(c_meta_line)) #Check if this line contains only the Body keyword
                reached_body_section = true
            else 
                throw(ParseError("Untypical body keyword position"))
            end
        else #Case of just another (informationn containing) metaline
            metadata_dict = parse_last_meta_lines(metadata_dict, c_meta_line)
            reached_body_section = false #Still no end to metadata, maybe; no change
        end

        line_cnt += 1
    end

    #Read out the body lines:
    reached_end_of_body = false
    c_line = file_content_lines[line_cnt]
    metadata_dict["Body"] = ""

    while !reached_end_of_body
        metadata_dict["Body"] *= c_line*"\n"

        line_cnt += 1
        c_line = file_content_lines[line_cnt]
        if occursin(lowercase("Graphic"), lowercase(c_line))
            if lowercase("Graphic") == rm_whitespace(lowercase(c_line))
                reached_end_of_body = true
            #else 
            #    throw(ParseError("Untypical Graphic keyword position"))
            end
        elseif occursin(lowercase("Classification"), lowercase(c_line)) && (occursin(":", file_content_lines[line_cnt+1]) || occursin(rm_whitespace(lowercase(metadata_dict["Headline"])), rm_whitespace(lowercase(file_content_lines[line_cnt+1]))) || occursin(lowercase("End of document"), lowercase(file_content_lines[line_cnt+1])))
            if lowercase("Classification") == rm_whitespace(lowercase(c_line))
                reached_end_of_body = true
            else
                println(rm_whitespace(lowercase(c_line)))
                #throw(ParseError("Untypical classification keyword position"))
            end
        end
    end

    line_cnt += 1 #Jump to newline behind Graphics / Classification keyword
    #Extract from here other Graphic or Classification things if needed

    #Correct for missing values if needed

    return metadata_dict
end

mutable struct Article
    article_id::Int
    filename::String
    headline::String
    newspaper_name::String
    pub_weekday::Int
    pub_day::Int
    pub_month::Int
    pub_year::Int
    word_count::Int 
    author_name::String
    section::String
    body::String
    urn::String
    Article(article_id, filename, headline, newspaper_name, pub_weekday, pub_day, pub_month, pub_year, word_count, author_name, section, body, urn)=new(article_id,filename, headline, newspaper_name, pub_weekday, pub_day, pub_month, pub_year,word_count, author_name, section, body, urn)
 end

function Article(d::Dict)
    return Article(d["Article ID"], d["Filename"], d["Headline"], d["Newspaper Name"], d["Publication Weekday"], d["Publication Day"], d["Publication Month"],d["Publication Year"], d["Word Count"], d["Author Name"], d["Newspaper Section"], d["Body"], d["URN"])
end

function article_to_dict(a::Article)
    return Dict("Article ID" => a.article_id,
             "Filename" => a.filename,
             "Headline" => a.headline, 
             "Newspaper Name" => a.newspaper_name, 
             "Publication Weekday" => a.pub_weekday, 
             "Publication Day" => a.pub_day, 
             "Publication Month" => a.pub_month,
             "Publication Year" => a.pub_year,
             "Word Count" => a.word_count, 
             "Author Name" => a.author_name, 
             "Newspaper Section" => a.section, 
             "Body" => a.body,
             "URN" => a.urn)
end

mutable struct ArticleSet
    label::String
    asArray::Array{Article, 1}
end


function articleset_to_dataframe(articleset::ArticleSet)
    #df = DataFrame(; )
    diclist = []
    for a in articleset.asArray[2:end]
        #push!(df, article_to_dict(a))
        push!(diclist, article_to_dict(a))
    end

    df = vcat(DataFrame.(diclist)...)
    return df
end


function save_articleset_to_excel(articleset::ArticleSet, filepath)
    @assert occursin(lowercase(".XLSX"), lowercase(filepath))
    XLSX.writetable(filepath, articleset_to_dataframe(articleset))
end

function save_articleset_to_csv(articleset::ArticleSet, filepath)
    @assert occursin(lowercase(".csv"), lowercase(filepath))
    CSV.write(filepath, articleset_to_dataframe(articleset))
end

function load_articleset_from_csv(filepath)
    @assert occursin(lowercase(".csv"), lowercase(filepath))
    @assert isfile(filepath)

    df = DataFrame(CSV.File(filepath))

    articleset = ArticleSet("Article Set Label", [])
    for row in 1:nrow(df)
        article = Article([row, :]...)
        append!(articleset.asArray, [article])
    end

    return articleset
end

function extract_from_file(filepath)
    @assert occursin(lowercase(".txt"), lowercase(filepath))
    @assert isfile(filepath)

    supportedEncodings = encodings() #[enc"UTF-8", enc"UTF-16", enc"ANSI"]
    foundEncoding = false
    encoding_idx = 0

    while !foundEncoding
        encoding_idx += 1
        @show Encoding(supportedEncodings[encoding_idx])

        try
        open(filepath, "r") do file
            file_content = lowercase(join(readlines(file, Encoding(supportedEncodings[encoding_idx]))))
        
            if occursin("body", file_content) && occursin("classification", file_content)
                foundEncoding =  true
            end
        end
        catch
            continue
        end
    end

    @show encoding_idx, Encoding(supportedEncodings[encoding_idx])

    article = nothing

    open(filepath, "r") do file    
        article = Article(extract_metadata(file, filepath, Encoding(supportedEncodings[encoding_idx])))
        #@show article
    end

    return article
end

function extract_from_fileset(datafiles_dir)
    filenames = filter(contains(".txt"), readdir(datafiles_dir))
    
    articleset = ArticleSet("Article Set Label", []) 

    for (i, filename) in enumerate(filenames)
        println("Processing $i of $(length(filenames))... $filename")
        article = extract_from_file(datafiles_dir*filename)
        append!(articleset.asArray, [article])
    end

    return articleset
end


function main()
    #datafiles_dir = "/mnt/s/Sync/University/20212022_EPQS/data_files/national_newspapers_09-21/complete_data/txt/"
    #datafiles_dir = "/mnt/s/Sync/University/20212022_EPQS/data_files/national_newspapers_09-21/complete_data/2022_singledout/txt/"
    #datafiles_dir = "/mnt/c/Users/trothe/Downloads/test_box/txt/"
    #datafiles_dir = "/mnt/s/OneDrive - Universiteit Leiden/QSTDN_Quantum&Society/data/national_newspapers_09-21/pilot_coding_data/_2022_postselected/txt/"
    datafiles_dir = "/mnt/s/OneDrive - Universiteit Leiden/QSTDN_Quantum&Society/data/national_newspapers_09-21/post_selection_data/txt/"
    
    #extract_from_file("/mnt/c/Users/trothe/Desktop/1208_#_510F-5X61-JC8W-Y291.txt")
    #extract_from_file("/mnt/c/Users/trothe/Downloads/test_box/txt/3_#_64DN-XT21-JC8X-623B.txt")
    articleset = extract_from_fileset(datafiles_dir)
    save_articleset_to_excel(articleset, datafiles_dir*"PSSet.xlsx")
end

main()

