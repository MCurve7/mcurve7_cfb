using CSV
using DataFrames
using DataFramesMeta
using DelimitedFiles
using RCall
R"library(tidyverse)"
@rlibrary ggplot2
import FloatingTableView

function make_penalty_df(df)
    penalties1_df = DataFrame(Penalty1_type = [], Penalty1_status = [], Penalty1_team = [], Penalty1_transgressor = [], Defense = [], Offense = [], Play_text = [])
    penalties2_df = DataFrame(Penalty2_type = [], Penalty2_status = [], Penalty2_team = [], Penalty2_transgressor = [], Defense = [], Offense = [], Play_text = [])
    penalties3_df = DataFrame(Penalty3_type = [], Penalty3_status = [], Penalty3_team = [], Penalty3_transgressor = [], Defense = [], Offense = [], Play_text = [])
    
    #get rows with non missing penalty rows
    penalties_df = filter([:Penalty1_type] => row -> !ismissing(row), df)
    
    #make dataframes with one penalty per
    penalties1_df = penalties_df[:, [:Penalty1_type, :Penalty1_status, :Penalty1_team, :Penalty1_transgressor, :Defense, :Offense, :Play_text]]
    penalties2_df = penalties_df[:, [:Penalty2_type, :Penalty2_status, :Penalty2_team, :Penalty2_transgressor, :Defense, :Offense, :Play_text]]
    penalties3_df = penalties_df[:, [:Penalty3_type, :Penalty3_status, :Penalty3_team, :Penalty3_transgressor, :Defense, :Offense, :Play_text]]
    #rename columns to same name
    rename!(penalties1_df, [:Penalty1_type, :Penalty1_status, :Penalty1_team, :Penalty1_transgressor] .=> [:Penalty_type, :Penalty_status, :Penalty_team, :Penalty_transgressor])
    rename!(penalties2_df, [:Penalty2_type, :Penalty2_status, :Penalty2_team, :Penalty2_transgressor] .=> [:Penalty_type, :Penalty_status, :Penalty_team, :Penalty_transgressor])    
    rename!(penalties3_df, [:Penalty3_type, :Penalty3_status, :Penalty3_team, :Penalty3_transgressor] .=> [:Penalty_type, :Penalty_status, :Penalty_team, :Penalty_transgressor])

    #concat above new dataframes and then remove missing rows
    penalties_df = vcat(penalties1_df, penalties2_df, penalties3_df)
    penalties_df = filter([:Penalty_type] => row -> !ismissing(row), penalties_df)    
end

SEC_teams = readdlm("../school_colors/SEC_teams.csv", ',')

dirContents = readdir("../../data", join=true)
dirContents[286]

i = 286

i = 285
game = dirContents[i]
df = DataFrame(CSV.File(game, normalizenames=true))



penalties_df = make_penalty_df(df)

penalties_enforced_df = filter([:Penalty_status] => row -> row =="enforced", penalties_df)
penalties_declined_df = filter([:Penalty_status] => row -> row =="declined", penalties_df)
penalties_offsetting_df = filter([:Penalty_status] => row -> row =="offsetting", penalties_df)
penalties_ambiguous_df = filter([:Penalty_status] => row -> row =="ambiguous", penalties_df)

combine(groupby(penalties_df, [:Penalty_team]), nrow)
combine(groupby(penalties_df, [:Penalty_team, :Penalty_status]), nrow)

FloatingTableView.browse(penalties_df)

function SEC_only_season(year, type)
    #type: standard (nonSECCG), regular
    SEC_df = similar(DataFrame(CSV.File("../../data/Alabama_2021_wk01_postseason-processed.csv", normalizenames=true)))
    deleteat!(SEC_df, 1:nrow(SEC_df))
    directory_prefix = "../../data/"
    type == "regular" ? weeklist = ["wk01", "wk02", "wk03", "wk04", "wk05", "wk06", "wk07", "wk08", "wk09", "wk10", "wk11", "wk12", "wk13", "wk14"] : weeklist = ["wk01", "wk02", "wk03", "wk04", "wk05", "wk06", "wk07", "wk08", "wk09", "wk10", "wk11", "wk12", "wk13"]
    for team in SEC_teams, week = weeklist
        file_pattern = "$(team)_$(year)_$(week)_$(type)-processed.csv"
        game = directory_prefix*file_pattern
        if isfile(game)
            SEC_df = vcat(SEC_df, DataFrame(CSV.File(game, normalizenames=true)))
        end
    end
    SEC_df = unique(SEC_df)
    SEC_df = filter(:Home => h -> (h in SEC_teams), SEC_df)
    SEC_df = filter(:Away => a -> (a in SEC_teams), SEC_df)    
end



function FBS_season(year, type)
    #type: standard (nonConferenceCG), regular, postseason, all

    #get a team, make similiar DF, and then delete all rows to make empty version
    FBS_df = similar(DataFrame(CSV.File("../../data/Alabama_2021_wk01_postseason-processed.csv", normalizenames=true)))
    deleteat!(FBS_df, 1:nrow(FBS_df))

    #get list of FBS teams
    FBS_teams = DataFrame(CSV.File("../school_colors/teams-fbs-$year.csv", normalizenames=true)).Name

    directory_prefix = "../../data/"
    if type == "all" || type == "regular" || type == "standard"
        #FIX must get max number of weeks for each season
        type == "all" || type == "regular" ? weeklist = ["wk01", "wk02", "wk03", "wk04", "wk05", "wk06", "wk07", "wk08", "wk09", "wk10", "wk11", "wk12", "wk13", "wk14", "wk15"] : weeklist = ["wk01", "wk02", "wk03", "wk04", "wk05", "wk06", "wk07", "wk08", "wk09", "wk10", "wk11", "wk12", "wk13"]
        for team in FBS_teams, week in weeklist
            file_pattern = "$(team)_$(year)_$(week)_regular-processed.csv"
            game = directory_prefix*file_pattern
            if isfile(game)
                FBS_df = vcat(FBS_df, DataFrame(CSV.File(game, normalizenames=true)))
            end
        end
    elseif type == "postseason" || type == "all"
        for team in FBS_teams, week in ["wk01", "wk02"]
            file_pattern = "$(team)_$(year)_$(week)_postseason-processed.csv"
            game = directory_prefix*file_pattern
            if isfile(game)
                FBS_df = vcat(FBS_df, DataFrame(CSV.File(game, normalizenames=true)))
            end
        end
    end
    FBS_df = unique(FBS_df)
    FBS_df = filter(:Home => h -> (h in FBS_teams), FBS_df)
    FBS_df = filter(:Away => a -> (a in FBS_teams), FBS_df)
end



SEC_df = SEC_only_standard_season(2021)

SEC_df

SEC_penalties = make_penalty_df(SEC_df)
SEC_penalties_enforced_df = filter([:Penalty_status] => row -> row =="enforced", SEC_penalties)
SEC_penalties_declined_df = filter([:Penalty_status] => row -> row =="declined", SEC_penalties)
SEC_penalties_offsetting_df = filter([:Penalty_status] => row -> row =="offsetting", SEC_penalties)
SEC_penalties_ambiguous_df = filter([:Penalty_status] => row -> row =="ambiguous", SEC_penalties)

SEC_penalties_count = rename!(combine(groupby(SEC_penalties, [:Penalty_team]), nrow), [:nrow] .=> [:Count])
SEC_penalties_analysis = sort(transform(SEC_penalties_count, [:Count] => ByRow(x -> x/8) => :Avg), [order(:Penalty_team)])

SEC_avg = sum(SEC_penalties_analysis.Avg)/14

school_colors = DataFrame(CSV.File("../school_colors/school_colors.csv", delim=';'))
school_colors = school_colors[:, [:School, :Primary]]
team_colors = filter([:School] => row -> row in SEC_teams, school_colors).Primary
@rput SEC_penalties_count
@rput SEC_penalties_analysis
@rput team_colors
@rput SEC_teams
@rput SEC_avg
@rput year
R"penalty_colors <- setNames(team_colors, SEC_teams)"

R"""
SEC_penalties <- ggplot(SEC_penalties_analysis, aes(x = Penalty_team, y = Avg, fill = Penalty_team)) +
    geom_hline(yintercept = SEC_avg, linetype='dashed') +
    geom_bar(stat = "identity") +
    scale_fill_manual(values = penalty_colors) +
    scale_y_continuous(breaks = seq(0, 12, by = 1)) +
    theme(axis.title.x = element_blank()) +
    ggtitle(paste(year, " SEC Teams average per game penaltes: ", "Mean(SEC) = ", sprintf("%1.3f", SEC_avg)))
    #ggtitle(paste(year, " SEC Teams average per game penaltes: ", "Mean(SEC) = ", sprintf("%1.3f", SEC_avg), ", sd(SEC) = ", sprintf("%1.3f", SEC.sd)))
"""

FloatingTableView.browse(SEC_penalties)