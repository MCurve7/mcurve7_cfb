using Revise
includet("processGame.jl")
using Logging
using Base.Threads: @threads, @spawn

println("Number of threads: ", Threads.nthreads())
############################################################################################################
#NOTE: 
#school_colors.csv uses ; as delimiter



############################################################################################################


############################################################################################################
#Runs process_game on all unprocessed files, but skips processed games if overwrite = false
function run_all_games()
    dirContents = readdir("../../data/unprocessed", join=true)
    setdiff!(dirContents, ["../../data/unprocessed\\corrected"])
    processed_directory = "..\\..\\data\\"

    # @Logging.configure(level=DEBUG)
    # Logging.configure(filename="../notes/logfile.log")

    overwrite = false
    # overwrite = true
    
    
    for game in dirContents
    # @threads for game in dirContents
        game_split = split(game, r"[\\/]")
        #println("Split directory: $game_split")
        game_file = last(game_split)
        #println("File name: $game_file")
        processed_game = split(game_file, ".")
        # println("Filename split: $processed_game")
        processed_game = processed_game[1]*"-processed."*processed_game[2]
        #println("New filename split: $processed_game")
        if overwrite || !isfile(processed_directory*processed_game)
            println("Processing game: $game \n")
            df = process_game(game)
            CSV.write(processed_directory*processed_game, df, transform = (col,val) -> something(val, ""))
        end

    end
end
@time run_all_games()

############################################################################################################
#To run a specific game

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
dirContents = readdir("../../data/unprocessed", join=true)
# dirContents[205]
# # ≈ + 123
# dirContents[341]

# dirContents[13628]
#Appalachian State_2018_wk14_regular.csv

i=findall(x->x=="../../data/unprocessed\\Alabama_2023_wk14_regular.csv", dirContents)[1]
dirContents[i]
@time run_game(i)

i=findall(x->x=="../../data/unprocessed\\Kentucky_2023_wk11_regular.csv", dirContents)[1]
dirContents[i]
@time run_game(i)
############################################################################################################
GET_NAMES = true
# GET_NAMES = false

global names_df = DataFrame(Name = String[], Txt = String[])

function add_names_df!(names_df, name, txt)
    global names_df = vcat(names_df, DataFrame(Name = [name], Txt = [txt]))
end

dirContents = readdir("../../data/unprocessed", join=true)
process_game(dirContents[1])

# dirContents[1587:end]
#Get names
function run_all_games_names()
    dirContents = readdir("../../data/unprocessed", join=true)

    # @Logging.configure(level=DEBUG)
    # Logging.configure(filename="../notes/logfile.log")

    # names_df = DataFrame(Name = String[], Txt = String[])

    for j in 7500:500:10000
    # j = 7500
        i = j
        lastval = j < 10000 ? j+500 : length(dirContents)
        # for game in dirContents[j+1:j+500]
        @threads for game in dirContents[j+1:lastval]
            i += 1
            game_split = split(game, r"[\\/]")
            game_file = last(game_split)
            processed_game = split(game_file, ".")
            processed_game = processed_game[1]*"-processed."*processed_game[2]
            println("Game number: $i, Thread: ", Threads.threadid())
            println("Processing game: $game")
            process_game(game)
            
        end
        CSV.write("../../data/all_games/names_play_text-$(j+500).csv", names_df)
    end
end
@time run_all_games_names()




# dirContents = readdir("../../data/unprocessed", join=true)
# dirContents[562]
# process_game(dirContents[1])

dirContents = readdir("../../data/unprocessed", join=true)
i=findall(x->x=="../../data/unprocessed\\Alabama_2023_wk02_regular.csv", dirContents)[1]

df = CSV.read(dirContents[i], DataFrame; normalizenames=true, types = Dict(:Scoring => Bool, :Distance => Int8, :Yards_gained => Int8))
df = select(df, Not(:PPA))

