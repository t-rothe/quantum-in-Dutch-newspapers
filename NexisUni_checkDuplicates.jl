###############################################################################
# Part of the Quantum Science & Technology in Dutch Newspapers (QSTDN) project
###############################################################################
# By Thomas Rothe 
# Copyright (c) 2022 Leiden University
################################################################################
# Takes NexisUni data files with filename in format "[Article ID]_#_[URN].txt"
# and tries to find duplicates in the provided filetree.
# Both the terminal output and the created .txt file give a list of all duplicate pairs of articles with the associated Similarity score/distance.
# 
# CAUTION: Any duplicates found are only candidates and need to be checked manually! 
# The purpose of this script is only to reduce the manual search space for duplicates from Ω(n^2) to Ω(n).
# Testing through multiple metrics and significance levels is an important calibaration step.
# For this project, we chose the significance level always rather conservatively to avoid false-negatives at the cost of false-positives.
#
# Depending on the use case, you may want to change the (default) significance level
#
# Requires the accompanying "NexisUni_extractMetaData.jl"-script in the same folder 
# Please take note of the documentation in the "NexisUni_extractMetaData.jl"-script
#

using FileIO
using CSV
using DataFrames
using StringEncodings
using StringDistances

include("NexisUni_extractMetaData.jl")

function get_duplicates_for_articleset(articleset::ArticleSet, sig_lvl)
    """Returns a list of duplicate candidates for the given articleset. 
    This function was finally NOT used since duplicate canddiates with different publication years can never be actual duplicates.
    Rather use the function get_duplicates_for_articleset_per_year() below to get only duplicates of articles published in the same year.
    """
    duplicates = []
    sim_scores = []

    @assert (sig_lvl > 0.0 && sig_lvl < 1.0)

    # We vary the distance metric here manually to ensure conservative results (s.t. we get rather a longer list of condidates for manual check than missing some duplicates after all)
    distance_metric = Overlap(3) #Should better be symeetric!
    #distance_metric = DamerauLevenshtein()
    #distance_metric = RatcliffObershelp

    n_articles = length(articleset.asArray)
    @assert n_articles > 2

    for (idxA, articleA) in enumerate(articleset.asArray)
        for (idxB, articleB) in enumerate(articleset.asArray[idxA+1:end]) #Only check each article pair once
            idxB += idxA #Correct for shifted index
            #@show idxA, idxB
            
            bodyA = articleA.body
            bodyB = articleB.body
            bodyA = replace(bodyA, "\n" => " ")
            bodyB = replace(bodyB, "\n" => " ")
            bodyA = replace(bodyA, r"\\s+" => " ")
            bodyB = replace(bodyB, r"\\s+" => " ")
            sim_score = compare(bodyA, bodyB, distance_metric)
            @show sim_score

            if sim_score > sig_lvl
                println("Found significant overlap between << $(articleA.filename) >> and << $(articleB.filename) >> with Similarity Score $sim_score")
                append!(duplicates, [(articleA, articleB)])
                append!(sim_scores, [sim_score])
            end
        end
    end

    if length(duplicates) == 0
        duplicates = nothing
        sim_scores = nothing
    end

    return duplicates, sim_scores
end


function get_duplicates_for_articleset_per_year(articleset::ArticleSet, sig_lvl)
    """Returns a list of duplicate candidates for the given articleset, but only those between articles that were published in the same year.
    """
    duplicates = []
    sim_scores = []

    @assert (sig_lvl > 0.0 && sig_lvl < 1.0)

    # We vary the distance metric here manually to ensure conservative results (s.t. we get rather a longer list of condidates for manual check than missing some duplicates after all)
    distance_metric = Overlap(3)
    #distance_metric = DamerauLevenshtein()
    #distance_metric_2 = RatcliffObershelp()
     
    for year in 2009:2021
        println("Checking duplicates for $year ...")
        year_articleset = filter(a -> a.pub_year == year, articleset.asArray)
        @assert length(year_articleset) > 2
        for (idxA, articleA) in enumerate(year_articleset)
            @show year, idxA, length(year_articleset)
            for (idxB, articleB) in enumerate(year_articleset[idxA+1:end]) #Only check each article pair once
                idxB += idxA #Correct for shifted index

                bodyA = articleA.body
                bodyB = articleB.body
                bodyA = replace(bodyA, "\n" => " ")
                bodyB = replace(bodyB, "\n" => " ")
                bodyA = replace(bodyA, r"\\s+" => " ")
                bodyB = replace(bodyB, r"\\s+" => " ")
            
                sim_score = compare(bodyA,bodyB,distance_metric)
                #@show sim_score
                if sim_score > sig_lvl
                    #@show sim_score, articleA.article_id, articleB.article_id
                    #if articleA.article_id >= 2242 || articleB.article_id >= 2242

                    println("Found significant overlap between << $(articleA.filename) >> and << $(articleB.filename) >> with Similarity Score $sim_score")
                    append!(duplicates, [(articleA, articleB)])
                    append!(sim_scores, [sim_score])
                end
            end
        end
    end

    if length(duplicates) == 0
        duplicates = nothing
        sim_scores = nothing
    end

    return duplicates, sim_scores
end


function main()
    datafiles_dir = "$DATAPATH/national_newspapers_09-21/post_selection_data/txt/"
    
    significance_level = 0.4 #Change this to make the duplication check more or less sensitive

    articleset = extract_from_fileset(datafiles_dir)

    duplicates, sim_scores = get_duplicates_for_articleset_per_year(articleset, significance_level)
    #duplicates, sim_scores = get_duplicates_for_articleset(articleset, significance_level)
    
    #@show duplicates
    #@show sim_scores

    
    open(datafiles_dir*"duplicate_candidates_Overlap8_p3.txt", "w") do f
        for (idx, duplicate) in enumerate(duplicates)
          println(f, ("[Article A]: ", duplicate[1].article_id,
                                      duplicate[1].urn, 
                                      duplicate[1].pub_day,
                                      duplicate[1].pub_month,
                                      duplicate[1].pub_year,
                                      duplicate[1].newspaper_name,
                                      duplicate[1].word_count,
                        "[Article B]: ",
                                      duplicate[2].article_id, 
                                      duplicate[2].urn, 
                                      duplicate[2].pub_day,
                                      duplicate[2].pub_month,
                                      duplicate[2].pub_year,
                                      duplicate[2].newspaper_name,
                                      duplicate[2].word_count,
                                      sim_scores[idx]))
        end
    end
    
    println("Succesfully Finished")
end

main()