from __future__ import print_function
import sys
import os
import time
import cfbd
from cfbd.rest import ApiException
from pprint import pprint
import csv


with open('../../data/info/cfbd.txt', mode = 'r') as file:
    Authorization = file.readlines()[0]
    
# Configure API key authorization: ApiKeyAuth
configuration = cfbd.Configuration()
configuration.api_key['Authorization'] = Authorization
# Uncomment below to setup prefix (e.g. Bearer) for API key, if needed
configuration.api_key_prefix['Authorization'] = 'Bearer'

if len(sys.argv) == 4:
    year_get = int(sys.argv[1])
    week_get = int(sys.argv[2])
    seasontype = sys.argv[3]
else:
    year_get = int(input("Year="))
    week_get = int(input("Week [1-16]="))
    seasontype = input("Season [regular/postseason]=")
#year_get = 2021

#seasontype = "regular"
#seasontype = "postseason"
#seasontype = "both"


# Get list of teams from https://collegefootballdata.com/exporter/teams/fbs and delete all non-School columns
csvfile='../school_colors/teams-fbs-'+str(year_get)+'.csv'
with open(csvfile, mode = 'r') as file:
    teams = csv.reader(file)
    
    api_instance = cfbd.PlaysApi(cfbd.ApiClient(configuration))
    for t in teams:
        team_get = t[0]
        print(team_get)
        plays = api_instance.get_plays(season_type = seasontype, year = year_get, week = week_get, team = team_get)

        '''
        for p in plays:
            print("Offense: ", p.offense, " Defense: ", p.defense, " Quarter: ", p.period, " Down: ", p.down, " Distance: ", p.distance, " Yards gain: ", p.yards_gained, "Play type: ", p.play_type)
        '''
        if week_get < 10:
            week_get_str = "0"+str(week_get)
        else:
            week_get_str = str(week_get)

        #Added Year, week, and season type to the data downloaded.
        header = ["Defense", "Offense", "Quarter", "Down", "Drive number", "Play number", "Play type", "Yard line", "Distance", "Yards gained", "Yards to goal", "Scoring", 
        "Away", "Clock", "Defense conference", "Defense score", "Defense timeouts", "Drive id", "Game id", "Home", "ID", "Offense conference", "Offense score", "Offense timeouts", "Play text", "PPA", "Wall clock", "Year", "Week", "Season"]

        data = []
        for p in plays:
            data.append([p.defense, p.offense, p.period, p.down, p.drive_number, p.play_number, p.play_type, p.yard_line, p.distance, p.yards_gained, p.yards_to_goal, p.scoring, 
            p.away, p.clock, p.defense_conference, p.defense_score, p.defense_timeouts,  p.drive_id, p.game_id, p.home, p.id, p.offense_conference, p.offense_score, p.offense_timeouts, p.play_text, p.ppa, p.wallclock, year_get, week_get_str, seasontype])
        if data != []:
            print("Found: "+team_get)
            f = open ("../../data/unprocessed/"+team_get+'_'+str(year_get)+'_wk'+week_get_str+'_'+seasontype+'.csv', 'w', newline='')
            writer = csv.writer(f)
            writer.writerow(header)
            writer.writerows(data)
            f.close()
        #print(data)    



'''
{'away': 'Alabama',
 'clock': {'minutes': 0, 'seconds': 0},
 'defense': 'Alabama',
 'defense_conference': 'SEC',
 'defense_score': 44,
 'defense_timeouts': 2,
 'distance': 10,
 'down': 0,
 'drive_id': 40128194225,
 'drive_number': 25,
 'game_id': 401281942,
 'home': 'Miami',
 'id': 401281942104999202,
 'offense': 'Miami',
 'offense_conference': 'ACC',
 'offense_score': 13,
 'offense_timeouts': 3,
 'period': 4,
 'play_number': 2,
 'play_text': 'End of 4th Quarter',
 'play_type': 'End of Game',
 'ppa': None,
 'scoring': False,
 'wallclock': '2021-09-04T23:09:52.000Z',
 'yard_line': 50,
 'yards_gained': 0,
 'yards_to_goal': 50}
'''