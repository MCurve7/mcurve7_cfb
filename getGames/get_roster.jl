using PyCall
using DataFrames
using CSV

import FloatingTableView

py"""
import cfbd
from cfbd.rest import ApiException

with open('../../data/info/cfbd.txt', mode = 'r') as file:
    Authorization = file.readlines()[0]
    
# Configure API key authorization: ApiKeyAuth
configuration = cfbd.Configuration()
configuration.api_key['Authorization'] = Authorization
# Uncomment below to setup prefix (e.g. Bearer) for API key, if needed
configuration.api_key_prefix['Authorization'] = 'Bearer'

api_instance = cfbd.TeamsApi(cfbd.ApiClient(configuration))
"""


year_list = 2014:2021
for year_get in year_list
# year_get = 2014
    println("Getting year: $year_get")
    df = CSV.read("../../data/FBS/teams-fbs-$year_get.csv", DataFrame; normalizenames=true)
    for team_get in df.Name
        team_get = replace(team_get, "\xc9" => "É")
        team_get = replace(team_get, "\xe9" => "é")
        roster = DataFrame(ID= [], First_name= [], Last_name= [], Team= [], Height= [], Weight= [], Jersey= [], Year= [], Position= [], Home_city= [], Home_state= [],  Home_country= [], Home_latitude= [], Home_longitude= [], 
                    Home_county_fips= [], Recruit_ids= [])
        println("  Getting: $team_get")
        if !isfile("../../data/FBS/rosters/$(team_get)_$(year_get)_roster.csv")
            py"""
            roster = api_instance.get_roster(team = $team_get, year = $year_get)
            """

            # py"roster"[1].recruit_ids[1]
            for p in py"roster"
                # println(p)

                isnothing(p.id) ? id = "No data" : id = p.id
                isnothing(p.first_name) ? first_name = "No data" : first_name = p.first_name
                isnothing(p.last_name) ? last_name = "No data" : last_name = p.last_name
                isnothing(p.team) ? team = "No data" : team = p.team
                isnothing(p.height) ? height = "No data" : height = p.height
                isnothing(p.weight) ? weight = "No data" : weight = p.weight
                isnothing(p.jersey) ? jersey = "No data" : jersey = p.jersey
                isnothing(p.year) ? year = "No data" : year = p.year
                isnothing(p.position) ? position = "No data" : position = p.position
                isnothing(p.home_city) ? home_city = "No data" : home_city = p.home_city
                isnothing(p.home_state) ? home_state = "No data" : home_state = p.home_state
                isnothing(p.home_country) ? home_country = "No data" : home_country = p.home_country
                isnothing(p.home_latitude) ? home_latitude = "No data" : home_latitude = p.home_latitude
                isnothing(p.home_longitude) ? home_longitude = "No data" : home_longitude = p.home_longitude
                isnothing(p.home_county_fips) ? home_county_fips = "No data" : home_county_fips = p.home_county_fips
                isnothing(p.recruit_ids) ? recruit_ids = "No data" : recruit_ids = p.recruit_ids

                roster = vcat(roster, DataFrame(
                    ID = id, 
                    First_name = first_name, 
                    Last_name = last_name, 
                    Team = team, 
                    Height = height, 
                    Weight = weight, 
                    Jersey = jersey, 
                    Year = year, 
                    Position = position, 
                    Home_city = home_city, 
                    Home_state = home_state, 
                    Home_country = home_country, 
                    Home_latitude = home_latitude, 
                    Home_longitude = home_longitude, 
                    Home_county_fips = home_county_fips,
                    Recruit_ids = recruit_ids
                ))
            end
            
            CSV.write("../../data/FBS/rosters/$(team_get)_$(year_get)_roster.csv", roster)
        end
    end
end

roster
FloatingTableView.browse(roster)

isnothing(py"roster"[1].weight) ? w = "No data" : w = py"roster"[1].weight
w
py"roster"[1].height
py"roster"[1].weight