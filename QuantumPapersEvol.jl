using HTTP
using JSON3
using CSV
using DataFrames
using Plots

function get_api_key()
    api_key = "1b5bcf475c3bae6b4e906c8e90a045f5ca727e1006e6c94daf6eb9cfe541846a"
    return api_key
end


function call_serpapi(query, year)
    params = [
        "engine" => "google_scholar",
        "q"=> query,
        "as_ylo"=> year,
        "as_yhi"=> year,
        "api_key"=> get_api_key()
    ]

    uri = "https://serpapi.com/search.json?"

    result = HTTP.get(uri, query = params)

    json_result = JSON3.read(result.body)
    return json_result
end


function gscholar_main()
    years = range(1998, 2020, step=1)
    total_results_per_year = []
    for year in years
        result = call_serpapi("quantum technology", year)
        println(result["search_information"]["total_results"])
        append!(total_results_per_year, result["search_information"]["total_results"])
    end
    plot(years, total_results_per_year)
    df = DataFrame(Dict("years" =>years, "total_search_results_per_year" =>total_results_per_year))
    CSV.write("gscholar_search_quantumtech_evol.csv", df)
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

gscholar_main()
#load_and_plot()
