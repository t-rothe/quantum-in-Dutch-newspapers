############################### 
Part of the Quantum Science & Technology in Dutch Newspapers (QSTDN) project

#####################

Note: This script is constructed to catch many of the layouting inconsisenties resulting from converting NexisUni .pdf files to .txt. Nevertheless, some layouting errors will let the script crash, particularly when linebreaks are misssing linebreaks. The script logs, however, always show the last considered article ID such that the .txt files can be corrected by hand. If the metadata can't be determined with certainty, the script will crash such that the correctness of extracted metadata is ensured. 

using FileIO
using CSV
using DataFrames
using Plots


weekdayCoding = ["maandag" => 1,
"monday" => 1,
"dinsdag" => 2,
"tuesday" => 2,
"woensdag" => 3,
"wednesday" => 3,
"donderdag" => 4,
"thursday" => 4,
"vrijdag" => 5,
"friday" => 5,
"zaterdag" => 6,
"saturday" => 6,
"zondag" => 7,
"sunday" => 7,
]

newspaperNameCoding =  ["NRC" => "a",
"NRC.nl" => "a",
"de Volkskrant" => "b",
"de Volkskrant.nl" => "b",
"Trouw" =>"c",
"Trouw.nl" => "c",
"AD/Algemeen Dagblad" => "c",
"AD/Algemeen Dagblad.nl" => "c",
"De Telegraaf" => "d",
"De Telegraaf.nl" => "d",
"Het Parool" => "e",
"Het Parool.nl" => "e",
]


function parse_second_meta_line(dataset, second_meta_line)
    weekday_idx = [] #First and last indices of the respective features in the line-string
    day_idx = []
    month_idx = []
    newspaper_name_idx = []

    for key in keys(weekdayCoding)
        if occursin(lowercase(key), lowercase(second_meta_line))
            weekday_idx_range = findfirst(lowercase(key), lowercase(second_meta_line)) 
            weekday_idx = [first(weekday_idx_range), last(weekday_idx_range)]
            dataset["Weekday"] = weekdayCoding[weekday_idx]
        end
    end

    for key in keys(dayCoding)
        if occursin(lowercase(key), lowercase(second_meta_line))
            day_idx_range = findfirst(lowercase(key), lowercase(second_meta_line)) 
            day_idx = [first(day_idx_range), last(day_idx_range)]
            dataset["Day"] = dayCoding[day_idx]
        end
    end

    for key in keys(monthCoding)
        if occursin(lowercase(key), lowercase(second_meta_line))
            month_idx_range = findfirst(lowercase(key), lowercase(second_meta_line)) 
            month_idx = [first(month_idx_range), last(month_idx_range)]
            dataset["Month"] = monthCoding[month_idx]
        end
    end

    for key in keys(yearCoding)
        if occursin(lowercase(key), lowercase(second_meta_line))
            year_idx_range = findfirst(lowercase(key), lowercase(second_meta_line)) 
            year_idx = [first(year_idx_range), last(year_idx_range)]
            dataset["Year"] = yearCoding[year_idx]
        end
    end

    #compare position of day and month
    if day_idx[1] < month_idx[1] 
        newspaper_name_idx = [1:day_idx[1] - 2]
    else
        newspaper_name_idx = [1:month_idx[1] - 2]
    end

    newspaper_name = second_meta_line[newspaper_name_idx[1]:newspaper_name_idx[2]]
    dataset["Newspaper Name"] = newspaper_name
    rm_whitespace(input) = filter(x -> !isspace(x), input)
    for key in keys(newspaperNameCoding)
        if rm_whitespace(lowercase(key)) == rm_whitespace(lowercase(newspaper_name))
            dataset["Newspaper Name"] = newspaperNameCoding[key]
        end
    end

    return dataset
end

function parse_last_meta_lines(dataset, meta_line)
    newspaper_section_idx = []
    author_name_idx = []
    article_length = []
    
    #If body keyword occurs at end of line, cut it out to prevent inserting it to the dataset
    if occursin(lowercase("body"), lowercase(meta_line))
        cutoff_idx = first(findfirst(lowercase("Body"), lowercase(meta_line)))
        meta_line = meta_line[1:cutoff_idx-2] #Remove body keyword + 1 whitespace character
    

    #Check which features/information occurs in this metaline:
    if !(split(meta_line, "Section: ", keepempty=false)[end] == meta_line) #Only consider if section information exists in line
        remain_line = split(meta_line, "Section: ")[2] #everything beyond the section keyword
        
        remain_line_components = split(remain_line, " ")
        next_feature_idx = findfirst(contains(':'), remain_line_components)
        if next_feature_idx === nothing
            remain_line = remain_line
        else
            remain_line = join(remain_line_components[1:next_feature_idx-1], " ")
        end

        values = split(remain_line, "; ", keepempty=false) #If multiple values mentioned, split into an array
        dataset["Newspaper Section"] = values[1] #Only store the first section mentioned
    end
    
    #findfirst(lowercase("Byline:"), lowercase(second_meta_line))
    #findfirst(lowercase("Section:"), lowercase(second_meta_line))
    #findfirst(lowercase("Length:"), lowercase(second_meta_line))
    
    return dataset
end

function main()
    dataset = DataFrame(["Article URN" => String[],
                        "Coder" => Int[], 
                        "Newspaper Name" => String[],
                        )


    open("./testfiles/_Jongeren in sociale netwerken_ en zes andere onderzoeksprogramma_s krijgen samen 142 miljoen euro a.txt",
    "r") do file
        line_cnt = 0        

        #First line is always Newspaper headline:
        first_meta_line = readlines(file)[1]
        dataset["Headline"] = first_meta_line 
        line_cnt += 1

        #Second line is formatted: [Newspaper Name] [Date; inconsitent format and language] [weekday] [time] [AM/PM] [Timezone, default=GMT]
        second_meta_line = readlines(file)[2]
        dataset = parse_second_meta_line(dataset, second_meta_line)
        line_cnt += 1

        #Third line = Copyright notice with publisher mentioned = Discard
        line_cnt += 1

        #Fourth line is formatted: [Length in words] [Author; feature called "Byline"] [Sometimes newspaper section and other stuff mentioned] Body
        fourth_meta_line = readlines(file)[4]
        dataset = parse_last_meta_lines(dataset, fourth_meta_line)
        line_cnt += 1

        reached_body_section = occursin(lowercase("body"), lowercase(fourth_meta_line))
        
        #From fifth line = Last metaline OR Body keyword OR start of actual body text if "body" mentioned at end of last line
        line_cnt += 1

        while !reached_body_section
            c_meta_line = readlines(file)[line_cnt]

            if lowercase("body") == lowercase(c_meta_line) #Check if this line contains only the Body keyword
                reached_body_section = true
            elseif occursin(lowercase("body"), lowercase(c_meta_line)) #Check if this is the last metaline before the body
                dataset = parse_last_meta_lines(dataset, c_meta_line) #Parse this last info to dataset
                reached_body_section = true
            else #Case of just another (informationn containing) metaline
                dataset = parse_last_meta_lines(dataset, c_meta_line)
                reached_body_section = false #Still no end to metadata, maybe; no change
            end

            line_cnt += 1
            end
        end
       
        #Catch automatic matched subject keywords at end of file if existent (to be corrected manually!)
        
    end
    
end

main()