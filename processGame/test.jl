#used for testing code

using Revise
using DataFrames
import FloatingTableView
# using FLoops
includet("processGame.jl")

#using StringEncodings

# name_regex = "(((?:[A-Z\\p{Lu}'-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+|(?:de))|(?:[A-Z\\p{Lu}-]\\.?)?\\s?)+)" #most general name regex
# Regex("$(name_regex)")
#name_lastfirst_regex = "((?:(?:[A-Z\\p{Lu}\\.-]+|[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+ ?)+, ?[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+))" #general last first regex

# name_caplastfirst_regex = "([A-Z\\p{Lu}-]+, ?(?:[A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+))" #just made it work need to genalize it last first

function run_all_games()
    dirContents = readdir("../../data/unprocessed", join=true)
    processed_directory = "..\\..\\data\\"

    overwrite = false
    
    for game in dirContents
        game_split = split(game, r"[\\/]")
        #println("Split directory: $game_split")
        game_file = last(game_split)
        #println("File name: $game_file")
        processed_game = split(game_file, ".")
        #println("Filename split: $processed_game")
        processed_game = processed_game[1]*"-processed."*processed_game[2]
        #println("New filename split: $processed_game")
        if overwrite || !isfile(processed_directory*processed_game)
            println("Processing game: $game")
            df = process_game(game)
            CSV.write(processed_directory*processed_game, df, transform = (col,val) -> something(val, ""))
        end

    end
end
@time run_all_games()

function run_game(n)
    dirContents = readdir("../../data/unprocessed", join=true)
    processed_directory = "..\\..\\data\\"
    game = dirContents[n]
    game_split = split(game, r"[\\/]")
    #println("Split directory: $game_split")
    game_file = last(game_split)
    #println("File name: $game_file")
    processed_game = split(game_file, ".")
    #println("Filename split: $processed_game")
    processed_game = processed_game[1]*"-processed."*processed_game[2]
    #println("New filename split: $processed_game")
    
    println("Processing game: $game")
    df = process_game(game)
    CSV.write(processed_directory*processed_game, df)
    
end

debug_game_list = []
function debug_games()
    dirContents = readdir("../../data/unprocessed", join=true)
    for game ∈ dirContents
        
        #DEBUGGING avoid writing files until debugiing is done: reset debug_game_list to []
        if game ∉ debug_game_list
            
            println("Debug Processing game: $game")

            process_game(game)
            #push!(debug_game_list, game)
            global debug_game_list = vcat(debug_game_list,[game])
        end
    end
end
debug_game_list[end]
@time debug_games()

# unicode_game_list = []
# #Trying to find games that have unicode that breaks my code and clean up before sending to play_info
# # May have to find fcn that broke and comment out unicode fix and go from there
# function fix_unicode_e()
#     dirContents = readdir("../../data/unprocessed", join=true)
#     game_w_e = Vector{String}
#     for game ∈ dirContents
        
#         println("Processing game: $game")

#         df = CSV.read(game, DataFrame; normalizenames=true)
#         play_texts = df[:, :Play_text]
#         for play_text ∈ play_texts
#             #println(play_text)
#             if ismissing(play_text)
#                 play_text = "blank"
#             elseif occursin("run", play_text)
#                 regex  = Regex("$(name_regex)")
#                 temp = strip(match(regex, play_text)[1])
#                 #game_w_e = vcat(game_w_e,[game])
#             end
#         end
          
#         global unicode_game_list = vcat(unicode_game_list,[game])
#     end
#     game_w_e
# end
# fix_unicode_e()

dirContents = readdir("../../data/unprocessed", join=true)
FloatingTableView.browse(DataFrame(Teams = dirContents))
dirContents[299]

i = 299
dirContents[i]
# begin
    game = dirContents[i]
    df = CSV.read(game, DataFrame; normalizenames=true)
    df = process_game(game)
# end
FloatingTableView.browse(df)
# df.Penalty1[57]


drive_number_list = unique(df.Drive_number)
for i in 1:length(drive_number_list)
    dfdrive = filter(:Drive_number => x->(x==drive_number_list[i]), df)
    len_dfdrive = nrow(dfdrive)

    if dfdrive[len_dfdrive, :Play_type] ∈ ["Field Goal Good", "Interception Return Touchdown"]
        println("I see non-O score")
    end
end




for i in 1:length(df.Play_text)
    last_i = i
    # println(penalties.Play_text[i])
    if !ismissing(df.Play_text[i]) && !isnothing(df.Play_text[i]) && occursin(r"(?:Penalty|PENALTY)", df.Play_text[i])
        println("N = $(length(df.Play_text)), i = $i, $(i/(length(df.Play_text))*100)%")
        # foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text[i], penalties.Offense[i], penalties.Defense[i]])
        type1, status1, team1, transgressor1, type2, status2, team2, transgressor2, type3, status3, team3, transgressor3 = foul_analysis([df.Play_text[i], df.Offense[i], df.Defense[i]])
        println(" ")
        if ismissing(type1)
            break
        end
    end
end

i = 12
type1, status1, team1, transgressor1, type2, status2, team2, transgressor2, type3, status3, team3, transgressor3 = foul_analysis([df.Play_text[i], df.Offense[i], df.Defense[i]])



for i in 1:length(df.Play_text)
    println("i = $i")
    println("Play_text = $(df.Play_text[i])")
    println("Play_type = $(df.Play_type[i])")
    println("Offense = $(df.Offense[i])")
    println("Defense = $(df.Defense[i])")
    play_info([df.Play_text[i], df.Play_type[i], df.Offense[i], df.Defense[i]])
end

i=174
df.Play_text[i]
df.Play_type[i]
df.Offense[i]
df.Defense[i]

#############################################################################################
@time run_game(186)
#31
#############################################################################################
dirContents_processed = readdir("../../data/", join=true)
game = dirContents_processed[186] #First Bama
game = dirContents_processed[299] #Last Bama
df = CSV.read(game, DataFrame; normalizenames=true)
# FloatingTableView.browse(df)
#############################################################################################


df_dirContents = DataFrame(dir = dirContents)
FloatingTableView.browse(df_dirContents)

# df_all_kickoff = CSV.read("../../data/all_games/all_kickoff.csv", DataFrame)
# FloatingTableView.browse(df_all_kickoff)

df_run = df[!,[:Play_text, :Play_type]]

for i in 1:nrow(df_run)
    println("i = $(i)")
    println(df_run[i, :Play_text])
    punter, receiver, returner, blocker, PAT_kicker, PAT, PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver, punt, punt_type = play_punt_return_td(df_run[i, :Play_text])
    println("punter = $(punter), returner = $(returner), \n")
end

kicker, returner, PAT_kicker, PAT, PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = play_punt_return_td(df_run[1, :Play_text])

############################################################################################################################################################################
# TESTING foul_analysis for specific team
dirContents = readdir("../../data/", join=true)
dirContents[11463]
team = CSV.read(dirContents[11463], DataFrame)
i = 90
team.Play_text[i]
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([team.Play_text[i], team.Offense[i], team.Defense[i]])


############################################################################################################################################################################
# TESTING foul_analysis
penalties = CSV.read("../../data/all_games/all_games_utf8.csv", DataFrame)
rename!(penalties, Symbol("Play text") => :Play_text)

last_i = 1

range_minus = last_i:length(penalties.Play_text)
# Threads.@threads for i in 1:length(penalties.Play_text)
for i in range_minus
    last_i = i
    # println(penalties.Play_text[i])
    if !ismissing(penalties.Play_text[i]) && !isnothing(penalties.Play_text[i]) && occursin(r"(?:Penalty|PENALTY)", penalties.Play_text[i])
        println("N = $(length(penalties.Play_text)), i = $i, $(i/(length(penalties.Play_text))*100)%")
        # foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text[i], penalties.Offense[i], penalties.Defense[i]])
        type1, status1, team1, transgressor1, type2, status2, team2, transgressor2, type3, status3, team3, transgressor3 = foul_analysis([penalties.Play_text[i], penalties.Offense[i], penalties.Defense[i]])
        println(" ")
        if ismissing(type1)
            break
        end
    end
end
last_i

i = 21815
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text[i], penalties.Offense[i], penalties.Defense[i]])


#Pretty sure I am not going to store penalty info in a vector in the dataframe
i = 2080566
package_foul([penalties.Play_text[i], penalties.Offense[i], penalties.Defense[i]])

penalties_regex_txt = "(?:Penalty|PENALTY)"


############################################################################################################################################################################
penalties = CSV.read("../../data/Alabama_2022_wk04_regular-processed.csv", DataFrame)
i = 114
penalties.Play_text[i]

foul_analysis([penalties.Play_text[i], penalties.Offense[i], penalties.Defense[i]])
############################################################################################################################################################################
penalties = CSV.read("../../data/all_games/all_penalties.csv", DataFrame)
# penalties_enforced = CSV.read("../../data/all_games/all_penalties_enforced.csv", DataFrame)
# penalties_declined = CSV.read("../../data/all_games/all_penalties_declined.csv", DataFrame)
# penalties_offsetting = CSV.read("../../data/all_games/all_penalties_offsetting.csv", DataFrame)




game = dirContents_processed[299]

i = 9744
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 9800
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 16838
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 18102
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 77232
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 83883
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 116185
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 139695
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 141168
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 144909
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])

i = 23974
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 35478
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 111180
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 111181
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 143481
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 61289
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])

#triple
i = 75696
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 130670
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
# declined accepted
i = 152712
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 4092
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 5292
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 125867
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 152725
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 1561
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 23955
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 73817
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 149619
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 135109
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 135522
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 153060
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 127499
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 129440
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 130381
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 130673
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 52695
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 65221
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 76489
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 102619
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 83926
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 95246
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 80986
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 92524
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
#declined name = name-name
i = 115759
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
#special case
i = 104235
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])

# Accepted-declined
#no names
i = 152548
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
#rev name
i = 8218
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 13540
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 113443
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 146635
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 131947
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 53387
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 97796
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 33598
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 13554
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])

i = 123213
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 110999
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
#missing foul
i = 36174
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])


# Decliend (NA)
i = 990
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 999
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 1001
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 1002
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 1013
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 3554
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 9873
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 56093
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 110238
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 125011
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])

#TEAM ###############################################################################
i = 9754
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 20454
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 50363
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 67784
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 70319
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 70331
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 77211
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 77280
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 83781
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 107740
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 113574
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])


#Yards ####################################################################################
i = 152179
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 11276
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 154950
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 4379
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 50686
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
#Yards:
i = 140176
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 50935
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 106855
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 146142
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
#penalty_team_team_yards
i = 53505
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
#\d Yards):
i = 12931
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 17929
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 105685
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
#Double space no penalty
i = 121632
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 12804
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])

i = 13839
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 34248
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 87426
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])

i = 144727
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 140989
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])

#ERROR unicode problem. Because I used LibreOffice instead of Excel?
i = 106786
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])




#no paraenthesis, no name
i = 4825
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 4826
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 21108
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 32005
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 32037
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 94074
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 102096
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 105410
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 113727
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])

#penalty_team_team
i = 14309
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 82747
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 94780
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 96875
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 124920
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 70272
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
#
i = 111290
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 139661
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 37831
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
#penalty_name_regex
i = 152187
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 794
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 1033
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 2049
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 2051
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 2055
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 2232
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 2318
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 153565
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 2342
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 2343
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 2347
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 2422
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 2662
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 2798
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 2877
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 2975
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 3250
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 21703
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 130974
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 50176
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 104165
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])


#team_penalty_penalty_on
i = 124909
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 51321
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])





#MISC:
i = 106738
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 85344 #Works if hard code [Ff]ace [Mm]ask but not when looping over penalty_type_vec ?! I think it is fixed...hopefully.
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 35543
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 143509
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 55894
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 95733
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 109799
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])
i = 34405
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_declined[i], penalties.Offense[i], penalties.Defense[i]])



# OFFSETTING ###########################################################################################################
#off
i = 17093
@time foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 931
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 1712
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 34324
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 85956
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 117287
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 1112
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 51992
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 13558
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 17827
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
#triple
i = 59876
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 39752
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 76415
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 152489
@time foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 33830
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 1639
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 13046
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 53963
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 107457
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 32036
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 99269
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 65442
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 107457
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 2635
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 19923
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 69184
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])


#single off-setting
#uns
i = 137366
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 31954
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 114854
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])

i = 4769
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 29767
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 56436
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 2487
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 34002
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])

i = 13230
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 61281
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 58957
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 153266
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 30757
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])

i = 77120
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])

#single on
i = 35484
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 37972
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 101912
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])


#no ons
i = 23992
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 95634
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])


i = 27440
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])

i = 28519
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 37877
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 144925
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])


i = 77502
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 77505
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 134236
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 3789
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 23403
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 1334
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 36075
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])


i = 41485
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])
i = 61418
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_offsetting[i], penalties.Offense[i], penalties.Defense[i]])

# ENFORCED ###########################################################################################################
#team_penalty_penalty_enforced
i = 42576
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 58975
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 111177
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])

#team_penalty_penalty_revcapname
i = 155400
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 51317
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 83889
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 124933
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])

#penalty_team_spot_foul
i = 14211
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 20453
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 155414
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 40406
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 155465
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])

#penalty_team_half_distance
i = 101914
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 7102
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 67723
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 92098
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 107729
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 138573
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])

#penalty_team_enforced_0yards
i = 100813 
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])

#penalty_team_enforced_distance
i = 67687
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 33172
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 42526
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 18147
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 24022
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 30806
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 42566
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 66371
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 77209
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 100707
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 133781
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 155473
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])

#team_penalty_on_number
i = 86263
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 42527
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 22945
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 77128
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 86260
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])


#team_penalty_on_name
i = 835
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 19358
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 58381
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 126233
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 18089
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 141148 
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 790
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 792
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 4774
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 8660
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 15703
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 23908
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 28536
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 29705
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 30737
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 33245
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 36625
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 42567
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 71470
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 101957
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 118674
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 155471
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])


#team_penalty_enforced_paraen_numberteam
i = 4784
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 95761
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 107760
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 153302
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])

#team_penalty_enforced_name
i = 9746
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 98109
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])

#team_penalty_enforced_revcapname
i = 30735
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 849
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 2156
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 4720
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 4767
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])

#Caught by declined and enforced case
i = 18102
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])

#team_penalty_on_player
i = 49013
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 108944
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 29662
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 67675
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 101913
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 127344
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalties_text_enforced_rest[i], penalties.Offense[i], penalties.Defense[i]])
i = 127347

# REST ###########################################################################################################
##############################################################################################
#DONE
penalties = CSV.read("../../data/all_games/rest/all_penalties_team_penalty_penalty.csv", DataFrame)

for i in 1:length(penalties.Team_penalty_penalty)

    println("N = $(length(penalties.Team_penalty_penalty)), i = $i")
    foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Team_penalty_penalty[i], penalties.Offense[i], penalties.Defense[i]])
    println(" ")
    if isempty(foul_type)
        break
    end
end

i = 17
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Team_penalty_penalty[i], penalties.Offense[i], penalties.Defense[i]])
i = 111
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Team_penalty_penalty[i], penalties.Offense[i], penalties.Defense[i]])
i = 174
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Team_penalty_penalty[i], penalties.Offense[i], penalties.Defense[i]])

##############################################################################################
#DONE
penalties = CSV.read("../../data/all_games/rest/all_penalties_penalty_team_number.csv", DataFrame)

# last_i = 1

# range_minus = last_i:length(penalties.Penalty_team_number)
for i in 1:length(penalties.Penalty_team_number)

    println("N = $(length(penalties.Penalty_team_number)), i = $i")
    foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalty_team_number[i], penalties.Offense[i], penalties.Defense[i]])
    println(" ")
    if isempty(foul_type)
        break
    end
end

i = 1
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalty_team_number[i], penalties.Offense[i], penalties.Defense[i]])

##############################################################################################
penalties = CSV.read("../../data/all_games/rest/all_penalties_penalty_team_name.csv", DataFrame)
#DONE
last_i = 1

range_minus = last_i:length(penalties.Penalty_team_name)
# Threads.@threads for i in range_minus
for i in range_minus

    println("N = $(length(penalties.Penalty_team_name)), i = $i")
    foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalty_team_name[i], penalties.Offense[i], penalties.Defense[i]])
    println(" ")
    if isempty(foul_type) || foul_transgressor[1] == "Name regex error"
        break
    end
    last_i = i
end
last_i

i = 14337
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalty_team_name[i], penalties.Offense[i], penalties.Defense[i]])

##############################################################################################
#DONE (it uses penalty_team_name_case)
penalties = CSV.read("../../data/all_games/rest/all_penalties_penalty_team_na.csv", DataFrame)

for i in 1:length(penalties.Penalty_team_na)

    println("N = $(length(penalties.Penalty_team_na)), i = $i")
    foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalty_team_na[i], penalties.Offense[i], penalties.Defense[i]])
    println(" ")
    if isempty(foul_type) || foul_transgressor[1] == "Name regex error"
        break
    end
end

i = 1
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalty_team_na[i], penalties.Offense[i], penalties.Defense[i]])



##############################################################################################
#DONE
penalties = CSV.read("../../data/all_games/rest/all_penalties_penalty_team_team.csv", DataFrame)

for i in 1:length(penalties.Penalty_team_team)

    println("N = $(length(penalties.Penalty_team_team)), i = $i")
    foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalty_team_team[i], penalties.Offense[i], penalties.Defense[i]])
    println(" ")
    if isempty(foul_type)
        break
    end
end

i = 1
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalty_team_team[i], penalties.Offense[i], penalties.Defense[i]])

##############################################################################################
#DONE no examples at this time
penalties = CSV.read("../../data/all_games/rest/all_penalties_penalty_team_yards.csv", DataFrame)
i = 
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Penalty_team_yards[i], penalties.Offense[i], penalties.Defense[i]])



##############################################################################################
#DONE
penalties = CSV.read("../../data/all_games/rest/all_penalties_team_penalty_team.csv", DataFrame)

for i in 1:length(penalties.Team_penalty_team)

    println("N = $(length(penalties.Team_penalty_team)), i = $i")
    foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Team_penalty_team[i], penalties.Offense[i], penalties.Defense[i]])
    println(" ")
    if isempty(foul_type)
        break
    end
end

i = 1
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Team_penalty_team[i], penalties.Offense[i], penalties.Defense[i]])

##############################################################################################
#DONE
penalties = CSV.read("../../data/all_games/rest/all_penalties_team_penalty_number.csv", DataFrame)

last_i = 1

range_minus = last_i:length(penalties.Team_penalty_number)
# Threads.@threads for i in 1:length(penalties.Team_penalty_number)
for i in range_minus

    println("N = $(length(penalties.Team_penalty_number)), i = $i")
    foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Team_penalty_number[i], penalties.Offense[i], penalties.Defense[i]])
    println(" ")
    if isempty(foul_type)
        break
    end
    last_i = i
end

i = 52172
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Team_penalty_number[i], penalties.Offense[i], penalties.Defense[i]])

##############################################################################################
#DONE
penalties = CSV.read("../../data/all_games/rest/all_penalties_team_penalty_name.csv", DataFrame)

last_i = 1

range_minus = last_i:length(penalties.Team_penalty_name)
# Threads.@threads for i in 1:length(penalties.Team_penalty_name)
for i in range_minus

    println("N = $(length(penalties.Team_penalty_name)), i = $i")
    foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Team_penalty_name[i], penalties.Offense[i], penalties.Defense[i]])
    println(" ")
    if isempty(foul_type)
        break
    end
    last_i = i
end

i = 9497
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Team_penalty_name[i], penalties.Offense[i], penalties.Defense[i]])

##############################################################################################
#DONE
penalties = CSV.read("../../data/all_games/rest/all_penalties_team_penalty_na.csv", DataFrame)

last_i = 1

range_minus = last_i:length(penalties.Team_penalty_na)
# Threads.@threads for i in 1:length(penalties.Team_penalty_na)
for i in range_minus

    println("N = $(length(penalties.Team_penalty_na)), i = $i")
    foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Team_penalty_na[i], penalties.Offense[i], penalties.Defense[i]])
    println(" ")
    if isempty(foul_type)
        break
    end
    last_i = i
end

i = 25
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Team_penalty_na[i], penalties.Offense[i], penalties.Defense[i]])

##############################################################################################
#DONE
penalties = CSV.read("../../data/all_games/rest/all_penalties_team_penalty_yards.csv", DataFrame)

last_i = 1

range_minus = last_i:length(penalties.Team_penalty_yards)
# Threads.@threads for i in 1:length(penalties.Team_penalty_yards)
for i in range_minus

    println("N = $(length(penalties.Team_penalty_yards)), i = $i")
    foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Team_penalty_yards[i], penalties.Offense[i], penalties.Defense[i]])
    println(" ")
    if isempty(foul_type)
        break
    end
    last_i = i
end

i = 1
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Team_penalty_yards[i], penalties.Offense[i], penalties.Defense[i]])

##############################################################################################
#DONE
penalties = CSV.read("../../data/all_games/rest/all_penalties_unkown.csv", DataFrame)

last_i = 1

range_minus = last_i:length(penalties.Rest)
# Threads.@threads for i in 1:length(penalties.Rest)
for i in range_minus

    println("N = $(length(penalties.Rest)), i = $i")
    foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Rest[i], penalties.Offense[i], penalties.Defense[i]])
    println(" ")
    if isempty(foul_type)
        break
    end
    last_i = i
end

i = 20163
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Rest[i], penalties.Offense[i], penalties.Defense[i]])

##############################################################################################
t = DataFrame(CSV.File("../school_colors/penalty-types.csv", delim='~'))
t[13, :Penalties]
FloatingTableView.browse(t)
##############################################################################################
penalties = CSV.read("../../data/all_games/all_penalties_penalized.csv", DataFrame)

# last_i = 1

# range_minus = last_i:length(penalties.Penalty_team_number)
for i in 1:length(penalties.Play_text_penalized)

    println("N = $(length(penalties.Play_text_penalized)), i = $i")
    foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_penalized[i], penalties.Offense[i], penalties.Defense[i]])
    println(" ")
    if isempty(foul_type)
        break
    end
end

i = 1
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_penalized[i], penalties.Offense[i], penalties.Defense[i]])
i = 26
foul_type, foul_status, foul_team, foul_transgressor = foul_analysis([penalties.Play_text_penalized[i], penalties.Offense[i], penalties.Defense[i]])

#############################################################################################################################################################

t = ["FLORIDA", "FLORIDA ST"]
sort!(t, rev=true)
t

get_team_name("FLORIDA ST", "Florida", "(FLORIDA|FLA|UFL|UF)", "Florida State", "(FLORIDAST|FSU|FS|FLORIDA ST)")