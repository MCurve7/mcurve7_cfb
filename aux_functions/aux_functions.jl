team_name_translation_dictionary = Dict(
    "Massachusetts" => "UMass",
    "UConn" => "Connecticut",
    "App State" => "Appalachian State",
    "Sam Houston" => "Sam Houston State",
    "Prairie View A&M" => "Prairie View",
    "Southern Miss" => "Southern Mississippi",
    "UTSA" => "UT San Antonio"
)

function translate_team_name(name) #may not need
    team_name_translation_dictionary[name]
end