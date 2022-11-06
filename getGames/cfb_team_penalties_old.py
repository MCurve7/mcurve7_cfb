from __future__ import print_function
import sys
import os
import time
import cfbd
from cfbd.rest import ApiException
from pprint import pprint
import csv
import json

arg_length = len(sys.argv)

if arg_length == 4:
    year_get = int(sys.argv[1])
    week_get = int(sys.argv[2])
    seasontype_entry = sys.argv[3]
elif arg_length == 5:
    team_get = sys.argv[1]
    year_get = int(sys.argv[2])
    week_get = int(sys.argv[3])
    seasontype_entry = sys.argv[4]
else:
    team_get = input("Team=")
    year_get = int(input("Year="))
    week_get = int(input("Week [1-16]="))
    seasontype_entry  = input("Season type [regular/postseason/both/preseason]=")

with open('../../data/info/cfbd.txt', mode = 'r') as file:
    Authorization = file.readlines()[0]
    
# Configure API key authorization: ApiKeyAuth
configuration = cfbd.Configuration()
configuration.api_key['Authorization'] = Authorization
# Uncomment below to setup prefix (e.g. Bearer) for API key, if needed
configuration.api_key_prefix['Authorization'] = 'Bearer'

if seasontype_entry == "preseason":
    seasontype = "regular"
else:
    seasontype = seasontype_entry
    
api_instance = cfbd.GamesApi(cfbd.ApiClient(configuration))



# print(stats_json[0])
# print(stats_json[0].teams[0]["school"])
# print(len(stats_json[0].teams[0]["stats"]))
# print(len(stats_json[0].teams[1]["stats"]))

def json2dict(data):
    stats_json_dict = {}
    # print(stats_json[0].teams[0]["school"])

    stats_json_dict["school"] = data["school"]
    stats_json_dict["conference"] = data["conference"]
    stats_json_dict["homeAway"] = data["homeAway"]
    stats_json_dict["points"] = data["points"]
    for s in range(len(data["stats"])):
        current_stat = data["stats"][s]['category']
        stats_json_dict[current_stat] = data["stats"][s]['stat']
    
    return stats_json_dict

# json_dict = json2dict(stats_json[0].teams[0])



header = ["year", "week", "school", "conference", "totalPenalties", "totalPenaltiesYards"]
data = []

#############################################################################################
#Fix:
# Western Kentucky has 2 week 1s
# Fix unicode for San Jos'e' State
#############################################################################################
week0_data = {}
if arg_length == 4:
    teams_seen = {}
    csvfile='../school_colors/teams-fbs-'+str(year_get)+'.csv'
    with open(csvfile, mode = 'r') as file:
        teams = csv.reader(file)
        #Skips the 1st row which is a header row
        next(teams)

        for t in teams:
            team_get = t[0]
            # print(team_get)
            # print(teams_seen.keys())
            for wk in range(1,week_get+1):
                stats_json = api_instance.get_team_game_stats(season_type = seasontype, year = year_get, week = wk, team = team_get)
                # print(stats_json)
                if stats_json == []:
                    # print("Bye week")
                    if team_get == "Utah State":
                        print("Utah State Bye week.")
                #Need this for "week 0"
                elif len(stats_json) == 2:
                    if team_get == "Utah State":
                        print("Utah State week 0")
                    # Put in order of id #s can remove later
                    if stats_json[0].id < stats_json[1].id:
                        #Loop over both teams in id 0 only grab team_get
                        for i in range(2):
                            current_team = stats_json[0].teams[i]
                            if current_team["school"] == team_get:
                                if current_team["school"] not in teams_seen.keys():
                                    teams_seen[current_team["school"]] = [0]
                                    #Loop to find "totalPenaltiesYards" (it's not ordered)
                                    for s in range(len(current_team["stats"])):
                                        if current_team["stats"][s]['category'] == "totalPenaltiesYards":
                                            num, yards = current_team["stats"][s]['stat'].split("-")
                                            break
                                    # data.append([year_get, 0, current_team["school"], current_team["conference"], num, yards])
                                    game0 = [year_get, 0, current_team["school"], current_team["conference"], num, yards]

                                    if current_team["school"] == "Utah State":
                                        print(team_get)
                                        print(year_get, 0, current_team["school"], current_team["conference"], num, yards)
                                        print(teams_seen[current_team["school"]])
                                elif 0 not in teams_seen[current_team["school"]]:
                                    teams_seen[current_team["school"]].append(0)
                                    #Loop to find "totalPenaltiesYards" (it's not ordered)
                                    for s in range(len(current_team["stats"])):
                                        if current_team["stats"][s]['category'] == "totalPenaltiesYards":
                                            num, yards = current_team["stats"][s]['stat'].split("-")
                                            break
                                    # data.append([year_get, 0, current_team["school"], current_team["conference"], num, yards])
                                    game0 = [year_get, 0, current_team["school"], current_team["conference"], num, yards]

                                    if current_team["school"] == "Utah State":
                                        print(team_get)
                                        print(year_get, 0, current_team["school"], current_team["conference"], num, yards)
                                        print(teams_seen[current_team["school"]])
                        #Loop over both teams in id 1 only grab team_get
                        for i in range(2):
                            current_team = stats_json[1].teams[i]
                            if current_team["school"] == team_get:
                                if current_team["school"] not in teams_seen.keys():
                                    teams_seen[current_team["school"]] = [1]
                                    #Loop to find "totalPenaltiesYards" (it's not ordered)
                                    for s in range(len(current_team["stats"])):
                                        if current_team["stats"][s]['category'] == "totalPenaltiesYards":
                                            num, yards = current_team["stats"][s]['stat'].split("-")
                                            break
                                    # data.append([year_get, 1, current_team["school"], current_team["conference"], num, yards])
                                    game1 = [year_get, 0, current_team["school"], current_team["conference"], num, yards]

                                    if current_team["school"] == "Utah State":
                                        print(team_get)
                                        print(year_get, 1, current_team["school"], current_team["conference"], num, yards)
                                        print(teams_seen[current_team["school"]])
                                elif 1 not in teams_seen[current_team["school"]]:
                                    teams_seen[current_team["school"]].append(1)
                                    #Loop to find "totalPenaltiesYards" (it's not ordered)
                                    for s in range(len(current_team["stats"])):
                                        if current_team["stats"][s]['category'] == "totalPenaltiesYards":
                                            num, yards = current_team["stats"][s]['stat'].split("-")
                                            break
                                    # data.append([year_get, 1, current_team["school"], current_team["conference"], num, yards])
                                    game1 = [year_get, 0, current_team["school"], current_team["conference"], num, yards]

                                    if current_team["school"] == "Utah State":
                                        print(team_get)
                                        print(year_get, 1, current_team["school"], current_team["conference"], num, yards)
                                        print(teams_seen[current_team["school"]])
                    else:
                        #Loop over both teams in id 0 only grab team_get
                        for i in range(2):
                            current_team = stats_json[1].teams[i]
                            if current_team["school"] == team_get:
                                if current_team["school"] not in teams_seen.keys():
                                    teams_seen[current_team["school"]] = [0]
                                    #Loop to find "totalPenaltiesYards" (it's not ordered)
                                    for s in range(len(current_team["stats"])):
                                        if current_team["stats"][s]['category'] == "totalPenaltiesYards":
                                            num, yards = current_team["stats"][s]['stat'].split("-")
                                            break
                                    # data.append([year_get, 0, current_team["school"], current_team["conference"], num, yards])
                                    game0 = [year_get, 0, current_team["school"], current_team["conference"], num, yards]

                                    if current_team["school"] == "Utah State":
                                        print(team_get)
                                        print(year_get, 0, current_team["school"], current_team["conference"], num, yards)
                                        print(teams_seen[current_team["school"]])
                                elif 0 not in teams_seen[current_team["school"]]:
                                    teams_seen[current_team["school"]].append(0)
                                    #Loop to find "totalPenaltiesYards" (it's not ordered)
                                    for s in range(len(current_team["stats"])):
                                        if current_team["stats"][s]['category'] == "totalPenaltiesYards":
                                            num, yards = current_team["stats"][s]['stat'].split("-")
                                            break
                                    # data.append([year_get, 0, current_team["school"], current_team["conference"], num, yards])
                                    game0 = [year_get, 0, current_team["school"], current_team["conference"], num, yards]

                                    if current_team["school"] == "Utah State":
                                        print(team_get)
                                        print(year_get, 0, current_team["school"], current_team["conference"], num, yards)
                                        print(teams_seen[current_team["school"]])
                        #Loop over both teams in id 1 only grab team_get
                        for i in range(2):
                            current_team = stats_json[0].teams[i]
                            if current_team["school"] == team_get:
                                if current_team["school"] not in teams_seen.keys():
                                    teams_seen[current_team["school"]] = [1]
                                    #Loop to find "totalPenaltiesYards" (it's not ordered)
                                    for s in range(len(current_team["stats"])):
                                        if current_team["stats"][s]['category'] == "totalPenaltiesYards":
                                            num, yards = current_team["stats"][s]['stat'].split("-")
                                            break
                                    # data.append([year_get, 1, current_team["school"], current_team["conference"], num, yards])
                                    game1 = [year_get, 0, current_team["school"], current_team["conference"], num, yards]

                                    if current_team["school"] == "Utah State":
                                        print(team_get)
                                        print(year_get, 1, current_team["school"], current_team["conference"], num, yards)
                                        print(teams_seen[current_team["school"]])
                                elif 1 not in teams_seen[current_team["school"]]:
                                    teams_seen[current_team["school"]].append(1)
                                    #Loop to find "totalPenaltiesYards" (it's not ordered)
                                    for s in range(len(current_team["stats"])):
                                        if current_team["stats"][s]['category'] == "totalPenaltiesYards":
                                            num, yards = current_team["stats"][s]['stat'].split("-")
                                            break
                                    # data.append([year_get, 1, current_team["school"], current_team["conference"], num, yards])
                                    game1 = [year_get, 0, current_team["school"], current_team["conference"], num, yards]

                                    if current_team["school"] == "Utah State":
                                        print(team_get)
                                        print(year_get, 1, current_team["school"], current_team["conference"], num, yards)
                                        print(teams_seen[current_team["school"]])
                    week0_data[team_get] = [game0, game1]
                #For teams that didn't play a week 0 game
                else:
                    #Loop over both teams
                    for i in range(2):
                        current_team = stats_json[0].teams[i]
                        # print("    ", current_team["school"])
                        if current_team["school"] not in teams_seen.keys():
                            teams_seen[current_team["school"]] = [wk]
                            #Loop to find "totalPenaltiesYards" (it's not ordered)
                            for s in range(len(current_team["stats"])):
                                if current_team["stats"][s]['category'] == "totalPenaltiesYards":
                                    num, yards = current_team["stats"][s]['stat'].split("-")
                                    break
                            data.append([year_get, wk, current_team["school"], current_team["conference"], num, yards])

                            if current_team["school"] == "Utah State":
                                print(team_get)
                                print(year_get, wk, current_team["school"], current_team["conference"], num, yards)
                                print(teams_seen[current_team["school"]])
                        elif wk not in teams_seen[current_team["school"]]:
                            teams_seen[current_team["school"]].append(wk)
                            #Loop to find "totalPenaltiesYards" (it's not ordered)
                            for s in range(len(current_team["stats"])):
                                if current_team["stats"][s]['category'] == "totalPenaltiesYards":
                                    num, yards = current_team["stats"][s]['stat'].split("-")
                                    break
                            data.append([year_get, wk, current_team["school"], current_team["conference"], num, yards])

                            if current_team["school"] == "Utah State":
                                print(team_get)
                                print(year_get, wk, current_team["school"], current_team["conference"], num, yards)
                                print(teams_seen[current_team["school"]])
            
    for t in week0_data.keys():
        numPenalties1 = week0_data[t][0][4]
        penaltyYards1 = week0_data[t][0][5]
        numPenalties2 = week0_data[t][1][4]
        penaltyYards2 = week0_data[t][1][5]
        if 1 in teams_seen[t]:
            print("Junk")

    f = open ("../../data/team_stats/"+str(year_get)+'_'+seasontype+'_'+"penalties_yards"+'.csv', 'w', newline='')
    writer = csv.writer(f)
    writer.writerow(header)
    writer.writerows(data)
    f.close()

    print(data)
    print(week0_data)

#################################################################################################################################
#Thought id would be in order...wrong
    # teams_seen = {}
    # csvfile='../school_colors/teams-fbs-'+str(year_get)+'.csv'
    # with open(csvfile, mode = 'r') as file:
    #     teams = csv.reader(file)
    #     #Skips the 1st row which is a header row
    #     next(teams)

    #     for t in teams:
    #         team_get = t[0]
    #         # print(team_get)
    #         # print(teams_seen.keys())
    #         for wk in range(1,week_get+1):
    #             stats_json = api_instance.get_team_game_stats(season_type = seasontype, year = year_get, week = wk, team = team_get)
    #             # print(stats_json)
    #             if stats_json == []:
    #                 # print("Bye week")
    #                 if team_get == "Alabama":
    #                     print("Alabama Bye week.")
    #             #Need this for "week 0"
    #             elif len(stats_json) == 2:
    #                 if team_get == "Alabama":
    #                     print("Alabama week 0")
    #                 # Put week 0 before week 1
    #                 if stats_json[0].id < stats_json[1].id:
    #                     #Loop over both teams in week 0
    #                     for i in range(2):
    #                         current_team = stats_json[0].teams[i]
    #                         # print("    ", current_team["school"])
    #                         if current_team["school"] not in teams_seen.keys():
    #                             teams_seen[current_team["school"]] = [0]
    #                             #Loop to find "totalPenaltiesYards" (it's not ordered)
    #                             for s in range(len(current_team["stats"])):
    #                                 if current_team["stats"][s]['category'] == "totalPenaltiesYards":
    #                                     num, yards = current_team["stats"][s]['stat'].split("-")
    #                                     break
    #                             data.append([year_get, 0, current_team["school"], current_team["conference"], num, yards])

    #                             if current_team["school"] == "Alabama":
    #                                 print(team_get)
    #                                 print(year_get, 0, current_team["school"], current_team["conference"], num, yards)
    #                                 print(teams_seen[current_team["school"]])
    #                         elif 0 not in teams_seen[current_team["school"]]:
    #                             teams_seen[current_team["school"]].append(0)
    #                             #Loop to find "totalPenaltiesYards" (it's not ordered)
    #                             for s in range(len(current_team["stats"])):
    #                                 if current_team["stats"][s]['category'] == "totalPenaltiesYards":
    #                                     num, yards = current_team["stats"][s]['stat'].split("-")
    #                                     break
    #                             data.append([year_get, 0, current_team["school"], current_team["conference"], num, yards])

    #                             if current_team["school"] == "Alabama":
    #                                 print(team_get)
    #                                 print(year_get, 0, current_team["school"], current_team["conference"], num, yards)
    #                                 print(teams_seen[current_team["school"]])
    #                     #Loop over both teams in week 1
    #                     for i in range(2):
    #                         current_team = stats_json[1].teams[i]
    #                         # print("    ", current_team["school"])
    #                         if current_team["school"] not in teams_seen.keys():
    #                             teams_seen[current_team["school"]] = [1]
    #                             #Loop to find "totalPenaltiesYards" (it's not ordered)
    #                             for s in range(len(current_team["stats"])):
    #                                 if current_team["stats"][s]['category'] == "totalPenaltiesYards":
    #                                     num, yards = current_team["stats"][s]['stat'].split("-")
    #                                     break
    #                             data.append([year_get, 1, current_team["school"], current_team["conference"], num, yards])

    #                             if current_team["school"] == "Alabama":
    #                                 print(team_get)
    #                                 print(year_get, 1, current_team["school"], current_team["conference"], num, yards)
    #                                 print(teams_seen[current_team["school"]])
    #                         elif 1 not in teams_seen[current_team["school"]]:
    #                             teams_seen[current_team["school"]].append(1)
    #                             #Loop to find "totalPenaltiesYards" (it's not ordered)
    #                             for s in range(len(current_team["stats"])):
    #                                 if current_team["stats"][s]['category'] == "totalPenaltiesYards":
    #                                     num, yards = current_team["stats"][s]['stat'].split("-")
    #                                     break
    #                             data.append([year_get, 1, current_team["school"], current_team["conference"], num, yards])

    #                             if current_team["school"] == "Alabama":
    #                                 print(team_get)
    #                                 print(year_get, 1, current_team["school"], current_team["conference"], num, yards)
    #                                 print(teams_seen[current_team["school"]])
    #                 else:
    #                     #Loop over both teams in week 0
    #                     for i in range(2):
    #                         current_team = stats_json[1].teams[i]
    #                         # print("    ", current_team["school"])
    #                         if current_team["school"] not in teams_seen.keys():
    #                             teams_seen[current_team["school"]] = [0]
    #                             #Loop to find "totalPenaltiesYards" (it's not ordered)
    #                             for s in range(len(current_team["stats"])):
    #                                 if current_team["stats"][s]['category'] == "totalPenaltiesYards":
    #                                     num, yards = current_team["stats"][s]['stat'].split("-")
    #                                     break
    #                             data.append([year_get, 0, current_team["school"], current_team["conference"], num, yards])

    #                             if current_team["school"] == "Alabama":
    #                                 print(team_get)
    #                                 print(year_get, 0, current_team["school"], current_team["conference"], num, yards)
    #                                 print(teams_seen[current_team["school"]])
    #                         elif 0 not in teams_seen[current_team["school"]]:
    #                             teams_seen[current_team["school"]].append(0)
    #                             #Loop to find "totalPenaltiesYards" (it's not ordered)
    #                             for s in range(len(current_team["stats"])):
    #                                 if current_team["stats"][s]['category'] == "totalPenaltiesYards":
    #                                     num, yards = current_team["stats"][s]['stat'].split("-")
    #                                     break
    #                             data.append([year_get, 0, current_team["school"], current_team["conference"], num, yards])

    #                             if current_team["school"] == "Alabama":
    #                                 print(team_get)
    #                                 print(year_get, 0, current_team["school"], current_team["conference"], num, yards)
    #                                 print(teams_seen[current_team["school"]])
    #                     #Loop over both teams in week 1
    #                     for i in range(2):
    #                         current_team = stats_json[0].teams[i]
    #                         # print("    ", current_team["school"])
    #                         if current_team["school"] not in teams_seen.keys():
    #                             teams_seen[current_team["school"]] = [1]
    #                             #Loop to find "totalPenaltiesYards" (it's not ordered)
    #                             for s in range(len(current_team["stats"])):
    #                                 if current_team["stats"][s]['category'] == "totalPenaltiesYards":
    #                                     num, yards = current_team["stats"][s]['stat'].split("-")
    #                                     break
    #                             data.append([year_get, 1, current_team["school"], current_team["conference"], num, yards])

    #                             if current_team["school"] == "Alabama":
    #                                 print(team_get)
    #                                 print(year_get, 1, current_team["school"], current_team["conference"], num, yards)
    #                                 print(teams_seen[current_team["school"]])
    #                         elif 1 not in teams_seen[current_team["school"]]:
    #                             teams_seen[current_team["school"]].append(1)
    #                             #Loop to find "totalPenaltiesYards" (it's not ordered)
    #                             for s in range(len(current_team["stats"])):
    #                                 if current_team["stats"][s]['category'] == "totalPenaltiesYards":
    #                                     num, yards = current_team["stats"][s]['stat'].split("-")
    #                                     break
    #                             data.append([year_get, 1, current_team["school"], current_team["conference"], num, yards])

    #                             if current_team["school"] == "Alabama":
    #                                 print(team_get)
    #                                 print(year_get, 1, current_team["school"], current_team["conference"], num, yards)
    #                                 print(teams_seen[current_team["school"]])
    #             #For teams that didn't play a week 0 game
    #             else:
    #                 #Loop over both teams
    #                 for i in range(2):
    #                     current_team = stats_json[0].teams[i]
    #                     # print("    ", current_team["school"])
    #                     if current_team["school"] not in teams_seen.keys():
    #                         teams_seen[current_team["school"]] = [wk]
    #                         #Loop to find "totalPenaltiesYards" (it's not ordered)
    #                         for s in range(len(current_team["stats"])):
    #                             if current_team["stats"][s]['category'] == "totalPenaltiesYards":
    #                                 num, yards = current_team["stats"][s]['stat'].split("-")
    #                                 break
    #                         data.append([year_get, wk, current_team["school"], current_team["conference"], num, yards])

    #                         if current_team["school"] == "Alabama":
    #                             print(team_get)
    #                             print(year_get, wk, current_team["school"], current_team["conference"], num, yards)
    #                             print(teams_seen[current_team["school"]])
    #                     elif wk not in teams_seen[current_team["school"]]:
    #                         teams_seen[current_team["school"]].append(wk)
    #                         #Loop to find "totalPenaltiesYards" (it's not ordered)
    #                         for s in range(len(current_team["stats"])):
    #                             if current_team["stats"][s]['category'] == "totalPenaltiesYards":
    #                                 num, yards = current_team["stats"][s]['stat'].split("-")
    #                                 break
    #                         data.append([year_get, wk, current_team["school"], current_team["conference"], num, yards])

    #                         if current_team["school"] == "Alabama":
    #                             print(team_get)
    #                             print(year_get, wk, current_team["school"], current_team["conference"], num, yards)
    #                             print(teams_seen[current_team["school"]])
            

    # f = open ("../../data/team_stats/"+str(year_get)+'_'+seasontype+'_'+"penalties_yards"+'.csv', 'w', newline='')
    # writer = csv.writer(f)
    # writer.writerow(header)
    # writer.writerows(data)
    # f.close()

    # print(data)



###############################################################################
else:
    stats_json = api_instance.get_team_game_stats(season_type = seasontype, year = year_get, week = week_get, team = team_get)
    # print(stats_json)
    # print(len(stats_json))








# for wk in range(1,week_get+1):
#     stats_json = api_instance.get_team_game_stats(season_type = seasontype, year = year_get, week = wk, team = team_get)
#     # print(stats_json)

#     if stats_json == []:
#         data.append([year_get, wk, team_get, "missing", "missing", "missing"])
#     #Need this for "week 0"
#     elif len(stats_json) == 2:
#         if stats_json[0].id < stats_json[1].id:
#             for i in range(2):
#                 for s in range(len(stats_json[0].teams[i]["stats"])):
#                     if stats_json[0].teams[i]["stats"][s]['category'] == "totalPenaltiesYards":
#                         num, yards = stats_json[0].teams[i]["stats"][s]['stat'].split("-")
#                 data.append([year_get, 0, stats_json[0].teams[i]["school"], stats_json[0].teams[i]["conference"], num, yards])
#             for i in range(2):
#                 for s in range(len(stats_json[1].teams[i]["stats"])):
#                     if stats_json[1].teams[i]["stats"][s]['category'] == "totalPenaltiesYards":
#                         num, yards = stats_json[1].teams[i]["stats"][s]['stat'].split("-")
#                 data.append([year_get, 1, stats_json[1].teams[i]["school"], stats_json[1].teams[i]["conference"], num, yards])
#         else:
#             for i in range(2):
#                 for s in range(len(stats_json[1].teams[i]["stats"])):
#                     print(stats_json[1].teams[i]["stats"][s]['category'])
#                     if stats_json[1].teams[i]["stats"][s]['category'] == "totalPenaltiesYards":
#                         print(stats_json[1].teams[i]["stats"][s])
#                         num, yards = stats_json[1].teams[i]["stats"][s]['stat'].split("-")
#                 data.append([year_get, 0, stats_json[1].teams[i]["school"], stats_json[1].teams[i]["conference"], num, yards])
#             for i in range(2):
#                 for s in range(len(stats_json[0].teams[i]["stats"])):
#                     if stats_json[0].teams[i]["stats"][s]['category'] == "totalPenaltiesYards":
#                         num, yards = stats_json[0].teams[i]["stats"][s]['stat'].split("-")
#                 data.append([year_get, 1, stats_json[0].teams[i]["school"], stats_json[0].teams[i]["conference"], num, yards])
#     else:
#         for i in range(2):
#             for s in range(len(stats_json[0].teams[i]["stats"])):
#                 if stats_json[0].teams[i]["stats"][s]['category'] == "totalPenaltiesYards":
#                     num, yards = stats_json[0].teams[i]["stats"][s]['stat'].split("-")
#                     break
#             data.append([year_get, wk, stats_json[0].teams[i]["school"], stats_json[0].teams[i]["conference"], num, yards])

# print(data)







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