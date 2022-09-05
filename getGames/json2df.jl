using DataFrames
using CSV
using JSON
import FloatingTableView

function json2df(vec)
    team_str = join(vec)
    team_str = replace(team_str, "null"=>"\"missing\"")
    # println(team_str)
    # team_str = SubString(team_str, 1, length(team_str)-1)
    team_str = rstrip(team_str, [','])
    # println(team_str)
    team_str = replace(team_str, r""" +"logos": +\[ +"http://a.espncdn.com/i/teamlogos/ncaa/500/(\d+).png", +"http://a.espncdn.com/i/teamlogos/ncaa/500-dark/(\d+).png" +\],""" 
                    => 
                    s"\"logos_main\": \"http://a.espncdn.com/i/teamlogos/ncaa/500/\1.png\",  \"logos_dark\": \"http://a.espncdn.com/i/teamlogos/ncaa/500-dark/\1.png\",")
    team_str = replace(team_str, "\xc9" => "É")
    team_str = replace(team_str, "\xe9" => "é")   
    # println(team_str)                 
    teams_dict = JSON.parse(team_str)
    DataFrame(teams_dict)
end

json_file = "../../data/FBS/FBS-teams-2021.json"
file_string_vec = open(json_file) do f
    readlines(f)
end
file_string_vec = file_string_vec[2:end-1]

##############################################################################################################################
df_teams = DataFrame(abbreviation = [], alt_color = [], alt_name1 = [], alt_name2 = [], alt_name3 = [], color = [], conference = [], division = [], id = [], location = [], logos_dark = [], logos_main = [], mascot = [], school = [])
for n in 0:((length(file_string_vec) ÷ 33)-1)
    println("n = $n")
    df_teams = vcat(df_teams, DataFrame(json2df(file_string_vec[(1+33n):(33+33n)])))    
end

csv_file = json_file[1:end-4]*"csv"
CSV.write(csv_file, df_teams)


FloatingTableView.browse(df_teams)