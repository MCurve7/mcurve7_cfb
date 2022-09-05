using CSV
using DataFrames
using Pipe: @pipe

import FloatingTableView

dirContents = readdir("../../data/unprocessed/", join=true)

#######################################################################################################################################
# Find all lines whose Play_type == "Uncategorized" or "placeholder"
##########
# t = CSV.read(dirContents[1], DataFrame; normalizenames=true)
# t[1,:]
# FloatingTableView.browse(t)

# split(dirContents[1],"/")[5]

# filter(x -> any(occursin.(["Rush", "Kickoff"], x.Play_type)), t)

uncat_df = DataFrame()
games_found = []
for game in dirContents
    println(game)
    df = CSV.read(game, DataFrame; normalizenames=true)
    t = filter(x -> any(occursin.(["Uncategorized", "placeholder", "0"], x.Play_type)), df)
    if nrow(t) > 0
        # println("game: $(game)")
        t_len = nrow(t)
        push!(games_found, split(game,"/")[5])
        for i in 1:t_len-1
            push!(games_found, "")
        end
        uncat_df = vcat(uncat_df, t)
    end
end
uncat_df = hcat(uncat_df, DataFrame(:File => games_found))

# uncat_df
# games_found
CSV.write("../../data/corrections/uncat.csv", uncat_df)



#######################################################################################################################################

df = @pipe DataFrame(CSV.File(dirContents[1])) |> filter(:Offense => x->x=="", _)
team = "Alabama"

for game in dirContents
    if occursin(team,game) && occursin("2021",game)
        g = DataFrame(CSV.File(game))
        df = vcat(df, g)
    end 
end
df

df = @pipe dropmissing(df[:, [Symbol("Penalty team"), Symbol("Penalty type")]]) |> filter(Symbol("Penalty team") => x->(x==team), _)


bama_pis = nrow(filter(Symbol("Penalty type") => x->(x=="Defensive Pass Interference" || x == "Pass Interference"), df))
bama_total = nrow(df)
bama = bama_pis/bama_total

#######################################################################################################################################

df = @pipe DataFrame(CSV.File(dirContents[1])) |> filter(:Offense => x->x=="", _)
team = "Auburn"

for game in dirContents
    if occursin(team,game) && occursin("2021",game)
        g = DataFrame(CSV.File(game))
        df = vcat(df, g)
    end 
end
df

df = @pipe dropmissing(df[:, [Symbol("Penalty team"), Symbol("Penalty type")]]) |> filter(Symbol("Penalty team") => x->(x==team), _)

barn_pis = nrow(filter(Symbol("Penalty type") => x->(x=="Defensive Pass Interference" || x == "Pass Interference"), df))
barn_total = nrow(df)
barn = barn_pis/barn_total



FloatingTableView.browse(df)

#######################################################################################################################################
game = dirContents[180]
g = DataFrame(CSV.File(game))
dropmissing!(g, Symbol("Play text"))


df = DataFrame(Defense = [], Offense = [], Text = [])
for game in dirContents
    println(game)
    g = DataFrame(CSV.File(game))
    dropmissing!(g, Symbol("Play text"))
    for i in 1:nrow(g)
        #println(g[i, "Play text"])
        if occursin(r"[Pp]enalty", g[i, "Play text"])
            o = g[i, :Offense]
            d = g[i, :Defense]
            t = g[i, Symbol("Play text")]
            dft = DataFrame(Offense = [o], Defense = [d], Text = [t])
            df = vcat(df, dft)
        end
    end
end
df
unique!(df)
CSV.write("all_penalties.csv", df)

#######################################################################################################################################
df

df_off = DataFrame(Defense = [], Offense = [], Text = [])
df_dec = DataFrame(Defense = [], Offense = [], Text = [])
df_acc = DataFrame(Defense = [], Offense = [], Text = [])

for i in 1:nrow(df)
    println("i = $i of $(nrow(df))")
    if occursin(r"[Oo]ff-?setting", df[i, "Text"])
        o = df[i, :Offense]
        d = df[i, :Defense]
        t = df[i, Symbol("Text")]
        dft = DataFrame(Offense = [o], Defense = [d], Text = [t])
        df_off = vcat(df_off, dft)
    elseif occursin(r"[Dd]eclined", df[i, "Text"])
        o = df[i, :Offense]
        d = df[i, :Defense]
        t = df[i, Symbol("Text")]
        dft = DataFrame(Offense = [o], Defense = [d], Text = [t])
        df_dec = vcat(df_dec, dft)
    else
        o = df[i, :Offense]
        d = df[i, :Defense]
        t = df[i, Symbol("Text")]
        dft = DataFrame(Offense = [o], Defense = [d], Text = [t])
        df_acc = vcat(df_acc, dft)
    end
end

nrow(df_off)+nrow(df_dec)+nrow(df_acc)

df_off
df_dec
df_acc

CSV.write("all_penalties_off.csv", df_off)
CSV.write("all_penalties_dec.csv", df_dec)
CSV.write("all_penalties_acc.csv", df_acc)