using FileIO
using CSV
using DataFrames
using StringEncodings

newspaperNameKeywordList =  ["NRC Handelsblad","de Volkskrant", "Trouw", "AD/Algemeen Dagblad", "De Telegraaf", "Het Parool"]

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
"donderdag" => 4, "thursday" => 4,
"vrijdag" => 5, "friday" => 5,
"zaterdag" => 6, "saturday" => 6,
"zondag" => 7, "sunday" => 7,
)

dayCoding = merge(Dict(" $d " => d for d in range(1, 31, step=1)), Dict(" $d," => d for d in range(1, 31, step=1)))
yearCoding = Dict("$y" => y for y in range(1990, 2022,step=1))

rm_whitespace(input) = filter(x -> !isspace(x), input)


function parse_second_meta_line(metadata_dict, second_meta_line)
    weekday_idx = [] #First and last indices of the respective features in the line-string
    day_idx = []
    month_idx = []
    newspaper_name_idx = []

    for key in keys(weekdayCoding)
        if occursin(lowercase(key), lowercase(second_meta_line))
            weekday_idx_range = findfirst(lowercase(key), lowercase(second_meta_line)) 
            weekday_idx = first(weekday_idx_range):last(weekday_idx_range)
            metadata_dict["Weekday"] = weekdayCoding[lowercase(second_meta_line[weekday_idx])]
        end
    end

    for key in keys(dayCoding)
        if occursin(lowercase(key), lowercase(second_meta_line))
            day_idx_range = findfirst(lowercase(key), lowercase(second_meta_line)) 
            day_idx = first(day_idx_range):last(day_idx_range)
            metadata_dict["Day"] = dayCoding[lowercase(second_meta_line[day_idx])]
        end
    end

    for key in keys(monthCoding)
        if occursin(lowercase(key), lowercase(second_meta_line))
            month_idx_range = findfirst(lowercase(key), lowercase(second_meta_line)) 
            month_idx = first(month_idx_range):last(month_idx_range)
            metadata_dict["Month"] = monthCoding[lowercase(second_meta_line[month_idx])]
        end
    end

    for key in keys(yearCoding)
        if occursin(lowercase(key), lowercase(second_meta_line))
            year_idx_range = findfirst(lowercase(key), lowercase(second_meta_line)) 
            year_idx = first(year_idx_range):last(year_idx_range)
            metadata_dict["Year"] = yearCoding[lowercase(second_meta_line[year_idx])]
        end
    end

    #Compare position of day, month and weekday to catch string position of newspaper name
    newspaper_name_idx = [1, min(first(day_idx), first(weekday_idx), first(month_idx)) - 1]

    newspaper_name = second_meta_line[first(newspaper_name_idx):last(newspaper_name_idx)]
    
    metadata_dict["Newspaper Name"] = newspaper_name

    for name_keyword in newspaperNameKeywordList
        if rm_whitespace(lowercase(name_keyword)) == rm_whitespace(lowercase(newspaper_name))
            metadata_dict["Newspaper Name"] = name_keyword
        end
    end

    return metadata_dict
end

function parse_last_meta_lines(metadata_dict, meta_line)
    newspaper_section_idx = []
    author_name_idx = []
    article_length = []
    
    #If body keyword occurs at end of line, cut it out to prevent inserting it to the metadata
    if occursin(lowercase("Body"), lowercase(meta_line))
        cutoff_idx = first(findfirst(lowercase("Body"), lowercase(meta_line)))
        meta_line = meta_line[1:cutoff_idx-2] #Remove body keyword + 1 whitespace character
    end

    #Check which features/information occurs in this metaline:
    feature_indicator_pairs = [("Newspaper Section", "Section: "), ("Author Name", "Byline: "), ("Word Count", "Length: ")]
    for (feature, indicator) in feature_indicator_pairs
        if !(split(meta_line, indicator, keepempty=false)[end] == meta_line) #Only consider if section information exists in line
            remain_line = split(meta_line, indicator)[2] #everything beyond the section keyword
            
            remain_line_components = split(remain_line, " ")
            next_feature_idx = findfirst(contains(':'), remain_line_components)
            if next_feature_idx === nothing #i.e. No other feature exists in this line
                remain_line = remain_line
            else # If other feature exists cutt out the string part before its indicator.
                remain_line = join(remain_line_components[1:next_feature_idx-1], " ")
            end

            if feature == "Word Count"
                metadata_dict[feature] = parse(Int, split(lowercase(rm_whitespace(remain_line)), "w")[1]) #Get rid of the "words" substrang
            else
                values = split(remain_line, "; ", keepempty=false) #If multiple values for this feature mentioned, split into an array
                metadata_dict[feature] = values[1] #Only store the first value that is mentioned
            end
        end
    end
    #findfirst(lowercase("Byline: "), lowercase(second_meta_line))
    #findfirst(lowercase("Section:"), lowercase(second_meta_line))
    #findfirst(lowercase("Length:"), lowercase(second_meta_line))
    
    return metadata_dict
end

function extract_metadata(file, encoding)
    metadata_dict = Dict()

    file_content_lines = readlines(file, encoding) #readlines(file, keep=false)

    line_cnt = 1        

    #First line is always Newspaper headline:
    first_meta_line = file_content_lines[line_cnt]
    metadata_dict["Headline"] = first_meta_line 
    line_cnt += 1

    #Second line is formatted: [Newspaper Name] [Date; inconsistent format and language] [weekday] [time] [AM/PM] [Timezone, default=GMT]
    second_meta_line = file_content_lines[line_cnt]
    metadata_dict = parse_second_meta_line(metadata_dict, second_meta_line)
    line_cnt += 1

    #Third line = Copyright notice with publisher mentioned = Discard
    third_meta_line = file_content_lines[line_cnt]
    @assert occursin(lowercase("Copyright"), lowercase(third_meta_line))
    line_cnt += 1

    #Fourth line is formatted: [Length in words] [Author; feature called "Byline"] [Sometimes newspaper section and other stuff mentioned] Body
    fourth_meta_line = file_content_lines[line_cnt]
    metadata_dict = parse_last_meta_lines(metadata_dict, fourth_meta_line)

    #Look whether the fourth line already contains the body keyword
    reached_body_section = occursin(lowercase("body"), lowercase(fourth_meta_line))
    line_cnt += 1

    #From fifth line = Last metaline OR Body keyword OR start of actual body text if "body" mentioned at end of last line
    metadata_dict["Body"] = ""
    while !reached_body_section
        c_meta_line = file_content_lines[line_cnt]
        
        if occursin(lowercase("body"), lowercase(c_meta_line))
            if lowercase("body") == lowercase(c_meta_line) #Check if this line contains only the Body keyword
                reached_body_section = true
            elseif first(findfirst(lowercase("body"), lowercase(c_meta_line))) == 1
                line_cnt -= 1
                reached_body_section = true
            elseif last(findlast(lowercase("body"), lowercase(c_meta_line))) == length(c_meta_line)
                metadata_dict = parse_last_meta_lines(metadata_dict, c_meta_line) #Parse this last info to dataset
                reached_body_section = true
            #elseif occursin(lowercase("body"), lowercase(c_meta_line)) #Check if this is the last metaline before the body
            #    metadata_dict = parse_last_meta_lines(metadata_dict, c_meta_line) #Parse this last info to dataset
            #    reached_body_section = true
            else
                metadata_dict["Body"] = split(c_meta_line, "Body")[end]
                reached_body_section = true
            end
        else #Case of just another (informationn containing) metaline
            metadata_dict = parse_last_meta_lines(metadata_dict, c_meta_line)
            reached_body_section = false #Still no end to metadata, maybe; no change
        end

        line_cnt += 1
    end

    #Now we read out the body lines:
    reached_end_of_body = false
    c_line = file_content_lines[line_cnt]
    

    while !reached_end_of_body
        metadata_dict["Body"] *= c_line*"\n"

        line_cnt += 1
        c_line = file_content_lines[line_cnt]
        if occursin(lowercase("Graphic"), lowercase(c_line))
            if first(findfirst(lowercase("Graphic"), lowercase(c_line))) == 1
                reached_end_of_body = true
            elseif last(findlast(lowercase("Graphic"), lowercase(c_line))) == length(c_line)
                metadata_dict["Body"] *= c_line[1:length(c_line) - length(" Graphic")]
                reached_end_of_body = true
            else
                metadata_dict["Body"] *= split(c_line, "Graphic")[1]
                reached_end_of_body = true
                #throw(ParseError("Untypical End of Body found"))
            end
        elseif occursin(lowercase("Classification"), lowercase(c_line)) && (occursin(":", file_content_lines[line_cnt]) || occursin(":", file_content_lines[line_cnt+1]) || occursin(lowercase("End of document"), lowercase(file_content_lines[line_cnt+1])) || occursin("Page", file_content_lines[line_cnt+1]))
            if first(findfirst(lowercase("Classification"), lowercase(c_line))) == 1
                reached_end_of_body = true
            elseif last(findlast(lowercase("Classification"), lowercase(c_line))) == length(c_line)
                metadata_dict["Body"] *= c_line[1:length(c_line) - length(" Classification")]
                reached_end_of_body = true
            else
                metadata_dict["Body"] *= split(c_line, "Classification")[1]
                reached_end_of_body = true
                #throw(ParseError("Untypical End of Body found"))
            end
        end
    end

    line_cnt += 1 #Jump to newline behind Graphics / Classification keyword
    #Extract from here other Graphic or Classification things if needed

    #Correct for missing values:
    if "Author Name" != keys(metadata_dict)
        metadata_dict["Author Name"] = ""
    end

    return metadata_dict
end

mutable struct Article 
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
    Article(headline, newspaper_name, pub_weekday, pub_day, pub_month, pub_year, word_count, author_name, section, body)=new(headline, newspaper_name, pub_weekday, pub_day, pub_month, pub_year,word_count, author_name, section, body)
 end

function Article(d::Dict)
    return Article(d["Headline"], d["Newspaper Name"], d["Weekday"], d["Day"], d["Month"],d["Year"], d["Word Count"], d["Author Name"], d["Newspaper Section"], d["Body"])
end

function extract_from_file(filepath)
    @assert occursin(lowercase(".txt"), lowercase(filepath))
    
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
        article = Article(extract_metadata(file, Encoding(supportedEncodings[encoding_idx])))
        @show article
    end

    return article
end

function extract_from_fileset(datafiles_dir)
    filenames = filter(contains(".txt"), readdir(datafiles_dir))
    
    article_set = []

    for filename in filenames
        println("Processing ... $filename")
        article = extract_from_file(datafiles_dir*filename)
        append!(article_set, [article])
    end

    return article_set
end

function main()
    #datafiles_dir = "/mnt/s/Sync/University/20212022_EPQS/data_files/national_newspapers_09-21/raw_src/raw_downloads/txt/"
    datafiles_dir = "/mnt/c/Users/trothe/Downloads/txt_temp/"

    #extract_from_file("/mnt/c/Users/trothe/Desktop/1208_#_510F-5X61-JC8W-Y291.txt")
    #extract_from_file("/mnt/c/Users/trothe/Downloads/124_#_61PJ-N221-DYMH-R1WM.txt")
    @show extract_from_fileset(datafiles_dir)
end

main()


"""
function get_duplicates_for_file(file)
    
    file_body = extract_body(file)

    for ... in reduced_filenames
        open
            extract_body()
        end
    end

    println("Found significant overlap between <<  >> and <<  >> with String distance ...")
    duplicates = None
    for any duplicate, add to common tuple or remove from filename_list
    

    return duplicates, reduced_filenames
end
"""