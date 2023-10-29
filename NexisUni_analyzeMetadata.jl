###############################################################################
# Part of the Quantum Science & Technology in Dutch Newspapers (QSTDN) project
###############################################################################
# By Thomas Rothe 
# Copyright (c) 2022 Leiden University
################################################################################
# Plotting / Visualization methods for metadata extracted from NexisUni article-set
# e.g. number of articles per year, per month, per weekday, per newspaper brand, etc.
#
# Requires the accompanying "NexisUni_extractMetaData.jl"-script in the same folder 
# Please take note of the documentation in the "NexisUni_extractMetaData.jl"-script
#


using FileIO
using CSV
using DataFrames
using StringEncodings
using Plots
using StatsPlots

include("NexisUni_extractMetaData.jl")

month_abbrev_list = ["Jan." ,"Feb.", "Mar.", "Apr.", "May", "Jun.", "Jul.", "Aug.", "Sep.", "Oct.", "Nov.", "Dec."]
weekday_abbrev_list = ["Mon.", "Tue.", "Wed.", "Thu.", "Fri.", "Sat.", "Sun."] 

function convert_regex(x::Regex)
    return string(x)[3:end-1]
end
function convert_regex(x::String)
    return x
end

function plot_articlesperyear_for_articleset(articleset::ArticleSet)
    """
    Plot the number of articles per year for a given ArticleSet.
    """

    n_articles_per_year = []

    n_articles = length(articleset.asArray)

    year_list = collect(2009:2021)

    for year in year_list 
        this_year_articleset = filter(a -> a.pub_year == year, articleset.asArray)
        n_articles_this_year = length(this_year_articleset)
        push!(n_articles_per_year, n_articles_this_year)
    end

    @show n_articles_per_year

    plt = bar(year_list, n_articles_per_year, legend = false)
    #plot!(arxiv_df[!, "years"], arxiv_df[!, "total_search_results_per_year"])
    
    title!(plt, "Number of articles per year")
    xticks!(year_list)

    display(plt)

    return plt, n_articles_per_year
end

function plot_articlespermonthandyear_for_articleset(articleset::ArticleSet)
    """
    Plot the number of articles per month for a given ArticleSet.
    """

    n_articles_per_monthandyear = []

    n_articles = length(articleset.asArray)

    year_list = collect(2009:2021)
    month_list = collect(1:12)
    n_months = length(month_list)*length(year_list)
    ticklabels = convert(Array{String}, [])

    for year in year_list
        for month in month_list
            this_year_articleset = filter(a -> a.pub_year == year && a.pub_month == month, articleset.asArray)
            n_articles_this_year = length(this_year_articleset)
            push!(n_articles_per_monthandyear, n_articles_this_year)
            
            #Create plot labels:
            month_label = month_abbrev_list[month]
            tick_label = month_label*" "*string(digits(year)[2])*string(digits(year)[1])
            push!(ticklabels, tick_label)
            @show month_label, tick_label
        end 
    end

    #Plot it!:
    plt = plot(collect(1:n_months), n_articles_per_monthandyear, legend=false, size=(900,500))
    #plot!(arxiv_df[!, "years"], arxiv_df[!, "total_search_results_per_year"])
    title!(plt, "Number of articles per month")
    xticks!(collect(1:n_months)[1:12:end], ticklabels[1:12:end])
    display(plt)
    #savefig(plt, "/mnt/s/Sync/University/20212022_EPQS/data_files/national_newspapers_09-21/figDel.png")
    return plt, n_articles_per_monthandyear
end


function plot_articlespernewspaperbrandperyear_for_articleset(articleset::ArticleSet)
    """
    Plot the number of articles per newspaper brand per year for a given ArticleSet.
    """
    
    n_articles_per_year = Dict()

    n_articles = length(articleset.asArray)

    temp_list = deepcopy(articleset.asArray)

    newspaperbrand_list = newspaperNameKeywordList
    year_list = collect(2009:2021)
    for (ib, brand) in enumerate(newspaperbrand_list)
        n_articles_per_year[brand] = []
        for year in year_list 
            this_year_articleset = filter(a -> a.pub_year == year && a.newspaper_name == brand, articleset.asArray)
            n_articles_this_year = length(this_year_articleset)


            if n_articles_this_year != 0
                for art in this_year_articleset
                    temp_idx = findall(el -> el.article_id ==art.article_id, temp_list)
                    deleteat!(temp_list, temp_idx)
                    if brand == "NRC"
                        @show art.filename
                    end
                end
            end
            push!(n_articles_per_year[brand], n_articles_this_year)
        end
    end
    @show temp_list


    #plt = bar(year_list, n_articles_per_year[newspaperbrand_list[1]], label = newspaperbrand_list[1],legend=:topleft, size=(700, 500))
    
    @show sum(sum(collect(values(n_articles_per_year))))

    plotdata = [n_articles_per_year[newspaperbrand_list[1]] n_articles_per_year[newspaperbrand_list[2]]]
    for (ib, brand) in enumerate(newspaperbrand_list[3:end])
        plotdata = hcat(plotdata, n_articles_per_year[brand])
    end

    df = DataFrame(plotdata, newspaperbrand_list)
    @show df
    plt = @df df groupedbar(year_list,cols(1:8),
                bar_position = :stack,
                legend = :topleft,
                size=(700,600),
                xticks=(year_list, string.(year_list)),
                background_color_legend = nothing)

    #for (ib, brand) in enumerate(newspaperbrand_list[2:end])
    #    bar!(plt, year_list, n_articles_per_year[brand], label=brand)
    #end
    #ylims!(plt, (0,84))
    title!(plt, "Number of articles per year for each newspaper brand")

    display(plt)

    #return plt, n_articles_per_year
end

function plot_articlesperweekday_for_articleset(articleset::ArticleSet)
    """
    Plot the number of articles per weekday for a given ArticleSet.
    """

    n_articles_per_weekday = []

    n_articles = length(articleset.asArray)

    weekday_list = collect(1:7)

    for weekday in weekday_list 
        this_weekday_articleset = filter(a -> a.pub_weekday == weekday, articleset.asArray)
        n_articles_this_weekday = length(this_weekday_articleset)
        push!(n_articles_per_weekday, n_articles_this_weekday)
    end

    push!(n_articles_per_weekday, n_articles - sum(n_articles_per_weekday))
    push!(weekday_abbrev_list, "Unknown")
    push!(weekday_list, 8)
    
    plt = bar(weekday_list, n_articles_per_weekday, legend = false)

    #plot!(arxiv_df[!, "years"], arxiv_df[!, "total_search_results_per_year"])
    
    title!(plt, "Number of articles per weekday")
    xticks!(weekday_list, weekday_abbrev_list)

    display(plt)

    return plt, n_articles_per_weekday
end

function plot_averagewordcountpermonth_for_articleset(articleset::ArticleSet)
    """
    Plot the average word count per month for a given ArticleSet.
    """

    av_wordcount_per_monthandyear = []

    n_articles = length(articleset.asArray)

    year_list = collect(2009:2021)
    month_list = collect(1:12)
    n_months = length(month_list)*length(year_list)
    ticklabels = convert(Array{String}, [])

    for (iy, year) in enumerate(year_list)
        for (im, month) in enumerate(month_list)
            temp_articleset = filter(a -> a.pub_year == year && a.pub_month == month, articleset.asArray)
            n_articles_in_temp_set = length(temp_articleset)
            
            temp_average_wordcount = 0
            for article in temp_articleset
                if article.word_count > 1.0
                    temp_average_wordcount += article.word_count
                else
                    n_articles_in_temp_set -= 1 #Exclude from average, word count hasn't been (correctly) extracted. 
                end
            end
            if n_articles_in_temp_set == 0
                temp_average_wordcount = av_wordcount_per_monthandyear[(iy-1)*12 + im - 1]
                #temp_average_wordcount = missing
            else
                temp_average_wordcount /= n_articles_in_temp_set 
            end

            push!(av_wordcount_per_monthandyear,temp_average_wordcount)
            
            #Create plot labels:
            month_label = month_abbrev_list[month]
            tick_label = month_label*" "*string(digits(year)[2])*string(digits(year)[1])
            push!(ticklabels, tick_label)
            
        end 
    end


    #Plot it!:
    plt = plot(collect(1:n_months), av_wordcount_per_monthandyear, legend=false, size=(900,500))
    #plot!(arxiv_df[!, "years"], arxiv_df[!, "total_search_results_per_year"])
    title!(plt, "Average word count per month")
    xticks!(collect(1:n_months)[1:12:end], ticklabels[1:12:end])
    display(plt)
    return plt, av_wordcount_per_monthandyear
end

function plot_averagewordcountperyear_for_articleset(articleset::ArticleSet)
    """
    Plot the average word count per year for a given ArticleSet.
    """

    av_wordcount_per_year = []

    n_articles = length(articleset.asArray)

    year_list = collect(2009:2021)

    for (iy, year) in enumerate(year_list)
        temp_articleset = filter(a -> a.pub_year == year, articleset.asArray)
        n_articles_in_temp_set = length(temp_articleset)
            
        temp_average_wordcount = 0
        for article in temp_articleset
            if article.word_count > 1.0
                temp_average_wordcount += article.word_count
            else
                n_articles_in_temp_set -= 1 #Exclude from average, word count hasn't been (correctly) extracted. 
            end
        end
        if n_articles_in_temp_set == 0
            temp_average_wordcount = av_wordcount_per_year[iy-1]
            #temp_average_wordcount = missing
        else
            temp_average_wordcount /= n_articles_in_temp_set 
        end

        push!(av_wordcount_per_year,temp_average_wordcount)
        
    end


    #Plot it!:
    plt = plot(year_list, av_wordcount_per_year, legend=false, size=(800,500))
    #plot!(arxiv_df[!, "years"], arxiv_df[!, "total_search_results_per_year"])
    title!(plt, "Average word count per year")
    xticks!(year_list)
    display(plt)
    return plt, av_wordcount_per_year
end

function pullAnchor(inputString, anchor, keyword)
    """
    Pull anchorwords from inputString and check if they are within the specified neighborhood of the keyword.
    """

    # Return true/false on whether any of the anchor-words (dict-keys) are within their specified neighborhouds (dict-vals in # of words)
    
    anchorApplied= false 

    #Prepare inputs:
    inputString = replace(inputString, "\n" => " ") #Remove linebreaks.
    splittedInputString = split(inputString, " ")
    filter!(s -> s != ";" && s != ":" && s != "," && s != "." && s != "  " && s != " " && s != "", splittedInputString)

    keyword_locs = findall(occursin.(keyword, lowercase.(splittedInputString)))
    for aw in keys(anchor) #Iterate over anchorwords
        anchorword_locs = findall(occursin.(aw, lowercase.(splittedInputString)))
        for kloc in keyword_locs
            if length(anchorword_locs) != 0
                if minimum(abs.(anchorword_locs .- kloc)) <= anchor[aw]
                    anchorApplied = true
                end
            end
        end
    end
    
    return anchorApplied
end    

function count_wordoccurancies_for_articleset(articleset::ArticleSet, keywordlist, mode, anchor=Dict())
    """
    Count the occurance of the given keywords in the given articleset.
    """

    if mode == :count
		n_articles_per_year = Dict()

		n_articles = length(articleset.asArray)
		n_keywords = length(keywordlist)

		year_list = collect(2009:2021)
		for keyword in keywordlist
			n_articles_per_year[keyword] = []
			for year in year_list 
				this_year_articleset = filter(a -> a.pub_year == year && (occursin(keyword, lowercase(a.headline)) || occursin(keyword, lowercase(a.body))), articleset.asArray)
				n_articles_this_year = length(this_year_articleset)
				#println(this_year_articleset[1].body)
				#println()
				#sleep(1000)
				push!(n_articles_per_year[keyword], n_articles_this_year)
			end
		end
		
		plotdata = []
		if n_keywords == 1
			plotdata = [n_articles_per_year[keywordlist[1]]]
		elseif n_keywords == 2
			plotdata = [n_articles_per_year[keywordlist[1]] n_articles_per_year[keywordlist[2]]]
		elseif n_keywords >= 3
			plotdata = [n_articles_per_year[keywordlist[1]] n_articles_per_year[keywordlist[2]]]
			for (ik, keyword) in enumerate(keywordlist[3:end])
				plotdata = hcat(plotdata, n_articles_per_year[keyword])
			end
		end

		df = DataFrame(plotdata, keywordlist)
		@show df
		plt = @df df groupedbar(year_list,cols(1:n_keywords), bar_position = :dodge,
					legend = :topleft,
					size=(700,600),
					xticks=(year_list, string.(year_list)),
					background_color_legend = nothing)

		title!(plt, "Number of articles per keyword per year")

		display(plt)
	elseif mode == :percent
		percent_articles_per_year = Dict()

		n_articles = length(articleset.asArray)
		n_keywords = length(keywordlist)

		year_list = collect(2009:2021)
		for keyword in keywordlist
			percent_articles_per_year[keyword] = []
			for year in year_list 
				this_year_articleset = filter(a -> a.pub_year == year , articleset.asArray)
				
                this_year_articleset_selected = filter(a -> a.pub_year == year && (occursin(keyword, lowercase(a.headline)) || occursin(keyword, lowercase(a.body))), articleset.asArray)
				if length(keys(anchor)) != 0
                    filter!(a -> (pullAnchor(a.headline, anchor, keyword) || pullAnchor(a.body, anchor, keyword)) , this_year_articleset_selected)
                end

                n_articles_this_year = length(this_year_articleset)
                n_articles_this_year_selected = length(this_year_articleset_selected)
				#println(this_year_articleset[1].body)
				#println()
				#sleep(1000)
				push!(percent_articles_per_year[keyword], 100* n_articles_this_year_selected / n_articles_this_year)
			end
		end
		
		plotdata = []
		if n_keywords == 1
			plotdata = [percent_articles_per_year[keywordlist[1]]]
		elseif n_keywords == 2
			plotdata = [percent_articles_per_year[keywordlist[1]] percent_articles_per_year[keywordlist[2]]]
		elseif n_keywords >= 3
			plotdata = [percent_articles_per_year[keywordlist[1]] percent_articles_per_year[keywordlist[2]]]
			for (ik, keyword) in enumerate(keywordlist[3:end])
				plotdata = hcat(plotdata, percent_articles_per_year[keyword])
			end
		end

		df = DataFrame(plotdata, convert_regex.(keywordlist))
		@show df
		plt = @df df groupedbar(year_list,cols(1:n_keywords), bar_position = :dodge,
					legend = :topright,
					size=(700,600),
					xticks=(year_list, string.(year_list)),
					background_color_legend = nothing)

		title!(plt, "Percentage of articles per keyword per year")
        #ylims!(0, 18)
		display(plt)
	else 
		println("Unknown mode. Either choose percentage or (absolute) count")
	end
end




function main()
    datafiles_dir = "$DATAPATH/national_newspapers_09-21/post_selection_data/txt/"
    
    articleset = extract_from_fileset(datafiles_dir)

    # Uncomment the desired plot-function below:
    #plot_articlesperyear_for_articleset(articleset)
    #plot_articlespermonthandyear_for_articleset(articleset)
    #plot_articlespernewspaperbrandperyear_for_articleset(articleset)
    #plot_articlesperweekday_for_articleset(articleset)
    #plot_averagewordcountpermonth_for_articleset(articleset)
    #plot_averagewordcountperyear_for_articleset(articleset)

    # ------    
    # Keyword counting:
    # ------
    
    #keywordlist = ["kwantum", "quantum"]
    #keywordlist = ["spookachtig", "spooky", r"myst[a-z]{1,12}", "vreemd"]
    #keywordlist = ["superpositie", r"verstrengel[a-z]{1,10}", "verbonden", "afhankelijk"]
    #keywordlist = ["meetprobleem", "meting", r"meet[a-z]{1,12}", r"waarne[a-z]{1,12}"]
    #keywordlist = ["risico", "probleem","gevaar", r"[a-z]{0,4}dreig[a-z]{1,12}"]
    #keywordlist = [r"voorde[a-z]{1,12}", r"[a-z]{0,4}bruik[a-z]{1,12}", r"belang[a-z]{0,12}", "winst", "nut"]
    #keywordlist = ["race", "groei", r"ontwik[a-z]{1,12}"]
    #keywordlist = ["computer", "phone", r"simulat[a-z]{1,12}"]
    #keywordlist = [ "internet" , "netwerk", r"crypt[a-z]{1,12}"]
    keywordlist = ["mri", "laser", "energie", "sensor"]

    anchor = Dict()
    anchor = Dict("quantum" => 30, "kwantum" => 30)
    count_wordoccurancies_for_articleset(articleset::ArticleSet, keywordlist, :percent, anchor)

    println("Succesfully Finished")
end

main()