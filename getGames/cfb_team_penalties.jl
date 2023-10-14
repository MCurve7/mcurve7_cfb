using PyCall
using DataFrames
using DataFramesMeta
using CSV
using JSONTables

# run(`$(PyCall.python) -m pip install --upgrade cython`)
# run(`$(PyCall.python) -m pip install cfbd`)

team_get = "Alabama" #input("Team=")
year_get = 2023 #int(input("Year="))
week_get = 1 #int(input("Week [1-16]="))
seasontype_entry = "regular" #input("Season type [regular/postseason/both/preseason]=")

# team_get = "Vanderbilt" #input("Team=")
year_get = 2023 #int(input("Year="))
week_get = 2 #int(input("Week [1-16]="))
seasontype_entry = "regular" #input("Season type [regular/postseason/both/preseason]=")

py"""
import cfbd
from cfbd.rest import ApiException
#Get password and access CFDB
with open('../../data/info/cfbd.txt', mode = 'r') as file:
    Authorization = file.readlines()[0]
    
# Configure API key authorization: ApiKeyAuth
configuration = cfbd.Configuration()
configuration.api_key['Authorization'] = Authorization
# Uncomment below to setup prefix (e.g. Bearer) for API key, if needed
configuration.api_key_prefix['Authorization'] = 'Bearer'

# if seasontype_entry == "preseason":
#     seasontype = "regular"
# else:
#     seasontype = seasontype_entry
    
api_instance = cfbd.GamesApi(cfbd.ApiClient(configuration))
"""

"""
Pass in stats_json[n].teams where n is 1 or 2 if they played a week 0 game
"""
function json2dict(data)
    team1 = Dict()
    team2 = Dict()

    team1["school"] = data[1]["school"]
    team1["conference"] = data[1]["conference"]
    team1["homeAway"] = data[1]["homeAway"]
    team1["points"] = data[1]["points"]
    for i in keys(data[1]["stats"])
        # println("data[stats][$i]= $(data["stats"][i]["category"])")
        # println("data[stats][$i]= $(data["stats"][i]["stat"])")
        team1[data[1]["stats"][i]["category"]] = data[1]["stats"][i]["stat"]
        # data["stats"]
    end

    team2["school"] = data[2]["school"]
    team2["conference"] = data[2]["conference"]
    team2["homeAway"] = data[2]["homeAway"]
    team2["points"] = data[2]["points"]
    for i in keys(data[2]["stats"])
        # println("data[stats][$i]= $(data["stats"][i]["category"])")
        # println("data[stats][$i]= $(data["stats"][i]["stat"])")
        team2[data[2]["stats"][i]["category"]] = data[2]["stats"][i]["stat"]
        # data["stats"]
    end

    team1["opponent"] = team2["school"]
    team2["opponent"] = team1["school"]
    team1, team2
end

# json2dict(stats_json[1].teams)

# ## Test getting json season_type = seasontype, year = year_get, week = wk, team = team_get
# stats_json = py"api_instance.get_team_game_stats"(season_type = seasontype_entry, year = year_get, week = week_get, team = team_get)
# stats_json
# stats_json[2].teams

# t = stats_json[1].teams
# t[1]["school"]

# keys(stats_json[1].teams)
# stats_json[1].teams[1]

# team1 = stats_json[1].teams[1]
# stats_json[1].teams[1]["school"]
# team1["school"]

# team1["stats"]
# keys(team1["stats"])
# team1["stats"][1]

# t = json2dict(stats_json[1].teams[1])
# t["school"]
# t["totalPenaltiesYards"]
# a, b = split(t["totalPenaltiesYards"], "-")
# parse(Int, a)
# b
# ## END testing region


# school_colors = CSV.File("../school_colors/teams-fbs-$year_get.csv", delim = ";") |> DataFrame
team_names = CSV.File("../school_colors/teams-fbs-$year_get.csv", delim = ";") |> DataFrame
# team_names[:, :School]

function get_stats(data, week)
    df = DataFrame(Year = Int8[], Week = Int8[], School = String[], Conference = String[], TotalPenalties = Int8[], TotalPenaltiesYards = Int8[], Opponent = String[], Season = String[])
    team1_data, team2_data = json2dict(data)
    tot_penalties_yards = split(team1_data["totalPenaltiesYards"], "-")
    df = vcat(df, DataFrame(Year = year_get, Week = week, School = team1_data["school"], Conference = team1_data["conference"], TotalPenalties = parse(Int, tot_penalties_yards[1]), TotalPenaltiesYards = parse(Int, tot_penalties_yards[2]), Opponent = team1_data["opponent"], Season = seasontype_entry))
    tot_penalties_yards = split(team2_data["totalPenaltiesYards"], "-")
    df = vcat(df, DataFrame(Year = year_get, Week = week, School = team2_data["school"], Conference = team2_data["conference"], TotalPenalties = parse(Int, tot_penalties_yards[1]), TotalPenaltiesYards = parse(Int, tot_penalties_yards[2]), Opponent = team2_data["opponent"], Season = seasontype_entry))
    df, team1_data["school"], team2_data["school"]
end

begin
    df = DataFrame(Year = Int8[], Week = Int8[], School = String[], Conference = String[], TotalPenalties = Int8[], TotalPenaltiesYards = Int8[], Opponent = String[], Season = String[])
    df0 = DataFrame(Year = Int8[], Week = Int8[], School = String[], Conference = String[], TotalPenalties = Int8[], TotalPenaltiesYards = Int8[], Opponent = String[], Season = String[])
    # teams_seen = (String, Int)[]
    teams_seen = Tuple{String, Int}[]
    for week in 1:week_get
        # teams_seen = String[]
        
        for team in team_names[:, :School]
            # if team in teams_seen
            if (team, week) in teams_seen
                println("Seen $team already in week $week")
            else
                println("Working on: $team")
                
                # json_team_data = py"api_instance.get_team_game_stats"(season_type = seasontype_entry, year = year_get, week = week_get, team = team)
                json_team_data = py"api_instance.get_team_game_stats"(season_type = seasontype_entry, year = year_get, week = week, team = team)
                # println("json_team_data:$json_team_data")
                if length(json_team_data) == 1
                    df_temp, school1, school2 = get_stats(json_team_data[1].teams, week)
                    df = vcat(df, df_temp)
                    push!(teams_seen, (school1, week))
                    push!(teams_seen, (school2, week))
                elseif length(json_team_data) == 2
                    df_temp, school1, school2 = get_stats(json_team_data[1].teams, -1)
                    df0 = vcat(df0, df_temp)
                    # push!(teams_seen, (school1, 0))
                    # push!(teams_seen, (school2, 0))
                    ##########################################################################
                    df_temp, school1, school2 = get_stats(json_team_data[2].teams, -2)
                    df0 = vcat(df0, df_temp)
                    # push!(teams_seen, (school1, 1))
                    # push!(teams_seen, (school2, 1))
                else
                    println("MISSED NOTHING PROCESSED")
                end
            end
            # println("teams_seen: $teams_seen")
        end
    end
    df0 = unique(df0)
end

println(df)
println(df0)

# df0
# t = not_wk1_df[:, :School]
# t2 = filter(:School => ==(t[1]), not_wk1_df)[:, :Opponent]

# not_wk1_df[in([t[1]]).(not_wk1_df.School), :][1,:]
# @rsubset(not_wk1_df, :School == t[1], :Opponent == t2[1])[1,2]

###change df_t to df
week_one_df = filter(:Week => ==(1), df)
not_wk1_df = unique(antijoin(df0, week_one_df, on = :School))
df_t = DataFrame(Year = Int8[], Week = Int8[], School = String[], Conference = String[], TotalPenalties = Int8[], TotalPenaltiesYards = Int8[], Opponent = String[], Season = String[])
for t_school in unique(not_wk1_df[:, :School])
    i = 0
    for t_opponenet in filter(:School => ==(t_school), not_wk1_df)[:, :Opponent]
        tt = @rsubset(not_wk1_df, :School == t_school, :Opponent == t_opponenet)
        println("School: $t_school, Opponent: $t_opponenet; $(tt)")
        df_t = vcat(df_t, DataFrame(Year = tt[1,:Year], Week = i, School = tt[1,:School], Conference = tt[1,:Conference], TotalPenalties = tt[1,:TotalPenalties], TotalPenaltiesYards = tt[1,:TotalPenaltiesYards], Opponent = tt[1,:Opponent], Season = tt[1,:Season]))
        i +=1
    end
end
df_t

# If length = 2 loop to set to 0 or 1
not_wk1_team = unique(filter(:School => ==("Jacksonville State"), not_wk1_df))
# not_wk1_team[1,:Week] = 0
# not_wk1_team
for i in 1:2
    not_wk1_team[i,:Week] = i-1
end
not_wk1_team

not_wk1_df2 = antijoin(df0, df_t, on = [:School, :Opponent])



df0



week_zeroone_teams
anti_df = antijoin(df0, week_one_df, on = [:School, :Opponent])
filter(:School => ==("SMU"), anti_df)

week_zero_teams = df0[:, :School]
week_one_teams = filter(:Week => ==(1), df)[:, :School]
week_zeroone_teams = intersect(week_zero_teams, week_one_teams)

week0_in_week1_df = filter([:Week, :School] => (x,y) -> x == 1 && y in week_zero_teams, df)

week_zeroone_teams
week0_in_week1_df

for team in week_zeroone_teams
    df_temp = filter(:School => ==(team), df0)

    println("df_temp:\n $df_temp")
end

for team in unique(df0[:, :School])
    println("team: $team")
    multi_opponenets = unique(filter(:School => ==(team), df0)[:, :Opponent])
    length(multi_opponenets) == 1 && continue
    seen_p = Bool[]
    # week_seen = Int[]
    for i in 1:2
        if multi_opponenets[i] in filter(:School => ==(team), df)[:, :Opponent]
            push!(seen_p, true)
            # week_seen = filter([:School, :Opponent] => (x,y) -> (x=="Hawai'i" && y==multi_opponenets[i]), df)[:, :Week]
        else
            push!(seen_p, false)
        end
    end
    # week_seen
    # seen_p
    for i in 1:2
        if !seen_p[i]
            println("$team seen=> week: $(i-1), opponent: $(multi_opponenets[i])")
            conference_seen = filter([:School, :Opponent] => (x,y) -> (x==team && y==multi_opponenets[i]), df0)[:, :Conference][1]
            # println("conference_seen: $conference_seen")
            totalpenalties_seen = filter([:School, :Opponent] => (x,y) -> (x==team && y==multi_opponenets[i]), df0)[:, :TotalPenalties]
            totalpenaltiesyards_seen = filter([:School, :Opponent] => (x,y) -> (x==team && y==multi_opponenets[i]), df0)[:, :TotalPenaltiesYards]
            println("Year = $year_get, Week = $(i-1), School = $team, Conference = $conference_seen, TotalPenalties = $totalpenalties_seen, TotalPenaltiesYards = $totalpenaltiesyards_seen, Opponent = $(multi_opponenets[i]), Season = regular")
            df = vcat(df, DataFrame(Year = year_get, Week = i-1, School = team, Conference = conference_seen, TotalPenalties = totalpenalties_seen, TotalPenaltiesYards = totalpenaltiesyards_seen, Opponent = multi_opponenets[i], Season = "regular"))
        end
    end
end
filter([:School, :Opponent] => (x,y) -> (x=="Hawai'i" && y==multi_opponenets[1]), df0)[:, :Conference]



println(df)
println(df0)

#open ("../../data/team_stats/"+str(year_get)+'_'+seasontype+'_'+"penalties_yards"+'.csv', 'w', newline='')
CSV.write("../../data/team_stats/$(year_get)_$(seasontype_entry)_penalties_yards_julia.csv", vcat(df, df0), append=false)
CSV.write("../../data/team_stats/$(year_get)_$(seasontype_entry)_penalties_yards_julia.csv", df, append=false)






"""
# length = 1
'''
[{'id': 401403854,
 'teams': [{'conference': 'SEC',
            'homeAway': 'home',
            'points': 55,
            'school': 'Alabama',
            'stats': [{'category': 'fumblesRecovered', 'stat': '0'},
                      {'category': 'rushingTDs', 'stat': '1'},
                      {'category': 'puntReturnYards', 'stat': '20'},
                      {'category': 'puntReturnTDs', 'stat': '0'},
                      {'category': 'puntReturns', 'stat': '3'},
                      {'category': 'passingTDs', 'stat': '6'},
                      {'category': 'kickReturnYards', 'stat': '18'},
                      {'category': 'kickReturnTDs', 'stat': '0'},
                      {'category': 'kickReturns', 'stat': '1'},
                      {'category': 'kickingPoints', 'stat': '13'},
                      {'category': 'tacklesForLoss', 'stat': '5'},
                      {'category': 'defensiveTDs', 'stat': '0'},
                      {'category': 'tackles', 'stat': '26'},
                      {'category': 'sacks', 'stat': '0'},
                      {'category': 'qbHurries', 'stat': '4'},
                      {'category': 'passesDeflected', 'stat': '3'},
                      {'category': 'possessionTime', 'stat': '31:51'},
                      {'category': 'interceptions', 'stat': '1'},
                      {'category': 'fumblesLost', 'stat': '0'},
                      {'category': 'turnovers', 'stat': '1'},
                      {'category': 'totalPenaltiesYards', 'stat': '6-40'},
                      {'category': 'yardsPerRushAttempt', 'stat': '8.7'},
                      {'category': 'rushingAttempts', 'stat': '32'},
                      {'category': 'rushingYards', 'stat': '278'},
                      {'category': 'yardsPerPass', 'stat': '7.0'},
                      {'category': 'completionAttempts', 'stat': '27-40'},
                      {'category': 'netPassingYards', 'stat': '281'},
                      {'category': 'totalYards', 'stat': '559'},
                      {'category': 'fourthDownEff', 'stat': '0-0'},
                      {'category': 'thirdDownEff', 'stat': '6-10'},
                      {'category': 'firstDowns', 'stat': '30'}]},
           {'conference': 'Mountain West',
            'homeAway': 'away',
            'points': 0,
            'school': 'Utah State',
            'stats': [{'category': 'rushingTDs', 'stat': '0'},
                      {'category': 'puntReturnYards', 'stat': '10'},
                      {'category': 'puntReturnTDs', 'stat': '0'},
                      {'category': 'puntReturns', 'stat': '1'},
                      {'category': 'passingTDs', 'stat': '0'},
                      {'category': 'interceptionYards', 'stat': '18'},
                      {'category': 'interceptionTDs', 'stat': '0'},
                      {'category': 'passesIntercepted', 'stat': '1'},
                      {'category': 'fumblesRecovered', 'stat': '0'},
                      {'category': 'totalFumbles', 'stat': '3'},
                      {'category': 'tacklesForLoss', 'stat': '5'},
                      {'category': 'defensiveTDs', 'stat': '0'},
                      {'category': 'tackles', 'stat': '40'},
                      {'category': 'sacks', 'stat': '1'},
                      {'category': 'qbHurries', 'stat': '1'},
                      {'category': 'passesDeflected', 'stat': '2'},
                      {'category': 'possessionTime', 'stat': '28:09'},
                      {'category': 'interceptions', 'stat': '0'},
                      {'category': 'fumblesLost', 'stat': '0'},
                      {'category': 'turnovers', 'stat': '0'},
                      {'category': 'totalPenaltiesYards', 'stat': '11-110'},
                      {'category': 'yardsPerRushAttempt', 'stat': '2.1'},
                      {'category': 'rushingAttempts', 'stat': '37'},
                      {'category': 'rushingYards', 'stat': '79'},
                      {'category': 'yardsPerPass', 'stat': '2.6'},
                      {'category': 'completionAttempts', 'stat': '8-22'},
                      {'category': 'netPassingYards', 'stat': '57'},
                      {'category': 'totalYards', 'stat': '136'},
                      {'category': 'fourthDownEff', 'stat': '2-4'},
                      {'category': 'thirdDownEff', 'stat': '3-17'},
                      {'category': 'firstDowns', 'stat': '7'}]}]}]
'''


# length = 2
'''
[{'id': 401403854,
 'teams': [{'conference': 'SEC',
            'homeAway': 'home',
            'points': 55,
            'school': 'Alabama',
            'stats': [{'category': 'fumblesRecovered', 'stat': '0'},
                      {'category': 'rushingTDs', 'stat': '1'},
                      {'category': 'puntReturnYards', 'stat': '20'},
                      {'category': 'puntReturnTDs', 'stat': '0'},
                      {'category': 'puntReturns', 'stat': '3'},
                      {'category': 'passingTDs', 'stat': '6'},
                      {'category': 'kickReturnYards', 'stat': '18'},
                      {'category': 'kickReturnTDs', 'stat': '0'},
                      {'category': 'kickReturns', 'stat': '1'},
                      {'category': 'kickingPoints', 'stat': '13'},
                      {'category': 'tacklesForLoss', 'stat': '5'},
                      {'category': 'defensiveTDs', 'stat': '0'},
                      {'category': 'tackles', 'stat': '26'},
                      {'category': 'sacks', 'stat': '0'},
                      {'category': 'qbHurries', 'stat': '4'},
                      {'category': 'passesDeflected', 'stat': '3'},
                      {'category': 'possessionTime', 'stat': '31:51'},
                      {'category': 'interceptions', 'stat': '1'},
                      {'category': 'fumblesLost', 'stat': '0'},
                      {'category': 'turnovers', 'stat': '1'},
                      {'category': 'totalPenaltiesYards', 'stat': '6-40'},
                      {'category': 'yardsPerRushAttempt', 'stat': '8.7'},
                      {'category': 'rushingAttempts', 'stat': '32'},
                      {'category': 'rushingYards', 'stat': '278'},
                      {'category': 'yardsPerPass', 'stat': '7.0'},
                      {'category': 'completionAttempts', 'stat': '27-40'},
                      {'category': 'netPassingYards', 'stat': '281'},
                      {'category': 'totalYards', 'stat': '559'},
                      {'category': 'fourthDownEff', 'stat': '0-0'},
                      {'category': 'thirdDownEff', 'stat': '6-10'},
                      {'category': 'firstDowns', 'stat': '30'}]},
           {'conference': 'Mountain West',
            'homeAway': 'away',
            'points': 0,
            'school': 'Utah State',
            'stats': [{'category': 'rushingTDs', 'stat': '0'},
                      {'category': 'puntReturnYards', 'stat': '10'},
                      {'category': 'puntReturnTDs', 'stat': '0'},
                      {'category': 'puntReturns', 'stat': '1'},
                      {'category': 'passingTDs', 'stat': '0'},
                      {'category': 'interceptionYards', 'stat': '18'},
                      {'category': 'interceptionTDs', 'stat': '0'},
                      {'category': 'passesIntercepted', 'stat': '1'},
                      {'category': 'fumblesRecovered', 'stat': '0'},
                      {'category': 'totalFumbles', 'stat': '3'},
                      {'category': 'tacklesForLoss', 'stat': '5'},
                      {'category': 'defensiveTDs', 'stat': '0'},
                      {'category': 'tackles', 'stat': '40'},
                      {'category': 'sacks', 'stat': '1'},
                      {'category': 'qbHurries', 'stat': '1'},
                      {'category': 'passesDeflected', 'stat': '2'},
                      {'category': 'possessionTime', 'stat': '28:09'},
                      {'category': 'interceptions', 'stat': '0'},
                      {'category': 'fumblesLost', 'stat': '0'},
                      {'category': 'turnovers', 'stat': '0'},
                      {'category': 'totalPenaltiesYards', 'stat': '11-110'},
                      {'category': 'yardsPerRushAttempt', 'stat': '2.1'},
                      {'category': 'rushingAttempts', 'stat': '37'},
                      {'category': 'rushingYards', 'stat': '79'},
                      {'category': 'yardsPerPass', 'stat': '2.6'},
                      {'category': 'completionAttempts', 'stat': '8-22'},
                      {'category': 'netPassingYards', 'stat': '57'},
                      {'category': 'totalYards', 'stat': '136'},
                      {'category': 'fourthDownEff', 'stat': '2-4'},
                      {'category': 'thirdDownEff', 'stat': '3-17'},
                      {'category': 'firstDowns', 'stat': '7'}]}]}, {'id': 401404146,
 'teams': [{'conference': 'FBS Independents',
            'homeAway': 'away',
            'points': 20,
            'school': 'Connecticut',
            'stats': [{'category': 'rushingTDs', 'stat': '1'},
                      {'category': 'passingTDs', 'stat': '1'},
                      {'category': 'kickReturnYards', 'stat': '88'},
                      {'category': 'kickReturnTDs', 'stat': '0'},
                      {'category': 'kickReturns', 'stat': '4'},
                      {'category': 'kickingPoints', 'stat': '8'},
                      {'category': 'fumblesRecovered', 'stat': '4'},
                      {'category': 'totalFumbles', 'stat': '1'},
                      {'category': 'tacklesForLoss', 'stat': '0'},
                      {'category': 'defensiveTDs', 'stat': '0'},
                      {'category': 'tackles', 'stat': '39'},
                      {'category': 'sacks', 'stat': '1'},
                      {'category': 'qbHurries', 'stat': '0'},
                      {'category': 'passesDeflected', 'stat': '2'},
                      {'category': 'possessionTime', 'stat': '28:17'},
                      {'category': 'interceptions', 'stat': '2'},
                      {'category': 'fumblesLost', 'stat': '1'},
                      {'category': 'turnovers', 'stat': '3'},
                      {'category': 'totalPenaltiesYards', 'stat': '4-35'},
                      {'category': 'yardsPerRushAttempt', 'stat': '6.3'},
                      {'category': 'rushingAttempts', 'stat': '39'},
                      {'category': 'rushingYards', 'stat': '245'},
                      {'category': 'yardsPerPass', 'stat': '3.6'},
                      {'category': 'completionAttempts', 'stat': '13-33'},
                      {'category': 'netPassingYards', 'stat': '119'},
                      {'category': 'totalYards', 'stat': '364'},
                      {'category': 'fourthDownEff', 'stat': '1-1'},
                      {'category': 'thirdDownEff', 'stat': '6-15'},
                      {'category': 'firstDowns', 'stat': '21'}]},
           {'conference': 'Mountain West',
            'homeAway': 'home',
            'points': 31,
            'school': 'Utah State',
            'stats': [{'category': 'rushingTDs', 'stat': '1'},
                      {'category': 'puntReturnYards', 'stat': '0'},
                      {'category': 'puntReturnTDs', 'stat': '0'},
                      {'category': 'puntReturns', 'stat': '2'},
                      {'category': 'passingTDs', 'stat': '3'},
                      {'category': 'kickingPoints', 'stat': '7'},
                      {'category': 'interceptionYards', 'stat': '10'},
                      {'category': 'interceptionTDs', 'stat': '0'},
                      {'category': 'passesIntercepted', 'stat': '2'},
                      {'category': 'fumblesRecovered', 'stat': '2'},
                      {'category': 'totalFumbles', 'stat': '2'},
                      {'category': 'tacklesForLoss', 'stat': '0.5'},
                      {'category': 'defensiveTDs', 'stat': '0'},
                      {'category': 'tackles', 'stat': '30'},
                      {'category': 'sacks', 'stat': '6'},
                      {'category': 'qbHurries', 'stat': '0'},
                      {'category': 'passesDeflected', 'stat': '4'},
                      {'category': 'possessionTime', 'stat': '31:43'},
                      {'category': 'interceptions', 'stat': '0'},
                      {'category': 'fumblesLost', 'stat': '2'},
                      {'category': 'turnovers', 'stat': '2'},
                      {'category': 'totalPenaltiesYards', 'stat': '6-60'},
                      {'category': 'yardsPerRushAttempt', 'stat': '4.8'},
                      {'category': 'rushingAttempts', 'stat': '54'},
                      {'category': 'rushingYards', 'stat': '261'},
                      {'category': 'yardsPerPass', 'stat': '9.1'},
                      {'category': 'completionAttempts', 'stat': '20-31'},
                      {'category': 'netPassingYards', 'stat': '281'},
                      {'category': 'totalYards', 'stat': '542'},
                      {'category': 'fourthDownEff', 'stat': '0-1'},
                      {'category': 'thirdDownEff', 'stat': '6-15'},
                      {'category': 'firstDowns', 'stat': '31'}]}]}]
'''
"""