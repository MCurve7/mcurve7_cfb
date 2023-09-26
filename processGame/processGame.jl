using CSV
using DataFrames
using Pipe: @pipe
using DelimitedFiles
using Unicode
using StringEncodings
using Dates
using JSON
using Printf
using CategoricalArrays
using Chain
using Bootstrap
using Downloads
using GLM
using Plots
using Random
using StatsPlots
using Statistics

using Revise
includet("foulAnalysis.jl")
includet("playInfo.jl")

#= 
ToDo:
convert all name regexs to best
SCRATCH add "process error" to all ifelse as a catchall,
learn to use Logging package
=#

#= Notes

Penalties:
I think U = unsportsmanlike conduct
=#

# DEBUG_PENALTY = true
DEBUG_PENALTY = false

# DEBUG_PLAY_INFO = true
DEBUG_PLAY_INFO = false

# DEBUG = true
DEBUG = false

# DEBUG_PROCESS_FUNCTION = true
DEBUG_PROCESS_FUNCTION = false

# Global variables
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
penalty_general_regex = "(?:(?:[A-Za-z012-]) ?)+" # need to prepend (?: UNS:)?, but then must find all uses of this regex and remove (?: UNS:)?
penalties_regex_txt = "(?:Penalty|PENALTY)"

GET_NAMES = false

###############################################################################################################################################
#Main function

function process_game(game)
    DEBUG_PROCESS_FUNCTION && println("Read CSV")
    df = CSV.read(game, DataFrame; normalizenames=true, types = Dict(:Scoring => Bool, :Distance => Int8, :Yards_gained => Int8))
    for i in 1:nrow(df)
        DEBUG_PROCESS_FUNCTION && println("Offense: $(df[i, :Offense])")
        if df[i, :Offense] == "San Jos� State" 
            df[i, :Offense] = "San José State"
        end
        # df[i, :Offense] = decode(encode((df[i, :Offense]), "UTF-8"), "UTF-8")        
    end

    DEBUG_PROCESS_FUNCTION && println("Remove PPA")
    df = select(df, Not(:PPA))
    # Need to process the play_text and replace unicode "\xc9" => "É" and "\xe9" => "é".

    

    if DEBUG_PROCESS_FUNCTION println("processGames=> offense from df:\n $(df[:, :Offense])") end
    #Move to end and add new variables
    # df = @pipe df |> select(_, :Defense => categorical => :Defense,
    #             :Offense => categorical => :Offense,
    #             :Quarter => categorical => :Quarter,
    #             :Down => categorical => :Down,
    #             Symbol("Drive number") => categorical => Symbol("Drive number"),
    #             Symbol("Play number") => categorical => Symbol("Play number"),
    #             Symbol("Play type") => categorical => Symbol("Play type"),
    #             Between(:Scoring, :Clock),
    #             Symbol("Defense conference") => categorical => Symbol("Defense conference"),
    #             Between(Symbol("Defense score"), :ID),
    #             Symbol("Offense conference") => categorical => Symbol("Offense conference"),
    #             Between(Symbol("Offense score"), :PPA),
    #             Symbol("Wall clock"),
    #             :Year,
    #             :Week,
    #             :Season) |>
    #             transform(_, AsTable([Symbol("Wall clock")]) => ByRow(DateTime) => Symbol("Wall clock"))
    DEBUG_PROCESS_FUNCTION && println("Transfor Clock")
    df = transform(df, :Clock => ByRow(clock_reformat) => :Clock)
    #df = transform(df, AsTable([:Play_type, :Scoring]) => ByRow(oscoring) => :O_scoring) #Useful now? Use Who_scored instead?
    DEBUG_PROCESS_FUNCTION && println("Find who scored")
    df = hcat(df, who_scored(df))
    DEBUG_PROCESS_FUNCTION && println("Yards_to_success")
    df = transform(df, AsTable([:Down, :Distance]) => ByRow(yards_to_success) => :Yards_to_success)
    DEBUG_PROCESS_FUNCTION && println("Success")
    df = transform(df, AsTable([:Play_type, :Down, :Play_text, :Yards_gained, :Distance, :Scoring, :Who_scored]) => ByRow(successful) => :Success) #Fumble Return Touchdown use who_scored
    DEBUG_PROCESS_FUNCTION && println("Explosive")
    df = transform(df, AsTable([:Play_type, :Down, :Play_text, :Yards_gained, :Distance, :Scoring, :Who_scored]) => ByRow(explosive) => :Explosive)    
    DEBUG_PROCESS_FUNCTION && println("TD_first")
    df = transform(df, AsTable([:Play_type, :Yards_gained, :Distance, :Who_scored, :Success]) => ByRow(tdfirst) => :TD_first)
    DEBUG_PROCESS_FUNCTION && println("scoredrive")
    df = hcat(df, scoredrive(df)) # need to check for punt score and mark as false
    DEBUG_PROCESS_FUNCTION && println("turnover_column_generate")
    df = hcat(df, turnover_column_generate(df))
    DEBUG_PROCESS_FUNCTION && println("score_turnover_column_generate")
    df = hcat(df, score_turnover_column_generate(df))
    DEBUG_PROCESS_FUNCTION && println("play_info")
    # df = transform(df, :Offense => ByRow(preprocess_playinfo_utf) => :Offense)
    # df = transform(df, :Defense => ByRow(preprocess_playinfo_utf) => :Defense)
    # df = transform(df, :Play_text => ByRow(preprocess_playinfo_utf) => :Play_text)
    df = transform(df, AsTable([:Play_text, :Play_type, :Offense, :Defense]) => ByRow(play_info) => 
    [:Runner, :Passer, :Receiver, :Interceptor, :Tackler, :Forcer, :Fumbler, :Recoverer, :PAT_kicker, :PAT_type, :Two_point, :Two_point_type, 
    :Two_point_runner, :Two_point_passer, :Two_point_receiver, :Kicker, :Kick_type, :Returner, :Blocker, :FG_type, :Punter, :Punt_type, :Timeout_team, :Timeout_time])
    # df = transform(df, AsTable(:Play_text) => ByRow(foultype) => :Penalty_type)
    # df = transform(df, AsTable([:Play_text, :Offense, :Defense, :Penalty_type]) => ByRow(foulteam) => :Penalty_team)
    # df = transform(df, AsTable([:Play_text, :Penalty_type]) => ByRow(foultransgressor) => :Penalty_transgressor)
    DEBUG_PROCESS_FUNCTION && println("foul_analysis")
    # df = transform(df, AsTable([:Play_text, :Offense, :Defense]) => ByRow(foul_analysis) => 
    #     [:Penalty1_type, :Penalty1_status, :Penalty1_team, :Penalty1_transgressor, :Penalty2_type, :Penalty2_status, :Penalty2_team, :Penalty2_transgressor, :Penalty3_type, :Penalty3_status, :Penalty3_team, :Penalty3_transgressor])
    df = transform(df, AsTable([:Play_text, :Offense, :Defense, :Quarter, :Down, :Drive_number, :Play_number]) => ByRow(foul_analysis) => 
        [:Penalty1_type, :Penalty1_status, :Penalty1_team, :Penalty1_transgressor, :Penalty2_type, :Penalty2_status, :Penalty2_team, :Penalty2_transgressor, :Penalty3_type, :Penalty3_status, :Penalty3_team, :Penalty3_transgressor])

    df
end
###############################################################################################################################################

function preprocess_playinfo_utf(txt)
    if DEBUG_PROCESS_FUNCTION println("processGames: preprocess_playinfo_utf => txt: $txt") end
    decode(encode(txt, "UTF-8"), "UTF-8")
end

"""
Covert {'minutes': 15, 'seconds': 0} to 15:00
"""
function clock_reformat(time)
    clock = JSON.parse(replace(time, "'" => '"'))
    "$(clock["minutes"]):$(@sprintf("%02d",clock["seconds"]))"
end

"""
Makes a column vector with elements: neither, offense, defense
"""
function who_scored(df)
    
    nr = nrow(df)

    #od_scored = offense or defense scored (or neither)
    od_scored = Vector{String}()
    if df[1, :Offense_score] ≠ 0
        push!(od_scored, "offense")
    elseif df[1, :Defense_score] ≠ 0
        push!(od_scored, "defense")
    else
        push!(od_scored, "neither")
    end
    
    for i in 2:nr
        last_d_score = df[i-1, :Defense_score]
        current_d_score = df[i, :Defense_score]
        last_o_score = df[i-1, :Offense_score]
        current_o_score = df[i, :Offense_score]

        #Take care of kickoffs and change of possessions
        if df[i, :Play_number] == 1
            # Need to fix bc recieving team (defense) isn't always the one who scored
            if ((df[i, :Play_type] == "Kickoff") || (df[i, :Play_type] == "Kickoff Return Touchdown") || (df[i, :Play_type] == "Kickoff Return (Offense)")) && (df[i, :Scoring] == true)
                push!(od_scored, "defense")
            elseif df[i, :Scoring]
                if current_o_score - last_d_score > 0
                    push!(od_scored, "offense")
                elseif current_d_score - last_o_score > 0
                    push!(od_scored, "defense")
                else
                    push!(od_scored, "ERROR")#push!(od_scored, "neither")
                end    
            else
                push!(od_scored, "neither")
            end
        elseif df[i, :Play_number] == 2
            #This first case is for after kickoffs: the offense and defense swap afte the kickoff
            if (current_o_score == last_d_score) && (current_d_score == last_o_score)
                push!(od_scored, "neither")
            elseif current_o_score - last_o_score > 0
                push!(od_scored, "offense")
            elseif current_d_score - last_d_score > 0
                push!(od_scored, "defense")
            else
                push!(od_scored, "neither")
            end
        else
            if current_o_score - last_o_score > 0
                push!(od_scored, "offense")
            elseif current_d_score - last_d_score > 0
                push!(od_scored, "defense")
            else
                push!(od_scored, "neither")
            end
        end
    end

    #Make DataFrame with one column :Who_scored
    DataFrame(:Who_scored => od_scored)
end

"""
Calculates how many yards needed to be successful.
    1st down:  50% of yards to make a 1st down or TD
    2nd down:  70% of yards to make a 1st down or TD
    3rd down: 100% of yards to make a 1st down or TD
"""
function yards_to_success(cols)
    down = cols[1]
    distance = cols[2]
    if down == 1
        .5*distance
    elseif down == 2
        .7*distance
    else
        distance
    end
end

"""
Determine if a play was successful or unsuccessful and return:
    Successful
    Unsuccessful
    or the play type for plays that successful/unsuccessful doesn't apply
"""
function successful(cols)
    playtype = cols[1]
    down = cols[2]
    playtext = cols[3]
    yardsgained = cols[4]
    distance = cols[5]
    scoring = cols[6]
    whoscored = cols[7]
    if playtype == "Penalty" 
        "Penalty"
    elseif playtype == "Punt" || playtype == "Blocked Punt" || playtype == "Punt Return Touchdown" || playtype == "Blocked Punt Touchdown"
        "Punt"
    elseif playtype == "Field Goal Good" ||  playtype == "Field Goal Missed" ||  playtype == "Blocked Field Goal" ||  playtype == "Blocked Field Goal Touchdown" ||  playtype == "Missed Field Goal Return" ||  playtype == "Missed Field Goal Return Touchdown"
        "Field Goal"    
    elseif playtype == "Kickoff" || playtype == "Kickoff Return Touchdown" || playtype == "Kickoff Return (Offense)"
        "Kickoff"
    elseif playtype == "Defensive 2pt Conversion"
        "Defensive 2pt Conversion"
    elseif playtype == "End Period" || playtype == "End of Half" || playtype == "End of Regulation" || playtype == "End of Game"
        "End of"
    elseif playtype == "Timeout"
        "Timeout"
    elseif playtype == "Uncategorized" || playtype == "placeholder"
        "Missing data"
    elseif playtype == "Passing Touchdown"
        "Successful"
    elseif playtype == "Two Point Pass"
        "Successful"
    elseif playtype == "Rushing Touchdown" 
        "Successful"
    elseif playtype == "Two Point Rush"
        "Successful"
    elseif playtype == "Pass Interception Return" || playtype == "Interception Return Touchdown" || playtype == "Pass Incompletion" || playtype == "Sack" || playtype == "Interception" || playtype == "Safety"
        "Unsuccessful"
    elseif playtype == "Fumble Recovery (Opponent)"
        "Unsuccessful"
    elseif playtype == "Fumble Return Touchdown"
        if whoscored == "offense"
            "Successful"
        elseif whoscored == "defense"
            "Unsuccessful"
        end
    elseif playtype == "Fumble Recovery (Own)"
        if scoring
            "Successful"
        else
            if down == 1
                yardsgained >= .5*distance ? "Successful" : "Unsuccessful"
            elseif down == 2
                yardsgained >= .7*distance ? "Successful" : "Unsuccessful"
            else
                yardsgained >= distance ? "Successful" : "Unsuccessful"
            end
        end   
    elseif down == 1
        yardsgained >= .5*distance ? "Successful" : "Unsuccessful"
    elseif down == 2
        yardsgained >= .7*distance ? "Successful" : "Unsuccessful"
    else
        yardsgained >= distance ? "Successful" : "Unsuccessful"
    end
end

function explosive(cols)
    playtype = cols[1]
    down = cols[2]
    playtext = cols[3]
    yardsgained = cols[4]
    distance = cols[5]
    scoring = cols[6]
    whoscored = cols[7]
    if playtype == "Penalty" 
        "Penalty"
    elseif playtype == "Punt" || playtype == "Blocked Punt" || playtype == "Punt Return Touchdown" || playtype == "Blocked Punt Touchdown"
        "Punt"
    elseif playtype == "Field Goal Good" ||  playtype == "Field Goal Missed" ||  playtype == "Blocked Field Goal" ||  playtype == "Blocked Field Goal Touchdown" ||  playtype == "Missed Field Goal Return" ||  playtype == "Missed Field Goal Return Touchdown"
        "Field Goal"    
    elseif playtype == "Kickoff" || playtype == "Kickoff Return Touchdown" || playtype == "Kickoff Return (Offense)"
        "Kickoff"
    elseif playtype == "Defensive 2pt Conversion"
        "Defensive 2pt Conversion"
    elseif playtype == "End Period" || playtype == "End of Half" || playtype == "End of Regulation" || playtype == "End of Game"
        "End of"
    elseif playtype == "Timeout"
        "Timeout"
    elseif playtype == "Uncategorized" || playtype == "placeholder"
        "Missing data"
    elseif playtype == "Pass Interception Return" || playtype == "Interception Return Touchdown" || playtype == "Pass Incompletion" || playtype == "Sack" || playtype == "Interception" || playtype == "Safety"
        "Unexplosive"
    elseif playtype == "Fumble Recovery (Opponent)"
        "Unexplosive"

    # elseif playtype == "Passing Touchdown"
    #     "Successful"
    # elseif playtype == "Two Point Pass"
    #     "Successful"
    # elseif playtype == "Rushing Touchdown" 
    #     "Successful"
    # elseif playtype == "Two Point Rush"
    #     "Successful"
    elseif playtype == "Fumble Return Touchdown"
        if whoscored == "offense"
            yardsgained ≥ 15 ? "Explosive" : "Unexplosive"
        else
            "Unexplosive"
        end
    # elseif playtype == "Fumble Recovery (Own)"
        # yardsgained ≥ 15 ? "Explosive" : "Unexplosive"
    else
        yardsgained ≥ 15 ? "Explosive" : "Unexplosive"
    end
end

"""
Return true if play makes a 1st down or TD and false o.w.
"""
function tdfirst(cols)
    play_type = cols[1]
    yardsgained = cols[2]
    distance = cols[3]
    #o_scoring = cols[4]
    who_scored = cols[4]
    success = cols[5]

    if((play_type == "Rushing Touchdown") || (play_type == "Passing Touchdown") || (play_type == "Two Point Pass") || (play_type == "Two Point Rush"))
        true
    elseif who_scored ≠ "offense" && (success ≠ "Kickoff" || success ≠ "Punt")
        (yardsgained >= distance ? true : false)
    else
        false
    end
end





#I think I need to exclude pic-6s, fumbles retunred for TD, KO/punts for TD, field goals:
#   make vector of Play types to exclude, in for loop:drive_number_list check if Play type is in vector and if so set to false.
function scoredrive(df)
    # need to check for punt score and mark as false
    exclusion = ["Field Goal Good", "Kickoff Return Touchdown"]

    scoredrivevec = Bool[]
    drive_number_list = unique(df.Drive_number)
    #println(drive_number_list)

    for i in 1:length(drive_number_list)
        dfdrive = filter(:Drive_number => x->(x==drive_number_list[i]), df)
        if DEBUG print("dfdrive:\n$dfdrive\n\n") end

        #remove drive ending on End of Game, End of half, etc
        #but need to keep track of how many removed and add back to get correct number of elemenets in column
        #rename end_of_count to number_of_removed_plays
        
        # end_of_count = nrow(filter(:Play_type => x->(x ∈ ["End of Game", "End of Half", "End of Regulation", "End Period"]), dfdrive))
        end_of_count = nrow(filter(:Play_type => x->(x ∈ ["End of Game", "End of Half", "End of Regulation", "End Period", "Timeout"]), dfdrive))

        # println("Drive number: $i, End_ofs: $end_of_count")
        # dfdrive = filter(:Play_type => x->(x ∉ ["End of Game", "End of Half", "End of Regulation", "End Period"]), dfdrive)
        dfdrive = filter(:Play_type => x->(x ∉ ["End of Game", "End of Half", "End of Regulation", "End Period", "Timeout"]), dfdrive)

        len_dfdrive = nrow(dfdrive)
        # df_len = length(unique(dfdrive.O_scoring))
        #df_len is the number of rows of dfdrive where the offense is the team that scored then + 1 for some reason...
        df_len = nrow(dfdrive[in(["offense"]).(dfdrive.Who_scored), :]) + 1
        # if dfdrive[len_dfdrive, :Play_type] == "Field Goal Good"
        if len_dfdrive == 0
            for j in 1:end_of_count
                push!(scoredrivevec, false)
            end
        #if the last row is one of below then fill scoredrivevec with false
        elseif dfdrive[len_dfdrive, :Play_type] ∈ ["Field Goal Good", "Interception Return Touchdown", "Defensive 2pt Conversion", "Fumble Return Touchdown", "Blocked Field Goal Touchdown",
                                                "Blocked Punt Touchdown", "Missed Field Goal Return Touchdown"]
            for j in 1:len_dfdrive + end_of_count
                push!(scoredrivevec, false)
            end
        elseif df_len == 2
            if dfdrive[len_dfdrive, :Who_scored] == "offense"
                #print("len = "*string(df_len)*"\n")
                for j in 1:len_dfdrive + end_of_count
                    push!(scoredrivevec, true)
                end
            else
                for j in 1:len_dfdrive + end_of_count
                    push!(scoredrivevec, false)
                end
            end
        else
            #temp = unique(dfdrive.O_scoring)[1]
            # if unique(dfdrive.O_scoring)[1]
            if last(dfdrive.Who_scored) == "offense"
                #print("len = $df_len, temp=$temp: true\n")
                for j in 1:len_dfdrive + end_of_count
                    push!(scoredrivevec, true)
                end
            else
                #print("len = $df_len, temp = $temp: false\n")
                for j in 1:len_dfdrive + end_of_count
                    push!(scoredrivevec, false)
                end
            end
        end
    end
    #print(scoredrivevec)
    DataFrame(:Score_drive => scoredrivevec)
end

function turnover_column_generate(df)
    turnover_bool = false
    turnover_vec = Bool[]
    drive_number_list = unique(df.Drive_number)

    for i in 1:length(drive_number_list)
        if DEBUG_PROCESS_FUNCTION println("i = $i") end
        dfdrive = filter(:Drive_number => x->(x==drive_number_list[i]), df)
        if DEBUG_PROCESS_FUNCTION println("dfdrive:\n$dfdrive\n\n") end
        if nrow(dfdrive) ≠ 1
            last_play = dfdrive[end, :Play_type]
            if last_play ∈ ["End Period", "End of Half", "End of Game", "End of Regulation"]
                last_play = dfdrive[end-1, :Play_type]
            end
            if last_play ∈ ["Fumble Recovery (Opponent)", "Fumble Return Touchdown", "Interception", "Interception Return Touchdown", "Pass Interception Return"]
                turnover_bool = true
            else
                turnover_bool = false
            end
            turnover_vec = vcat(turnover_vec, fill(turnover_bool, nrow(dfdrive)))
        else
            turnover_vec = vcat(turnover_vec, [false])
        end
    end
    DataFrame(:Turnover_drive => turnover_vec)
end

function score_turnover_column_generate(df)
    score_turnover_vec = String[]
    score_vec = df[!, :Score_drive]
    turnover_vec = df[!, :Turnover_drive]

    for i in 1:length(score_vec)
        if turnover_vec[i]
            push!(score_turnover_vec, "Turnover")
        elseif score_vec[i]
            push!(score_turnover_vec, "Score")
        else
            push!(score_turnover_vec, "Neither")
        end
    end
    DataFrame(:Score_Turnover_drive => score_turnover_vec)
end

"""
Takes Symbol("Play type") :Scoring
"""
function oscoring(cols)
    playtype = cols[1]
    scoring = cols[2]

    #println("playtype: $playtype, scoring: $scoring")
    # if playtype == "Interception Return Touchdown"
    if playtype ∈ ["Interception Return Touchdown", "Fumble Return Touchdown", "Safety"]
        false
    elseif scoring == true
        true
    else
        false
    end
end

