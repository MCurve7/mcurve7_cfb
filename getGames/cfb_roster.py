from __future__ import print_function
import sys
import os
import time
import cfbd
from cfbd.rest import ApiException
from pprint import pprint
import csv

if len(sys.argv) == 3:
    team_get = sys.argv[1]
    year_get = int(sys.argv[2])
else:
    team_get = input("Team=")
    year_get = int(input("Year="))

with open('../../data/info/cfbd.txt', mode = 'r') as file:
    Authorization = file.readlines()[0]
    
# Configure API key authorization: ApiKeyAuth
configuration = cfbd.Configuration()
configuration.api_key['Authorization'] = Authorization
# Uncomment below to setup prefix (e.g. Bearer) for API key, if needed
configuration.api_key_prefix['Authorization'] = 'Bearer'
'''
team_get = "Alabama"
week_get = 2 #max is 16
year_get = 2019
seasontype = "regular"
#seasontype = "postseason"
#seasontype = "both"
'''



#for week_get in range(1,17):
api_instance = cfbd.TeamsApi(cfbd.ApiClient(configuration))
roster = api_instance.get_roster(team = team_get, year = year_get)

for p in roster:
    print("First: ", p.first_name, "Last: ", p.last_name)
    
header = ["ID", "First_name", "Last_name", "Team", "Height", "Weight", "Jersey", "Year", "Position", "Home_city", "Home_state",  "Home_country", "Home_latitude", "Home_longitude", "Home_county_fips", "Recruit_ids"]

data = []
for p in roster:
    data.append([p.id, p.first_name, p.last_name, p.team, p.height, p.weight, p.jersey, p.year, p.position, p.home_city, p.home_state, 
    p.home_country, p.home_latitude, p.home_longitude, p.home_county_fips, p.recruit_ids])
if data != []:
    f = open ("../../data/FBS/rosters/"+team_get+'_'+str(year_get)+'_roster.csv', 'w', newline='')
    writer = csv.writer(f)
    writer.writerow(header)
    writer.writerows(data)
    f.close()
print(data)  
'''
    for p in plays:
        print("Offense: ", p.offense, " Defense: ", p.defense, " Quarter: ", p.period, " Down: ", p.down, " Distance: ", p.distance, " Yards gain: ", p.yards_gained, "Play type: ", p.play_type)

    if week_get < 10:
        week_get = "0"+str(week_get)
    else:
        week_get = str(week_get)


    header = ["Defense", "Offense", "Quarter", "Down", "Drive number", "Play number", "Play type", "Yard line", "Distance", "Yards gained", "Yards to goal", "Scoring", 
    "Away", "Clock", "Defense conference", "Defense score", "Defense timeouts", "Drive id", "Game id", "Home", "ID", "Offense conference", "Offense score", "Offense timeouts", "Play text", "PPA", "Wall clock", "Year", "Week", "Season"]

    data = []
    for p in plays:
        data.append([p.defense, p.offense, p.period, p.down, p.drive_number, p.play_number, p.play_type, p.yard_line, p.distance, p.yards_gained, p.yards_to_goal, p.scoring, 
        p.away, p.clock, p.defense_conference, p.defense_score, p.defense_timeouts,  p.drive_id, p.game_id, p.home, p.id, p.offense_conference, p.offense_score, p.offense_timeouts, p.play_text, p.ppa, p.wallclock, year_get, week_get, seasontype])
    if data != []:
        f = open ("../../data/unprocessed/"+team_get+'_'+str(year_get)+'_wk'+week_get+'_'+seasontype+'.csv', 'w', newline='')
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(data)
        f.close()
    print(data)    
'''


'''
{
    "id": 0,
    "first_name": "string",
    "last_name": "string",
    "team": "string",
    "height": 0,
    "weight": 0,
    "jersey": 0,
    "year": 0,
    "position": "string",
    "home_city": "string",
    "home_state": "string",
    "home_country": "string",
    "home_latitude": 0,
    "home_longitude": 0,
    "home_county_fips": "string",
    "recruit_ids": [
      0
    ]
  }
'''