using CSV
using DataFrames
using Pipe: @pipe

using FloatingTableView

# dirContents = readdir("../../data/unprocessed/", join=true)
dirContents = readdir("../../data/", join=true)

#######################################################################################################################################
# Drive peril by krnxprs

function excess_yards(distance, yards_gained)
    excess_yard = yards_gained - distance
    excess_yard > 0 ? excess_yard : 0
end

dirContents[313]
df = CSV.read(dirContents[313], DataFrame; normalizenames=true)

df
# browse(df)
unique(df.Play_type)

begin
    df_alabama = filter(:Offense => ==("Alabama"), df)
    df_alabama = select(df_alabama, [:Offense, :Play_type, :Yards_to_goal, :Down, :Distance, :Yards_gained])
    df_alabama = filter(:Play_type => !=("Penalty"), df_alabama)
    df_alabama = filter(:Play_type => !=("End Period"), df_alabama)
    df_alabama = filter(:Play_type => !=("End of Regulation"), df_alabama)
    df_alabama = filter(:Play_type => !=("End of Game"), df_alabama)
    df_alabama = filter(:Play_type => !=("Field Goal Missed"), df_alabama)
    df_alabama = filter(:Play_type => !=("Timeout"), df_alabama)
    df_alabama = filter(:Play_type => !=("End of Half"), df_alabama)
    df_alabama = filter(:Play_type => !=("Fumble Recovery (Opponent)"), df_alabama)
    df_alabama = filter(:Play_type => !=("Punt"), df_alabama)
    df_alabama = filter(:Play_type => !=("Blocked Punt"), df_alabama)
    df_alabama = filter(:Play_type => !=("Punt Return Touchdown"), df_alabama)
    df_alabama = filter(:Play_type => !=("Blocked Punt Touchdown"), df_alabama)
    df_alabama = filter(:Play_type => !=("Field Goal Good"), df_alabama)
    df_alabama = filter(:Play_type => !=("Blocked Field Goal"), df_alabama)
    df_alabama = filter(:Play_type => !=("Blocked Field Goal Touchdown"), df_alabama)
    df_alabama = filter(:Play_type => !=("Missed Field Goal Return"), df_alabama)
    df_alabama = filter(:Play_type => !=("Missed Field Goal Return Touchdown"), df_alabama)
    df_alabama = filter(:Play_type => !=("Kickoff"), df_alabama)
    df_alabama = filter(:Play_type => !=("Kickoff Return Touchdown"), df_alabama)
    df_alabama = filter(:Play_type => !=("Kickoff Return (Offense)"), df_alabama)
    df_alabama = filter(:Play_type => !=("Uncategorized"), df_alabama)
    df_alabama = filter(:Play_type => !=("placeholder"), df_alabama)
    df_alabama = filter(:Play_type => !=("Defensive 2pt Conversion"), df_alabama)
    df_alabama = filter(:Play_type => !=("Two Point Pass"), df_alabama)
    df_alabama = filter(:Play_type => !=("Two Point Rush"), df_alabama)
    # df_alabama = filter(:Yards_to_goal => >=(10), df_alabama)
end
begin
    df_alabama_nonperil = filter(:Play_type => !=("Interception Return Touchdown"), df_alabama)
    df_alabama_nonperil = filter(:Play_type => !=("Interception"), df_alabama_nonperil)
    df_alabama_nonperil = filter(:Play_type => !=("Fumble Return Touchdown"), df_alabama_nonperil)
    df_alabama_nonperil = filter(:Play_type => !=("Pass Interception Return"), df_alabama_nonperil)
end



# browse(df_alabama)

first_down = sum(filter(:Down => ==(1), df_alabama_nonperil).Yards_gained)
second_down = sum(filter(:Down => ==(2), df_alabama_nonperil).Yards_gained)
# first_second = first_down + second_down



df_third_down = filter(:Down => ==(3), df_alabama_nonperil)
df_third_down = transform(df_third_down, [:Distance, :Yards_gained] => ByRow(excess_yards) => :Excess_yards)

df_fourth_down = filter(:Down => ==(4), df_alabama_nonperil)
df_fourth_down = transform(df_fourth_down, [:Distance, :Yards_gained] => ByRow(excess_yards) => :Excess_yards)

third_down = sum(df_third_down.Excess_yards)
fourth_down = sum(df_fourth_down.Excess_yards)

non_peril = first_down + second_down + third_down + fourth_down

total_yards_gained = sum(df_alabama.Yards_gained)

filter(:Down => ==(3), df_alabama).Distance
perilous_yards = sum(filter(:Down => ==(3), df_alabama).Distance)

nominal_peril_yards_ratio = 0.1764705882

peril_yards_ratio = perilous_yards/non_peril

drive_peril = peril_yards_ratio/nominal_peril_yards_ratio

print("Total yds gained: $total_yards_gained
1st & 2nd yds gained: $(first_down + second_down)
3rd & 4th yds gained: $(third_down + fourth_down)
3rd yds to go: $perilous_yards
3rd & 4th yds excess: $third_down
3rd & 4th yds non-excess: $(third_down-perilous_yards)
3rd snaps: $(nrow(df_third_down))
Non-peril yards gained: $(total_yards_gained - (third_down-perilous_yards))
Peril yards ratio: $peril_yards_ratio
Drive peril: $drive_peril
")







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