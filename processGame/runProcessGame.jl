using Revise
includet("processGame.jl")
using Logging

############################################################################################################
#NOTE: 
#school_colors.csv uses ; as delimiter



############################################################################################################


############################################################################################################
#Runs process_game on all unprocessed files, but skips processed games if overwrite = false
function run_all_games()
    dirContents = readdir("../../data/unprocessed", join=true)
    processed_directory = "..\\..\\data\\"

    # @Logging.configure(level=DEBUG)
    # Logging.configure(filename="../notes/logfile.log")

    overwrite = false
    # overwrite = true
    
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
dirContents[205]
# ≈ + 123
dirContents[328]


i=327
dirContents[i]
@time run_game(i)