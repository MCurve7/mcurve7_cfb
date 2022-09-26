using CSV
using DataFrames
using Pipe: @pipe
using DelimitedFiles
using Unicode
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
add "process error" to all ifelse as a catchall
=#

#= Notes

Penalties:
I think U = unsportsmanlike conduct
=#

# DEBUG_PENALTY = true
DEBUG_PENALTY = false

# DEBUG_PLAY_INFO = true
DEBUG_PLAY_INFO = false

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

###############################################################################################################################################
#Main function

function process_game(game)
    df = CSV.read(game, DataFrame; normalizenames=true)
    df = select(df, Not(:PPA))
    # Need to process the play_text and replace unicode "\xc9" => "É" and "\xe9" => "é".

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
    
    df = transform(df, :Clock => ByRow(clock_reformat) => :Clock)
    #df = transform(df, AsTable([:Play_type, :Scoring]) => ByRow(oscoring) => :O_scoring) #Useful now? Use Who_scored instead?
    df = hcat(df, who_scored(df))
    df = transform(df, AsTable([:Down, :Distance]) => ByRow(yards_to_success) => :Yards_to_success)
    df = transform(df, AsTable([:Play_type, :Down, :Play_text, :Yards_gained, :Distance, :Scoring, :Who_scored]) => ByRow(successful) => :Success) #Fumble Return Touchdown use who_scored
    df = transform(df, AsTable([:Play_type, :Yards_gained, :Distance, :Who_scored, :Success]) => ByRow(tdfirst) => :TD_first)
    df = hcat(df, scoredrive(df)) # need to check for punt score and mark as false
    df = transform(df, AsTable([:Play_text, :Play_type, :Offense, :Defense]) => ByRow(play_info) => 
    [:Runner, :Passer, :Receiver, :Interceptor, :Tackler, :Forcer, :Fumbler, :Recoverer, :PAT_kicker, :PAT_type, :Two_point, :Two_point_type, 
    :Two_point_runner, :Two_point_passer, :Two_point_receiver, :Kicker, :Kick_type, :Returner, :Blocker, :FG_type, :Punter, :Punt_type, :Timeout_team, :Timeout_time])
    # df = transform(df, AsTable(:Play_text) => ByRow(foultype) => :Penalty_type)
    # df = transform(df, AsTable([:Play_text, :Offense, :Defense, :Penalty_type]) => ByRow(foulteam) => :Penalty_team)
    # df = transform(df, AsTable([:Play_text, :Penalty_type]) => ByRow(foultransgressor) => :Penalty_transgressor)
    df = transform(df, AsTable([:Play_text, :Offense, :Defense]) => ByRow(foul_analysis) => 
        [:Penalty1_type, :Penalty1_status, :Penalty1_team, :Penalty1_transgressor, :Penalty2_type, :Penalty2_status, :Penalty2_team, :Penalty2_transgressor, :Penalty3_type, :Penalty3_status, :Penalty3_team, :Penalty3_transgressor])

    df
end
###############################################################################################################################################

"""
Takes Symbol("Play type") :Scoring
"""
function oscoring(cols)
    playtype = cols[1]
    scoring = cols[2]

    #println("playtype: $playtype, scoring: $scoring")
    if playtype == "Interception Return Touchdown"
        false
    elseif scoring == true
        true
    else
        false
    end
end

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
        len_dfdrive = nrow(dfdrive)
        # df_len = length(unique(dfdrive.O_scoring))
        df_len = nrow(dfdrive[in(["offense"]).(dfdrive.Who_scored), :]) + 1
        # if dfdrive[len_dfdrive, :Play_type] == "Field Goal Good"
        if dfdrive[len_dfdrive, :Play_type] ∈ ["Field Goal Good", "Interception Return Touchdown", "Defensive 2pt Conversion", "Fumble Return Touchdown", "Blocked Field Goal Touchdown",
                                                "Blocked Punt Touchdown", "Missed Field Goal Return Touchdown"]
            for j in 1:len_dfdrive
                push!(scoredrivevec, false)
            end
        elseif df_len == 2
            if dfdrive[len_dfdrive, :Who_scored] == "offense"
                #print("len = "*string(df_len)*"\n")
                for j in 1:len_dfdrive
                    push!(scoredrivevec, true)
                end
            else
                for j in 1:len_dfdrive
                    push!(scoredrivevec, false)
                end
            end
        else
            #temp = unique(dfdrive.O_scoring)[1]
            # if unique(dfdrive.O_scoring)[1]
            if last(dfdrive.Who_scored) == "offense"
                #print("len = $df_len, temp=$temp: true\n")
                for j in 1:len_dfdrive
                    push!(scoredrivevec, true)
                end
            else
                #print("len = $df_len, temp = $temp: false\n")
                for j in 1:len_dfdrive
                    push!(scoredrivevec, false)
                end
            end
        end
    end
    #print(scoredrivevec)
    DataFrame(:Score_drive => scoredrivevec)
end


function who_scored(df)
    
    nr = nrow(df)

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

    DataFrame(:Who_scored => od_scored)
end

#######################################################################################################################################################################################
function foulteam_checkname(foulteam, offense, defense, school_colors)
    #println("foulteam: $foulteam, offense: $offense, defense: $defense")
    if foulteam !== nothing
        foulteam = replace(foulteam, "\xc9" => "É")
        foulteam = replace(foulteam, "\xe9" => "é")
        # if(!(occursin(Regex(filter(:School => x->(x==offense), school_colors).Penalty[1]), foulteam) || occursin(Regex(filter(:School => x->(x==defense), school_colors).Penalty[1]), foulteam)))
        if(!(occursin(Regex(filter(:School => x->(x==offense), school_colors).Abbreviation_regex[1]), foulteam) || occursin(Regex(filter(:School => x->(x==defense), school_colors).Abbreviation_regex[1]), foulteam)))
            foulteam = nothing
        end
    end
    foulteam
end

function strip_replace_match(regex, txt)
    penalties_regex = r"(Penalty)|(PENALTY)|(Penalty)|(PENALTY)"
    foulteam = match(regex ,txt)
    foulteam = (foulteam === nothing) ? foulteam : strip(replace(foulteam[1], penalties_regex => ""))
    
    foulteam
end

#################################################################################################################
# Don't need amymore, but waiting to delete until 100% sure
function foulteam(cols)
    txt = cols[1]
    offense = cols[2]
    defense = cols[3]
    isna = uppercase(cols[4])

    # println("txt: $txt...")
    # println("...offense: $offense, defense: $defense, isna: $isna\n")

    txt = ismissing(txt) ? "" : txt

    txt = replace(txt, "\xc9" => "É")
    txt = replace(txt, "\xe9" => "é")
    offense = replace(offense, "\xc9" => "É")
    offense = replace(offense, "\xe9" => "é")
    defense = replace(defense, "\xc9" => "É")
    defense = replace(defense, "\xe9" => "é")

    #penalties_regex = r"(Penalty)|(PENALTY)|(Penalty)|(PENALTY)"
    declined_regex = r"[Dd]eclined"
    enforced_regex = r"[Ee]nforced"

    team_penalties_enforcedDeclined_split_regex = 
    r"declined ((?:[A-Z\p{Lu}-]+\s?)+)\b"
    team_penalties_enforcedDeclined_combine_regex = 
    r"((?:[A-Z\p{Lu}-]+\s?)+)\b(?:(?:Penalty)|(?:PENALTY)|(?:Penalty)|(?:PENALTY))"
    declined_aux = 
    r"declined(.*)"
    team_penalties_aux_regex = 
    r"([A-Z\p{Lu}-]+)\b"

    team_penalties_before_regex =
    r"(?:PENALTY|Penalty),? Before the snap,? ([A-Z\p{Lu}-]+) "
    team_penalties_regex_pre_lower =
    r"(Penalty\s(([A-Z&\p{Lu}-]{2,}\s?)+))"
    team_penalties_regex_pre_upper =
    r"(PENALTY\s(([A-Z&\p{Lu}-]{2,}\s?)+))"
    team_penalties_regex_post_lower =
    r"((([A-Z&\p{Lu}-]{2,}\s?)+)\sPenalty)"
    team_penalties_regex_post_upper =
    r"((([A-Z&\p{Lu}-]{2,}\s?)+)\sPENALTY)"
    team_penalties_regex_titlecase_pre_lower =
    r"(Penalty\s(([A-Z\p{Lu}-][a-z\p{Ll}A-Z&\p{Lu}-]+\s?)+))"
    team_penalties_regex_titlecase_pre_upper =
    r"(PENALTY\s(([A-Z\p{Lu}-][a-z\p{Ll}A-Z&\p{Lu}-]+\s?)+))"
    team_penalties_regex_titlecase_pre_lower_single =
    r"(Penalty\s([A-Z\p{Lu}-][a-z\p{Ll}A-Z&\p{Lu}-]+))"
    team_penalties_regex_titlecase_pre_upper_single =
    r"(PENALTY\s([A-Z\p{Lu}-][a-z\p{Ll}A-Z&\p{Lu}-]+))"
    team_penalties_regex_titlecase_post_lower =
    r"((([A-Z\p{Lu}-][a-z\p{Ll}A-Z&\p{Lu}-]+\s?)+)\sPenalty)"
    team_penalties_regex_titlecase_post_upper =
    r"((([A-Z\p{Lu}-][a-z\p{Ll}A-Z&\p{Lu}-]+\s?)+)\sPENALTY)"
    team_penalties_regex_spacedUppers = 
    r"(?:PENALTY|Penalty),? ([A-Z] [A-Z])"

    foul_team_regexs = 
    [
        team_penalties_before_regex, team_penalties_regex_pre_lower, team_penalties_regex_pre_upper, team_penalties_regex_post_lower, 
        team_penalties_regex_post_upper, team_penalties_regex_titlecase_pre_lower, team_penalties_regex_titlecase_pre_upper, 
        team_penalties_regex_titlecase_pre_lower_single, team_penalties_regex_titlecase_pre_upper_single, 
        team_penalties_regex_titlecase_post_lower, team_penalties_regex_titlecase_post_upper, team_penalties_regex_spacedUppers
    ]

    #penalty_codes =["OF","CIT","IL","IS","BI","IF","IP","IM","TGB","FL","RO","OFF","IB","PS","FD","PFRP","RU","UR","DL","HL","IR"]

    #foulteam = "NA"
    foulteam = missing
    if isna != ""
        #println("Foul occurred.")
        school_colors = CSV.File("../school_colors/school_colors.csv", delim=';') |> DataFrame
        
        if(occursin(declined_regex, lowercase(txt)) && occursin(enforced_regex, lowercase(txt)) !== nothing)
            #Why didn't I get rid of the declined part and only process the enforced part? Fix in rewrite.
            #println("Declined and enforced.")
            if occursin(team_penalties_enforcedDeclined_split_regex, txt)
                foulteam = strip(match(team_penalties_enforcedDeclined_split_regex, txt)[1])
            elseif occursin(team_penalties_enforcedDeclined_combine_regex, txt)
                foulteam = strip(match(team_penalties_enforcedDeclined_combine_regex, txt)[1])
            else # catch edge case
                res_temp = strip(match(declined_aux, txt)[1])
                if occursin(team_penalties_aux_regex, res_temp)
                    foulteam = strip(match(team_penalties_aux_regex,res_temp)[1])
                end
            end
        elseif !occursin(declined_regex, lowercase(txt)) 
            for regex in foul_team_regexs
                foulteam = strip_replace_match(regex, txt)
                foulteam = foulteam_checkname(foulteam, offense, defense, school_colors)
                if foulteam !== nothing
                    break
                end
            end
        elseif occursin(declined_regex, lowercase(txt))
            #foulteam = "NA"
            foulteam = missing
        end

        if(ismissing(foulteam) || foulteam === nothing)
            println("foulteam: $foulteam")
            println("txt: $txt...")
            println("...offense: $offense, defense: $defense, isna: $isna")
            foulteam = ""
        end
        #println("offense: $offense, defense: $defense, foulteam: $foulteam")
        #if foulteam != "NA"            
            if occursin(Regex(filter(:School => x->(x==offense), school_colors).Abbreviation_regex[1]), foulteam)
                foulteam = offense
            elseif occursin(Regex(filter(:School => x->(x==defense), school_colors).Abbreviation_regex[1]), foulteam)
                foulteam = defense
            else
                foulteam = "Add team code for: $foulteam"
            end
        #end
    end
    
    foulteam
end

#Need to check for TD, in Interception Return Touchdown they are not always tagged with declined:
# Daniel Jones pass intercepted for a TD Nasir Greer return for 20 yds for a TD WAKE FOREST Penalty, false start (-89 Yards) to the WFrst 8 (Nick Sciba KICK)
# Need to check all Play_types that involve penalties
#Need to return:
# foul: accepted/declined/offsetting
# foul_type: from data
function foultype(cols)
    txt = cols[1]

    #println("txt: $txt")
    txt = ismissing(txt) ? "NA" : txt

    txt = replace(txt, "\xc9" => "É")
    txt = replace(txt, "\xe9" => "é")

    #penalty_type_list = CSV.File("../../data/FBS/penalty-types.csv") |> DataFrame
    penalty_type_list = DataFrame(CSV.File("../school_colors/penalty-types.csv", delim='~'))
    penalty_type_list = penalty_type_list.Penalties
    penalty_codes = ["BI","DL","FD","FL","HL","IB","IF","IK","IL","IM","IP","IR","IS","OF","PS","RO","RU","UR","CIT","OFF","TGB","PFRP"]

    #penalties_regex = r"(Penalty)|(PENALTY)|(Penalty)|(PENALTY)"
    declined_regex = r"[Dd]eclined"
    enforced_regex = r"[Ee]nforced"
    offsetting_regex = r"off-? ?setting"
    regex_text_after_penalty = r"((PENALTY|Penalty).+)"

    type_penalties_enforcedDeclined_split_regex = r"declined;? (?:[A-Z\p{Lu}-]+\s?)+\b ((?:[A-Z\p{Lu}a-z\p{Ll}-]+\s?)+) on"
    type_penalties_enforcedDeclined_combine_regex_stage1 = r"(?:[A-Z\p{Lu}-]+\s?)+\b(?:(?:Penalty)|(?:PENALTY)|(?:Penalty)|(?:PENALTY)),?\s*(.+)"

    foul_type_regex =
    [
      r"(?:PENALTY|Penalty),? (?:[A-Z-]{2,}) State ((?:\w+\s)+)[\d\(]"
      ,r"(?:PENALTY|Penalty),? [A-Z-]{2,}(?: [A-Z-]{2,}),? ((?:\w+\s)+?)\s*[\d\(]"
      ,r"(?:PENALTY|Penalty),? (12 (\w+\s)+)[\d|\(]"
      ,r"(?:PENALTY|Penalty),? [A-Z-]{2,},? ((?:\w+\s)+?)\s*[\d\(]",r"(?:PENALTY|Penalty),? fumbled snap.+?(?:PENALTY|Penalty),? Before the snap,? ((?:\w+\s)+?)(?:on|enforced|\d)"
      ,r"(?:PENALTY|Penalty),? ((?:[A-Za-z]+\s)+)[\d\(]"
      ,r"(?:PENALTY|Penalty),? [A-Z0-9-]+ ((?:\w+\s)+)on"
      ,r"(?:PENALTY|Penalty),? [A-Z0-9-]+ ((?:\w+\s)+)\("
      ,r"(?:PENALTY|Penalty),? ((?:\w+\s)+)(?:on|enforced)"
      ,r"(?:PENALTY|Penalty),? Before the snap,? [A-Z-]+ ((?:\w+\s)+?)(?:on|enforced|\d)"
      ,r"(?:PENALTY|Penalty),?(\s+)\("
      ,r"(?:PENALTY|Penalty),? [A-Z-]{2,} [A-Z-]{2,}: ((?:\w+\s)+)[\d\(]"
      ,r"(?:PENALTY|Penalty),? [A-Z-]{2,}: ((?:\w+\s)+)[\d\(]"
      ,r"(?:PENALTY|Penalty),? [A-Z-]{2,} ([A-Z-]{2,}) [\d\(]"
      ,r"(?:PENALTY|Penalty),? .+ (Targeting)"
    ]
    #foul_type_group <- [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]

    foultype = nothing
    if(occursin(declined_regex, lowercase(txt)) && occursin(enforced_regex, lowercase(txt)))# != nothing)
        if occursin(type_penalties_enforcedDeclined_split_regex, txt)
            foultype = strip(match(type_penalties_enforcedDeclined_split_regex, txt)[1])
        else
            text_txt = match(type_penalties_enforcedDeclined_combine_regex_stage1, txt)[1]
            #println("text_txt: $text_txt")
            penalty_split = split(text_txt, " ")
            #println("penalty_split: $penalty_split")
            missed_it = true
            for  i in 1:(length(penalty_split)-1)#1:3
                for j in (i+2):length(penalty_split)#1:3
                    declined = join(penalty_split[1:i], " ")
                    enforced = join(penalty_split[i+1: j], " ")
                    #print("Declined: $declined, Enforced: $enforced\n")

                    if((titlecase(declined) in penalty_type_list) && titlecase(enforced) in penalty_type_list)
                        foultype = enforced
                        missed_it = false
                        break
                    end
                end
                missed_it && (foultype = "What: $text_txt")
            end
        end
    elseif(!occursin(offsetting_regex, lowercase(txt)) && !occursin(declined_regex, lowercase(txt)) && occursin(regex_text_after_penalty, txt))
        #txt = match(regex_text_after_penalty, txt)
        #txt = (txt == nothing) ? txt : txt[1]
        txt = match(regex_text_after_penalty, txt)[1]

        foultype = match(foul_type_regex[1], txt)
        foultype = (foultype === nothing) ? foultype : strip(foultype[1])
        i = 2
        while foultype === nothing
            if i > length(foul_type_regex)
                foultype = ""
                break
            end
            foultype = match(foul_type_regex[i], txt)
            foultype = (foultype === nothing) ? foultype : strip(foultype[1])
            #foultype = strip(match(foul_type_regex[i])[1], txt)
            i += 1
        end
    end

    if(foultype == "NA" || foultype === nothing)
        foultype = ""
    elseif(foultype ∉ penalty_codes) 
        if foultype == "Offsides"
            foultype = "Offside"
        end
        foultype = titlecase(foultype)
        if foultype == "Personal Foul Targeting"
            foultype = "Personal Foul, Targeting"
        elseif foultype == "Block Below The Waist"
            foultype = "Block Below Waist"
        end
    end

    foultype
end

function foultransgressor(cols)
    txt = cols[1]
    isna = cols[2]

    txt = ismissing(txt) ? "" : txt

    txt = replace(txt, "\xc9" => "É")
    txt = replace(txt, "\xe9" => "é")

    if isna != ""
        penalty_who_regex = r".*\(((?:[A-Z\p{Lu}][a-z\p{Ll}',\.-]+\s?)+)\)"
        res3 = match(penalty_who_regex, txt)
        if res3 === nothing
            res3 = "Unknown"
        else
            res3 = strip(res3[1])
        end
    else
        res3 = ""
    end
    res3
end

function foultransgressor(cols)
    txt = cols[1]
    isna = cols[2]

    txt = ismissing(txt) ? "" : txt

    txt = replace(txt, "\xc9" => "É")
    txt = replace(txt, "\xe9" => "é")

    if isna != ""
        penalty_who_regex = r".*\(((?:[A-Z\p{Lu}][a-z\p{Ll}',\.-]+\s?)+)\)"
        penalty_who_on_regex = r"on (?:#\d+ )?([A-Z'-]+, [A-Z][a-z'-]+)"
        
        if occursin(penalty_who_regex, txt)
            foultransgressor = strip(match(penalty_who_regex, txt)[1])
        elseif occursin(penalty_who_on_regex, txt)
            lastname, firstname = strip.(split(match(penalty_who_on_regex, txt)[1], ","))
            foultransgressor = "$(firstname) $(titlecase(lastname))"
        else
            foultransgressor = "Unknown"
        end
    else
        foultransgressor = ""
    end
    foultransgressor
end

function clock_reformat(time)
    clock = JSON.parse(replace(time, "'" => '"'))
    "$(clock["minutes"]):$(@sprintf("%02d",clock["seconds"]))"
end
#END old foul functions
##############################################################################################################

#####################################################################################################



