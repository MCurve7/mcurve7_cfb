using CSV
using DataFrames
using Printf

dirContents = readdir("../../data/", join=true)

team = "Vanderbilt"
seasonType = "regular"
year = 2021

#file = team*"_"*string(year)*"_wk"*@sprintf("%02d", 1)*"_"*seasonType*".csv"

teamFiles = String[]
for i in 1:13
    file = team*"_"*string(year)*"_wk"*@sprintf("%02d", i)*"_"*seasonType*".csv"
    push!(teamFiles, "../../data/"*file)
end
#teamFiles

teamdf = CSV.read("../../data/FBS/blank.csv", DataFrame)
for f in dirContents
    if(isfile(f))
        if(f in teamFiles)
            dfNew = CSV.read(f, DataFrame) 
            teamdf=vcat(teamdf, dfNew)
        end
    end
end


#size(teamdf)


CSV.write("../../data/all_games/"*team*"_"*string(year)*"_all_games.csv", teamdf)