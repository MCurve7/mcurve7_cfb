using CSV
using DataFrames
using Pipe: @pipe

using FloatingTableView

# dirContents = readdir("../../data/unprocessed/", join=true)
dirContents = readdir("../../data/", join=true)
#######################################################################################################################################
# Make a singel function to parse names no matter their format
name_regex = "((?:(?:[A-Z\\p{Lu}'-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+|(?:de))|(?:[A-Z\\p{Lu}-]\\.?)?\\s?)+)" #most general name regex
name_simple_regex = "((?:[A-Z\\p{Lu}'-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+ ?)+)"
name_regex_nc = "(?:((?:[A-Z\\p{Lu}'-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+|(?:de))|(?:[A-Z\\p{Lu}-]\\.?)?\\s?)+)" #non-capturing
# name_lastfirst_regex = "([A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+,\\s*[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+)" #just madeit work need to genalize it last first
name_lastfirst_regex = "([A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+,\\s*[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+)" #just madeit work need to genalize it last first
name_caplastfirst_regex = "([A-Z\\p{Lu}-]+, ?(?:[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+))" #just made it work need to genalize it last first
name_penalty_regex = "((?:(?:(?:(?:[A-Z\\p{Lu}'-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+|(?:de))|(?:[A-Z\\p{Lu}-]\\.?)?\\s?)+) ?)+)"
# name_lastfirst_penalty_regex = "([A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+, ?[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+)" #just madeit work need to genalize it last first
# name_lastfirst_penalty_regex = "((?:(?:[A-Z\\p{Lu}\\.-]+|[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+ ?)+, ?[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+))" #general last first regex
# name_lastfirst_penalty_regex = "([A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+,? ?[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]*)" #general last first regex, could be single letter first name
name_twofirst_penalty_regex = "((?:(?:(?:[A-Z\\p{Lu}'-][a-z\\p{Ll}A-Z&\\p{Lu}'\\. -]+)+|(?:de))|(?:[A-Z\\p{Lu}-]\\.?)?\\s?)+)"
#general last first regex, could be single letter first name
# name_lastfirst_penalty_regex = "((?:[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+|,? Jr.| III| II)+,? ?[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]*)"
name_lastfirst_penalty_regex = 
"((?:(?:(?:(?:(?:de )?[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+ ?)+|,? Jr.|,? Sr.|,? III|,? II|,? IV|,? V)+, *(?:[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]* ?)+)|(?:(?:[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+ ?)+|,? Jr.|,? III|,? II|,? IV|,? V)+ [A-Z\\p{Lu}-]\\.?\\b))"
# "((?:(?:[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+ ?)+|,? Jr.|,? III|,? II|,? IV|,? V)+,? *(?:[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]* ?)+)"
# "((?:(?:[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+ ?)+|,? Jr.|,? III|,? II|,? IV|,? V)+, *(?:[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]* ?)+)"
name_lowerlastfirst_penalty_regex = 
"((?:(?:(?:(?:[a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+ ?)+|,? Jr.|,? Sr.|,? III|,? II|,? IV|,? V)+, *(?:[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]* ?)+)|(?:(?:[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+ ?)+|,? Jr.|,? III|,? II|,? IV|,? V)+ [A-Z\\p{Lu}-]\\.?\\b))"
name_lasttwofirst_penalty_regex = "((?:[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+| Jr.|,? Sr.| III| II)+,? ?(?:[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+ ?)*)"
# name_caplastfirst_penalty_regex = "([A-Z\\p{Lu}-]+, ?(?:[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+))" #just made it work need to genalize it last first
# name_caplastfirst_penalty_regex = "([A-Z\\p{Lu}-]+, ?(?:[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]*))"
# name_caplastfirst_penalty_regex = "((?:[A-Z\\p{Lu}'-]+| III)+, ?(?:[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]*))"
# name_caplastfirst_penalty_regex = "((?:(?:Mc|Mac)[A-Z\\p{Lu}'-]+| III)+, ?(?:[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]*))"
# name_caplastfirst_penalty_regex = "((?:(?:Mc|Mac)?[A-Z\\p{Lu}'-]+)+(?: JR\\.?|,? SR\\.?| IIII| III| II| IV| V)?, ?(?:[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]*))"
name_caplastfirst_penalty_regex = "((?:Mc|Mac)?[A-Z\\p{Lu}'-]+,? (?:JR\\.|SR\\.|IIII|III|II|IV|V)?,? ?(?:[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]*))"
name_captwolastfirst_penalty_regex = "([A-Z\\p{Lu}'-]+ [A-Z\\p{Lu}-]+, ?(?:[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]*))"
name_caplasttwofirst_penalty_regex = "((?:Mc|Mac)?[A-Z\\p{Lu}'-]+,? (?:JR\\.|SR\\.|IIII|III|II|IV|V)?,? ?(?:[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]*) (?:[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]*))"
# name_caplast_postfix_first_penalty_regex = "((?:[A-Z\\p{Lu}'-]+)+, (?:JR\\.|SR\\.?|III|II|IV),? ?(?:[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]*))"
name_caplast_postfix_first_penalty_regex = "((?:[A-Z\\p{Lu}'-]+)+, (?:JR\\.|SR\\.|III|II|IV),? ?(?:[A-Z\\p{Lu}\\.-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]*))"
# name_period_penalty_regex = "([A-Z\\p{Lu}'-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+\\.[A-Z\\p{Lu}'-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+)"
# name_period_penalty_regex = "([A-Z\\p{Lu}'-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+(?: J[Rr]\\.?| II| III| IV))"
name_period_penalty_regex = "([A-Z\\p{Lu}'-].[A-Z\\p{Lu}'-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+(?: J[Rr]\\.?| S[Rr]\\.?| III| II| IV)?)"
name_lastonly_regex = "((?:[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+| J[Rr]\\.|S[Rr]\\.?| III| II)+)"

df_names_text = DataFrame(:Name => String[], :Txt => String[])
# df = CSV.read("../../data/all_games/names_play_text-500.csv", DataFrame; normalizenames=true)
for i in 500:500:10000
    df = CSV.read("../../data/all_games/names_play_text-$i.csv", DataFrame; normalizenames=true)
    dropmissing!(df)
    df_names_text = vcat(df_names_text, df)
    unique!(df_names_text)
end

# sort!(df_names_text)
df_names_text

CSV.write("../../data/all_games/names_all.csv", df_names_text)


df = CSV.read("../../data/all_games/names_all-edit.csv", DataFrame; normalizenames=true)
df_names_text = DataFrame(:Name => df[1,1], :Txt => df[1,2])
last_name = df_names_text[1, :Name]
for r in 2:nrow(df)
    if df[r, :Name] ≠ last_name
        df_names_text = vcat(df_names_text, DataFrame(:Name => df[r,1], :Txt => df[r,2]))
        last_name = df[r, :Name]
    end
end

df_names_text
CSV.write("../../data/all_games/names_all-unique.csv", df_names_text)




df = CSV.read("../../data/all_games/names_all-unique.csv", DataFrame; normalizenames=true)
df_names_text = DataFrame(:Name => df[1,1], :Txt => df[1,2])
last_name = df_names_text[1, :Name]
for r in 2:nrow(df)
    if df[r, :Name] ≠ last_name
        df_names_text = vcat(df_names_text, DataFrame(:Name => df[r,1], :Txt => df[r,2]))
        last_name = df[r, :Name]
    end
end
df_names_text
CSV.write("../../data/all_games/names_all-unique.csv", df_names_text)


#Make comma list and non-comma list
df = CSV.read("../../data/all_games/names_all-unique.csv", DataFrame; normalizenames=true)
df_names_comma = DataFrame(:Name => String[], :Txt => String[])
df_names_nocomma = DataFrame(:Name => String[], :Txt => String[])
for r in 1:nrow(df)
    if occursin(",", df[r,1])
        df_names_comma = vcat(df_names_comma, DataFrame(:Name => df[r,1], :Txt => df[r,2]))
    else
        df_names_nocomma = vcat(df_names_nocomma, DataFrame(:Name => df[r,1], :Txt => df[r,2]))
    end
end

df_names_comma
df_names_nocomma

CSV.write("../../data/all_games/names_all-unique_comma.csv", df_names_comma)
CSV.write("../../data/all_games/names_all-unique_nocomma.csv", df_names_nocomma)



df_names_nocomma = CSV.read("../../data/all_games/names_all-unique_nocomma.csv", DataFrame)

current_name = df_names_nocomma[10,:Name]
if current_name == "-"
    println("Missing")
elseif occursin("-", current_name)
    processed_name = replace(current_name, r"^\s*-\s*" => "")
    println("$processed_name from $current_name")
end

splitnames = split(current_name, " ")
length_split_names = length(splitnames)
if length_split_names == 2   
    processed_name = splitnames[2]*", "*splitnames[1]
end




# name_vec = String[]

# for i in 500:500:10000
#     df = CSV.read("../../data/all_games/names_play_text-$i.csv", DataFrame; normalizenames=true)
#     dropmissing!(df)
#     name_vec = vcat(name_vec, df[:, :Name])    
#     unique!(name_vec)
# end

# sort!(name_vec)

# CSV.write("../../data/all_games/names_all.csv", DataFrame(:Names => name_vec))


#######################################################################################################################################
# Drive peril by krnxprs

#######################################################################################################################################
# Rewrite code for drive peril (use simple formulas e.g. 1st/2nd = total - 3rd/4th instead of getting directly from dataframe)
function excess_yards(offense, play_type, down, distance, yards_gained, penalty_status1, penalty_team1, penalty_status2, penalty_team2, penalty_status3, penalty_team3)
    println("$offense, $down, $distance, $yards_gained, $penalty_status1, $penalty_team1, $penalty_status2, $penalty_team2, $penalty_status3, $penalty_team3")
    if ismissing(penalty_status1)
        excess_yard = yards_gained - distance
        excess_yard = excess_yard >= 0 ? excess_yard : 0
    elseif offense == penalty_team1 && penalty_status1 == "enforced"
        excess_yard = 0
    elseif penalty_status1 == "offsetting" && ismissing(penalty_status3)
        excess_yard = yards_gained - distance
        excess_yard = excess_yard >= 0 ? excess_yard : 0
    elseif play_type == "Penalty"
            excess_yard = 0
    else
        # println("Add code for situation")
        excess_yard = yards_gained - distance
        excess_yard = excess_yard >= 0 ? excess_yard : 0
    end
    excess_yard
end

function team_and_filter(df, team)
    df_team = filter(:Offense => ==(team), df)
    df_team = select(df_team, [:Offense, :Play_type, :Yards_to_goal, :Down, :Distance, :Yards_gained, :Penalty1_status, :Penalty1_team, :Penalty2_status, :Penalty2_team, :Penalty3_status, :Penalty3_team])
    df_team = filter(:Play_type => !=("End Period"), df_team)
    df_team = filter(:Play_type => !=("End of Regulation"), df_team)
    df_team = filter(:Play_type => !=("End of Game"), df_team)
    df_team = filter(:Play_type => !=("Field Goal Missed"), df_team)
    df_team = filter(:Play_type => !=("Timeout"), df_team)
    df_team = filter(:Play_type => !=("End of Half"), df_team)
    df_team = filter(:Play_type => !=("Punt"), df_team)
    df_team = filter(:Play_type => !=("Blocked Punt"), df_team)
    df_team = filter(:Play_type => !=("Punt Return Touchdown"), df_team)
    df_team = filter(:Play_type => !=("Blocked Punt Touchdown"), df_team)
    df_team = filter(:Play_type => !=("Field Goal Good"), df_team)
    df_team = filter(:Play_type => !=("Blocked Field Goal"), df_team)
    df_team = filter(:Play_type => !=("Blocked Field Goal Touchdown"), df_team)
    df_team = filter(:Play_type => !=("Missed Field Goal Return"), df_team)
    df_team = filter(:Play_type => !=("Missed Field Goal Return Touchdown"), df_team)
    df_team = filter(:Play_type => !=("Kickoff"), df_team)
    df_team = filter(:Play_type => !=("Kickoff Return Touchdown"), df_team)
    df_team = filter(:Play_type => !=("Kickoff Return (Offense)"), df_team)
    df_team = filter(:Play_type => !=("Uncategorized"), df_team)
    df_team = filter(:Play_type => !=("placeholder"), df_team)
    df_team = filter(:Play_type => !=("Defensive 2pt Conversion"), df_team)
    df_team = filter(:Play_type => !=("Two Point Pass"), df_team)
    df_team = filter(:Play_type => !=("Two Point Rush"), df_team)
end

function filter_defense_gains(df)
    df_team_other = filter(:Play_type => !=("Interception Return Touchdown"), df)
    df_team_other = filter(:Play_type => !=("Interception"), df_team_other)
    df_team_other = filter(:Play_type => !=("Fumble Return Touchdown"), df_team_other)
    df_team_other = filter(:Play_type => !=("Fumble Recovery (Opponent)"), df_team_other)
    df_team_other = filter(:Play_type => !=("Pass Interception Return"), df_team_other)
end

function filter_penalties(df)
    filter(:Play_type => !=("Penalty"), df)
end

# i = 315
# dirContents[i]
# df = CSV.read(dirContents[i], DataFrame; normalizenames=true)

i = 316
dirContents[i]
df = CSV.read(dirContents[i], DataFrame; normalizenames=true)

# df
# browse(df)
# unique(df.Play_type)

# team = "Alabama"
# team = "Arkansas"
team = "Texas A&M"

df_team = team_and_filter(df, team)
df_team_other = filter_defense_gains(df_team)
df_nonpenalties = filter_penalties(df_team_other)
#In case plays need to be removed e.g. Bama-Ark 2022 bad punt snap included as Rush
# deleteat!(df_team_other, [49])

# browse(df_team)
# browse(df_team_other)

begin
    
# first_down_gained = sum(filter(:Down => ==(1), df_team_other).Yards_gained)
# second_down_gained = sum(filter(:Down => ==(2), df_team_other).Yards_gained)
first_down_gained = sum(filter(:Down => ==(1), df_team_other).Yards_gained)
second_down_gained = sum(filter(:Down => ==(2), df_team_other).Yards_gained)


df_third_down = filter(:Down => ==(3), df_nonpenalties)
df_third_down = transform(df_third_down, [:Offense, :Play_type, :Down, :Distance, :Yards_gained, :Penalty1_status, :Penalty1_team, :Penalty2_status, :Penalty2_team, :Penalty3_status, :Penalty3_team] 
                                            => ByRow(excess_yards) => :Excess_yards)

df_fourth_down = filter(:Down => ==(4), df_nonpenalties)
df_fourth_down = transform(df_fourth_down, [:Offense, :Play_type, :Down, :Distance, :Yards_gained, :Penalty1_status, :Penalty1_team, :Penalty2_status, :Penalty2_team, :Penalty3_status, :Penalty3_team] 
                                            => ByRow(excess_yards) => :Excess_yards)

third_down_gained = sum(df_third_down.Yards_gained)
fourth_down_gained = sum(df_fourth_down.Yards_gained)


third_down_excess = sum(df_third_down.Excess_yards)
fourth_down_excess = nrow(df_fourth_down) == 0 ? 0 : sum(df_fourth_down.Excess_yards)

thrid_downs = nrow(filter(:Down => ==(3), df_team))
# browse(thrid_downs)

total_yards_gained = sum(df_nonpenalties.Yards_gained)
# total_yards_gained = sum(df_team.Yards_gained)

perilous_yards = sum(filter(:Down => ==(3), df_nonpenalties).Distance)

thrid_fourth_nonexcess = third_down_gained + fourth_down_gained - (third_down_excess+fourth_down_excess)

non_peril = total_yards_gained - thrid_fourth_nonexcess


nominal_peril_yards_ratio = 0.1764705882

peril_yards_ratio = perilous_yards/non_peril

drive_peril = peril_yards_ratio/nominal_peril_yards_ratio

print("Team: $team
Total yds gained: $total_yards_gained
1st & 2nd yds gained: $(first_down_gained + second_down_gained)
3rd & 4th yds gained: $(third_down_gained + fourth_down_gained)
3rd & 4th yds excess: $(third_down_excess+fourth_down_excess)
3rd & 4th yds non-excess: $thrid_fourth_nonexcess
3rd downs: $thrid_downs
3rd yds to go: $perilous_yards
Non-peril yards gained: $non_peril
Peril yards ratio: $peril_yards_ratio
Drive peril: $drive_peril
")
end
#######################################################################################################################################
#Original code for drive peril
function excess_yards(offense, play_type, down, distance, yards_gained, penalty_status1, penalty_team1, penalty_status2, penalty_team2, penalty_status3, penalty_team3)
    println("$offense, $down, $distance, $yards_gained, $penalty_status1, $penalty_team1, $penalty_status2, $penalty_team2, $penalty_status3, $penalty_team3")
    if ismissing(penalty_status1)
        excess_yard = yards_gained - distance
        excess_yard = excess_yard >= 0 ? excess_yard : 0
    elseif offense == penalty_team1 && penalty_status1 == "enforced"
        excess_yard = 0
    elseif penalty_status1 == "offsetting" && ismissing(penalty_status3)
        excess_yard = yards_gained - distance
        excess_yard = excess_yard >= 0 ? excess_yard : 0
    elseif play_type == "Penalty"
            excess_yard = 0
    else
        # println("Add code for situation")
        excess_yard = yards_gained - distance
        excess_yard = excess_yard >= 0 ? excess_yard : 0
    end
    excess_yard
end

function team_and_filter(df, team)
    df_team = filter(:Offense => ==(team), df)
    df_team = select(df_team, [:Offense, :Play_type, :Yards_to_goal, :Down, :Distance, :Yards_gained, :Penalty1_status, :Penalty1_team, :Penalty2_status, :Penalty2_team, :Penalty3_status, :Penalty3_team])
    df_team = filter(:Play_type => !=("End Period"), df_team)
    df_team = filter(:Play_type => !=("End of Regulation"), df_team)
    df_team = filter(:Play_type => !=("End of Game"), df_team)
    df_team = filter(:Play_type => !=("Field Goal Missed"), df_team)
    df_team = filter(:Play_type => !=("Timeout"), df_team)
    df_team = filter(:Play_type => !=("End of Half"), df_team)
    df_team = filter(:Play_type => !=("Punt"), df_team)
    df_team = filter(:Play_type => !=("Blocked Punt"), df_team)
    df_team = filter(:Play_type => !=("Punt Return Touchdown"), df_team)
    df_team = filter(:Play_type => !=("Blocked Punt Touchdown"), df_team)
    df_team = filter(:Play_type => !=("Field Goal Good"), df_team)
    df_team = filter(:Play_type => !=("Blocked Field Goal"), df_team)
    df_team = filter(:Play_type => !=("Blocked Field Goal Touchdown"), df_team)
    df_team = filter(:Play_type => !=("Missed Field Goal Return"), df_team)
    df_team = filter(:Play_type => !=("Missed Field Goal Return Touchdown"), df_team)
    df_team = filter(:Play_type => !=("Kickoff"), df_team)
    df_team = filter(:Play_type => !=("Kickoff Return Touchdown"), df_team)
    df_team = filter(:Play_type => !=("Kickoff Return (Offense)"), df_team)
    df_team = filter(:Play_type => !=("Uncategorized"), df_team)
    df_team = filter(:Play_type => !=("placeholder"), df_team)
    df_team = filter(:Play_type => !=("Defensive 2pt Conversion"), df_team)
    df_team = filter(:Play_type => !=("Two Point Pass"), df_team)
    df_team = filter(:Play_type => !=("Two Point Rush"), df_team)
end

function filter_penalties_defense_gains(df)
    df_team_other = filter(:Play_type => !=("Penalty"), df)
    df_team_other = filter(:Play_type => !=("Interception Return Touchdown"), df_team_other)
    df_team_other = filter(:Play_type => !=("Interception"), df_team_other)
    df_team_other = filter(:Play_type => !=("Fumble Return Touchdown"), df_team_other)
    df_team_other = filter(:Play_type => !=("Fumble Recovery (Opponent)"), df_team_other)
    df_team_other = filter(:Play_type => !=("Pass Interception Return"), df_team_other)
end

# i = 315
# dirContents[i]
# df = CSV.read(dirContents[i], DataFrame; normalizenames=true)

i = 316
dirContents[i]
df = CSV.read(dirContents[i], DataFrame; normalizenames=true)

# df
# browse(df)
# unique(df.Play_type)

# team = "Alabama"
# team = "Arkansas"
team = "Texas A&M"

df_team = team_and_filter(df, team)


df_team_other = filter_penalties_defense_gains(df_team)
#In case plays need to be removed e.g. Bama-Ark 2022 bad punt snap included as Rush
# deleteat!(df_team_other, [49])

# browse(df_team)
# browse(df_team_other)

first_down_gained = sum(filter(:Down => ==(1), df_team_other).Yards_gained)
second_down_gained = sum(filter(:Down => ==(2), df_team_other).Yards_gained)


df_third_down = filter(:Down => ==(3), df_team_other)
df_third_down = transform(df_third_down, [:Offense, :Play_type, :Down, :Distance, :Yards_gained, :Penalty1_status, :Penalty1_team, :Penalty2_status, :Penalty2_team, :Penalty3_status, :Penalty3_team] 
                                            => ByRow(excess_yards) => :Excess_yards)

df_fourth_down = filter(:Down => ==(4), df_team_other)
df_fourth_down = transform(df_fourth_down, [:Offense, :Play_type, :Down, :Distance, :Yards_gained, :Penalty1_status, :Penalty1_team, :Penalty2_status, :Penalty2_team, :Penalty3_status, :Penalty3_team] 
                                            => ByRow(excess_yards) => :Excess_yards)

third_down_gained = sum(df_third_down.Yards_gained)
fourth_down_gained = sum(df_fourth_down.Yards_gained)


third_down_excess = sum(df_third_down.Excess_yards)
fourth_down_excess = nrow(df_fourth_down) == 0 ? 0 : sum(df_fourth_down.Excess_yards)

thrid_downs = nrow(filter(:Down => ==(3), df_team))
# browse(thrid_downs)

total_yards_gained = sum(df_team_other.Yards_gained)
# total_yards_gained = sum(df_team.Yards_gained)

perilous_yards = sum(filter(:Down => ==(3), df_team_other).Distance)

thrid_fourth_nonexcess = third_down_gained + fourth_down_gained - (third_down_excess+fourth_down_excess)

non_peril = total_yards_gained - thrid_fourth_nonexcess


nominal_peril_yards_ratio = 0.1764705882

peril_yards_ratio = perilous_yards/non_peril

drive_peril = peril_yards_ratio/nominal_peril_yards_ratio

print("Team: $team
Total yds gained: $total_yards_gained
1st & 2nd yds gained: $(first_down_gained + second_down_gained)
3rd & 4th yds gained: $(third_down_gained + fourth_down_gained)
3rd & 4th yds excess: $(third_down_excess+fourth_down_excess)
3rd & 4th yds non-excess: $thrid_fourth_nonexcess
3rd downs: $thrid_downs
3rd yds to go: $perilous_yards
Non-peril yards gained: $non_peril
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

#######################################################################################################################################
