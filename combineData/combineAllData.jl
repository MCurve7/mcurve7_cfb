using CSV
using DataFrames

dirContents = readdir("../../data/", join=true)

#=
# Check to make sure all files have the correct number of columns
wrongSize = String[]
for f in dirContents
    if(isfile(f))
        if(size(CSV.read(f,DataFrame),2) !== 30)
            push!(wrongSize, f)
        end
    end
end
print(wrongSize)
=#

firstFile = popfirst!(dirContents)

df = CSV.read(firstFile, DataFrame) 
for f in dirContents
    if(isfile(f))
        dfNew = CSV.read(f, DataFrame) 
        df=vcat(df, dfNew)
    end
end


size(df)


CSV.write("../../data/all_games/all_games.csv", df)