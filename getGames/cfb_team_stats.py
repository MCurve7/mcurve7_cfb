from __future__ import print_function
import sys
import os
import time
import cfbd
from cfbd.rest import ApiException
from pprint import pprint
import csv
import json

if len(sys.argv) == 5:
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
stats_json = api_instance.get_team_game_stats(season_type = seasontype, year = year_get, week = week_get, team = team_get)


print(stats_json[0])
print(stats_json[0].teams[0])
print(stats_json[0].teams[1])


# header = ["school", "conference", "homeAway", "points", "rushingTDs", "passingTDs", "kickingPoints", "fumblesRecovered", "totalFumbles", "tacklesForLoss", "defensiveTDs", "tackles", "sacks", "qbHurries", "passesDeflected", "possessionTime", "interceptions", "fumblesLost", "turnovers", "totalPenaltiesYards", "yardsPerRushAttempt", "rushingAttempts", 
# "rushingYards", "yardsPerPass", "completionAttempts", "netPassingYards", "totalYards", "fourthDownEff", "thirdDownEff", "firstDowns"]
# stats_categories = ["rushingTDs", "passingTDs", "kickingPoints", "fumblesRecovered", "totalFumbles", "tacklesForLoss", "defensiveTDs", "tackles", "sacks", "qbHurries", "passesDeflected", "possessionTime", "interceptions", "fumblesLost", "turnovers", "totalPenaltiesYards", "yardsPerRushAttempt", "rushingAttempts", 
# "rushingYards", "yardsPerPass", "completionAttempts", "netPassingYards", "totalYards", "fourthDownEff", "thirdDownEff", "firstDowns"]
# # data = []
# # #loop over stats_json[0].teams[i]
# Stats_dict = {}
# for i in range(2):
#     stats_list = []
#     for s in range(32):
#         Stats_dict[stats_json[0].teams[i]["stats"][s]['category']] = stats_json[0].teams[i]["stats"][s]['stat']
# #     stats_json[0].teams[i]["stats"][0]['category']
# #     stats_json[0].teams[i]["stats"][0]['stat']
# #     stats_json[0].teams[i]["stats"][1]['stat']
# #     stats_json[0].teams[i]["stats"][2]['stat']
# #     stats_json[0].teams[i]["stats"][3]['stat']
# #     stats_json[0].teams[i]["stats"][4]['stat'] 
# #     stats_json[0].teams[i]["stats"][5]['stat']
# #     stats_json[0].teams[i]["stats"][6]['stat']
# #     stats_json[0].teams[i]["stats"][7]['stat']
# #     stats_json[0].teams[i]["stats"][8]['stat']
# #     stats_json[0].teams[i]["stats"][9]['stat']
# #     stats_json[0].teams[i]["stats"][10]['stat']
# #     stats_json[0].teams[i]["stats"][11]['stat']
# #     stats_json[0].teams[i]["stats"][12]['stat'] 
# #     stats_json[0].teams[i]["stats"][13]['stat']
# #     stats_json[0].teams[i]["stats"][14]['stat']
# #     stats_json[0].teams[i]["stats"][15]['stat']
# #     stats_json[0].teams[i]["stats"][16]['stat']
# #     stats_json[0].teams[i]["stats"][17]['stat']
# #     stats_json[0].teams[i]["stats"][18]['stat']
# #     stats_json[0].teams[i]["stats"][19]['stat']
# #     stats_json[0].teams[i]["stats"][20]['stat'] 
# #     stats_json[0].teams[i]["stats"][21]['stat']
# #     stats_json[0].teams[i]["stats"][22]['stat']
# #     stats_json[0].teams[i]["stats"][23]['stat']
# #     stats_json[0].teams[i]["stats"][24]['stat']
# #     stats_json[0].teams[i]["stats"][25]['stat']
#     for cat in stats_categories:
#         stats_list.append(Stats_dict[cat])
# #     data.append([stats_json[0].teams[i]["school"], stats_json[0].teams[i]["conference"], stats_json[0].teams[i]["homeAway"], stats_json[0].teams[i]["points"], ])

# print(stats_list)

# print(data)


###############################################################################
#Need to deal with week 0 e.g. Vandy 2022
# print(len(stats_json))
# number_games = len(stats_json)
# if number_games == 2:

# print(stats_json[0])
# print(stats_json[1])

# print(stats_json[0].id)
# print(stats_json[0].teams[0]['school'])

# id0 = stats_json[0].id
# team00 = stats_json[0].teams[0]['school']
# team01 = stats_json[0].teams[1]['school']

# id1 = stats_json[1].id
# team10 = stats_json[1].teams[0]['school']
# team11 = stats_json[1].teams[1]['school']


# stats0 = stats_json[0].teams[0]
# stats1 = stats_json[0].teams[1]
# print(stats1['school'])
# print(stats1['stats'][15]['stat'])
# team1_num_penalties, team1_penalty_yards = stats1['stats'][15]['stat'].split("-")
# print(team1_num_penalties)
# print(team1_penalty_yards)

'''
if seasontype_entry == "preseason":
    week_get = "00"
else:
    if week_get < 10:
        week_get = "0"+str(week_get)
    else:
        week_get = str(week_get)

header = ["school", "conference", "homeAway", "points", "rushingTDs", "passingTDs", "kickingPoints", "fumblesRecovered", "totalFumbles", "tacklesForLoss", "defensiveTDs", "tackles", "sacks", "qbHurries", "passesDeflected", "possessionTime", "interceptions", "fumblesLost", "turnovers", "totalPenaltiesYards", "yardsPerRushAttempt", "rushingAttempts", 
"rushingYards", "yardsPerPass", "completionAttempts", "netPassingYards", "totalYards", "fourthDownEff", "thirdDownEff", "firstDowns"]

data = []
for i in range(2):
    data.append([stats_json[0].teams[i]["school"], stats_json[0].teams[i]["conference"], stats_json[0].teams[i]["homeAway"], stats_json[0].teams[i]["points"], stats_json[0].teams[i]["stats"][0]['stat'], stats_json[0].teams[i]["stats"][1]['stat'], stats_json[0].teams[i]["stats"][2]['stat'], stats_json[0].teams[i]["stats"][3]['stat'], stats_json[0].teams[i]["stats"][4]['stat'], 
    stats_json[0].teams[i]["stats"][5]['stat'], stats_json[0].teams[i]["stats"][6]['stat'], stats_json[0].teams[i]["stats"][7]['stat'], stats_json[0].teams[i]["stats"][8]['stat'], stats_json[0].teams[i]["stats"][9]['stat'], stats_json[0].teams[i]["stats"][10]['stat'], stats_json[0].teams[i]["stats"][11]['stat'], stats_json[0].teams[i]["stats"][12]['stat'], 
    stats_json[0].teams[i]["stats"][13]['stat'], stats_json[0].teams[i]["stats"][14]['stat'], stats_json[0].teams[i]["stats"][15]['stat'], stats_json[0].teams[i]["stats"][16]['stat'], stats_json[0].teams[i]["stats"][17]['stat'], stats_json[0].teams[i]["stats"][18]['stat'], stats_json[0].teams[i]["stats"][19]['stat'], stats_json[0].teams[i]["stats"][20]['stat'], 
    stats_json[0].teams[i]["stats"][21]['stat'], stats_json[0].teams[i]["stats"][22]['stat'], stats_json[0].teams[i]["stats"][23]['stat'], stats_json[0].teams[i]["stats"][24]['stat'], stats_json[0].teams[i]["stats"][25]['stat']])
print(data)    
if data != []:
    f = open ("../../data/team_stats/"+str(year_get)+'_wk'+week_get+'_'+seasontype+'.csv', 'w', newline='')
    #f = open ("./data/"+team_get+'_'+str(year_get)+'_wk'+week_get+'_'+seasontype+'.csv', 'w', newline='')
    writer = csv.writer(f)
    writer.writerow(header)
    writer.writerows(data)
    f.close()
'''


'''
{'id': 401403921,
 'teams': [{'conference': 'SEC',
            'homeAway': 'away',
            'points': 49,
            'school': 'Alabama',
            'stats': [{'category': 'rushingTDs', 'stat': '3'},
                      {'category': 'puntReturnYards', 'stat': '3'},
                      {'category': 'puntReturnTDs', 'stat': '0'},
                      {'category': 'puntReturns', 'stat': '1'},
                      {'category': 'passingTDs', 'stat': '2'},
                      {'category': 'kickReturnYards', 'stat': '56'},
                      {'category': 'kickReturnTDs', 'stat': '0'},
                      {'category': 'kickReturns', 'stat': '4'},
                      {'category': 'kickingPoints', 'stat': '11'},
                      {'category': 'interceptionYards', 'stat': '0'},
                      {'category': 'interceptionTDs', 'stat': '0'},
                      {'category': 'passesIntercepted', 'stat': '1'},
                      {'category': 'fumblesRecovered', 'stat': '1'},
                      {'category': 'totalFumbles', 'stat': '2'},
                      {'category': 'tacklesForLoss', 'stat': '2'},
                      {'category': 'defensiveTDs', 'stat': '0'},
                      {'category': 'tackles', 'stat': '32'},
                      {'category': 'sacks', 'stat': '1'},
                      {'category': 'qbHurries', 'stat': '0'},
                      {'category': 'passesDeflected', 'stat': '0'},
                      {'category': 'possessionTime', 'stat': '37:29'},
                      {'category': 'interceptions', 'stat': '0'},
                      {'category': 'fumblesLost', 'stat': '1'},
                      {'category': 'turnovers', 'stat': '1'},
                      {'category': 'totalPenaltiesYards', 'stat': '17-130'},
                      {'category': 'yardsPerRushAttempt', 'stat': '3.7'},
                      {'category': 'rushingAttempts', 'stat': '31'},
                      {'category': 'rushingYards', 'stat': '114'},
                      {'category': 'yardsPerPass', 'stat': '8.8'},
                      {'category': 'completionAttempts', 'stat': '35-52'},
                      {'category': 'netPassingYards', 'stat': '455'},
                      {'category': 'totalYards', 'stat': '569'},
                      {'category': 'fourthDownEff', 'stat': '1-1'},
                      {'category': 'thirdDownEff', 'stat': '6-13'},
                      {'category': 'firstDowns', 'stat': '32'}]},
           {'conference': 'SEC',
            'homeAway': 'home',
            'points': 52,
            'school': 'Tennessee',
            'stats': [{'category': 'rushingTDs', 'stat': '2'},
                      {'category': 'puntReturnYards', 'stat': '12'},
                      {'category': 'puntReturnTDs', 'stat': '0'},
                      {'category': 'puntReturns', 'stat': '1'},
                      {'category': 'passingTDs', 'stat': '5'},
                      {'category': 'kickReturnYards', 'stat': '10'},
                      {'category': 'kickReturnTDs', 'stat': '0'},
                      {'category': 'kickReturns', 'stat': '1'},
                      {'category': 'kickingPoints', 'stat': '8'},
                      {'category': 'fumblesRecovered', 'stat': '1'},
                      {'category': 'totalFumbles', 'stat': '1'},
                      {'category': 'tacklesForLoss', 'stat': '4'},
                      {'category': 'defensiveTDs', 'stat': '0'},
                      {'category': 'tackles', 'stat': '41'},
                      {'category': 'sacks', 'stat': '1'},
                      {'category': 'qbHurries', 'stat': '9'},
                      {'category': 'passesDeflected', 'stat': '3'},
                      {'category': 'possessionTime', 'stat': '22:31'},
                      {'category': 'interceptions', 'stat': '1'},
                      {'category': 'fumblesLost', 'stat': '1'},
                      {'category': 'turnovers', 'stat': '2'},
                      {'category': 'totalPenaltiesYards', 'stat': '6-39'},
                      {'category': 'yardsPerRushAttempt', 'stat': '4.7'},
                      {'category': 'rushingAttempts', 'stat': '39'},
                      {'category': 'rushingYards', 'stat': '182'},
                      {'category': 'yardsPerPass', 'stat': '12.4'},
                      {'category': 'completionAttempts', 'stat': '21-31'},
                      {'category': 'netPassingYards', 'stat': '385'},
                      {'category': 'totalYards', 'stat': '567'},
                      {'category': 'fourthDownEff', 'stat': '0-2'},
                      {'category': 'thirdDownEff', 'stat': '5-10'},
                      {'category': 'firstDowns', 'stat': '29'}]}]}
'''