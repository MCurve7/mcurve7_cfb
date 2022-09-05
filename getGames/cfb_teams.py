from __future__ import print_function
import sys
import os
import time
import cfbd
from cfbd.rest import ApiException
from pprint import pprint
import csv

if len(sys.argv) == 2:
    # team_get = sys.argv[1]
    year_get = int(sys.argv[1])
    # week_get = int(sys.argv[3])
    # seasontype = sys.argv[3]
else:
    # team_get = input("Team=")
    year_get = int(input("Year="))
    # week_get = int(input("Week [1-16]="))
    # seasontype  = input("Season type [regular/postseason/both]=")

with open('D:/Dropbox/program_project/data/info/cfbd.txt', mode = 'r') as file:
    Authorization = file.readlines()[0]
# with open('../../data/info/cfbd.txt', mode = 'r') as file:
#     Authorization = file.readlines()[0]    
    
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



api_instance = cfbd.TeamsApi(cfbd.ApiClient(configuration))
teams = api_instance.get_fbs_teams(year = year_get)

header = ["ID", "School", "Mascot", "Abbreviation", "Alt_name_1", "Alt_name_2", "Alt_name_3", "Classification", "Conference", "Division", "Color", "Alt_color", "Logo1", "Logo2", "Venue_id", "Name", "City", "State", "Zip", "Country_code", "Timezone", "Latitude", "Longitude", "Elevation", "Capacity", "Year_constructed", "Grass", "Dome"]
data = []
for t in teams:
    data.append([t.id, t.school, t.mascot, t.abbreviation, t.alt_name_1, t.alt_name_2, t.alt_name_3, t.classification, t.conference, t.division, t.color, t.alt_color, t.logos[0], t.logos[1], t.location['venue_id'], t.location['name'], t.location['city'], t.location['state'], t.location['zip'], t.location['country_code'], t.location['timezone'], 
    t.location['latitude'], t.location['longitude'], t.location['elevation'], t.location['capacity'], t.location['year_constructed'], t.location['grass'], t.location['dome']])

f = open ("D:/Dropbox/program_project/data/FBS/FBS-teams-"+str(year_get)+'.csv', 'w', newline='')
writer = csv.writer(f)
writer.writerow(header)
writer.writerows(data)
f.close()
print(data)    


'''
id	integer
school	string
mascot	string
abbreviation	string
alt_name_1	string
alt_name_2	string
alt_name_3	string
classification	string
conference	string
division	string
color	string
alt_color	string
logos	[string]
location	{
    venue_id	integer
    name	string
    city	string
    state	string
    zip	string
    country_code	string
    timezone	string
    latitude	number
    longitude	number
    elevation	number
    capacity	number
    year_constructed	number
    grass	boolean
    dome	boolean
}
'''
