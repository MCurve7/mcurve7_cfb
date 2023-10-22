using DataFrames
using CSV

#Goto https://www.espn.com/college-football/schedule before games begin, copy/paste starting with MATCHUP to end of that day into a text file called: copy_paste_$(year)_$week.txt

year = 2023
week = "08"
open("copy_paste_$(year)_$week.txt") do f
 
    readline(f)
    readline(f)
    readline(f)
    readline(f)
    readline(f)
    readline(f)
    my_input = readlines(f)
    println(my_input[1])

    df = DataFrame(Matchup = String[], Time = String[], TV = String[])

    i = 0
    team1 = ""
    team2 = ""
    tv_time = ""
    tv = ""
    for line in my_input
        i += 1
        println("Seeing: i = $i, line = $line")
        if !isnothing(match(r"^\d+$", line))
            i -= 1
            println("Skip: i = $i, line = $line")
            continue
        elseif i == 1
            println("i = $i, team1 = $line")
            team1 = line
        elseif i == 4
            println("i = $i, team2 = $line")
            team2 = line
        elseif i == 5
            println("i = $i, time = $line")
            tv_time = line
        elseif i == 6
            println("i = $i, tv = $line")
            tv = line
        elseif i == 7
            if !occursin(r"Tickets", line)
                println("i = $i, tv = $line")
                tv = tv*"/"*line
                i -= 1
            end
        elseif i == 9
            println("RESET: i = $i, line = $line \n")
            i = 0
            df = vcat(df, DataFrame(Matchup = ["$team1 @ $team2"], Time = [tv_time], TV = String[tv]))
        end        
    end

    println(df)
    CSV.write("schedule_$(year)_$week.csv", df)
   
end

# open("copy_paste_2023_04.txt") do f
 
#     my_input = read(f, String)
#     println(my_input)
#     println(my_input[1])

#     df = DataFrame(Matchup = String[], Time = String[], TV = String[])
    
   
# end