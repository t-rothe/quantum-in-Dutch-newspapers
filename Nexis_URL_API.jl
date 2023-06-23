using HTTP
using JSON
using JSON3
using CSV
using DataFrames
using Plots

function get_api_key()
    api_key = "1b5bcf475c3bae6b4e906c8e90a045f5ca727e1006e6c94daf6eb9cfe541846a"
    return api_key
end

function call_nexisurlapi_search(query, year)
    params = [
        "q"=> query,
        "collection" => "news",
        "startdate"=> year,
        "enddate"=> year,
        #"source" => ""
    ]

    uri = "http://advance.lexis.com/api/search?"

    auth_params =  [
        "userid"=> "t.rothe@umail.leidenuniv.nl",
        "password" => "62SBUcDUK3gnyQGqCoh",
    ]

    auth_uri = "https://signin.lexisnexis.com/lnaccess/app/signin?back=https%3A%2F%2Fadvance.lexis.com%3A443%2Fnexis-uni%2Flaapi%2Fresearch%2Fhome%3Fcontext%3D1516831%26primaryipauth%3Dtrue&aci=nu"

    result = HTTP.request("POST", auth_uri, [],  JSON.json(auth_params))
    print(result)
    sleep(1000)
    gotnoresult = true
    while gotnoresult
        result = HTTP.get(uri, query = params)
        println(JSON3.read(result.body))
        sleep(200)
        if contains(result.body, "Sign In")

        end
    end

    println(result)
    json_result = JSON3.read(result.body)
    return json_result
end

function call_nexisurlapi_document(doc_urn)
    params = [
        "collection" => "news",
        "id" => "urn:contentItem:"+doc_urn,
        "api_key"=> get_api_key()
    ]

    uri = "http://advance.lexis.com/api/search?"

    result = HTTP.get(uri, query = params)
    println(result.body)
    json_result = JSON3.read(result.body)
    return json_result
end

call_nexisurlapi_search("quantum*", 2006)


function nexis_main()
    years = range(1990, 2022, step=1)
    total_results_per_year = []
    for year in years
        result = call_nexisurlapi_search("quantum*", year)
        println(result["search_information"]["total_results"])
        #append!(total_results_per_year, result["search_information"]["total_results"])
    end
    plot(years, total_results_per_year)
    df = DataFrame(Dict("years" =>years, "total_search_results_per_year" =>total_results_per_year))
    CSV.write("gscholar_search_quantum_evol.csv", df)
end

function load_and_plot()
    gs_df = DataFrame()
    gs_df = DataFrame(CSV.File("gscholar_search_quantum_evol.csv"))
    #CSV.read("gscholar_search_quantum_evol.csv",df)
    arxiv_df = DataFrame(CSV.File("arxiv_search_quantum_evol.csv"))
    println(gs_df)
    println(arxiv_df)
    plt = plot(gs_df[!, "years"], gs_df[!, "total_search_results_per_year"])
    plot!(arxiv_df[!, "years"], arxiv_df[!, "total_search_results_per_year"])
    display(plt)
end

#nexis_main()
#load_and_plot()
