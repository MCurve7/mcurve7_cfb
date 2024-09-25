# Translate team names from new ESPN version to origonal names
team_name_translation_dictionary = Dict(
    "Massachusetts" => "UMass",
    "UConn" => "Connecticut",
    "App State" => "Appalachian State",
    "Sam Houston" => "Sam Houston State",
    "Prairie View A&M" => "Prairie View",
    "Southern Miss" => "Southern Mississippi",
    "UTSA" => "UT San Antonio",
    "App State" => "Appalachian State",
    "Southern Miss" => "Southern Mississippi",
    "UL Monroe" => "Louisiana Monroe",
    "St. Francis (PA)" => "St Francis (PA)"
)

function translate_team_name(name) #may not need
    team_name_translation_dictionary[name]
end