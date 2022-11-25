#########################################################################################################################################
# foul_analysis #########################################################################################################################
# Rewritten to find foul team, status, type, and transgressor to find enforced, declined, and offsetting and ambiguous for some cases.

#I might break this further apart into: offsetting_aux, declined_enforced_aux, declined_aux, enforced_aux, and rest_aux files

function foul_analysis(cols)
    txt = cols[1]
    offense = cols[2]
    defense = cols[3]

    school_colors = CSV.File("../school_colors/school_colors.csv", delim=';') |> DataFrame
    off_abbrv = replace(school_colors[school_colors.School .== offense, :Abbreviation_regex][1], "^("=>"(?:")
    def_abbrv = replace(school_colors[school_colors.School .== defense, :Abbreviation_regex][1], "^("=>"(?:")
    off_abbrv_catch = school_colors[school_colors.School .== offense, :Abbreviation_regex][1]
    def_abbrv_catch = school_colors[school_colors.School .== defense, :Abbreviation_regex][1]
    off_abbrv_catch = replace(off_abbrv_catch, "\xe9" => "é")
    off_abbrv_catch = replace(off_abbrv_catch, "\xc9" => "É")
    def_abbrv_catch = replace(def_abbrv_catch, "\xe9" => "é")
    def_abbrv_catch = replace(def_abbrv_catch, "\xc9" => "É")
    
    #Had to read from school_colors and then change "San Jos\xe9 State" to "San José State" may have to relook at how play_info works (I think switch from Excel to LibreOffice Calc...) 
    offense = escape_string(cols[2])
    defense = escape_string(cols[3])
    offense = replace(cols[2], "\xe9" => "é")
    offense = replace(offense, "\xc9" => "É")
    defense = replace(cols[3], "\xe9" => "é")
    defense = replace(defense, "\xc9" => "É")
    if DEBUG_PENALTY println("offense = $offense, defense = $defense") end
    if DEBUG_PENALTY println("off_abbrv_catch: $off_abbrv_catch; $def_abbrv_catch") end

    #penalty code "BL;" is breaking my regex so I am striping out the ; since that seems to be the problem:
    if !ismissing(txt)
        txt = replace(txt, r"BL;" => "BL")
    end
    # println("Gone ';'?: $txt")

    enforced = ""
    declined = ""

    type1 = missing
    status1 = missing
    team1 = missing
    transgressor1 = missing
    type2 = missing
    status2 = missing
    team2 = missing
    transgressor2 = missing
    type3 = missing
    status3 = missing
    team3 = missing
    transgressor3 = missing

    #println("txt: $txt")
    txt = ismissing(txt) ? "NA" : txt

    txt = replace(txt, "\xc9" => "É")
    txt = replace(txt, "\xe9" => "é")
    # txt = transcode(String, txt)
    txt = escape_string(txt)

    

    # penalty_type_list = CSV.File("../../data/FBS/penalty-types.csv", delim='~') |> DataFrame
    penalty_type_list = DataFrame(CSV.File("../school_colors/penalty-types.csv", delim='~'))
    penalty_type_vec = penalty_type_list.Penalties
    # penalty_codes = ["BI","DL","FD","FL","HL","IB","IF","IK","IL","IM","IP","IR","IS","OF","PS","RO","RU","UR","CIT","OFF","TGB","PFRP"]

    
    # name_regex = "(((?:[A-Z\\p{Lu}'-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+|(?:de))|(?:[A-Z\\p{Lu}-]\\.?)?\\s?)+)" #most general name regex


    penalties_regex_txt = "(?:Penalty|PENALTY)"
    offsetting_regex = r"[Oo]ff-?setting"
    declined_regex = r"[Dd]eclined"
    enforced_regex = r"[Ee]nforced"
    penalties_regex = r"(?:Penalty|PENALTY)"
    penalized_regex = r"(?:PENALIZED|Penalized)"
    
    
    
    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]
    if DEBUG_PENALTY println("I see: $txt") end
  # println("Offense: $offense, Defense: $defense")
    if occursin(offsetting_regex, txt)
      if DEBUG_PENALTY println("Calling: offsetting_aux") end
        foul_type, foul_status, foul_team, foul_transgressor = offsetting_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_type_vec)
    elseif occursin(declined_regex, lowercase(txt)) && occursin(enforced_regex, lowercase(txt))
        if DEBUG_PENALTY println("Calling: declined_enforced_aux") end
        foul_type, foul_status, foul_team, foul_transgressor = declined_enforced_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, off_abbrv, def_abbrv, penalty_type_vec)
    elseif occursin(declined_regex, txt)
        if DEBUG_PENALTY println("Calling: declined_aux") end
        foul_type, foul_status, foul_team, foul_transgressor = declined_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_type_vec)
    elseif occursin(enforced_regex, txt)
        if DEBUG_PENALTY println("Calling: enforced_aux") end
        foul_type, foul_status, foul_team, foul_transgressor = enforced_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_type_vec)
    elseif occursin(penalties_regex, txt)
        if DEBUG_PENALTY println("Calling: rest_aux") end
        foul_type, foul_status, foul_team, foul_transgressor = rest_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_type_vec)
    elseif occursin(penalized_regex, txt)
        if DEBUG_PENALTY println("Calling: penalized_aux") end
        foul_type, foul_status, foul_team, foul_transgressor = penalized_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_type_vec)
    # else
    #   println("No aux function called")
    end

    # titlecase.(foul_type), foul_status, foul_team, foul_transgressor
    if length(foul_type) == 1
        type1 = titlecase(foul_type[1])
        status1 = foul_status[1]
        team1 = foul_team[1]
        transgressor1 = foul_transgressor[1]
    elseif length(foul_type) == 2
        type1 = titlecase(foul_type[1])
        status1 = foul_status[1]
        team1 = foul_team[1]
        transgressor1 = foul_transgressor[1]
        type2 = titlecase(foul_type[2])
        status2 = foul_status[2]
        team2 = foul_team[2]
        transgressor2 = foul_transgressor[2]
    elseif length(foul_type) == 3
        type1 = titlecase(foul_type[1])
        status1 = foul_status[1]
        team1 = foul_team[1]
        transgressor1 = foul_transgressor[1]
        type2 = titlecase(foul_type[2])
        status2 = foul_status[2]
        team2 = foul_team[2]
        transgressor2 = foul_transgressor[2]
        type3 = titlecase(foul_type[3])
        status3 = foul_status[3]
        team3 = foul_team[3]
        transgressor3 = foul_transgressor[3]
    end
    type1, status1, team1, transgressor1, type2, status2, team2, transgressor2, type3, status3, team3, transgressor3
end


function get_team_name(str, offense, off_abbrv_catch, defense, def_abbrv_catch)
    # if occursin(Regex(str), off_abbrv_catch)
    #     offense
    # elseif occursin(Regex(str), def_abbrv_catch)
    #     defense
    # else
    #     "No data"
    # end
    if length(defense) < length(offense)
        if !isnothing(match(Regex(off_abbrv_catch), str))
            offense
        elseif !isnothing(match(Regex(def_abbrv_catch), str))
            defense
        else
            "No data"
        end
    else
        if !isnothing(match(Regex(def_abbrv_catch), str))
            defense
        elseif !isnothing(match(Regex(off_abbrv_catch), str))
            offense
        else
            "No data"
        end
    end
end

function process_name(name)
    if isnothing(name)
        "Name regex error"
    elseif occursin(r"[A-Z]\.[A-Z]", name)
        replace(name, r"\.\b" => " ")
    else
        if occursin(r",", name)
            name_vec = strip.(split(name, ","))
        else
            name_vec = strip.(split(name, " "))
        end
        if length(name_vec) == 1
            name_vec[1]
        elseif length(name_vec) == 2
            titlecase(name_vec[2])*" "*titlecase(name_vec[1])
        elseif length(name_vec) == 3
            titlecase(name_vec[3])*" "*titlecase(name_vec[1])*" "*name_vec[2]
        end
    end
end

############################################################################################################################################################
function declined_enforced_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, off_abbrv, def_abbrv, penalty_type_vec)

    penalties_regex_txt = "(?:Penalty|PENALTY)"
    de_enc_regex = "(declined|enforced)"
    enforced_declined_regex = r"enforced .*\((?:\s*\w+)+\) declined"
    enforced_declined_on_regex = r"on ([A-Z\\p{Lu}'-]+, (?:[A-Z\\p{Lu}'-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+ ?)+)"
    enforced_declined_enforced_regex = r"enforced \(((?:[A-Z\\p{Lu}'-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+ ?)+)\)"
    declined_enforced_regex= r"declined;? .+ enforced"

    if DEBUG_PENALTY println("  Trying declined and enforced") end
    declined_enforced_multi_regex= Regex("$de_enc_regex;? .+ $de_enc_regex;? .+ $de_enc_regex;?")

    enforced = ""
    declined = ""

    penalty_list_occurred = Vector{String}()#[]
    for penalty in penalty_type_vec
        # if occursin(Regex("$penalties_regex_txt (?:$team1|$team2) ($penalty)"), txt)
        # if occursin(Regex("(?:$team1|$team2|$team3) $penalty"), txt)
        if occursin(Regex("$penalty"), txt)
            push!(penalty_list_occurred, penalty)
        end
    end
    if DEBUG_PENALTY println("penalty_list_occurred: $penalty_list_occurred") end
    
    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]
    if occursin(declined_enforced_multi_regex, txt)
        m = ""
        if occursin(off_abbrv_catch, txt) 
            team_regex = off_abbrv_catch
            team = offense
        else 
            team_regex = def_abbrv_catch
            team = defense
        end
        for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, penalty3 in penalty_list_occurred
            regex = Regex("PENALTY $team_regex ($penalty1) on $name_lastfirst_penalty_regex $de_enc_regex $team_regex ($penalty2) on $name_lastfirst_penalty_regex $de_enc_regex $team_regex ($penalty3) on $name_lastfirst_penalty_regex $de_enc_regex")
            # println(regex)
            # println("penalty1: $penalty1, penalty2: $penalty2, penalty3: $penalty3")
            m = match(regex, txt) 
            if !isnothing(m)
                break
            end
        end
        push!(foul_type, m[2])
        push!(foul_type, m[6])
        push!(foul_type, m[10])
        push!(foul_status, m[4])
        push!(foul_status, m[8])
        push!(foul_status, m[12])
        push!(foul_team, team) #m[1])
        push!(foul_team, team) #m[5])
        push!(foul_team, team) #m[9])
        push!(foul_transgressor, process_name(m[3]))
        push!(foul_transgressor, process_name(m[7]))
        push!(foul_transgressor, process_name(m[11]))
    elseif occursin(enforced_declined_regex, txt)
        if DEBUG_PENALTY println("I see enforced_declined_regex") end
        txt_penalty = strip(match(r"Penalty, (.*)", txt)[1])
      # println("txt_penalty = $txt_penalty")
        for re in penalty_list_occurred
            # println("For 1, penalty = $re")
            re = Regex("^("*re*")")
            if occursin(re, txt_penalty)
                declined = strip(match(re, txt_penalty)[1])
                txt_penalty = strip(SubString(txt_penalty, length(declined)+1, length(txt_penalty)))

              # println("New txt = $txt_penalty")
                break
            end
        end
        for re in penalty_list_occurred
            # println("For 2, penalty = $re")
            re = Regex("^("*re*")")
            if occursin(re, txt_penalty)
                enforced = strip(match(re, txt_penalty)[1])
                break
            end
        end
        foul_type = [enforced, declined]
        foul_status = ["enforced", "declined"]

        #Find which team comitted the foul
        if occursin(Regex(off_abbrv*" "*penalties_regex_txt), txt)
            push!(foul_team, offense)
            push!(foul_team, offense)
        elseif occursin(Regex(def_abbrv*" "*penalties_regex_txt), txt)
            push!(foul_team, defense)
            push!(foul_team, defense)
        else
            push!(foul_team, "Parse Error")
            push!(foul_team, "Parse Error")
        end

        #Find transgressor
        if occursin(enforced_declined_on_regex, txt_penalty)
            last_name, first_name = strip.(split(match(enforced_declined_on_regex, txt_penalty)[1], ","))
            push!(foul_transgressor, first_name*" "*titlecase(last_name))
            push!(foul_transgressor, "No data")
        elseif occursin(enforced_declined_enforced_regex, txt_penalty)
            push!(foul_transgressor, strip(match(enforced_declined_enforced_regex, txt_penalty)[1]))
            push!(foul_transgressor, "No data")
        else
            push!(foul_transgressor, "No data")
            push!(foul_transgressor, "No data")
        end
    elseif occursin(declined_enforced_regex, txt)
        if DEBUG_PENALTY println("I see declined_enforced_regex") end
        m = ""
        match1 = nothing
        if occursin(Regex("PENALTY "*off_abbrv_catch), txt) 
            team_regex = off_abbrv_catch
            team = offense
        else 
            team_regex = def_abbrv_catch
            team = defense
        end
      # println("team: $team")
        for penalty_declined in penalty_list_occurred, penalty_enforced in penalty_list_occurred
            # regex = Regex("PENALTY $team_regex ($penalty_declined) on ([A-Z\\p{Lu}'-]+, (?:[A-Z\\p{Lu}'-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+ ?)+) declined $team_regex ($penalty_enforced) on ([A-Z\\p{Lu}'-]+, (?:[A-Z\\p{Lu}'-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+ ?)+) enforced")
            regex = Regex("PENALTY $team_regex ($penalty_declined) on $name_lastfirst_penalty_regex declined $team_regex ($penalty_enforced) on $name_lastfirst_penalty_regex enforced")
            # println(regex)
            m = match(regex, txt) 
            # println("m = $m")
            if !isnothing(m)
                match1 = true
                break
            end
            regex = Regex("PENALTY $team_regex ($penalty_declined) on(?: #\\d+)? ([A-Z\\p{Lu}'-].(?:[A-Z\\p{Lu}'-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+ ?)+) declined; $team_regex ($penalty_enforced) on(?: #\\d+)? ([A-Z\\p{Lu}'-].(?:[A-Z\\p{Lu}'-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+ ?)+) enforced")
            m = match(regex, txt) 
            if !isnothing(m)
                match1 = false
                break
            end
        end
        if isnothing(m)
            maux = ""
            m = Vector{String}()#[]
            # for penalty_declined in penalty_list_occurred[51:53], penalty_enforced in penalty_list_occurred[15:17]
            for penalty_declined in penalty_list_occurred, penalty_enforced in penalty_list_occurred
                regex = Regex("PENALTY $team_regex ($penalty_declined) declined; $team_regex ($penalty_enforced) on(?: #\\d+)? ([A-Z\\p{Lu}'-].(?:[A-Z\\p{Lu}'-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+ ?)+) enforced")
                # println("penalty_declined: $penalty_declined, penalty_enforced: $penalty_enforced")
                maux = match(regex, txt) 
                if !isnothing(maux)
                    push!(m, maux[1])
                    push!(m, maux[2])
                    push!(m, "No.Data")
                    push!(m, maux[3])
                    push!(m, maux[4])
                    push!(m, maux[5])
                    match1 = false
                    break
                end
            end
        end
        if DEBUG_PENALTY println(m) end
        push!(foul_type, m[5])
        push!(foul_type, m[2])
        push!(foul_status, "enforced")
        push!(foul_status, "declined")
        push!(foul_team, team) #m[4])
        push!(foul_team, team) #m[1])
        if match1
            push!(foul_transgressor, process_name(m[6]))
            push!(foul_transgressor, process_name(m[3]))
        else
            #TIGHTEN: I don't think I need the two different cases since process_name converts both
            push!(foul_transgressor, process_name(m[6]))
            push!(foul_transgressor, process_name(m[3]))
        end
    else
        println("Missed: declined_enforced_aux")
        @warn("Missed: declined_enforced_aux")
    end
    
    foul_type, foul_status, foul_team, foul_transgressor
end

#############################################################################################################################################################################
#declined_aux aux functions
function declinedaux_triple_regex(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    m = nothing

    if occursin(Regex("PENALTY $off_abbrv_catch"), txt) 
        team_regex = off_abbrv_catch
        team = offense
    else 
        team_regex = def_abbrv_catch
        team = defense
    end

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    if DEBUG_PENALTY println("  Trying triple_regex") end
    # for penalty_declined1 in penalty_type_vec, penalty_declined2 in penalty_type_vec, penalty_enforced in penalty_type_vec
    for penalty_declined1 in penalty_list_occurred, penalty_declined2 in penalty_list_occurred, penalty_enforced in penalty_list_occurred
        multi_penalty_name_regex = 
        Regex("$penalties_regex_txt $team_regex ($penalty_declined1) declined, $penalties_regex_txt $team_regex ($penalty_declined2) declined, $penalties_regex_txt $team_regex ($penalty_enforced) \\($name_regex\\)")
        m = match(multi_penalty_name_regex, txt) 
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_type, m[4])
            push!(foul_type, m[6])
            push!(foul_status, "declined")
            push!(foul_status, "declined")
            push!(foul_status, "enforced")
            push!(foul_team, team) #m[1])
            push!(foul_team, team) #m[3])
            push!(foul_team, team) #m[5])
            push!(foul_transgressor, "No data")
            push!(foul_transgressor, "No data")
            push!(foul_transgressor, m[7])
            break
        end
        multi_penalty_regex = 
        Regex("$penalties_regex_txt $team_regex ($penalty_declined1) declined, $penalties_regex_txt $team_regex ($penalty_declined2) declined, $penalties_regex_txt $team_regex ($penalty_enforced)")
        m = match(multi_penalty_regex, txt) 
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_type, m[4])
            push!(foul_type, m[6])
            push!(foul_status, "declined")
            push!(foul_status, "declined")
            push!(foul_status, "enforced")
            push!(foul_team, team) #m[1])
            push!(foul_team, team) #m[3])
            push!(foul_team, team) #m[5])
            push!(foul_transgressor, "No data")
            push!(foul_transgressor, "No data")
            push!(foul_transgressor, "No data")
            break
        end
    end
    if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

function declinedaux_declined_accepted(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    m = nothing
    
    if occursin(Regex("PENALTY $off_abbrv_catch"), txt) 
        team_regex = off_abbrv_catch
        team = offense
    else 
        team_regex = def_abbrv_catch
        team = defense
    end

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    # declined accepted
    if DEBUG_PENALTY println("  Trying declined_accepted") end
    # println("Team is $team, regex is $team_regex")
    for penalty_declined in penalty_list_occurred, penalty_accepted in penalty_list_occurred
        declined_accepted_name_regex = 
        Regex("PENALTY $team_regex ($penalty_declined) declined,(?: NO PLAY,)? PENALTY $team_regex ($penalty_accepted) \\($name_regex\\)")
        m = match(declined_accepted_name_regex, txt)
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_type, m[4])
            push!(foul_status, "declined")
            push!(foul_status, "enforced")
            push!(foul_team, team) #m[1])
            push!(foul_team, team) #m[3])
            push!(foul_transgressor, "No data")
            push!(foul_transgressor, m[5])
        # println("declined_accepted_name_regex")
            break
        end
        declined_accepted_revname_regex = 
        Regex("PENALTY $team_regex ($penalty_declined) declined,(?: NO PLAY,)? PENALTY $team_regex ($penalty_accepted) \\($name_lastfirst_penalty_regex\\)")
        m = match(declined_accepted_revname_regex, txt)
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_type, m[4])
            push!(foul_status, "declined")
            push!(foul_status, "enforced")
            push!(foul_team, team) #m[1])
            push!(foul_team, team) #m[3])
            push!(foul_transgressor, "No data")
            push!(foul_transgressor, process_name(m[5]))
            # last_name, first_name = strip.(split(m[5], ","))
            # push!(foul_transgressor, titlecase(first_name)*" "*titlecase(last_name))
        # println("declined_accepted_revname_regex")                  
            break
        end
        declined_accepted_revcapname_regex = 
        Regex("PENALTY $team_regex ($penalty_declined) declined,(?: NO PLAY,)? PENALTY $team_regex ($penalty_accepted) \\($name_caplastfirst_penalty_regex\\)")
        m = match(declined_accepted_revcapname_regex, txt)
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_type, m[4])
            push!(foul_status, "declined")
            push!(foul_status, "enforced")
            push!(foul_team, team) #m[1])
            push!(foul_team, team) #m[3])
            push!(foul_transgressor, "No data")
            push!(foul_transgressor, process_name(m[5]))
            # last_name, first_name = strip.(split(m[5], ","))
            # push!(foul_transgressor, titlecase(first_name)*" "*titlecase(last_name))
        # println("declined_accepted_revcapname_regex")
            break
        end
        declined_revname_accepted_revname_regex = 
        Regex("PENALTY $team_regex ($penalty_declined) \\($name_lastfirst_penalty_regex\\) declined,(?: NO PLAY,)? PENALTY $team_regex ($penalty_accepted) \\($name_lastfirst_penalty_regex\\)")
        m = match(declined_revname_accepted_revname_regex, txt)
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_type, m[5])
            push!(foul_status, "declined")
            push!(foul_status, "enforced")
            push!(foul_team, team) #m[1])
            push!(foul_team, team) #m[3])
            push!(foul_transgressor, process_name(m[3]))
            push!(foul_transgressor, process_name(m[6]))
            # last_name, first_name = strip.(split(m[3], ","))
            # push!(foul_transgressor, titlecase(first_name)*" "*titlecase(last_name))
            # last_name, first_name = strip.(split(m[6], ","))
            # push!(foul_transgressor, titlecase(first_name)*" "*titlecase(last_name))
        # println("declined_revname_accepted_revname_regex")
            break
        end
        declined_noname_accepted_noname_regex = 
        Regex("$penalties_regex_txt $team_regex ($penalty_declined) declined,(?: NO PLAY,)? $penalties_regex_txt $team_regex ($penalty_accepted)")
        #PENALTY APP illegal block declined, PENALTY APP holding 10 yards to the CAM39, NO PLAY.
        m = match(declined_noname_accepted_noname_regex, txt)
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_type, m[4])
            push!(foul_status, "declined")
            push!(foul_status, "enforced")
            push!(foul_team, team) #m[1])
            push!(foul_team, team) #m[3])
            push!(foul_transgressor, "No data")
            push!(foul_transgressor, "No data")
            break
        end
    end
    if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

function declinedaux_declined_accepted_specialcase(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    m = nothing

    if occursin(Regex("PENALTY $off_abbrv_catch"), txt) 
        team_regex = off_abbrv_catch
        team = offense
    else 
        team_regex = def_abbrv_catch
        team = defense
    end

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    if DEBUG_PENALTY println("  Trying declined_accepted_specialcase") end
    for penalty_declined in penalty_list_occurred
        declined_nopenalty_accepted_revname_regex = Regex("$penalties_regex_txt,?\\s+(?:\\( Yards\\))? declined.*,(?: NO PLAY,)? $penalties_regex_txt,? $team_regex ($penalty_declined) \\($name_lastfirst_penalty_regex\\)")
        m = match(declined_nopenalty_accepted_revname_regex, txt)
        if !isnothing(m)
            push!(foul_type, "No data")
            push!(foul_type, m[2])
            push!(foul_status, "declined")
            push!(foul_status, "enforced")
            push!(foul_team, team) #m[1])
            push!(foul_team, team) #m[3])
            push!(foul_transgressor, "No data")
            push!(foul_transgressor, process_name(m[3]))
            # last_name, first_name = strip.(split(m[3], ","))
            # push!(foul_transgressor, titlecase(first_name)*" "*titlecase(last_name))
            break
        end
    end
    if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

function declinedaux_accepted_declined(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    m = nothing

    if occursin(Regex("PENALTY $off_abbrv_catch"), txt) 
        team_regex = off_abbrv_catch
        team = offense
    else 
        team_regex = def_abbrv_catch
        team = defense
    end

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    if DEBUG_PENALTY println("  Trying accepted_declined") end
    # declined accepted
    # println("Team is $team, regex is $team_regex")
    for penalty_declined in penalty_list_occurred, penalty_accepted in penalty_list_occurred
        accepted_declined_noname_regex = Regex("PENALTY $team_regex ($penalty_accepted) \\d+.+,(?: NO PLAY,)? PENALTY $team_regex ($penalty_declined) declined")
        m = match(accepted_declined_noname_regex, txt)
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_type, m[4])
            push!(foul_status, "enforced")
            push!(foul_status, "declined")
            push!(foul_team, team) #m[1])
            push!(foul_team, team) #m[3])
            push!(foul_transgressor, "No data")
            push!(foul_transgressor, "No data")
            break
        end
        accepted_name_declined_regex = Regex("PENALTY $team_regex ($penalty_accepted) \\($name_regex\\) \\d+.+,(?: NO PLAY,)? PENALTY $team_regex ($penalty_declined) declined")
        m = match(accepted_name_declined_regex, txt)
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_type, m[5])
            push!(foul_status, "enforced")
            push!(foul_status, "declined")
            push!(foul_team, team) 
            push!(foul_team, team) 
            push!(foul_transgressor, m[3])
            push!(foul_transgressor, "No data")
            break
        end
        accepted_revname_declined_regex = Regex("PENALTY $team_regex ($penalty_accepted) \\($name_lastfirst_penalty_regex\\) \\d+.+,(?: NO PLAY,)? PENALTY $team_regex ($penalty_declined) declined")
        m = match(accepted_revname_declined_regex, txt)
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_type, m[5])
            push!(foul_status, "enforced")
            push!(foul_status, "declined")
            push!(foul_team, team) #m[1])
            push!(foul_team, team) #m[3])
            push!(foul_transgressor, process_name(m[3]))
            # last_name, first_name = strip.(split(m[3], ","))
            # push!(foul_transgressor, titlecase(first_name)*" "*titlecase(last_name))
            push!(foul_transgressor, "No data")
            break
        end
    end
      if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

function declinedaux_accepted_declined_specialcase1(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    m = nothing

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    if DEBUG_PENALTY println("  Trying accepted_declined_specialcase1") end
    for penalty_accepted in penalty_list_occurred, penalty_declined in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
        # println("team1 = $team1")
        # println("|team1| = $(length(team1)), |penalties_regex_txt| = $(length(penalties_regex_txt)), |penalty_accepted| = $(length(penalty_accepted))")
        accepted_declined_specialcase_regex1 = Regex("$team1 $penalties_regex_txt,? ($penalty_accepted).+ $team2 $penalties_regex_txt,? ($penalty_declined) \\(-?\\d* Yards\\) declined")
        m = match(accepted_declined_specialcase_regex1, txt)
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_type, m[4])
            push!(foul_status, "enforced")
            push!(foul_status, "declined")
            push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
            push!(foul_team, get_team_name(m[3], offense, off_abbrv_catch, defense, def_abbrv_catch))
            # if occursin(Regex("$(m[3])"), off_abbrv_catch)
            #     push!(foul_team, offense)
            #     # println("defense = $offense")
            # elseif occursin(Regex("$(m[3])"), def_abbrv_catch)
            #     push!(foul_team, defense)
            #     # println("defense = $defense")
            # else
            #     push!(foul_team, "No data")
            #     # println("No data")
            # end
            push!(foul_transgressor, "No data")
            push!(foul_transgressor, "No data")
            break
        end
        accepted_declined_specialcase_regex2 = Regex("$team2 $penalties_regex_txt,?.+$penalties_regex_txt,? ($penalty_declined) \\(-?\\d* Yards\\) declined")
        m = match(accepted_declined_specialcase_regex2, txt)
        if !isnothing(m)
            push!(foul_type, "No data")
            push!(foul_type, m[2])
            push!(foul_status, "enforced")
            push!(foul_status, "declined")
            if occursin(Regex("$(m[1])"), off_abbrv_catch)
                push!(foul_team, offense)
                push!(foul_team, offense)
                # println("offense = $offense")
            elseif occursin(Regex("$(m[1])"), def_abbrv_catch)
                push!(foul_team, defense)
                push!(foul_team, defense)
                # println("offense = $defense")
            else
                push!(foul_team, "No data")
                # println("No data")
            end
            push!(foul_transgressor, "No data")
            push!(foul_transgressor, "No data")
            break
        end
        accepted_declined_specialcase_turnoverdowns_regex = 
        Regex("$team2 $penalties_regex_txt,? turnover on downs\\.? $penalties_regex_txt,? ($penalty_declined) on $name_caplastfirst_penalty_regex \\(-?\\d* Yards\\) declined")
        m = match(accepted_declined_specialcase_turnoverdowns_regex, txt)
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_status, "declined")
            if occursin(Regex("$(m[1])"), off_abbrv_catch)
                push!(foul_team, offense)
            elseif occursin(Regex("$(m[1])"), def_abbrv_catch)
                push!(foul_team, defense)
            else
                push!(foul_team, "No data")
            end
            push!(foul_transgressor, process_name(m[3]))
            # last_name, first_name = strip.(split(m[3], ","))
            # push!(foul_transgressor, titlecase(first_name)*" "*titlecase(last_name))
            break
        end
        #CHECK: I'm sure the below is correct, but would like to verify with game film.
        accepted_declined_specialcase_kick_regex = 
        Regex("$penalties_regex_txt,? $team1 ($penalty_accepted) \\($name_lastfirst_penalty_regex\\) \\d+ yards to .+ \\(.+ KICK\\) $team2 $penalties_regex_txt,? ($penalty_declined) \\(-?\\d* Yards\\) declined")
        #PENALTY UF offside (Henderson,C.) 2 yards to the UF1, NO PLAY. (Tucker McCann KICK) FLORIDA Penalty, Defensive offside ( Yards) declined
        m = match(accepted_declined_specialcase_kick_regex, txt)
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_type, m[5])
            push!(foul_status, "enforced")
            push!(foul_status, "declined")
            push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
            push!(foul_team, get_team_name(m[4], offense, off_abbrv_catch, defense, def_abbrv_catch))
            push!(foul_transgressor, process_name(m[3]))
            push!(foul_transgressor, "No data")
            break
        end
    end
    if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

function declinedaux_accepted_declined_specialcase2(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    m = nothing

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    if DEBUG_PENALTY println("  Trying accepted_declined_specialcase2") end
    for penalty_declined in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
        accepted_declined_specialcase_regex2 = 
        # Regex("$penalties_regex_txt $team ($penalty_declined)")
        Regex("$penalties_regex_txt $team ($penalty_declined)")
        #PENALTY MIA Holding 10 yards from EMU47 to MIA43. NO PLAY.
        m = match(accepted_declined_specialcase_regex2, txt)
        if isnothing(m)
            team_peanlty_junk_peanlty_foul_declined_regex = 
            Regex("$team $penalties_regex_txt,? ball on .+, $penalties_regex_txt ($penalty_declined) \\(-?\\d* [Yy]ards\\) declined")
            #SAN JOSÉ ST Penalty, ball on WY40, PENALTY offside (-5 Yards) 
            m = match(team_peanlty_junk_peanlty_foul_declined_regex, txt)
        end
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_status, "declined")
            push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
            push!(foul_transgressor, "No data")
            break
        end
    end
    if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

function declinedaux_declined_na(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    m = nothing

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    if DEBUG_PENALTY println("  Trying declined_na") end
    if occursin(Regex("$off_abbrv_catch Penalty"), txt) 
        team_regex = off_abbrv_catch
        team = offense
    else 
        team_regex = def_abbrv_catch
        team = defense
    end
    # Penalty (NA)
    if DEBUG_PENALTY println("  Trying (NA)") end
    # println("Team is $team, regex is $team_regex")
    for penalty in penalty_list_occurred
        declined_na_regex = Regex("$team_regex $penalties_regex_txt,? ($penalty) \\(NA\\) declined")
        m = match(declined_na_regex, txt)
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_status, "declined")
            push!(foul_team, team)
            push!(foul_transgressor, "No data")
            break
        end
        declined_na_doublespace_regex = Regex("$team_regex $penalties_regex_txt,?  \\(NA\\) declined")
        m = match(declined_na_doublespace_regex, txt)
        if !isnothing(m)
            push!(foul_type, "No data")
            push!(foul_status, "declined")
            push!(foul_team, team)
            push!(foul_transgressor, "No data")
            break
        end
        declined_0yards_na_regex = Regex("$team_regex $penalties_regex_txt,? ($penalty) \\(\\d+ [Yy]ards\\) \\(NA\\) declined")
        # declined_0yards_na_regex = Regex("$team_regex $penalties_regex_txt,? (face mask) \\(\\d+ [Yy]ards\\) \\(NA\\) declined")
        #NORTH TEXAS Penalty, face mask (0 yards) (NA) declined
        m = match(declined_0yards_na_regex, txt)
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_status, "declined")
            push!(foul_team, team)
            push!(foul_transgressor, "No data")
            break
        end
    end
    if isnothing(m)
        missed1_regex = Regex("$team_regex $penalties_regex_txt,? .+\\(NA\\) declined")
        m = match(missed1_regex, txt)
        if !isnothing(m)
            push!(foul_type, "No data")
            push!(foul_status, "declined")
            push!(foul_team, team)
            push!(foul_transgressor, "No data")
        end
    end
    if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

function declinedaux_declined_team(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    m = nothing

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    if DEBUG_PENALTY println("  Trying declined_team") end
    if occursin(Regex("$off_abbrv_catch Penalty"), txt) 
        team_regex = off_abbrv_catch
        team = offense
    else 
        team_regex = def_abbrv_catch
        team = defense
    end
    # Penalty (TEAM)
    if DEBUG_PENALTY println("  Trying (TEAM)") end
    # println("Team is $team, regex is $team_regex")
    for penalty in penalty_list_occurred
        declined_na_regex = Regex("$team_regex $penalties_regex_txt,? ($penalty) \\(TEAM\\) declined")
        m = match(declined_na_regex, txt)
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_status, "declined")
            push!(foul_team, team)
            push!(foul_transgressor, "No data")
            break
        end
    end

    foul_type, foul_status, foul_team, foul_transgressor
end

function declinedaux_declined_accepted_yards(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    m = nothing

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    if DEBUG_PENALTY println("  Trying declined_accepted_yards") end
    # println("Team is $team, regex is $team_regex")
    for team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch], penalty_declined in penalty_list_occurred, penalty_accepted in penalty_list_occurred
        declined_accpeted_yards_regex = Regex("$team1 $penalties_regex_txt,? ($penalty_declined)(?: \\(0 yards\\))? \\(-?\\d* Yards\\) declined $team2 $penalties_regex_txt,? ($penalty_accepted) \\(-?\\d* Yards\\)")
        m = match(declined_accpeted_yards_regex, txt)
        if !isnothing(m)                
            push!(foul_type, m[2])                
            push!(foul_type, m[4])
            push!(foul_status, "declined")
            push!(foul_status, "enforced")
            push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
            if occursin(Regex("$(m[3])"), off_abbrv_catch)
                push!(foul_team, offense)
                # println("defense = $offense")
            elseif occursin(Regex("$(m[3])"), def_abbrv_catch)
                push!(foul_team, defense)
                # println("defense = $defense")
            else
                push!(foul_team, "No data")
                # println("No data")
            end
            push!(foul_transgressor, "No data")
            push!(foul_transgressor, "No data")
            break
        end
        accpeted_declined_yards_regex = Regex("$team1 $penalties_regex_txt,? ($penalty_accepted)(?: \\(0 yards\\))? \\(-?\\d* Yards\\).+$team2 $penalties_regex_txt,? ($penalty_declined) \\(-?\\d* Yards\\) declined")
        m = match(accpeted_declined_yards_regex, txt)
        if !isnothing(m)                
            push!(foul_type, m[2])                
            push!(foul_type, m[4])
            push!(foul_status, "enforced")
            push!(foul_status, "declined")
            push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
            if occursin(Regex("$(m[3])"), off_abbrv_catch)
                push!(foul_team, offense)
                # println("defense = $offense")
            elseif occursin(Regex("$(m[3])"), def_abbrv_catch)
                push!(foul_team, defense)
                # println("defense = $defense")
            else
                push!(foul_team, "No data")
                # println("No data")
            end
            push!(foul_transgressor, "No data")
            push!(foul_transgressor, "No data")
            break
        end
    end
    if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

function declinedaux_declined_yards(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    m = nothing

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    if DEBUG_PENALTY println("  Trying declined_yards") end
    if occursin(Regex("$off_abbrv_catch Penalty"), txt) 
        team_regex = off_abbrv_catch
        team = offense
    else 
        team_regex = def_abbrv_catch
        team = defense
    end
    # println("Team is $team, regex is $team_regex")
    for penalty_declined1 in penalty_list_occurred, penalty_declined2 in penalty_list_occurred
        declined_yards_regex = 
        Regex("$team_regex $penalties_regex_txt,? ($penalty_declined2)?(?: \\(\\d+ yards\\))? \\(-?\\d* Yards\\) declined")
        m = match(declined_yards_regex, txt)
        # println("m[2] = $(m[2])")
        if !isnothing(m)
            if isnothing(m[2])
                push!(foul_type, "No data")
            else
                push!(foul_type, m[2])
            end
            push!(foul_status, "declined")
            push!(foul_team, team)
            push!(foul_transgressor, "No data")
            break
        end
        #Having to guess which is the declined and which is the enforced penalties. Need to find videos.
        #SOUTHN ILLINOIS Penalty, Illegal Shift Ineligible Downfield on Pass ( Yards) declined
        penalty_penalty_yards_regex = 
        Regex("$team_regex $penalties_regex_txt,? ($penalty_declined1) ($penalty_declined2) \\( Yards\\) declined")
        m = match(penalty_penalty_yards_regex, txt)
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_type, m[3])
            push!(foul_status, "declined")
            push!(foul_status, "declined")
            push!(foul_team, team)
            push!(foul_team, team)
            push!(foul_transgressor, "No data")
            push!(foul_transgressor, "No data")
            break
        end
        penalty_penalty_yards_regex = 
        Regex("$team_regex $penalties_regex_txt,? ($penalty_declined1) ($penalty_declined2) on $name_caplastfirst_penalty_regex \\( Yards\\) declined")
        #TEMPLE Penalty, Offsides Pass Interference on RUIZ, Cameron ( Yards) declined for a 1ST down
        #CHECK: Need to check video to verify player committed the 2nd foul
        m = match(penalty_penalty_yards_regex, txt)
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_type, m[3])
            push!(foul_status, "declined")
            push!(foul_status, "declined")
            push!(foul_team, team)
            push!(foul_team, team)
            push!(foul_transgressor, "No data")
            push!(foul_transgressor, process_name(m[4]))
            break
        end
    end
    if isnothing(m)
        for penalty_declined in penalty_list_occurred
            penalty_yards_specialcase1_regex = 
            Regex("$team_regex $penalties_regex_txt,? ($penalty_declined) on $name_caplastfirst_penalty_regex \\( Yards\\) declined")
            #AKRON Penalty, Ineligible Receiver Downfield on Pass on GRAY, Xavior ( Yards) declined
            m = match(penalty_yards_specialcase1_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "declined")
                push!(foul_team, team)
                push!(foul_transgressor, process_name(m[3]))
                break
            end
        end
    end
    if isnothing(m)
        for penalty_declined in penalty_list_occurred
            team_penalty_on_periodname_declined_yards_regex = 
            Regex("$team_regex $penalties_regex_txt,? ($penalty_declined) on $name_period_penalty_regex declined;?(?: \\.)? \\( Yards\\)")
            #MEMPHIS Penalty, Ineligible Receiver Downfield on Pass on I.Ellis declined; . ( Yards) to the NicSt 20
            m = match(team_penalty_on_periodname_declined_yards_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "declined")
                push!(foul_team, team)
                push!(foul_transgressor, process_name(m[3]))
                break
            end
        end
    end
    if isnothing(m)
        for penalty_declined in penalty_list_occurred
            penalty_yards_specialcase1_regex = 
            Regex("$team_regex $penalties_regex_txt,? .+($penalty_declined) \\( Yards\\) declined")
            m = match(penalty_yards_specialcase1_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "declined")
                push!(foul_team, team)
                push!(foul_transgressor, "No data")
                break
            end
        end
    end
    if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

function declinedaux_declined_no_paraenthesis(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    m = nothing

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    if DEBUG_PENALTY println("  Trying declined_no_paraenthesis") end
    if occursin(Regex("$off_abbrv_catch Penalty"), txt) 
        team_regex = off_abbrv_catch
        team = offense
    else 
        team_regex = def_abbrv_catch
        team = defense
    end
    # println("Team is $team, regex is $team_regex")
    for penalty in penalty_list_occurred
        declined_yards_regex = Regex("$team_regex $penalties_regex_txt,? ($penalty) declined")
        m = match(declined_yards_regex, txt)
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_status, "declined")
            push!(foul_team, team)
            push!(foul_transgressor, "No data")
            break
        end
    end
    if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

function declinedaux_penalty_team_team(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    m = nothing

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    if DEBUG_PENALTY println("  Trying penalty_team_team") end
    if occursin(Regex("PENALTY $off_abbrv_catch"), txt) 
        team_regex = off_abbrv_catch
        team = offense
    else 
        team_regex = def_abbrv_catch
        team = defense
    end
    # println("Team is $team, regex is $team_regex")
    for penalty_declined in penalty_list_occurred, penalty_accepted in penalty_list_occurred
        team_team_regex = Regex("$penalties_regex_txt $team_regex ($penalty_declined) declined $team_regex ($penalty_accepted) \\($name_lastfirst_penalty_regex\\)")
        m = match(team_team_regex, txt)
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_type, m[4])
            push!(foul_status, "declined")
            push!(foul_status, "enforced")
            push!(foul_team, team)
            push!(foul_team, team)
            push!(foul_transgressor, "No data")
            push!(foul_transgressor, process_name(m[5]))
            # last_name, first_name = strip.(split(m[5], ","))
            # push!(foul_transgressor, titlecase(first_name)*" "*titlecase(last_name))
            break
        end
    end
    if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

function declinedaux_team_penalty_penalty_or_name(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    m = nothing

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    if DEBUG_PENALTY println("  Trying team_penalty_penalty_or_name") end
    if occursin(Regex("$off_abbrv_catch Penalty"), txt) 
        team_regex = off_abbrv_catch
        team = offense
    else 
        team_regex = def_abbrv_catch
        team = defense
    end
    # Penalty ( Yards)
    # println("Team is $team, regex is $team_regex")
    for penalty_accepted in penalty_list_occurred, penalty_declined in penalty_list_occurred
        #HAVING to GUESS which is the declined and which is the enforced penalties. NEED to find videos.            
        penalty_penalty_regex = Regex("$team_regex $penalties_regex_txt,? ($penalty_declined) ($penalty_accepted) \\($name_regex\\)")
        #CLEMSON Penalty, Holding Holding (Davis Allen) declined
        m = match(penalty_penalty_regex, txt)
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_type, m[3])
            push!(foul_status, "declined")
            push!(foul_status, "declined")
            push!(foul_team, team)
            push!(foul_team, team)
            push!(foul_transgressor, "No data")
            push!(foul_transgressor, m[4])
            break
        end
        #Having to guess which is the declined and which is the enforced penalties. Need to find videos.            
        penalty_name_regex = Regex("$team_regex $penalties_regex_txt,? ($penalty_declined)(?: \\(0 [Yy]ards\\))? \\($name_regex\\)")
        #WESTRN MICHIGAN Penalty, Offensive Pass Interference (Corey Davis) declined
        #KENT ST Penalty, Face Mask (0 yards) (Zayin West) declined, (Marshall Meeder KICK)
        m = match(penalty_name_regex, txt)
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_status, "declined")
            push!(foul_team, team)
            push!(foul_transgressor, m[3])
            break
        end
    end
    if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

function declinedaux_team_penalty_penalty_on(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    m = nothing

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    if DEBUG_PENALTY println("  Trying team_penalty_penalty_on") end
    if occursin(Regex("$off_abbrv_catch Penalty"), txt) 
        team_regex = off_abbrv_catch
        team = offense
    else 
        team_regex = def_abbrv_catch
        team = defense
    end
    # Penalty ( Yards)
    # println("Team is $team, regex is $team_regex")
    for penalty_declined in penalty_list_occurred, penalty_accepted in penalty_list_occurred
        penalty_penalty_on_regex = Regex("$team_regex $penalties_regex_txt,? ($penalty_declined) ($penalty_accepted) on $name_caplastfirst_penalty_regex \\($name_simple_regex\\)")
        m = match(penalty_penalty_on_regex, txt)
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_type, m[3])
            push!(foul_status, "declined")
            push!(foul_status, "enforced")
            push!(foul_team, team)
            push!(foul_team, team)
            push!(foul_transgressor, process_name(m[4]))
            # last_name, first_name = strip.(split(m[4], ","))
            # push!(foul_transgressor, titlecase(first_name)*" "*titlecase(last_name))
            push!(foul_transgressor, m[5])
            break
        end
    end
    if DEBUG_PENALTY println(m) end    

    foul_type, foul_status, foul_team, foul_transgressor
end

function declinedaux_team_penalty_name_declined(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    m = nothing

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    if DEBUG_PENALTY println("  Trying team_penalty_name_declined") end
    if occursin(Regex("$off_abbrv_catch Penalty"), txt) 
        team_regex = off_abbrv_catch
        team = offense
    else 
        team_regex = def_abbrv_catch
        team = defense
    end
    # Penalty ( Yards)
    # println("Team is $team, regex is $team_regex")
    for penalty_declined in penalty_list_occurred
    team_penalty_name_declined_regex = 
        Regex("$team_regex $penalties_regex_txt,? ($penalty_declined) \\($name_penalty_regex\\) declined")
        # MEMPHIS Penalty, Illegal Touch-Pass (Thomas Pickens) declined
        m = match(team_penalty_name_declined_regex, txt)
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_status, "declined")
            push!(foul_team, team)
            push!(foul_transgressor, m[3])
            break
        end
    end
    if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

function declinedaux_penalty_team_accepted_revname_team_declined(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    m = nothing

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    if DEBUG_PENALTY println("  Trying penalty_team_accepted_revname_team_declined") end
    for penalty_accepted in penalty_list_occurred, penalty_declined in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
        penalty_team_accepted_revname_team_declined_regex = 
        Regex("$penalties_regex_txt,? $team1(?: UNS:)? ($penalty_accepted) \\($name_lastfirst_penalty_regex\\) $team2(?: UNS:)? ($penalty_declined) declined")
        #PENALTY BAY UNS: Unsportsmanlike Conduct (Pitre,Jalen) BAY UNS: Unsportsmanlike Conduct declined 15 yards from ISU35 to ISU50. NO PLAY.
        m = match(penalty_team_accepted_revname_team_declined_regex, txt)
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_type, m[5])
            push!(foul_status, "enforced")
            push!(foul_status, "declined")
            push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
            push!(foul_team, get_team_name(m[4], offense, off_abbrv_catch, defense, def_abbrv_catch))
            push!(foul_transgressor, process_name(m[3]))
            push!(foul_transgressor, "No data")
            break
        end
    end
    if DEBUG_PENALTY println(m) end    

    foul_type, foul_status, foul_team, foul_transgressor
end

function declinedaux_penalty_safety(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    m = nothing

    if occursin(Regex("PENALTY $off_abbrv_catch"), txt) 
        team_regex = off_abbrv_catch
        team = offense
    else 
        team_regex = def_abbrv_catch
        team = defense
    end

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    if DEBUG_PENALTY println("  Trying penalty_safety") end
    if occursin(Regex("$off_abbrv_catch Penalty"), txt) 
        team_regex = off_abbrv_catch
        team = offense
    else 
        team_regex = def_abbrv_catch
        team = defense
    end
    # Penalty ( Yards)
    # println("Team is $team, regex is $team_regex")
    for penalty_declined in penalty_list_occurred
        penalty_safety_regex = 
        Regex("$team_regex $penalties_regex_txt,?(?: fumbled snap, *\\.?)? (?:SAFETY|[Ss]afety) ($penalty_declined) on $name_caplastfirst_penalty_regex.+declined")
        #FLA ATLANTIC Penalty, SAFETY Intentional Grounding on PERRY, N'Kosi (N'Kosi Perry) declined
        #AUSTINPEAY Penalty, fumbled snap, . SAFETY Illegal Touch Of Kick on RIGNEY, Matthew (Matt Rigney) declined for a SAFETY
        m = match(penalty_safety_regex, txt)
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_status, "declined")
            push!(foul_team, team)
            push!(foul_transgressor, process_name(m[3]))
            # last_name, first_name = strip.(split(m[3], ","))
            # push!(foul_transgressor, titlecase(first_name)*" "*titlecase(last_name))
            break
        end
    end
    if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

function declinedaux_team_penalty_caprevname_paren_name_declined(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    m = nothing

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    if DEBUG_PENALTY println("  Trying team_penalty_caprevname_paren_name_declined") end
    for penalty_declined in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
        team_penalty_caprevname_paren_name_declined_regex = 
        Regex("$team $penalties_regex_txt,? ($penalty_declined) on $name_caplastfirst_penalty_regex \\($name_penalty_regex\\) declined")
        #OLDDOMINION Penalty, Running Into the kicker on MCDANIEL, Tyrik (Tyrik McDaniel) declined
        m = match(team_penalty_caprevname_paren_name_declined_regex, txt)
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_status, "declined")
            push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
            push!(foul_transgressor, m[4])
            break
        end
    end
    if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

function declinedaux_team_penalty_declined(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    m = nothing

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    if DEBUG_PENALTY println("  Trying team_penalty_declined") end
    for penalty_declined in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
        team_penalty_declined_regex = 
        Regex("$team $penalties_regex_txt,?(?: UNS:)? ($penalty_declined),? declined")
        #NORTH CAROLINA Penalty, Substitution Infraction, declined, (Brent Cimaglia KICK)
        m = match(team_penalty_declined_regex, txt)
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_status, "declined")
            push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
            push!(foul_transgressor, "No data")
            break
        end
    end
    if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

function declinedaux_penalty_team_declined(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    m = nothing

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    if DEBUG_PENALTY println("  Trying penalty_team_declined") end
    for penalty_declined in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
        penalty_team_declined_regex = 
        Regex("$penalties_regex_txt,? $team(?: UNS:)? ($penalty_declined),? declined")
        #NORTH CAROLINA Penalty, Substitution Infraction, declined, (Brent Cimaglia KICK)
        m = match(penalty_team_declined_regex, txt)
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_status, "declined")
            push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
            push!(foul_transgressor, "No data")
            break
        end
    end
    if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

function declinedaux_penalty_team_foul_team_foul_declined(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    m = nothing

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    if DEBUG_PENALTY println("  Trying penalty_team_foul_team_foul_declined") end
    for penalty_accepted in penalty_list_occurred, penalty_declined in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
        penalty_team_foul_team_foul_declined_regex = 
        Regex("$penalties_regex_txt,? $team1(?: UNS:)? ($penalty_accepted) $team2(?: UNS:)? ($penalty_declined) declined")
        #PENALTY NEV Offside NEV Offside declined 5 yards from NLV30 to NLV35, 1ST DOWN. NO PLAY.
        m = match(penalty_team_foul_team_foul_declined_regex, txt)
        if !isnothing(m)
            push!(foul_type, m[2])
            push!(foul_type, m[4])
            push!(foul_status, "enforced")
            push!(foul_status, "declined")
            push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
            push!(foul_team, get_team_name(m[3], offense, off_abbrv_catch, defense, def_abbrv_catch))
            push!(foul_transgressor, "No data")
            push!(foul_transgressor, "No data")
            break
        end
    end
    if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

############################################################################################################################################################
function declined_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_type_vec)
    
    declined_accepted = Regex("$penalties_regex_txt (?:[A-Za-z'\\(\\),\\.\\d-]+ )+declined,(?: NO PLAY,)? $penalties_regex_txt (?:[A-Za-z'\\(\\),\\.\\d-]+ )+\\d+")
    declined_accepted_specialcase = Regex("(?:Penalty|PENALTY),?  \\( Yards\\) declined.*, (?:Penalty|PENALTY) (?:[A-Za-z'\\(\\),\\.\\d-]+ )+\\d+")
    accepted_declined = Regex("$penalties_regex_txt (?:[A-Za-z'\\(\\),\\.\\d-]+ )+\\d+.+,(?: NO PLAY,)? $penalties_regex_txt (?:[A-Za-z'\\(\\),\\.\\d-]+ )+declined")
    accepted_declined_specialcase1 = Regex("$penalties_regex_txt.+$penalties_regex_txt.+ \\( Yards\\) declined")
    accepted_declined_specialcase2 = Regex("$penalties_regex_txt.+$penalties_regex_txt.+declined")

    declined_na = r"Penalty.+\(NA\)"
    declined_team = r"Penalty.+\(TEAM\)"
    declined_yards = r"Penalty,.+\(-?\d* Yards\)"
    declined_accepted_yards = r"(?:Penalty,.+\(-?\d* Yards\) declined.+ Penalty|Penalty,.+\(-?\d* Yards\).+ Penalty,.+\(-?\d* Yards\) declined)"
    declined_no_paraenthesis = r"[A-Z]+ Penalty, (?:[A-Za-z]+ ?){1,5}declined"
    penalty_team_team = r"PENALTY ([A-Z]+) (?:[A-Za-z]+ )+declined (?1)(?:[A-Za-z]+ )+\("
    team_penalty_penalty_or_name = r"([A-Z]+) Penalty,? (?:[A-Za-z]+ )+\("
    team_penalty_penalty_on = r"([A-Z]+) Penalty,? (?:(?:12)?[A-Z][a-z]+ )+on"
    team_penalty_name_declined = Regex("([A-Z]+) $penalties_regex_txt,? $penalty_general_regex \\($name_penalty_regex\\) declined")
    penalty_team_accepted_revname_team_declined = 
    Regex("$penalties_regex_txt,? ([A-Z]+)(?: UNS:)? $penalty_general_regex \\($name_lastfirst_penalty_regex\\) ([A-Z]+)(?: UNS:)? $penalty_general_regex declined")
    penalty_safety = Regex("$penalties_regex_txt,?(?: fumbled snap, *\\.?)? (?:SAFETY|[Ss]afety)")
    team_penalty_caprevname_paren_name_declined = 
    Regex("([A-Z]+) $penalties_regex_txt,?(?: UNS:)? $penalty_general_regex on $name_caplastfirst_penalty_regex \\($name_penalty_regex\\) declined")
    team_penalty_declined = 
    Regex("([A-Z]+) $penalties_regex_txt,?(?: UNS:)? $penalty_general_regex,? declined")
    penalty_team_declined = 
    Regex("$penalties_regex_txt,? ([A-Z]+)(?: UNS:)? $penalty_general_regex,? declined")
    penalty_team_foul_team_foul_declined = Regex("$penalties_regex_txt ([A-Z]+),?(?: UNS:)? $penalty_general_regex ([A-Z]+),?(?: UNS:)? $penalty_general_regex declined \\d+ [Yy]ards")
    Regex("([A-Z]+) $penalties_regex_txt,?(?: UNS:)? $penalty_general_regex,? declined")
    

    if DEBUG_PENALTY println("Trying declined_aux") end
    if occursin(Regex("PENALTY $off_abbrv_catch"), txt) 
        team_regex = off_abbrv_catch
        team = offense
    else 
        team_regex = def_abbrv_catch
        team = defense
    end
    # VVV Needed to fix Unicode problems VVV
    team_regex = replace(team_regex, "\xc9" => "É")
    team_regex = replace(team_regex, "\xe9" => "é")

    # m = "failed"

    penalty_list_occurred = Vector{String}()#[]
    for penalty in penalty_type_vec
        # if occursin(Regex("$penalties_regex_txt (?:$team1|$team2) ($penalty)"), txt)
        # if occursin(Regex("(?:$team1|$team2|$team3) $penalty"), txt)
        if occursin(Regex("$penalty"), txt)
            push!(penalty_list_occurred, penalty)
        end
    end
    if length(penalty_list_occurred) == 0
        push!(penalty_list_occurred, "NONE")
    end
    if DEBUG_PENALTY println("penalty_list_occurred: $penalty_list_occurred") end

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]
    #triple
    triple_regex = Regex("$penalties_regex_txt $team_regex .+$penalties_regex_txt $team_regex .+$penalties_regex_txt $team_regex")        
    if occursin(triple_regex, txt)
        foul_type, foul_status, foul_team, foul_transgressor = declinedaux_triple_regex(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    if isempty(foul_type) && occursin(declined_accepted, txt)
        foul_type, foul_status, foul_team, foul_transgressor = declinedaux_declined_accepted(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    if isempty(foul_type) && occursin(declined_accepted_specialcase, txt)
        foul_type, foul_status, foul_team, foul_transgressor = declinedaux_declined_accepted_specialcase(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    if isempty(foul_type) && occursin(accepted_declined, txt)
        foul_type, foul_status, foul_team, foul_transgressor = declinedaux_accepted_declined(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    if isempty(foul_type) && occursin(accepted_declined_specialcase1, txt)
        foul_type, foul_status, foul_team, foul_transgressor = declinedaux_accepted_declined_specialcase1(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    if isempty(foul_type) && occursin(accepted_declined_specialcase2, txt)
        foul_type, foul_status, foul_team, foul_transgressor = declinedaux_accepted_declined_specialcase2(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    if isempty(foul_type) && occursin(declined_na, txt)
        foul_type, foul_status, foul_team, foul_transgressor = declinedaux_declined_na(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    if isempty(foul_type) && occursin(declined_team, txt)
        foul_type, foul_status, foul_team, foul_transgressor = declinedaux_declined_team(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    if isempty(foul_type) && occursin(declined_accepted_yards, txt)
        foul_type, foul_status, foul_team, foul_transgressor = declinedaux_declined_accepted_yards(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    if isempty(foul_type) && occursin(declined_yards, txt)
        foul_type, foul_status, foul_team, foul_transgressor = declinedaux_declined_yards(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    if isempty(foul_type) && occursin(declined_no_paraenthesis, txt)
        foul_type, foul_status, foul_team, foul_transgressor = declinedaux_declined_no_paraenthesis(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    if isempty(foul_type) && occursin(penalty_team_team, txt)
        foul_type, foul_status, foul_team, foul_transgressor = declinedaux_penalty_team_team(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    if isempty(foul_type) && occursin(team_penalty_penalty_or_name, txt)
        foul_type, foul_status, foul_team, foul_transgressor = declinedaux_team_penalty_penalty_or_name(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    if isempty(foul_type) && occursin(team_penalty_penalty_on, txt)
        foul_type, foul_status, foul_team, foul_transgressor = declinedaux_team_penalty_penalty_on(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    if isempty(foul_type) && occursin(team_penalty_name_declined, txt)
        foul_type, foul_status, foul_team, foul_transgressor = declinedaux_team_penalty_name_declined(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    if isempty(foul_type) && occursin(penalty_team_accepted_revname_team_declined, txt)
        foul_type, foul_status, foul_team, foul_transgressor = declinedaux_penalty_team_accepted_revname_team_declined(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    if isempty(foul_type) && occursin(penalty_safety, txt)
        foul_type, foul_status, foul_team, foul_transgressor = declinedaux_penalty_safety(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    if isempty(foul_type) && occursin(team_penalty_caprevname_paren_name_declined, txt)
        foul_type, foul_status, foul_team, foul_transgressor = declinedaux_team_penalty_caprevname_paren_name_declined(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    if isempty(foul_type) && occursin(team_penalty_declined, txt)
        foul_type, foul_status, foul_team, foul_transgressor = declinedaux_team_penalty_declined(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    if isempty(foul_type) && occursin(penalty_team_declined, txt)
        foul_type, foul_status, foul_team, foul_transgressor = declinedaux_penalty_team_declined(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    if isempty(foul_type) && occursin(penalty_team_foul_team_foul_declined, txt)
        foul_type, foul_status, foul_team, foul_transgressor = declinedaux_penalty_team_foul_team_foul_declined(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    if isempty(foul_type)
        println("Missed: declined_aux")
    end
    
    foul_type, foul_status, foul_team, foul_transgressor
end

############################################################################################################################################################
function offsetting_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_type_vec)
    penalties_regex_txt = "(?:Penalty|PENALTY)"

    offsetting_offsetting = r"off-setting.+off-setting"
    offsetting = r"[Oo]ff-?setting"
    triple_penalty_regex = r"(?:Penalty|PENALTY).+(?:Penalty|PENALTY).+(?:Penalty|PENALTY)"
    
    double_penalty_regex = r"(?:Penalty|PENALTY).+(?:Penalty|PENALTY)"
    penalty_uns = r" UNS: "
    penalty_on_penalty_on = r"(?:Penalty|PENALTY) .+ on(?: #\d+)? .+on(?: #\d+)?"
    penalty_name_penalty = r"(?:Penalty|PENALTY),? [A-Za-z ]+\( ?[A-Za-z' -]+ ?\), [A-Z ]+(?:Penalty|PENALTY),? .+offsetting"
    penalty_name_penalty_name = r"(?:Penalty|PENALTY),? [A-Za-z ]+\( ?[A-Za-z' -]+ ?\), [A-Z ]+(?:Penalty|PENALTY),? [A-Za-z ]+\( ?[A-Za-z' -]+ ?\)"
    team_penalty_offsetting_team_penalty = r"(?:Penalty|PENALTY),? [A-Z ]+ [A-Za-z ]+ off-setting,? (?:Penalty|PENALTY) [A-Z ]+"
    team_penalty_team_penalty_offsetting = r"[A-Z ]+ [A-Za-z ]+ [A-Z ]+ [A-Za-z ]+ , [Oo]ff-?setting"
    team_penalty_team_penalty_on = r"[A-Z ]+ [A-Za-z ]+ [A-Z ]+ [A-Za-z ]+ on"
    team_penalty_offsetting_triple = r"[A-Z ]+ [A-Za-z ]+ [Oo]ff-?setting [A-Z ]+ [A-Za-z ]+ [Oo]ff-?setting [A-Z ]+ [A-Za-z ]+ [Oo]ff-?setting"
    # team_penalty_offsetting_team_penalty_offsetting = r"(?:Penalty|PENALTY) [A-Z ]+ [A-Za-z ]+ [Oo]ff-?setting [A-Z ]+ [A-Za-z ]+ [Oo]ff-?setting"
    team_penalty_offsetting_team_penalty_offsetting = r"(?:Penalty|PENALTY) [A-Za-z ]+ [Oo]ff-?setting [A-Za-z ]+ [Oo]ff-?setting"
    team_penalty_offsetting = r"[A-Z]+ (?:Penalty|PENALTY),? [A-Za-z ]+ off-?setting"
    penalty_team_foul_offsetting_team_foul_offsetting = 
    Regex("$penalties_regex_txt [A-Z]+ $penalty_general_regex $offsetting [A-Z]+ $penalty_general_regex $offsetting")
    team_penalty_adjacent_offsetting = r"(?:Penalty|PENALTY),? [A-Z]+ [A-Za-z ]+ off-?setting"
    
    m = "failed"

    #TESTING on i = 59876 to get team names so to not have to loop over them
    
    #END TESTING
    
    #Testing speedup idea: grab only penalties that occur in txt and then loop over them below.
    penalty_list_occurred = Vector{String}()#[]
    for penalty in penalty_type_vec
        # if occursin(Regex("$penalties_regex_txt (?:$team1|$team2) ($penalty)"), txt)
        # if occursin(Regex("(?:$team1|$team2|$team3) $penalty"), txt)
        if occursin(Regex("$penalty"), txt)
            push!(penalty_list_occurred, penalty)
        end
    end
    if DEBUG_PENALTY println("penalty_list_occurred: $penalty_list_occurred") end

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]
    if occursin(offsetting_offsetting, txt)
        if DEBUG_PENALTY println("  Trying: offsetting_offsetting") end
        
        if occursin(triple_penalty_regex, txt)

            team1 = ""
            team2 = ""
            team3 = ""
            for team_a in [off_abbrv_catch, def_abbrv_catch], team_b in [off_abbrv_catch, def_abbrv_catch], team_c in [off_abbrv_catch, def_abbrv_catch]
                
                triple_team_regex = Regex("$penalties_regex_txt $team_a .+ $penalties_regex_txt $team_b .+ $penalties_regex_txt $team_c")
                m = match(triple_team_regex, txt)
                if !isnothing(m)
                    team1 = team_a
                    team2 = team_b
                    team3 = team_c
                    break
                end
                triple_team_regex = Regex("$penalties_regex_txt $team_a .+ $penalties_regex_txt $team_b .+ $team_c $penalties_regex_txt")
                m = match(triple_team_regex, txt)
                if !isnothing(m)
                    team1 = team_a
                    team2 = team_b
                    team3 = team_c
                    break
                end
            end
          # println("team1: $team1, team2: $team2, team3: $team3")

            if DEBUG_PENALTY println("  trying: triple_penalty_regex (all cases)") end
            # for penalty1 in penalty_type_vec, penalty2 in penalty_type_vec, penalty3 in penalty_type_vec
            for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, penalty3 in penalty_list_occurred

                # println("team1: $team1, team2: $team2, team3: $team3, penalty1: $penalty1, penalty2: $penalty2, penalty3: $penalty3")

                penalty_offset_penalty_offset_penalty_offset = 
                Regex("$penalties_regex_txt $team1 ($penalty1) off-setting, $penalties_regex_txt $team2 ($penalty2) off-setting, $penalties_regex_txt $team3 ($penalty3) off-setting")
                #PENALTY UH personal foul off-setting, PENALTY UH player disqualification off-setting, PENALTY FS unsportsmanlike conduct off-setting, NO PLAY.
                m = match(penalty_offset_penalty_offset_penalty_offset, txt)
                if !isnothing(m)
                    push!(foul_type, m[2])
                    push!(foul_type, m[4])
                    push!(foul_type, m[6])
                    push!(foul_status, "off-setting")
                    push!(foul_status, "off-setting")
                    push!(foul_status, "off-setting")
                    push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_team, get_team_name(m[3], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_team, get_team_name(m[5], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_transgressor, "No data")
                    push!(foul_transgressor, "No data")
                    push!(foul_transgressor, "No data")
                    break
                end

                penalty_offset_penalty_offset_penalty_enforced_caprevname = 
                Regex("$penalties_regex_txt $team1 ($penalty1) off-setting, $penalties_regex_txt $team2 ($penalty2) off-setting, (?:NO PLAY, )?$penalties_regex_txt $team3 ($penalty3) \\($name_caplastfirst_penalty_regex\\)")
                #PENALTY WMU offside defense off-setting, PENALTY NCCU personal foul off-setting, NO PLAY, PENALTY WMU personal foul (SPILLANE, R) 14 yards to the NCCU49, 1ST DOWN NCCU, NO PLAY.
                m = match(penalty_offset_penalty_offset_penalty_enforced_caprevname, txt)
                if !isnothing(m)
                    push!(foul_type, m[2])
                    push!(foul_type, m[4])
                    push!(foul_type, m[6])
                    push!(foul_status, "off-setting")
                    push!(foul_status, "off-setting")
                    push!(foul_status, "enforced")
                    push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_team, get_team_name(m[3], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_team, get_team_name(m[5], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_transgressor, "No data")
                    push!(foul_transgressor, "No data")
                    push!(foul_transgressor, process_name(m[7]))
                    # last_name, first_name = strip.(split(m[7], ","))
                    # push!(foul_transgressor, titlecase(first_name)*" "*titlecase(last_name))
                    break
                end

                penalty_offset_penalty_offset_penalty_enforced = 
                Regex("$penalties_regex_txt $team1 ($penalty1) off-setting, $penalties_regex_txt $team2 ($penalty2) off-setting, (?:NO PLAY, )?$penalties_regex_txt $team3 ($penalty3)")
                m = match(penalty_offset_penalty_offset_penalty_enforced, txt)
                if !isnothing(m)
                    push!(foul_type, m[2])
                    push!(foul_type, m[4])
                    push!(foul_type, m[6])
                    push!(foul_status, "off-setting")
                    push!(foul_status, "off-setting")
                    push!(foul_status, "enforced")
                    push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_team, get_team_name(m[3], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_team, get_team_name(m[5], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_transgressor, "No data")
                    push!(foul_transgressor, "No data")
                    push!(foul_transgressor, "No data")
                    break
                end

                penalty_enforced_penalty_offset_penalty_offset = 
                Regex("$penalties_regex_txt $team1 ($penalty1) \\d+ [Yy]ards .+, (?:NO PLAY, )?$penalties_regex_txt $team2 ($penalty2) off-setting, $penalties_regex_txt $team3 ($penalty3) off-setting")
                #PENALTY ULM offside 5 yards to the ULM24, NO PLAY, PENALTY USA unsportsmanlike conduct off-setting, PENALTY ULM unsportsmanlike conduct off-setting, NO PLAY.
                m = match(penalty_enforced_penalty_offset_penalty_offset, txt)
                if !isnothing(m)
                    push!(foul_type, m[2])
                    push!(foul_type, m[4])
                    push!(foul_type, m[6])
                    push!(foul_status, "enforced")
                    push!(foul_status, "off-setting")
                    push!(foul_status, "off-setting")
                    push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_team, get_team_name(m[3], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_team, get_team_name(m[5], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_transgressor, "No data")
                    push!(foul_transgressor, "No data")
                    push!(foul_transgressor, "No data")
                    break
                end
                penalty_team_offset_penalty_team_offset_team_penalty_yards_declined = 
                Regex("$penalties_regex_txt $team1 ($penalty1) off-setting, $penalties_regex_txt $team2 ($penalty2) off-setting, NO PLAY. $team3 $penalties_regex_txt,? ($penalty3) \\( Yards\\) declined")
                #PENALTY UT unsportsmanlike conduct off-setting, PENALTY UK unsportsmanlike conduct off-setting, NO PLAY. KENTUCKY Penalty, offside defense ( Yards) declined (Brent Cimaglia KICK)
                m = match(penalty_team_offset_penalty_team_offset_team_penalty_yards_declined, txt)
                if !isnothing(m)
                    push!(foul_type, m[2])
                    push!(foul_type, m[4])
                    push!(foul_type, m[6])
                    push!(foul_status, "off-setting")
                    push!(foul_status, "off-setting")
                    push!(foul_status, "declined")                    
                    push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_team, get_team_name(m[3], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_team, get_team_name(m[5], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_transgressor, "No data")
                    push!(foul_transgressor, "No data")
                    push!(foul_transgressor, "No data")
                    break
                end
                penalty_team_declined_penalty_team_offset_penalty_team_offset = 
                Regex("$penalties_regex_txt $team1 ($penalty1) declined,? $penalties_regex_txt $team2 ($penalty2) off-setting,? $penalties_regex_txt $team3 ($penalty3) off-setting")
                #PENALTY MAR illegal block declined, PENALTY MAR illegal use of hands off-setting, PENALTY WKU illegal use of hands off-setting, NO PLAY.
                m = match(penalty_team_declined_penalty_team_offset_penalty_team_offset, txt)
                if !isnothing(m)
                    push!(foul_type, m[2])
                    push!(foul_type, m[4])
                    push!(foul_type, m[6])
                    push!(foul_status, "declined")
                    push!(foul_status, "off-setting")
                    push!(foul_status, "off-setting")
                    push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_team, get_team_name(m[3], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_team, get_team_name(m[5], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_transgressor, "No data")
                    push!(foul_transgressor, "No data")
                    push!(foul_transgressor, "No data")
                    break
                end
            end
            if DEBUG_PENALTY println(m) end
        elseif occursin(double_penalty_regex, txt)
            if DEBUG_PENALTY println("  trying: double_penalty_regex") end
            
            for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
                if DEBUG_PENALTY println("    trying: penalty_offset_penalty_offset") end
                penalty_offset_penalty_offset = 
                Regex("$penalties_regex_txt $team1 ($penalty1) off-setting, $penalties_regex_txt $team2 ($penalty2) off-setting")
                #PENALTY AKRON unsportsmanlike conduct off-setting, PENALTY UP unsportsmanlike conduct off-setting, NO PLAY.
                m = match(penalty_offset_penalty_offset, txt)
                if !isnothing(m)
                    push!(foul_type, m[2])
                    push!(foul_type, m[4])
                    push!(foul_status, "off-setting")
                    push!(foul_status, "off-setting")
                    push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_team, get_team_name(m[3], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_transgressor, "No data")
                    push!(foul_transgressor, "No data")
                    break
                end
                if DEBUG_PENALTY println("    trying: penalty_offset_penalty_revname_offset") end
                penalty_offset_penalty_revname_offset = 
                Regex("$penalties_regex_txt $team1 ($penalty1) off-setting, $penalties_regex_txt $team2 ($penalty2) \\($name_lastfirst_penalty_regex\\) +off-setting")
                #PENALTY SANDIEGOST ineligible downfield on kick off-setting, PENALTY CENTMICH Personal Foul, Targeting (Reid, Willie)  off-setting, NO PLAY. Reid ejected.
                m = match(penalty_offset_penalty_revname_offset, txt)
                if !isnothing(m)
                    push!(foul_type, m[2])
                    push!(foul_type, m[4])
                    push!(foul_status, "off-setting")
                    push!(foul_status, "off-setting")
                    push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_team, get_team_name(m[3], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_transgressor, "No data")
                    push!(foul_transgressor, process_name(m[5]))
                    break
                end
                if DEBUG_PENALTY println("    trying: penalty_revname_offset_penalty_revname_offset") end
                penalty_revname_offset_penalty_revname_offset = 
                Regex("$penalties_regex_txt $team1 ($penalty1) \\($name_lastfirst_penalty_regex\\) +off-setting, $penalties_regex_txt $team2 ($penalty2) \\($name_lastfirst_penalty_regex\\) +off-setting")
                ##PENALTY AKRON unsportsmanlike conduct off-setting, PENALTY UP unsportsmanlike conduct off-setting, NO PLAY.
                m = match(penalty_revname_offset_penalty_revname_offset, txt)
                if !isnothing(m)
                    push!(foul_type, m[2])
                    push!(foul_type, m[5])
                    push!(foul_status, "off-setting")
                    push!(foul_status, "off-setting")
                    push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_team, get_team_name(m[4], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_transgressor, process_name(m[3]))
                    push!(foul_transgressor, process_name(m[6]))
                    break
                end
                if DEBUG_PENALTY println("    trying: penalty_offset_penalty_revname_misctext_offset") end
                penalty_offset_penalty_revname_misctext_offset = 
                Regex("$penalties_regex_txt $team1 ($penalty1) +off-setting, $penalties_regex_txt $team2 ($penalty2) \\($name_lastfirst_penalty_regex [a-z ]+\\) +off-setting")
                ##PENALTY AKRON unsportsmanlike conduct off-setting, PENALTY UP unsportsmanlike conduct off-setting, NO PLAY.
                m = match(penalty_offset_penalty_revname_misctext_offset, txt)
                if !isnothing(m)
                    push!(foul_type, m[2])
                    push!(foul_type, m[4])
                    push!(foul_status, "off-setting")
                    push!(foul_status, "off-setting")
                    push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_team, get_team_name(m[3], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_transgressor, "No data")
                    push!(foul_transgressor, process_name(m[5]))
                    break
                end
                if DEBUG_PENALTY println("    trying: penalty_revname_offset_penalty_offset") end
                penalty_revname_offset_penalty_offset = 
                Regex("$penalties_regex_txt $team1 ($penalty1) \\($name_lastfirst_penalty_regex\\) +off-setting, $penalties_regex_txt $team2 ($penalty2) +off-setting")
                #PENALTY WASHST offside (Paulo, Darryl) off-setting, PENALTY MIAMIFL Illegal Block off-setting, NO PLAY.
                m = match(penalty_revname_offset_penalty_offset, txt)
                if !isnothing(m)
                    push!(foul_type, m[2])
                    push!(foul_type, m[5])
                    push!(foul_status, "off-setting")
                    push!(foul_status, "off-setting")
                    push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_team, get_team_name(m[4], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_transgressor, process_name(m[3]))
                    push!(foul_transgressor, "No data")
                    break
                end
            end
            if DEBUG_PENALTY println(m) end
        end
    elseif occursin(offsetting, txt)
        if DEBUG_PENALTY println("  Trying: offsetting") end
        if occursin(penalty_uns, txt)
            if DEBUG_PENALTY println("  trying: penalty_uns") end
            # for penalty1 in penalty_type_vec, penalty2 in penalty_type_vec, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
            for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
                
                # println("team1: $team1, team2: $team2, penalty1: $penalty1, penalty2: $penalty2")
                uns_regex = 
                Regex("$penalties_regex_txt $team1 UNS: ($penalty1) offsetting $team2 UNS: ($penalty2) offsetting")
                #PENALTY UVA UNS: Unsportsmanlike Conduct offsetting DUK UNS: Unsportsmanlike Conduct offsetting. NO PLAY.
                m = match(uns_regex, txt)
                if !isnothing(m)
                    push!(foul_type, m[2])
                    push!(foul_type, m[4])
                    push!(foul_status, "off-setting")
                    push!(foul_status, "off-setting")
                    push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_team, get_team_name(m[3], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_transgressor, "No data")
                    push!(foul_transgressor, "No data")
                    break
                end
            end
        end
        if occursin(penalty_on_penalty_on, txt)
            if DEBUG_PENALTY println("  trying: penalty_on_penalty_on") end
            # for penalty1 in penalty_type_vec, penalty2 in penalty_type_vec, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
            for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
                
                # println("team1: $team1, team2: $team2, penalty1: $penalty1, penalty2: $penalty2")
                on_singlename_on_singlename_regex = 
                Regex("$penalties_regex_txt $team1 ($penalty1) on $name_caplastfirst_penalty_regex $team2 ($penalty2) on $name_caplastfirst_penalty_regex")
                #PENALTY USA Unsportsmanlike Conduct on GRAY, Anterrious APP Unsportsmanlike Conduct on SPURLIN, Caleb , Offsetting penalties [NHSG]. NO PLAY (replay the down).
                m = match(on_singlename_on_singlename_regex, txt)
                if isnothing(m)
                    on_doublename_on_singlename_regex = 
                    Regex("$penalties_regex_txt $team1 ($penalty1) on $name_captwolastfirst_penalty_regex $team2 ($penalty2) on $name_caplastfirst_penalty_regex")
                    #PENALTY USA Unsportsmanlike Conduct on GRAY, Anterrious APP Unsportsmanlike Conduct on SPURLIN, Caleb , Offsetting penalties [NHSG]. NO PLAY (replay the down).
                    m = match(on_doublename_on_singlename_regex, txt)
                end
                if isnothing(m)
                    on_singlename_on_doublename_regex = 
                    Regex("$penalties_regex_txt $team1 ($penalty1) on $name_caplastfirst_penalty_regex $team2 ($penalty2) on $name_captwolastfirst_penalty_regex")
                    #PENALTY USA Unsportsmanlike Conduct on GRAY, Anterrious APP Unsportsmanlike Conduct on SPURLIN, Caleb , Offsetting penalties [NHSG]. NO PLAY (replay the down).
                    m = match(on_singlename_on_doublename_regex, txt)
                end
                if !isnothing(m)
                    push!(foul_type, m[2])
                    push!(foul_type, m[5])
                    push!(foul_status, "off-setting")
                    push!(foul_status, "off-setting")
                    push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_team, get_team_name(m[4], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_transgressor, process_name(m[3]))
                    push!(foul_transgressor, process_name(m[6]))
                    break
                end
                if isnothing(m)
                    on_number_singlenameperiod_on_number_singlenameperiod_regex = 
                    Regex("$penalties_regex_txt $team1 ($penalty1) on #\\d+ $name_period_penalty_regex $team2 ($penalty2) on #\\d+ $name_period_penalty_regex")
                    #PENALTY MIZ Holding on #31 D.Smith CMU Pass Interference on #25 D.McNary , Offsetting penalties [NHSG]. NO PLAY (replay the down).
                    m = match(on_number_singlenameperiod_on_number_singlenameperiod_regex, txt)
                end
                if !isnothing(m)
                    push!(foul_type, m[2])
                    push!(foul_type, m[5])
                    push!(foul_status, "off-setting")
                    push!(foul_status, "off-setting")
                    push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_team, get_team_name(m[4], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_transgressor, process_name(m[3]))
                    push!(foul_transgressor, process_name(m[6]))
                    break
                end
            end
        end
        if occursin(penalty_name_penalty, txt)
            if DEBUG_PENALTY println("  trying: penalty_name_penalty") end
            # for penalty1 in penalty_type_vec, penalty2 in penalty_type_vec, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
            for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
                
                # println("team1: $team1, team2: $team2, penalty1: $penalty1, penalty2: $penalty2")
                team_penalty_name_team_penalty_regex = 
                Regex("$team1 $penalties_regex_txt,? ($penalty1) \\( ?$name_regex ?\\),? $team2 $penalties_regex_txt,? ($penalty2),? offsetting")
                #NORTHWESTERN Penalty, Targeting ( Paddy Fisher ), KENTUCKY Penalty, Personal Foul, offsetting. Fisher ejected.
                m = match(team_penalty_name_team_penalty_regex, txt)
                if !isnothing(m)
                    push!(foul_type, m[2])
                    push!(foul_type, m[5])
                    push!(foul_status, "off-setting")
                    push!(foul_status, "off-setting")
                    push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_team, get_team_name(m[4], offense, off_abbrv_catch, defense, def_abbrv_catch))  
                    push!(foul_transgressor, m[3])
                    push!(foul_transgressor, "No data")
                    break
                end
            end
        end
        if occursin(penalty_name_penalty_name, txt)
            if DEBUG_PENALTY println("  trying: penalty_name_penalty_name") end
            # for penalty1 in penalty_type_vec, penalty2 in penalty_type_vec, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
            for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
                # println("team1: $team1, team2: $team2, penalty1: $penalty1, penalty2: $penalty2")
                team_penalty_name_team_penalty_name_regex = 
                Regex("$team1 $penalties_regex_txt,? ($penalty1) \\( ?$name_regex ?\\),? $team2 $penalties_regex_txt,? ($penalty2) \\( ?$name_regex ?\\)")
                #ALABAMA Penalty, Unnecessary Roughness (Cyrus Jones), FLORIDA Penalty, Unnecessary Roughness (Demarcus Robinson) offsetting.
                m = match(team_penalty_name_team_penalty_name_regex, txt)
                if !isnothing(m)
                    push!(foul_type, m[2])
                    push!(foul_type, m[5])
                    push!(foul_status, "off-setting")
                    push!(foul_status, "off-setting")
                    push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_team, get_team_name(m[4], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_transgressor, m[3])
                    push!(foul_transgressor, m[6])
                    break
                end
            end
        end
        if occursin(team_penalty_offsetting_team_penalty, txt)
            if DEBUG_PENALTY println("  trying: team_penalty_offsetting_team_penalty") end
            # for penalty1 in penalty_type_vec, penalty2 in penalty_type_vec, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
            for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
                # println("team1: $team1, team2: $team2, penalty1: $penalty1, penalty2: $penalty2")
                team_penalty_offsetting_team_penalty_regex = 
                Regex("$penalties_regex_txt,? $team1 ($penalty1) off-?setting,? $penalties_regex_txt,? $team2 ($penalty2)")
                #PENALTY WMU personal foul off-setting, PENALTY EMU personal foul 1 yards to the EMU37, NO PLAY.
                m = match(team_penalty_offsetting_team_penalty_regex, txt)
                if !isnothing(m)
                    push!(foul_type, m[2])
                    push!(foul_type, m[4])
                    push!(foul_status, "off-setting")
                    push!(foul_status, "off-setting")
                    push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_team, get_team_name(m[3], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_transgressor, "No data")
                    push!(foul_transgressor, "No data")
                    break
                end
            end
        end
        if occursin(team_penalty_team_penalty_offsetting, txt)
            if DEBUG_PENALTY println("  trying: team_penalty_team_penalty_offsetting") end
            # for penalty1 in penalty_type_vec, penalty2 in penalty_type_vec, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in sort([off_abbrv_catch, def_abbrv_catch], rev=true)           
            for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
                # println("team1: $team1, team2: $team2, penalty1: $penalty1, penalty2: $penalty2")
                # println("penalty1: $penalty1, penalty2: $penalty2")

                
                team_penalty_team_penalty_offsetting_regex = 
                Regex("$penalties_regex_txt(?: Before the snap,)? $team1 ($penalty1) $team2 ($penalty2) , Offsetting")
                #PENALTY LAT Pass Interference CLT Ineligible Receiver Downfield on Pass , Offsetting penalties [NHSG]. NO PLAY (replay the down).
                m = match(team_penalty_team_penalty_offsetting_regex, txt)
                if !isnothing(m)
                    push!(foul_type, m[2])
                    push!(foul_type, m[4])
                    push!(foul_status, "off-setting")
                    push!(foul_status, "off-setting")
                    push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_team, get_team_name(m[3], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_transgressor, "No data")
                    push!(foul_transgressor, "No data")
                    break
                end
            end
        end
        if m == "failed" #isnothing(m)
            if occursin(team_penalty_team_penalty_on, txt)
                if DEBUG_PENALTY println("  trying: team_penalty_team_penalty_on") end
                # for penalty1 in penalty_type_vec, penalty2 in penalty_type_vec, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in sort([off_abbrv_catch, def_abbrv_catch], rev=true)           
                for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
                    # println("team1: $team1, team2: $team2, penalty1: $penalty1, penalty2: $penalty2")
                    # println("penalty1: $penalty1, penalty2: $penalty2")
                    team_penalty_team_penalty_on_regex = 
                    Regex("$penalties_regex_txt(?: Before the snap,)? $team1 ($penalty1) $team2 ($penalty2) on(?: #\\d+)? $name_caplastfirst_penalty_regex")
                    #SUAREZ, Morgan kickoff 63 yards to the FIU2, JOSEPH, Lexington return 56 yards to the FAU42 (LEWIS, Joe). PENALTY FIU Holding FAU Offsides on JERRELS, Jarrett , Offsetting penalties. NO PLAY (replay the down).
                    m = match(team_penalty_team_penalty_on_regex, txt)
                    if !isnothing(m)
                        push!(foul_type, m[2])
                        push!(foul_type, m[4])
                        push!(foul_status, "off-setting")
                        push!(foul_status, "off-setting")
                        push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                        push!(foul_team, get_team_name(m[3], offense, off_abbrv_catch, defense, def_abbrv_catch))
                        push!(foul_transgressor, "No data")
                        push!(foul_transgressor, process_name(m[5]))
                        # last_name, first_name = strip.(split(m[5], ","))
                        # push!(foul_transgressor, titlecase(first_name)*" "*titlecase(last_name))
                        break
                    end
                    team_penalty_team_penalty_on_nameperiod_regex = 
                    Regex("$penalties_regex_txt(?: Before the snap,)? $team1 ($penalty1) $team2 ($penalty2) on(?: #\\d+)? $name_period_penalty_regex")
                    #SUAREZ, Morgan kickoff 63 yards to the FIU2, JOSEPH, Lexington return 56 yards to the FAU42 (LEWIS, Joe). PENALTY FIU Holding FAU Offsides on JERRELS, Jarrett , Offsetting penalties. NO PLAY (replay the down).
                    m = match(team_penalty_team_penalty_on_nameperiod_regex, txt)
                    if !isnothing(m)
                        push!(foul_type, m[2])
                        push!(foul_type, m[4])
                        push!(foul_status, "off-setting")
                        push!(foul_status, "off-setting")
                        push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                        push!(foul_team, get_team_name(m[3], offense, off_abbrv_catch, defense, def_abbrv_catch))
                        push!(foul_transgressor, "No data")
                        push!(foul_transgressor, process_name(m[5]))
                        # push!(foul_transgressor, replace(m[5], "." => " "))
                        break
                    end
                end
            end
        end
        if occursin(team_penalty_offsetting_triple, txt)
            if DEBUG_PENALTY println("  trying: team_penalty_offsetting_triple") end
            # for penalty1 in penalty_type_vec, penalty2 in penalty_type_vec, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in sort([off_abbrv_catch, def_abbrv_catch], rev=true)   
            team1 = ""
            team2 = ""
            team3 = ""
            for team_a in [off_abbrv_catch, def_abbrv_catch], team_b in [off_abbrv_catch, def_abbrv_catch], team_c in [off_abbrv_catch, def_abbrv_catch]
                
                triple_team_regex = Regex("$penalties_regex_txt $team_a .+ $team_b .+ $team_c")
                m = match(triple_team_regex, txt)
                if !isnothing(m)
                    team1 = team_a
                    team2 = team_b
                    team3 = team_c
                    break
                end
            end
            # println("team1: $team1, team2: $team2, team3: $team3")

            for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, penalty3 in penalty_list_occurred#, 
                # team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch], team3 in [off_abbrv_catch, def_abbrv_catch]
                # println("team1: $team1, team2: $team2, penalty1: $penalty1, penalty2: $penalty2")
                # println("penalty1: $penalty1, penalty2: $penalty2")
                
                team_penalty_offsetting_triple_regex = 
                Regex("$penalties_regex_txt $team1 ($penalty1) [Oo]ff-?setting $team2 ($penalty2) [Oo]ff-?setting $team3 ($penalty3) [Oo]ff-?setting")
                #PENALTY GSU Illegal Formation offsetting CCU Illegal Block in Back offsetting GSU Personal Foul offsetting. NO PLAY.
                m = match(team_penalty_offsetting_triple_regex, txt)
                if !isnothing(m)
                    push!(foul_type, m[2])
                    push!(foul_type, m[4])
                    push!(foul_type, m[6])
                    push!(foul_status, "off-setting")
                    push!(foul_status, "off-setting")
                    push!(foul_status, "off-setting")
                    push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_team, get_team_name(m[3], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_team, get_team_name(m[5], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_transgressor, "No data")
                    push!(foul_transgressor, "No data")
                    push!(foul_transgressor, "No data")
                    break
                end
            end
        end
        if m == "failed"
            if occursin(team_penalty_offsetting_team_penalty_offsetting, txt)
                if DEBUG_PENALTY println("  trying: team_penalty_offsetting_team_penalty_offsetting") end
                # for penalty1 in penalty_type_vec, penalty2 in penalty_type_vec, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in sort([off_abbrv_catch, def_abbrv_catch], rev=true)           
                for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
                    
                    team_penalty_offsetting_team_penalty_offsetting_regex = 
                    Regex("$penalties_regex_txt $team1 ($penalty1) [Oo]ff-?setting $team2 ($penalty2) [Oo]ff-?setting")
                    #PENALTY ASU Illegal Use Of Hands offsetting MEM Holding offsetting. NO PLAY.
                    m = match(team_penalty_offsetting_team_penalty_offsetting_regex, txt)
                    if !isnothing(m)
                        push!(foul_type, m[2])
                        push!(foul_type, m[4])
                        push!(foul_status, "off-setting")
                        push!(foul_status, "off-setting")
                        push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                        push!(foul_team, get_team_name(m[3], offense, off_abbrv_catch, defense, def_abbrv_catch))
                        push!(foul_transgressor, "No data")
                        push!(foul_transgressor, "No data")
                        break
                    end
                end
            end
        end
        if m == "failed"
            if occursin(team_penalty_offsetting, txt)
                if DEBUG_PENALTY println("  trying: team_penalty_offsetting") end
                for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
                    
                    team_penalty_offsetting_regex = 
                    Regex("$team $penalties_regex_txt,? ($penalty) [Oo]ff-?setting")
                    #SYRACUSE Penalty, UN off-setting ( Yards) to the Syrac 3
                    m = match(team_penalty_offsetting_regex, txt)
                    if !isnothing(m)
                        push!(foul_type, "Ambiguous")
                        push!(foul_type, "Ambiguous")
                        push!(foul_status, "off-setting")
                        push!(foul_status, "off-setting")
                        push!(foul_team, offense)
                        push!(foul_team, defense)
                        push!(foul_transgressor, "No data")
                        push!(foul_transgressor, "No data")
                        break
                    end
                end
            end
        end
        if m == "failed"
            if occursin(penalty_team_foul_offsetting_team_foul_offsetting, txt)
                if DEBUG_PENALTY println("  trying: team_penalty_offsetting") end
                for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
                    
                    team_penalty_offsetting_regex = 
                    Regex("$penalties_regex_txt,? $team1 ($penalty1) $offsetting $team2 ($penalty2) $offsetting")
                    # PENALTY ASU Illegal Use Of Hands offsetting MEM Holding offsetting. NO PLAY.
                    m = match(team_penalty_offsetting_regex, txt)
                    if !isnothing(m)
                        #   push!(foul_type, "Ambiguous")
                        #   push!(foul_type, "Ambiguous")
                        #   push!(foul_status, "off-setting")
                        #   push!(foul_status, "off-setting")
                        #   push!(foul_team, offense)
                        #   push!(foul_team, defense)
                        #   push!(foul_transgressor, "No data")
                        #   push!(foul_transgressor, "No data")
                        break
                    end
                end
            end
        end
        if m == "failed"
            if occursin(team_penalty_adjacent_offsetting, txt)
                if DEBUG_PENALTY println("  trying: team_penalty_adjacent_offsetting") end
                for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
                    
                    team_penalty_offsetting_regex = 
                    Regex("$penalties_regex_txt,? $team ($penalty) [Oo]ff-?setting")
                    #SYRACUSE Penalty, UN off-setting ( Yards) to the Syrac 3
                    m = match(team_penalty_offsetting_regex, txt)
                    if !isnothing(m)
                        push!(foul_type, "Ambiguous")
                        push!(foul_type, "Ambiguous")
                        push!(foul_status, "off-setting")
                        push!(foul_status, "off-setting")
                        push!(foul_team, offense)
                        push!(foul_team, defense)
                        push!(foul_transgressor, "No data")
                        push!(foul_transgressor, "No data")
                        break
                    end
                end
            end
        end
        if DEBUG_PENALTY println(m) end
    else
      println("Missed: offsetting_aux")
      @warn("Missed: offsetting_aux")
    end
    
    foul_type, foul_status, foul_team, foul_transgressor
end

############################################################################################################################################################
function enforced_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_type_vec)
    penalties_regex_txt = "(?:Penalty|PENALTY)"

    #I think this is a temp problem and won't occur when process_game calls it... maybe
    off_abbrv_catch = replace(off_abbrv_catch, "\xc9" => "É")
    def_abbrv_catch = replace(def_abbrv_catch, "\xe9" => "é")

    team_penalty_penalty_revcapname = r"[A-Z]+ (?:Penalty|PENALTY),? .+ (?:Penalty|PENALTY) .+ on "
    team_penalty_penalty_enforced = r"[A-Z]+ (?:Penalty|PENALTY),? .+ (?:Penalty|PENALTY) .+ enforced"
    penalty_team_spot_foul = r"(?:Penalty|PENALTY)(?: Before the snap,)? [A-Z]+ [A-Za-z ]+ enforced at the spot of the foul"
    penalty_team_half_distance = r"(?:Penalty|PENALTY)(?: Before the snap,)? [A-Z]+ [A-Za-z ]+ enforced half the distance from the goal"
    penalty_team_enforced_0yards = r"(?:Penalty|PENALTY)(?: Before the snap,)? [A-Z]+ [A-Za-z ]+ enforced 0 [Yy]ards"
    penalty_team_enforced_distance = r"(?:Penalty|PENALTY)(?: Before the snap,)? [A-Z]+ [A-Za-z ]+ enforced \d+"
    team_penalty_on_number = r"(?:Penalty|PENALTY)(?: Before the snap,)? [A-Z]+\.? [A-Za-z ]+ on #\d+"
    team_penalty_on_name = r"(?:Penalty|PENALTY)(?: Before the snap,)? [A-Z]+\.? [A-Za-z ]+ on "
    team_penalty_enforced_paraen_numberteam = r"[A-Z]+ (?:Penalty|PENALTY),? [A-Za-z ]+ enforced(?: at the deadball spot for)? \((?:-?\d+ [Yy]ards|TEAM)\)"
    team_penalty_enforced_name = Regex("[A-Z]+ (?:Penalty|PENALTY),? [A-Za-z ]+ enforced \\($name_regex")
    team_penalty_enforced_revcapname = Regex("[A-Z]+ (?:Penalty|PENALTY),? [A-Za-z ]+ $name_caplastfirst_penalty_regex enforced")
    team_penalty_revcapname_enforced = Regex("(?:Penalty|PENALTY) [A-Z]+ [A-Za-z\\- ]+ $name_caplastfirst_penalty_regex enforced")
    team_penalty_on_player = r"[A-Z]+ (?:Penalty|PENALTY),? [A-Za-z ]+ on [A-Z]+"

    
    m = "failed"

    
    penalty_list_occurred = Vector{String}()#[]
    for penalty in penalty_type_vec
        # if occursin(Regex("$penalties_regex_txt (?:$team1|$team2) ($penalty)"), txt)
        # if occursin(Regex("(?:$team1|$team2|$team3) $penalty"), txt)
        if occursin(Regex("$penalty"), txt)
            push!(penalty_list_occurred, penalty)
        end
    end
  # println("penalty_list_occurred: $penalty_list_occurred")

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]
    
    if occursin(team_penalty_penalty_revcapname, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_penalty_revcapname") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            
            team_penalty_penalty_revcapname_regex = 
            Regex("$team $penalties_regex_txt,? [\\w ,]+\\. $penalties_regex_txt ($penalty) on $name_caplastfirst_penalty_regex")
            #WYOMING Penalty, turnover on downs. PENALTY Pass Interference on COLDON, C.J. enforced at the spot of the foul for (4 Yards) to the Wyom 42 for a 1ST down
            m = match(team_penalty_penalty_revcapname_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, process_name(m[3]))
                # last_name, first_name = strip.(split(m[3], ","))
                # push!(foul_transgressor, titlecase(first_name)*" "*titlecase(last_name))
                break
            end
        end
    elseif occursin(team_penalty_penalty_enforced, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_penalty_enforced") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            
            team_penalty_penalty_enforced_regex = 
            Regex("$team $penalties_regex_txt,? [\\w ,]+\\. $penalties_regex_txt(?: Before the snap)? ($penalty) enforced")
            #GEORGIA ST Penalty, turnover on downs. PENALTY Offsides enforced (5 Yards) to the GeoSt 25
            m = match(team_penalty_penalty_enforced_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
        end
    elseif occursin(penalty_team_spot_foul, txt)
        if DEBUG_PENALTY println("  Trying: penalty_team_spot_foul") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            
            penalty_team_spot_foul_regex = 
            Regex("$penalties_regex_txt(?: Before the snap,)? $team ($penalty) enforced at the spot of the foul")
            #PENALTY WYO Pass Interference enforced at the spot of the foul for 15 yards to the WYO11 and results in automatic 1ST DOWN [NHSG]. NO PLAY (replay the down).
            m = match(penalty_team_spot_foul_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
            if isnothing(m)
                penalty_team_spot_foul_regex = 
                Regex("$penalties_regex_txt(?: Before the snap,)? $team ($penalty) on $name_penalty_regex enforced at the spot of the foul")
                #PENALTY FAU Pass Interference on Zyon Gilbert enforced at the spot of the foul for 14 yards to the CLT33 and results in automatic 1ST DOWN [NHSG]. NO PLAY (replay the down).
                m = match(penalty_team_spot_foul_regex, txt)
                if !isnothing(m)
                    push!(foul_type, m[2])
                    push!(foul_status, "enforced")
                    push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_transgressor, process_name(m[3]))
                    break
                end
            end
        end
    elseif occursin(penalty_team_half_distance, txt)
        if DEBUG_PENALTY println("  Trying: penalty_team_half_distance") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            
            penalty_team_half_distance_regex = 
            Regex("$penalties_regex_txt(?: Before the snap,)? $team ($penalty) enforced half the distance from the goal")
            #PENALTY MAS Illegal Wedge enforced half the distance from the goal, 11 yards from the MAS22 to the MAS11. NO PLAY (replay the down).
            m = match(penalty_team_half_distance_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
            if isnothing(m)
                penalty_team_name_half_distance_regex = 
                Regex("$penalties_regex_txt(?: Before the snap,)? $team ($penalty) on $name_penalty_regex enforced half the distance from the goal")
                #PENALTY FAU Holding on Zyon Gilbert enforced half the distance from the goal, 7 yards from the FAU14
                m = match(penalty_team_name_half_distance_regex, txt)
                if !isnothing(m)
                    push!(foul_type, m[2])
                    push!(foul_status, "enforced")
                    push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_transgressor, m[3])
                    break
                end
            end
        end
    elseif occursin(penalty_team_enforced_0yards, txt)
        if DEBUG_PENALTY println("  Trying: penalty_team_enforced_0yards") end
        for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
            

            penalty_team_enforced_0yards_regex = 
            Regex("$penalties_regex_txt(?: Before the snap,)? $team1 ($penalty1) enforced 0 yards $team2 ($penalty2) on $name_caplastfirst_penalty_regex enforced 0 yards")
            # PENALTY Before the snap, RUT Illegal Shift enforced 0 yards PSU Personal Foul on BROWN, Ji'Ayir enforced 0 yards from the RUT23 to the RUT23, from the the spot of the ball when the foul occurred, runner is credited with -5 yards on the play. NO PLAY (replay the down).
            m = match(penalty_team_enforced_0yards_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_type, m[4])
                push!(foul_status, "off-setting")
                push!(foul_status, "off-setting")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_team, get_team_name(m[3], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                push!(foul_transgressor, process_name(m[5]))
                # last_name, first_name = strip.(split(m[5], ","))
                # push!(foul_transgressor, titlecase(first_name)*" "*titlecase(last_name))
                break
            end
        end
    elseif occursin(penalty_team_enforced_distance, txt)
        if DEBUG_PENALTY println("  Trying: penalty_team_enforced_distance") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            
            penalty_team_enforced_distance_regex = 
            Regex("$penalties_regex_txt(?: Before the snap,)? $team ($penalty) enforced \\d+")
            # PENALTY Before the snap, MEM Illegal Formation enforced 5 yards from the NIC5 to the NIC10 [NHSG]. NO PLAY (replay the down).
            m = match(penalty_team_enforced_distance_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
            if isnothing(m)
                penalty_team_name_enforced_distance_regex = 
                Regex("$penalties_regex_txt(?: Before the snap,)? $team ($penalty) on $name_penalty_regex enforced \\d+")
                # PENALTY Before the snap, MEM Illegal Formation enforced 5 yards from the NIC5 to the NIC10 [NHSG]. NO PLAY (replay the down).
                m = match(penalty_team_name_enforced_distance_regex, txt)
                if !isnothing(m)
                    push!(foul_type, m[2])
                    push!(foul_status, "enforced")
                    push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_transgressor, m[3])
                    break
                end
            end
        end
    elseif occursin(team_penalty_on_number, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_on_number") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            
            team_penalty_on_number_regex = 
            Regex("$penalties_regex_txt(?: Before the snap,)? $team ($penalty) on(?: #\\d+)? $name_period_penalty_regex enforced")
            #PENALTY Before the snap, NSU Illegal Shift on #18 J.Griffin enforced 5 yards from the UNT38 to the UNT43 [NHSG]. NO PLAY (replay the down).
            #PENALTY CMU Pass Interference on #19 D.Kent enforced at the spot of the foul for 7 yards from the CMU25 to the CMU25 and results in automatic 1ST DOWN [NHSG]. NO PLAY (replay the down).
            m = match(team_penalty_on_number_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, replace(m[3], "." => " "))
                break
            end
        end
    elseif occursin(team_penalty_on_name, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_on_name") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            
            team_penalty_on_name_regex = 
            Regex("$penalties_regex_txt(?: Before the snap,)? $team ($penalty) on $name_caplastfirst_penalty_regex enforced (?:\\d+|half the distance from the goal|at the spot of the foul|at the deadball spot)")
            #PENALTY Before the snap, AFA Illegal Motion on SANFORD, Vince enforced 5 yards from the AWP29 to the AWP34. NO PLAY (replay the down).
            m = match(team_penalty_on_name_regex, txt)
            #Pretty sure below is a repeat of above but just commenting out until verified.
            # if isnothing(m)
            #     team_penalty_on_revname_regex = 
            #     Regex("$penalties_regex_txt(?: Before the snap,)? $team ($penalty) on $name_caplastfirst_penalty_regex enforced (?:\\d+|half the distance from the goal|at the spot of the foul|at the deadball spot)")
            #     #PENALTY CON Personal Foul on DIDIO, Mark enforced at the deadball spot for 15 yards after the change of possession
            #     m = match(team_penalty_on_revname_regex, txt)
            # end
            if isnothing(m)
                team_penalty_on_revname_regex = 
                Regex("$penalties_regex_txt(?: Before the snap,)? $team ($penalty) on $name_caplasttwofirst_penalty_regex enforced (?:\\d+|half the distance from the goal|at the spot of the foul|at the deadball spot)")
                #PENALTY CON Personal Foul on DIDIO, Mark enforced at the deadball spot for 15 yards after the change of possession
                m = match(team_penalty_on_revname_regex, txt)
            end
            if isnothing(m)
                team_penalty_on_revdoublelast_name_regex = 
                Regex("$penalties_regex_txt(?: Before the snap,)? $team ($penalty) on $name_captwolastfirst_penalty_regex enforced (?:\\d+|half the distance from the goal|at the spot of the foul|at the deadball spot)")
                #
                m = match(team_penalty_on_revdoublelast_name_regex, txt)
            end
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, process_name(m[3]))
                # last_name, first_name = strip.(split(m[3], ","))
                # push!(foul_transgressor, titlecase(first_name)*" "*titlecase(last_name))
                break
            end
        end
    elseif occursin(team_penalty_enforced_paraen_numberteam, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_enforced_paraen_numberteam") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            
            team_penalty_enforced_paraen_numberteam_regex = 
            Regex("$team $penalties_regex_txt(?: Before the snap)?,? ($penalty) enforced(?: at the deadball spot for)? \\((?:-?\\d+ [Yy]ards|TEAM)\\)")
            #APPALACHIAN ST Penalty, Block below the waist enforced (-15 Yards) to the Troy 49
            m = match(team_penalty_enforced_paraen_numberteam_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
        end
    elseif occursin(team_penalty_enforced_name, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_enforced_name") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            
            team_penalty_enforced_name_regex = 
            Regex("$team $penalties_regex_txt(?: Before the snap)?,? ($penalty) enforced \\($name_regex")
            #ARK PINE BLUFF Penalty, Illegal use of the hands enforced (Paul Reeves) to the ArkPB 32 for a 1ST down
            m = match(team_penalty_enforced_name_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, m[3])
                break
            end
        end
    elseif occursin(team_penalty_enforced_revcapname, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_enforced_revcapname") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            
            team_penalty_enforced_revcapname_regex = 
            Regex("$team $penalties_regex_txt(?: Before the snap)?,? ($penalty)(?: on)? $name_caplastfirst_penalty_regex enforced")
            #VANDERBILT Penalty, False Start DEMARK, Ryan enforced (5 Yards) to the UConn 46
            m = match(team_penalty_enforced_revcapname_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, process_name(m[3]))
                break
            end
            team_penalty_junk_enforced_revcapname_regex = 
            Regex("$team $penalties_regex_txt,? .+ ($penalty)(?: on)? $name_caplastfirst_penalty_regex enforced")
            #PITTSBURGH Penalty, the middle for a gain of Horse Collar Tackle on BALDONADO, Habakkuk enforced (Habakkuk Baldonado) to the Pitt 31 for a 1ST down
            m = match(team_penalty_junk_enforced_revcapname_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, process_name(m[3]))
                break
            end
        end        
    elseif occursin(team_penalty_revcapname_enforced, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_revcapname_enforced") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            
            team_penalty_revcapname_enforced_regex = 
            Regex("$penalties_regex_txt $team(?: Before the snap)?,? ($penalty)(?: on)? $name_caplastfirst_penalty_regex enforced")
            #YOUNG, Bryce pass to the left complete for 12 yards to BROOKS, Ja'Corey caught at the ALA47 and advanced to the ALA47 (BATTLE, Miles), out of bounds. PENALTY ALA Illegal Touch-Pass on BROOKS, Ja'Corey enforced 0 yards from the ALA35 to the ALA35, penalty results in a loss of down [NHSG]. NO PLAY (replay the down).
            m = match(team_penalty_revcapname_enforced_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, process_name(m[3]))
                break
            end
        end    
    elseif occursin(team_penalty_on_player, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_on_player") end
        for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            

            if length(penalty_list_occurred) == 1
                team_penalty_on_player_regex = 
                Regex("$team $penalties_regex_txt(?: Before the snap)?,? ($penalty2) on (?:$name_caplast_postfix_first_penalty_regex|$name_period_penalty_regex) enforced")
                #ILLINOIS Penalty, Roughing the Passer on CARNEY, JR., Owen enforced half the distance from the goal (Owen Carney Jr.) to the Illin 8 for a 1ST down
                m = match(team_penalty_on_player_regex, txt)
                if !isnothing(m)
                    push!(foul_type, m[2])
                    push!(foul_status, "enforced")
                    push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    if isnothing(m[4])
                        push!(foul_transgressor, process_name(m[3]))
                        # last_name, postfix, first_name = strip.(split(m[3], ","))
                        # push!(foul_transgressor, titlecase(first_name)*" "*titlecase(last_name)*" "*postfix)
                    elseif isnothing(m[3])
                        push!(foul_transgressor, process_name(m[4]))
                        # push!(foul_transgressor, replace(m[4], "." => " "))
                    end
                    break
                end
            elseif length(penalty_list_occurred) == 2
                team_penalty_on_player_regex = 
                Regex("$team $penalties_regex_txt(?: Before the snap)?,? ($penalty1) ($penalty2) on (?:$name_caplast_postfix_first_penalty_regex|$name_period_penalty_regex) enforced")
                #MASSACHUSETTS Penalty, Offsides Roughing the Passer on G.Johnson enforced (Uchenna Ezewike) to the Pitt 45 for a 1ST down
                m = match(team_penalty_on_player_regex, txt)
                if !isnothing(m)
                    push!(foul_type, m[3])
                    push!(foul_type, m[2])
                    push!(foul_status, "enforced")
                    push!(foul_status, "declined")
                    push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_team, foul_team[1])
                    push!(foul_transgressor, process_name(m[5]))
                    # push!(foul_transgressor, replace(m[5], "." => " "))
                    push!(foul_transgressor, "No data")
                    break
                end
            end
        end
    else
      println("Missed: enforced_aux")
      @warn("Missed: enforced_aux")
    end
    if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

#BEGIN rest_aux section
function penalty_penalty_case_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    penalties_regex_txt = "(?:Penalty|PENALTY)"

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    m = "failed"

    #penalty_penalty_case
    penalty_triple_enforce_revname_revname_noname = Regex("(?:Penalty|PENALTY).+\\($name_lastfirst_penalty_regex\\).+(?:Penalty|PENALTY).+\\($name_lastfirst_penalty_regex\\).+(?:Penalty|PENALTY)[\\w ]+ \\d+ yards")
    penalty_triple_enforce_noname_noname_noname = Regex("(?:Penalty|PENALTY).+ \\d+ yards .+(?:Penalty|PENALTY).+ \\d+ yards .+(?:Penalty|PENALTY)[\\w ]+ \\d+ yards")
    # team_penalty_number_team_penalty_number = r"[A-Z]+ (?:Penalty|PENALTY),? (?:[A-Z]?[a-z]+ )+\((?:-?\d+)? [Yy]ards\) to.* [A-Z]+ (?:Penalty|PENALTY),? (?:[A-Z]?[a-z]+ )+\((?:-?\d+)? [Yy]ards\)"
    team_penalty_number_team_penalty_number = 
        r"(?:[A-Z]+|[A-Z]+[a-z]+) (?:Penalty|PENALTY),? (?:[A-Z]?[a-z]+ )+\((?:-?\d+)? [Yy]ards\) to.* (?:[A-Z]+|[A-Z]+[a-z]+) (?:Penalty|PENALTY),? (?:[A-Z]?[a-z]+ )+\((?:-?\d+)? [Yy]ards\)"
    team_penalty_name_team_penalty_name = r"[A-Z]+ (?:Penalty|PENALTY),? (?:[A-Z][a-z]+ )+\((?:[A-Z][a-z]+ ?)+\).+[A-Z]+ (?:Penalty|PENALTY),? (?:[A-Z][a-z]+ )+\((?:[A-Z][a-z-]+ ?)+\)"
    team_penalty_name_team_penalty_number = r"[A-Z]+ (?:Penalty|PENALTY),? (?:[A-Z]?[a-z]+ )+\((?:[A-Z][a-z]+ ?)+\).+[A-Z]+ (?:Penalty|PENALTY),? (?:[A-Z]?[a-z]+ )+\(-?\d+ [Yy]ards\)"
    team_peanlty_number_penalty_team_revcapname = Regex("[A-Z]+ (?:Penalty|PENALTY),?.+ \\(-?\\d+ [Yy]ards\\).+ (?:Penalty|PENALTY),? [A-Z]+.+\\($name_caplastfirst_penalty_regex\\)")
    team_peanlty_number_penalty_team_name = Regex("[A-Z]+ (?:Penalty|PENALTY),?.+ \\(-?\\d+ [Yy]ards\\).+ (?:Penalty|PENALTY),? [A-Z]+.+\\($name_regex\\)")
    team_penalty_number_penalty_team_number = Regex("[A-Z]+ (?:Penalty|PENALTY),?.+ \\(-?\\d+ [Yy]ards\\).+ (?:Penalty|PENALTY),? [A-Z]+.+(?:\\(-?\\d+ [Yy]ards\\)|-?\\d+ [Yy]ards)")
    team_penalty_endofplay_name = Regex("[A-Z]+ (?:Penalty|PENALTY),?.+ End Of Play (?:Penalty|PENALTY),?(?: UNS:)? (?:[A-Z]?[a-z]+ ?)+\\.? \\($name_regex\\)")
    team_penalty_junk_number = r"[A-Z]+ (?:Penalty|PENALTY),?.+(?:Penalty|PENALTY),? [A-Z]+ (?:\(-?\d+ [Yy]ards\)|\( [Yy]ards\))"
    team_penalty_name_penalty_team_revcapname = Regex("[A-Z]+ (?:Penalty|PENALTY),?.+ \\($name_regex\\).+(?:Penalty|PENALTY),? [A-Z]+ .+\\($name_caplastfirst_penalty_regex\\)")
    team_penalty_ballon_penalty_number = r"[A-Z]+ (?:Penalty|PENALTY),? ball on .+ (?:Penalty|PENALTY),? .+ \(-?\d+ [Yy]ards\)"
    team_penalty_ballon_penalty_name = Regex("[A-Z]+ (?:Penalty|PENALTY),? ball on .+ (?:Penalty|PENALTY),? .+ \\($name_regex\\)")
    team_penalty_penalty_name = Regex("[A-Z]+ (?:Penalty|PENALTY),? (?:[A-Z][a-z-]+ ?)* (?:Penalty|PENALTY),? \\($name_regex\\)")
    penalty_team_team_penalty_number = r"(?:Penalty|PENALTY),? [A-Z]+.* (?:Penalty|PENALTY),? .+\(-?\d+ [Yy]ards\)"
    penalty_team_noname_peanlty_team_revname = Regex("(?:Penalty|PENALTY),? [A-Z-]+ (?:[A-Z]?[a-z]+ )+\\d+ yards.+(?:Penalty|PENALTY),? [A-Z-]+ (?:[A-Z]?[a-z]+ )+\\($name_lastfirst_penalty_regex\\)")
    penalty_team_number_penalty_team_number = r"(?:Penalty|PENALTY),? [A-Z-]+ (?:[A-Z]?[a-z]+ )+\d+ yards to.+(?:Penalty|PENALTY),? [A-Z-]+ (?:[A-Z]?[a-z]+ )+\d+ yards to"
    penalty_team_revcapname_penalty_team_number = Regex("(?:Penalty|PENALTY),? [A-Z-]+ (?:[A-Z]?[a-z]+ )+\\($name_caplastfirst_penalty_regex\\).+(?:Penalty|PENALTY),? [A-Z-]+ (?:[A-Z]?[a-z]+ )+\\d+ yards to")
    penalty_team_revcapname_penalty_team_revcapname = 
        Regex("(?:Penalty|PENALTY),? [A-Z-]+ (?:[A-Z]?[a-z]+ )+\\($name_caplastfirst_penalty_regex\\).+(?:Penalty|PENALTY),? [A-Z-]+ (?:[A-Z]?[a-z]+ )+\\($name_caplastfirst_penalty_regex\\)")
    penalty_team_revname_penalty_team_revname = 
        Regex("(?:Penalty|PENALTY),? [A-Z-]+ (?:(?:[A-Z]+ )|(?:[A-Z]?[a-z]+ )+)\\($name_lastfirst_penalty_regex\\).+(?:Penalty|PENALTY),? [A-Z-]+ (?:[A-Z]?[a-z]+ )+\\($name_lastfirst_penalty_regex\\)")
    penalty_team_revname_penalty_team_number = Regex("(?:Penalty|PENALTY),? [A-Z-]+ (?:[A-Z]?[a-z]+ )+\\($name_lastfirst_penalty_regex\\).+(?:Penalty|PENALTY),? [A-Z-]+ (?:(?:[A-Z]+ )|(?:[A-Z]?[a-z]+ )+)\\d+ yards to")
    penalty_team_number_penalty_team_revname = Regex("(?:Penalty|PENALTY),? [A-Z-]+ (?:[A-Z]?[a-z]+ )+(?:\\(#\\) )?\\d+ yards to.+(?:Penalty|PENALTY),? [A-Z-]+ (?:[A-Z]?[a-z]+ )+\\($name_lastfirst_penalty_regex\\)")

    if DEBUG_PENALTY println("Case: penalty_penalty_case") end
    if occursin(penalty_triple_enforce_revname_revname_noname, txt)
        if DEBUG_PENALTY println("  Trying: penalty_triple_enforce_revname_revname_noname") end

        team1 = ""
        team2 = ""
        team3 = ""
        for team_a in [off_abbrv_catch, def_abbrv_catch], team_b in [off_abbrv_catch, def_abbrv_catch], team_c in [off_abbrv_catch, def_abbrv_catch]
            
            triple_team_regex = Regex("$penalties_regex_txt $team_a .+ $penalties_regex_txt $team_b .+, $penalties_regex_txt $team_c")
            m = match(triple_team_regex, txt)
            if !isnothing(m)
                team1 = team_a
                team2 = team_b
                team3 = team_c
                break
            end
        end
        
        for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, penalty3 in penalty_list_occurred
            
            penalty_triple_enforce_revname_revname_noname_regex = 
            Regex("$penalties_regex_txt,? $team1 ($penalty1) \\($name_lastfirst_penalty_regex\\).+$penalties_regex_txt,? $team2 ($penalty2) \\($name_lastfirst_penalty_regex\\).+$penalties_regex_txt,? $team2 ($penalty2) \\d")
            #PENALTY USA ineligible downfield on pass (Thompson, Nick) 5 yards to the ASU43, NO PLAY, PENALTY USA unsportsmanlike conduct (Tolbert, Jalen) 15 yards to the USA42, NO PLAY, PENALTY USA unsportsmanlike conduct 16 yards to the USA26, NO PLAY.
            m = match(penalty_triple_enforce_revname_revname_noname_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_type, m[5])
                push!(foul_type, m[8])
                push!(foul_status, "enforced")
                push!(foul_status, "enforced")
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_team, get_team_name(m[4], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_team, get_team_name(m[7], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, process_name(m[3]))
                push!(foul_transgressor, process_name(m[6]))
                push!(foul_transgressor, "No data")
                break
            end
        end
    end
    if isnothing(m) && occursin(penalty_triple_enforce_noname_noname_noname, txt)
        if DEBUG_PENALTY println("  Trying: penalty_triple_enforce_noname_noname_noname") end

        team1 = ""
        team2 = ""
        team3 = ""
        for team_a in [off_abbrv_catch, def_abbrv_catch], team_b in [off_abbrv_catch, def_abbrv_catch], team_c in [off_abbrv_catch, def_abbrv_catch]
            
            triple_team_regex = Regex("$penalties_regex_txt $team_a .+ $penalties_regex_txt $team_b .+, $penalties_regex_txt $team_c")
            m = match(triple_team_regex, txt)
            if !isnothing(m)
                team1 = team_a
                team2 = team_b
                team3 = team_c
                break
            end
        end
        
        for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, penalty3 in penalty_list_occurred
            
            penalty_triple_enforce_noname_noname_noname_regex = 
            Regex("$penalties_regex_txt,? $team1 ($penalty1) \\d+ yards .+$penalties_regex_txt,? $team2 ($penalty2) \\d+ yards .+$penalties_regex_txt,? $team2 ($penalty2) \\d")
            #PENALTY MIAMI pass interference 15 yards to the OHIO46, 1ST DOWN OHIO, NO PLAY, PENALTY MIAMI unsportsmanlike conduct 15 yards to the MIAMI39, 1ST DOWN OHIO, NO PLAY, PENALTY MIAMI unsportsmanlike conduct 15 yards to the MIAMI24, 1ST DOWN OHIO, NO PLAY.
            m = match(penalty_triple_enforce_noname_noname_noname_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_type, m[4])
                push!(foul_type, m[6])
                push!(foul_status, "enforced")
                push!(foul_status, "enforced")
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_team, get_team_name(m[3], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_team, get_team_name(m[5], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                push!(foul_transgressor, "No data")
                push!(foul_transgressor, "No data")
                break
            end
        end
    end
    if isnothing(m) && occursin(team_penalty_number_team_penalty_number, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_number_team_penalty_number") end
        for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
                        
            # team_penalty_number_team_penalty_number_regex = 
            # Regex("$team1 $penalties_regex_txt,? ($penalty1) \\(-?\\d+ Yards\\).+ $team2 $penalties_regex_txt,? ($penalty2) \\(-?\\d+ Yards\\)")
            team_penalty_number_team_penalty_number_regex = 
            Regex("$team1 $penalties_regex_txt,? ($penalty1) \\((?:-?\\d+)? [Yy]ards\\).+ $team2 $penalties_regex_txt,? ($penalty2) \\((?:-?\\d+)? [Yy]ards\\)")
            #BAYLOR Penalty, Offensive Holding (-10 Yards) to the Bayl 12, WEST VIRGINIA Penalty, Personal Foul (-15 Yards) to the Bayl 27.
            #AIR FORCE Penalty, Defensive offside ( Yards) to the AFA 3 UNLV Penalty, false start (-5 Yards) to the AFA 8 (Evan Pantels KICK)
            m = match(team_penalty_number_team_penalty_number_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_type, m[4])
                push!(foul_status, "enforced")
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_team, get_team_name(m[3], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                push!(foul_transgressor, "No data")
                break
            end
        end
    end
    if isnothing(m) && occursin(team_penalty_name_team_penalty_name, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_name_team_penalty_name") end
        for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
                        
            team_penalty_name_team_penalty_name_regex = 
            Regex("$team1 $penalties_regex_txt,? ($penalty1) \\($name_regex\\).+ $team2 $penalties_regex_txt,? ($penalty2) \\($name_regex\\)")
            #OREGON Penalty, False Start (Alex Forsyth) to the Cal 8 OREGON Penalty, Personal Foul (Malaesala Aumavae-Laulu) to the Cal 23 (Henry Katleman KICK)
            m = match(team_penalty_name_team_penalty_name_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_type, m[5])
                push!(foul_status, "enforced")
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_team, get_team_name(m[4], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, m[3])
                push!(foul_transgressor, m[6])
                break
            end
        end
    end
    if isnothing(m) && occursin(team_penalty_name_team_penalty_number, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_name_team_penalty_number") end
        for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
                        
            team_penalty_name_team_penalty_number_regex = 
            Regex("$team1 $penalties_regex_txt,? ($penalty1) \\($name_regex\\).+ $team2 $penalties_regex_txt,? ($penalty2) \\(-?\\d+ [Yy]ards\\)")
            #RICE Penalty, roughing passer (Blaze Alldredge) to the Rice 0 UTEP Penalty, false start (-5 Yards) to the Rice 6 (Gavin Baechle KICK)
            m = match(team_penalty_name_team_penalty_number_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_type, m[5])
                push!(foul_status, "enforced")
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_team, get_team_name(m[4], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, m[3])
                push!(foul_transgressor, "No data")
                break
            end
        end
    end
    if isnothing(m) && occursin(team_peanlty_number_penalty_team_revcapname, txt)
        if DEBUG_PENALTY println("  Trying: team_peanlty_number_penalty_team_revcapname") end
        for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
            
            team_peanlty_number_penalty_team_revcapname_regex = 
            Regex("$team1 $penalties_regex_txt,? ($penalty1) \\(-?\\d+ [Yy]ards\\).+ $penalties_regex_txt,? $team2 ($penalty2) \\($name_caplastfirst_penalty_regex\\)")
            #NAVY Penalty, delay of game (-5 Yards) to the SMU 8 GOSLIN, Tyger pass attempt failed, PENALTY SMU pass interference (PHILLIPS JR.,J) 6 yards to the SMU2, NO PLAY. (Two-Point Conversion failed)
            m = match(team_peanlty_number_penalty_team_revcapname_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_type, m[4])
                push!(foul_status, "enforced")
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_team, get_team_name(m[3], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                push!(foul_transgressor, process_name(m[5]))
                break
            end
        end
    end
    if isnothing(m) && occursin(team_peanlty_number_penalty_team_name, txt)
        if DEBUG_PENALTY println("  Trying: team_peanlty_number_penalty_team_name") end
        for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
                        
            team_peanlty_number_penalty_team_name_regex = 
            Regex("$team1 $penalties_regex_txt,? ($penalty1) \\(-?\\d+ [Yy]ards\\).+ $penalties_regex_txt,? $team2 ($penalty2) \\($name_regex\\)")
            #ABIL CHRISTIAN Penalty, unsportsmanlike conduct (-15 Yards) to the Virg 18 Hernandez, Oscar kick attempt failed (blocked), PENALTY VA offside (Elijah Gaines) 5 yards to the VA13, NO PLAY. (Brock Thompson PAT MISSED)
            m = match(team_peanlty_number_penalty_team_name_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_type, m[4])
                push!(foul_status, "enforced")
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_team, get_team_name(m[3], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                push!(foul_transgressor, process_name(m[5]))
                break
            end
        end
    end
    if isnothing(m) && occursin(team_penalty_number_penalty_team_number, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_number_penalty_team_number") end
        for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
                        
            team_penalty_number_penalty_team_number_regex = 
            Regex("$team1 $penalties_regex_txt,? ($penalty1) \\(-?\\d+ [Yy]ards\\).+ $penalties_regex_txt,? $team2 ($penalty2) (?:\\(-?\\d+ [Yy]ards\\)|-?\\d+ [Yy]ards)")
            #FORDHAM Penalty, illegal block (10 Yards) to the Fordh 20 Brewer, Cale kickoff 54 yards to the FOR11, Williams, Ian return 59 yards to the ARMY30 (Washle, Scott;McBryde, Sean), PENALTY FOR illegal block 10 yards to the ARMY20, 1st and 10, FOR ball on FOR20.
            m = match(team_penalty_number_penalty_team_number_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_type, m[4])
                push!(foul_status, "enforced")
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_team, get_team_name(m[3], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                push!(foul_transgressor, "No data")
                break
            end
        end
    end
    if isnothing(m) && occursin(team_penalty_endofplay_name, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_endofplay_name") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
                        
            team_penalty_endofplay_name_regex = 
            Regex("$team $penalties_regex_txt,?.+ End Of Play $penalties_regex_txt,?(?: UNS:)? ($penalty)\\.? \\($name_regex\\)")
            #WESTRN ILLINOIS Penalty, Lawson,Michael at BSU35, End Of Play PENALTY UNS: Unsportsmanlike Conduct (Jalen Powe) to the BalSt 35
            #TEMPLE Penalty, at TLS47, End Of Play PENALTY Personal Foul. (Randle Jones) to the Tulsa 47
            m = match(team_penalty_endofplay_name_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, m[3])
                break
            end
        end
    end
    if isnothing(m) && occursin(team_penalty_junk_number, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_junk_number") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            
            team_penalty_junk_number_regex = 
            Regex("$team $penalties_regex_txt,?.+ $penalties_regex_txt ($penalty) (?:\\(-?\\d+ [Yy]ards\\)|\\( [Yy]ards\\))")
            #UTAH Penalty, ball on UTAH44, PENALTY OB (-5 Yards) to the Utah 39
            m = match(team_penalty_junk_number_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
        end
    end
    if isnothing(m) && ccursin(team_penalty_name_penalty_team_revcapname, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_name_penalty_team_revcapname") end
        for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
            
            team_penalty_name_penalty_team_revcapname_regex = 
            Regex("$team1 $penalties_regex_txt,? ($penalty1) \\($name_regex\\).+ $penalties_regex_txt $team2 ($penalty2) \\($name_caplastfirst_penalty_regex\\)")
            #UT SAN ANTONIO Penalty, false start (Jarrod Carter-McLin) to the NoTex 8 SACKETT, Jared kick attempt good, PENALTY UTSA holding (FUENTES, Robert) 10 yards to the UNT18, NO PLAY. (Jared Sackett KICK)
            m = match(team_penalty_name_penalty_team_revcapname_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_type, m[5])
                push!(foul_status, "enforced")
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_team, get_team_name(m[4], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, m[3])
                push!(foul_transgressor, process_name(m[6]))
                break
            end
        end
    end
    if isnothing(m) && occursin(team_penalty_ballon_penalty_number, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_ballon_penalty_number") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            
            team_penalty_ballon_penalty_number_regex = 
            Regex("$team $penalties_regex_txt,?.+ $penalties_regex_txt ($penalty) \\(-?\\d+ [Yy]ards\\)")
            #ARIZONA Penalty, ball on ASU47, PENALTY offside (-5 Yards) to the Ariz 48
            m = match(team_penalty_ballon_penalty_number_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
        end
    end
    if isnothing(m) && occursin(team_penalty_ballon_penalty_name, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_ballon_penalty_name") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            
            team_penalty_ballon_penalty_name_regex = 
            Regex("$team $penalties_regex_txt,? ball on .+ $penalties_regex_txt ($penalty) \\($name_regex\\)")
            #IOWA ST Penalty, ball on ISU35, PENALTY personal foul (Dylan Soehner) to the IowSt 20
            m = match(team_penalty_ballon_penalty_name_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, m[3])
                break
            end
        end
    end
    if isnothing(m) && occursin(team_penalty_penalty_name, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_penalty_name") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            
            team_penalty_penalty_name_regex = 
            Regex("$team $penalties_regex_txt,? ($penalty) $penalties_regex_txt \\($name_regex\\)")
            #WEST VIRGINIA Penalty, Targeting Penalty (Kenny Robinson Jr.) to the WVirg 5 for a 1ST down.  WVU #2 (K. Robinson) has been ejected for targeting.
            m = match(team_penalty_penalty_name_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, m[3])
                break
            end
        end
    end
    if isnothing(m) && occursin(penalty_team_team_penalty_number, txt)
        if DEBUG_PENALTY println("  Trying: penalty_team_team_penalty_number") end
        for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
            
            penalty_team_team_penalty_number_regex = 
            Regex("$penalties_regex_txt,? $team1 ($penalty1).+ $team2 +$penalties_regex_txt,? ($penalty2) \\(-?\\d+ [Yy]ards\\)")
            #PENALTY TULANE pass interference 2 yards to the TULANE1, NO PLAY. NEVADA Penalty, False Start (-5 Yards) to the Tulan 6 (Brandon Talton KICK)
            #AIR FORCE Penalty, Defensive offside ( Yards) to the AFA 3 UNLV Penalty, false start (-5 Yards) to the AFA 8 (Evan Pantels KICK)
            m = match(penalty_team_team_penalty_number_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_type, m[4])
                push!(foul_status, "enforced")
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_team, get_team_name(m[3], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                push!(foul_transgressor, "No data")
                break
            end
        end
    end
    if isnothing(m) && occursin(penalty_team_noname_peanlty_team_revname, txt)
        if DEBUG_PENALTY println("  Trying: penalty_team_noname_peanlty_team_revname") end
        for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
            
            penalty_team_noname_peanlty_team_revname_regex = 
            Regex("$penalties_regex_txt,? $team1 ($penalty1) \\d+ yards.+ $penalties_regex_txt,? $team2 ($penalty2) \\($name_lastfirst_penalty_regex\\)")
            #PENALTY UTAHST holding 10 yards to the UTAHST15, NO PLAY, PENALTY BOISEST personal foul (Maeva, Tyson) 15 yards to the UTAHST30, NO PLAY, 1ST DOWN UTAHST.
            m = match(penalty_team_noname_peanlty_team_revname_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_type, m[4])
                push!(foul_status, "enforced")
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_team, get_team_name(m[3], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                push!(foul_transgressor, process_name(m[5]))
                break
            end
        end
    end
    if isnothing(m) && occursin(penalty_team_number_penalty_team_number, txt)
        if DEBUG_PENALTY println("  Trying: penalty_team_number_penalty_team_number") end
        for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
            
            penalty_team_number_penalty_team_number_regex = 
            Regex("$penalties_regex_txt,? $team1 ($penalty1) \\d+ yards to.+ $penalties_regex_txt,? $team2 ($penalty2) \\d+ yards to")
            #PENALTY MARSHALL offside 5 yards to the MARSHALL26, PENALTY MARSHALL personal foul 13 yards to the MARSHALL13, 1ST DOWN AKRON, NO PLAY. for a 1ST down
            #PENALTY USM offside 5 yards to the TROY33, PENALTY USM illegal defense 5 yards to the TROY38, NO PLAY.
            m = match(penalty_team_number_penalty_team_number_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_type, m[4])
                push!(foul_status, "enforced")
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_team, get_team_name(m[3], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                push!(foul_transgressor, "No data")
                break
            end
        end
    end
    if isnothing(m) && occursin(penalty_team_revcapname_penalty_team_number, txt)
        if DEBUG_PENALTY println("  Trying: penalty_team_revcapname_penalty_team_number") end
        for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
            
            penalty_team_revcapname_penalty_team_number_regex = 
            Regex("$penalties_regex_txt,? $team1 ($penalty1) \\($name_caplastfirst_penalty_regex\\).+ $penalties_regex_txt,? $team2 ($penalty2) \\d+ [Yy]ards")
            #PENALTY TLN false start (LEGLUE, John) 5 yards to the TLN20, PENALTY TLN unsportsmanlike conduct 10 yards to the TLN10, NO PLAY.
            m = match(penalty_team_revcapname_penalty_team_number_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_type, m[5])
                push!(foul_status, "enforced")
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_team, get_team_name(m[4], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, process_name(m[3]))
                push!(foul_transgressor, "No data")
                break
            end
        end
    end
    if isnothing(m) && occursin(penalty_team_revcapname_penalty_team_revcapname, txt)
        if DEBUG_PENALTY println("  Trying: penalty_team_revcapname_penalty_team_revcapname") end
        for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
            
            penalty_team_revcapname_penalty_team_revcapname_regex = 
            Regex("$penalties_regex_txt,? $team1 ($penalty1) \\($name_caplastfirst_penalty_regex\\).+ $penalties_regex_txt,? $team2 ($penalty2) \\($name_caplastfirst_penalty_regex\\)")
            #PENALTY BALL pass interference (POTTS, Tyler) 12 yards to the BALL16, 1ST DOWN CMU, NO PLAY, PENALTY BALL unsportsmanlike conduct (WHITE, Jacob) 9 yards to the BALL7, 1ST DOWN CMU, NO PLAY.
            m = match(penalty_team_revcapname_penalty_team_revcapname_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_type, m[5])
                push!(foul_status, "enforced")
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_team, get_team_name(m[4], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, process_name(m[3]))
                push!(foul_transgressor, process_name(m[6]))
                break
            end
        end
    end
    if isnothing(m) && occursin(penalty_team_revname_penalty_team_revname, txt)
        if DEBUG_PENALTY println("  Trying: penalty_team_revname_penalty_team_revname") end
        for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
            
            penalty_team_revname_penalty_team_revname_regex = 
            Regex("$penalties_regex_txt,? $team1 ($penalty1) \\($name_lastfirst_penalty_regex\\).+ $penalties_regex_txt,? $team2 ($penalty2) \\($name_lastfirst_penalty_regex\\)")
            #PENALTY GRAM holding (Franklin,Edgard) 10 yards to the ULM26, NO PLAY, PENALTY GRAM personal foul (Davis,De'Vante) 15 yards to the ULM41, NO PLAY.
            m = match(penalty_team_revname_penalty_team_revname_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_type, m[5])
                push!(foul_status, "enforced")
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_team, get_team_name(m[4], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, process_name(m[3]))
                push!(foul_transgressor, process_name(m[6]))
                break
            end
        end
    end
    if isnothing(m) && occursin(penalty_team_revname_penalty_team_number, txt)
        if DEBUG_PENALTY println("  Trying: penalty_team_revname_penalty_team_number") end
        for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
            
            penalty_team_revname_penalty_team_number_regex = 
            Regex("$penalties_regex_txt,? $team1 ($penalty1) \\($name_lastfirst_penalty_regex\\).+ $penalties_regex_txt,? $team2 ($penalty2) \\d+ [Yy]ards to")
            #PENALTY UL pass interference (Brown,Savion) 11 yards to the UL41, 1ST DOWN AKRON, NO PLAY, PENALTY UL unsportsmanlike conduct 15 yards to the UL26, 1ST DOWN AKRON, NO PLAY.
            m = match(penalty_team_revname_penalty_team_number_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_type, m[5])
                push!(foul_status, "enforced")
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_team, get_team_name(m[4], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, process_name(m[3]))
                push!(foul_transgressor, "No data")
                break
            end
        end
    end
    if isnothing(m) && occursin(penalty_team_number_penalty_team_revname, txt)
        if DEBUG_PENALTY println("  Trying: penalty_team_number_penalty_team_revname") end
        for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team1 in [off_abbrv_catch, def_abbrv_catch], team2 in [off_abbrv_catch, def_abbrv_catch]
            
            penalty_team_number_penalty_team_revname_regex = 
            Regex("$penalties_regex_txt,? $team1 ($penalty1)(?: \\(#\\))? \\d+ yards to.+ $penalties_regex_txt,? $team2 ($penalty2) \\($name_lastfirst_penalty_regex\\)")
            #PENALTY TROY holding (#) 10 yards to the TROY11, NO PLAY, PENALTY GEORGIAST personal foul (Applin, DeAndre) 0 yards to the TROY21, NO PLAY.
            m = match(penalty_team_number_penalty_team_revname_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_type, m[4])
                push!(foul_status, "enforced")
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_team, get_team_name(m[3], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                push!(foul_transgressor, process_name(m[5]))
                println("foul_type: $foul_type, foul_status: $foul_status, foul_team: $foul_team, foul_transgressor: $foul_transgressor")
                break
            end
        end
    end
    if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

function penalty_team_number_case_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    penalties_regex_txt = "(?:Penalty|PENALTY)"

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    m = "failed"

    #penalty_team_number_case
    # penalty_team_number = r"(?:Penalty|PENALTY) [A-Z0-9]+ [A-Za-z0 ]+ \(-?\d+"
    # penalty_team_playernumber_number = r"(?:Penalty|PENALTY),? [A-Z0-9-]+ [A-Za-z0 ]+ \([\dA-Z]+\) \d+ yards to"
    penalty_team_playernumber_number = r"(?:Penalty|PENALTY),? [A-Z0-9-]+ [A-Za-z0 ]+ \(\d[\dA-Z]*\) \d+ yards to"
    penalty_teamdigit_revcapname = Regex("(?:Penalty|PENALTY),? [A-Z0-9-]+\\(\\d\\) [A-Za-z0 ]+\\($name_caplastfirst_penalty_regex\\)")
    penalty_teamdigit_revname = Regex("(?:Penalty|PENALTY),? [A-Z0-9-]+\\(\\d\\) [A-Za-z0 ]+\\($name_lastfirst_penalty_regex\\)")
    team_penalty_number = r"(?:[A-Z]+|[A-Z][a-z]+) +(?:Penalty|PENALTY),? [A-Za-z0 ]+"#\(-?\d+ [Yy]ards\)"
    # penalty_team_number = r"(?:Penalty|PENALTY),? [A-Z0-9-]+[a-z]*,?(?: UNS:)? [A-Za-z012 ]+\d+ [Yy]ards? (?:to|from)"
    penalty_team_number = r"(?:Penalty|PENALTY),? (?:[A-Z0-9-]+[a-z]* ?)+,?(?: UNS:)? [A-Za-z012 ]+ \d+ [Yy](?:ar)?ds? (?:to|from)"
    penalty_team_number_name = Regex("(?:Penalty|PENALTY),? [A-Z0-9-]+ [A-Za-z012 ]+\\(#\\d+ $name_penalty_regex\\)")
    penalty_team_nameejected_number = Regex("(?:Penalty|PENALTY),? [A-Z0-9-]+ [A-Za-z012 ]+,? $name_penalty_regex ejected,? \\d+ yard")


    if DEBUG_PENALTY println("Case: penalty_team_number_case") end
    if occursin(penalty_team_playernumber_number, txt)
        if DEBUG_PENALTY println("  Trying: penalty_team_playernumber_number") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            
            penalty_team_playernumber_number_regex = 
            Regex("$penalties_regex_txt,? $team ($penalty) \\(([\\dA-Z]+)\\) \\d+ yards to")
            #PENALTY NEVADA personal foul (4) 15 yards to the NEVADA16, NO PLAY.
            m = match(penalty_team_playernumber_number_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "Player #$(m[3])")
                break
            end
        end
    elseif occursin(penalty_teamdigit_revcapname, txt)
        if DEBUG_PENALTY println("  Trying: penalty_teamdigit_revcapname") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            
            penalty_teamdigit_revcapname_regex = 
            Regex("$penalties_regex_txt,? $team\\(\\d\\) ($penalty) \\($name_caplastfirst_penalty_regex\\) \\d+ yards to")
            #PENALTY FAU(1) pass interference (HAFIZ, Quran) 15 yards to the ODU43, 1ST DOWN ODU, NO PLAY.
            m = match(penalty_teamdigit_revcapname_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, process_name(m[3]))
                break
            end
        end
    elseif occursin(penalty_teamdigit_revname, txt)
        if DEBUG_PENALTY println("  Trying: penalty_teamdigit_revname") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            
            penalty_teamdigit_revname_regex = 
            Regex("$penalties_regex_txt,? $team\\(\\d\\) ($penalty) \\($name_lastfirst_penalty_regex\\) \\d+ yards to")
            #PENALTY ULM(3) pass interference (Newton, Josh) 15 yards to the ULM(3)20, 1ST DOWN USA, NO PLAY.
            m = match(penalty_teamdigit_revname_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, process_name(m[3]))
                break
            end
        end
    elseif occursin(penalty_team_number, txt)
        if DEBUG_PENALTY println("  Trying: penalty_team_number") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            
            penalty_team_number_regex = 
            Regex("$penalties_regex_txt,? $team,?(?: UNS:)? ($penalty) +\\d+ [Yy](?:ar)?ds? (?:to|from)")
            #PENALTY AIRFORCE holding 10 yards to the AIRFORCE27, NO PLAY.
            #PENALTY ARZ Illegal Substitution 5 yards from ARZ40 to ARZ35. NO PLAY.
            m = match(penalty_team_number_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
        end
    elseif occursin(team_penalty_number, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_number") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            
            team_penalty_number_regex = 
            Regex("$team +$penalties_regex_txt,? ($penalty) \\(-?\\d+ [Yy]ards\\) to")
            #NICHOLLS  Penalty, Illegal Block (5 Yards) to the NicSt 5
            m = match(team_penalty_number_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
        end
    elseif occursin(penalty_team_number_name, txt)
        if DEBUG_PENALTY println("  Trying: penalty_team_number_name") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            
            penalty_team_number_name_regex = 
            Regex("$penalties_regex_txt,? $team ($penalty) \\(#\\d+ $name_penalty_regex\\)")
            #PENALTY FIU Illegal Forward Pass (#21 E.Wilson Jr.)
            m = match(penalty_team_number_name_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, process_name(m[3]))
                break
            end
        end
    elseif occursin(penalty_team_nameejected_number, txt)
        if DEBUG_PENALTY println("  Trying: penalty_team_nameejected_number") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
                    
            penalty_team_nameejected_number_regex = 
            Regex("$penalties_regex_txt,? $team ($penalty),? $name_penalty_regex ejected,? \\d+ yard")
            #PENALTY OREGON Targeting, Drayton Carlberg ejected, 15 yards to the 50 yardline, NO PLAY, 1ST DOWN WASHINGTON.
            m = match(penalty_team_nameejected_number_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, process_name(m[3]))
                break
            end
        end
    end

    if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

function penalty_team_name_case_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    penalties_regex_txt = "(?:Penalty|PENALTY)"

    #penalty_team_name_case
    team_penalty_cap_last_post_name = Regex("(?:Penalty|PENALTY),? (?:(?:[A-Za-z012-]) ?)+\\((?:Targeting: |,)?$name_caplast_postfix_first_penalty_regex(?: ejected| ejected for targeting)?\\)")
    # penalty_team_revname = r"(?:Penalty|PENALTY) [A-Z0-9]+ [A-Za-z ]+\((?:[A-Z'][a-z'-]+)+(?: III| II| J[Rr]\.?)?, ?[A-Z'][a-z']+"
    # penalty_team_revname = r"(?:Penalty|PENALTY) [A-Z0-9]+(?: UNS:)? [A-Za-z0 ]+\((?:[A-Z'][a-z'-]+)+(?: III| II| J[Rr]\.?)?, ?(?:[A-Z'][A-Za-z'\.]+|[A-Z]\.?)"
    # penalty_team_revname = r"(?:Penalty|PENALTY) [A-Za-z0-9]+(?: UNS:)? [A-Za-z0 ]+\((?:[A-Z'][a-z'-]+)+(?: III| II| J[Rr]\.?)?, ?(?:[A-Z'][A-Za-z'\.]+|[A-Z]\.?)"
    penalty_team_revname = Regex("(?:Penalty|PENALTY),? [A-Za-z0-9&_-]+,?(?: UN(?:R|S):)? [A-Za-z012 -]+\\((?: |,)?$name_lastfirst_penalty_regex")
    # penalty_team_name = r"(?:Penalty|PENALTY),? [A-Z0-9]+ [A-Za-z0 ]+ \((?:[A-Z][a-z]|[A-Z][a-z]{2})?'?[A-Z'][a-z'\.]+ +[A-Z'][a-z']+"
    penalty_team_name = Regex("(?:Penalty|PENALTY),? [A-Z0-9&_-]+ [A-Za-z012 ]+ \\((?: |,|#\\d+ )?$name_penalty_regex(?: ejected)?\\)")
    # penalty_team_revcapname = r"(?:Penalty|PENALTY),? [A-Z0-9-]+ [A-Za-z0 ]+ \((?:Mc|Mac)[A-Z']+, *(?:[A-Z'][A-Za-z'\.]+|[A-Z]\.?)"
    penalty_team_revcapname = Regex("(?:Penalty|PENALTY),? [A-Z0-9&_-]+ [A-Za-z0 ]+ \\((?: |,)?$name_caplastfirst_penalty_regex\\)")
    penalty_team_lastonlyname = r"(?:Penalty|PENALTY),? [A-Z0-9&_-]+ [A-Za-z0 ]+ \((?: |,)?(?:Mc|Mac)?(?:[A-Z'][a-z'-]+)+,?\)"
    penalty_team_capslastonlyname = r"(?:Penalty|PENALTY),? [A-Z0-9&_-]+ [A-Za-z0 ]+ \((?: |,)?(?:Mc|Mac)?(?:[A-Z'-]+)+,?\)"
    penalty_team_lowerlastname = r"(?:Penalty|PENALTY),? [A-Z0-9&_-]+ [A-Za-z0 ]+ \([a-z'-]+, [A-Z'][a-z'-]+\)"

#MOVING penalty_team_capslastonlyname before penalty_team_name
    


    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    m = "failed"

    if DEBUG_PENALTY println("Case: penalty_team_name_case") end
    if occursin(team_penalty_cap_last_post_name, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_cap_last_post_name") end
        for penalty in penalty_list_occurred, team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            
            team_penalty_cap_last_post_name_regex = 
            Regex("$penalties_regex_txt,? $team ($penalty) *\\((?:Targeting: |,)?$name_caplast_postfix_first_penalty_regex(?: ejected| ejected for targeting)?\\)")
            #PENALTY UMASS personal foul (THOMAS, SR., R.) 15 yards to the UMASS35, NO PLAY.
            m = match(team_penalty_cap_last_post_name_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, process_name(m[3]))
                break
            end
        end
    elseif occursin(penalty_team_revname, txt)
        if DEBUG_PENALTY println("  Trying: penalty_team_revname") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]

            # println("    trying: 1 penalty_team_revname_regex")
            penalty_team_revname_regex = 
            Regex("$penalties_regex_txt,? $team,?(?: UN(?:R|S):)? ($penalty) +\\((?: |,)?$name_lastfirst_penalty_regex\\)")
            #PENALTY WESTMICH face mask (Ash, Richard) 15 yards to the WESTMICH24, NO PLAY, 1ST DOWN AIRFORCE. for a 1ST down
            m = match(penalty_team_revname_regex, txt)
            if isnothing(m)
                # println("    trying: 2 penalty_team_revname_regex")
                penalty_team_revname_regex = 
                Regex("$penalties_regex_txt,? $team,?(?: UN(?:R|S):)? ($penalty) \\((?: |,)?$name_lasttwofirst_penalty_regex\\)")
                #PENALTY WESTMICH face mask (Ash, Richard) 15 yards to the WESTMICH24, NO PLAY, 1ST DOWN AIRFORCE. for a 1ST down
                m = match(penalty_team_revname_regex, txt)
            end
            if isnothing(m)
                # println("    trying: 3 penalty_team_revname_regex")
                penalty_team_revname_regex = 
                Regex("$penalties_regex_txt,? $team,?(?: UN(?:R|S):)? ($penalty) +\\((?: |,)?$name_lastfirst_penalty_regex ejected\\)")
                #
                m = match(penalty_team_revname_regex, txt)
            end
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, process_name(m[3]))
                break
            end
        end
    elseif occursin(penalty_team_lastonlyname, txt) || occursin(penalty_team_capslastonlyname, txt)
        if DEBUG_PENALTY println("  Trying: penalty_team_lastonlyname") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            
            penalty_team_lastonlyname_regex = 
            Regex("$penalties_regex_txt,? $team ($penalty) \\((?: |,)?$name_lastonly_regex,?\\)")
            #PENALTY CU personal foul (Simpson) 12 yards to the CU13, NO PLAY.
            m = match(penalty_team_lastonlyname_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, titlecase(m[3]))
                break
            end
        end
    elseif occursin(penalty_team_name, txt)
        if DEBUG_PENALTY println("  Trying: penalty_team_name") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
                        
            penalty_team_name_regex = 
            # Regex("$penalties_regex_txt,? $team ($penalty) \\($name_lastfirst_penalty_regex\\)")
            Regex("$penalties_regex_txt,? $team ($penalty) \\((?: |,|#\\d+ )?$name_penalty_regex(?: ejected)?\\)")
            #PENALTY WESTMICH face mask (Ash, Richard) 15 yards to the WESTMICH24, NO PLAY, 1ST DOWN AIRFORCE. for a 1ST down
            m = match(penalty_team_name_regex, txt)
            if isnothing(m)
                penalty_team_name_regex = 
                Regex("$penalties_regex_txt,? $team ($penalty) \\((?: |,|#\\d+ )?$name_twofirst_penalty_regex\\)")
                #PENALTY WESTMICH face mask (Ash, Richard) 15 yards to the WESTMICH24, NO PLAY, 1ST DOWN AIRFORCE. for a 1ST down
                m = match(penalty_team_name_regex, txt)
            end
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, m[3])
                break
            end
        end
    elseif occursin(penalty_team_revcapname, txt)
        if DEBUG_PENALTY println("  Trying: penalty_team_revcapname") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            
            penalty_team_revcapname_regex = 
            Regex("$penalties_regex_txt,? $team ($penalty) \\((?: |,)?$name_caplastfirst_penalty_regex\\)")
            #PENALTY CSU pass interference (McBRIDE, Trey) 15 yards to the CSU32, NO PLAY.
            m = match(penalty_team_revcapname_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name(m[1], offense, off_abbrv_catch, defense, def_abbrv_catch))
                last_name, first_name = strip.(split(m[3], ","))
                push!(foul_transgressor, titlecase(first_name)*" "*titlecase(last_name))
                break
            end
        end
    elseif occursin(penalty_team_lowerlastname, txt)
        if DEBUG_PENALTY println("  Trying: penalty_team_lowerlastname") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
                    
            penalty_team_lowerlastname_regex = 
            Regex("$penalties_regex_txt,? $team ($penalty) \\($name_lowerlastfirst_penalty_regex\\)")
            #PENALTY UTAH personal foul (lauaki, Semisi) 15 yards to the ISU21, 1ST DOWN ISU, NO PLAY.
            m = match(penalty_team_lowerlastname_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, process_name(m[3]))
                break
            end
        end
    end

    if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

function penalty_team_team_case_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    penalties_regex_txt = "(?:Penalty|PENALTY)"

    penalty_team = r"(?:Penalty|PENALTY) [A-Z]+ (?:[A-Z]?[a-z12]+ ?)+ \(TEAM\)"

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    m = "failed"

    if DEBUG_PENALTY println("Case: penalty_team_team_case") end
    if occursin(penalty_team, txt)
        if DEBUG_PENALTY println("  Trying: penalty_team") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            
            penalty_team_regex = 
            Regex("$penalties_regex_txt,? $team(?: UNS:)? ($penalty) +\\(TEAM\\)")
            #PENALTY OLEMISS offside (TEAM) 5 yards to the CALIFORNIA28, NO PLAY.
            m = match(penalty_team_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
        end
    end
    if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

function team_peanlty_team_case_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    penalties_regex_txt = "(?:Penalty|PENALTY)"

    penalty_team = r"[A-Z]+ (?:Penalty|PENALTY),? (?:[A-Z]?[a-z12]+ ?)+ \(TEAM\)"

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    m = "failed"

    if DEBUG_PENALTY println("Case: team_peanlty_team_case") end
    if occursin(penalty_team, txt)
        if DEBUG_PENALTY println("  Trying: penalty_team") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            
            penalty_team_regex = 
            Regex("$team $penalties_regex_txt,? ($penalty) +\\(TEAM\\)")
            #AIR FORCE Penalty, Personal Foul (TEAM) to the AFA 24 for a 1ST down
            m = match(penalty_team_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
        end
    end

    if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

function team_penalty_number_case_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    penalties_regex_txt = "(?:Penalty|PENALTY)"

    team_penalty_unsfoul = r"(?:[A-Z]+|[A-Z][a-z]+)+ +(?:Penalty|PENALTY),? UN(?:R|S): (?:(?:[A-Za-z012-]) ?)+ \(-?\d+ [Yy]ards\)"
    team_penalty_unsfoul_unsfoul = r"(?:[A-Z]+|[A-Z][a-z]+)+ +(?:Penalty|PENALTY),? UN(?:R|S): (?:(?:[A-Za-z012-]) ?)+ UN(?:R|S): (?:(?:[A-Za-z012-]) ?)+\(-?\d+ [Yy]ards\)"
    #This was to try to handle penalty code BL;
    # team_penalty_number_simple = r"(?:[A-Z]+|[A-Z][a-z]+)+ +(?:Penalty|PENALTY),? (?:(?:[A-Za-z012-]) ?)+|[A-Z;]+) \(-?\d+ [Yy]a?r?ds\)"
    team_penalty_number = r"(?:[A-Z]+|[A-Z][a-z]+)+ +(?:Penalty|PENALTY),?(?: UN(?:R|S):| ball on)? (?:(?:(?:[A-Za-z012-]) ?)+|[A-Z;]+)\.? \((?:-| )?\d+ [Yy]a?r?ds(?:(?:,| -)? [A-Za-z ]+)?\)"
    # team_penalty_number_parens = r"(?:[A-Z]+|[A-Z][a-z]+)+ +(?:Penalty|PENALTY),?(?: UN(?:R|S):| ball on)? (?:(?:[A-Za-z012-]) ?)+|[A-Z;]+)\.? \((?:-| )?\d+ [Yy]a?r?ds(?:(?:,| -)? [A-Za-z ]+)?\)"
    team_nopenalty_number = r"(?:[A-Z]+|[A-Z][a-z]+)+ +(?:Penalty|PENALTY),? +\((?:-| )?\d+ [Yy]ards\)"

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    m = "failed"

    if DEBUG_PENALTY println("Case: team_peanlty_number_case") end
    if occursin(team_penalty_unsfoul, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_unsfoul") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            
            team_penalty_unsfoul_regex = 
            Regex("$team +$penalties_regex_txt,? UN(?:R|S): ($penalty) \\(-?\\d+ [Yy]ards\\)")
            #TOLEDO Penalty, UNR: Unnecessary Roughness (-15 Yards) to the BwGrn 40
            m = match(team_penalty_unsfoul_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
        end
    elseif occursin(team_penalty_unsfoul_unsfoul, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_unsfoul_unsfoul") end
        for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            
            team_penalty_unsfoul_unsfoul_regex = 
            Regex("$team +$penalties_regex_txt,? UN(?:R|S): ($penalty1) UN(?:R|S): ($penalty2) \\(-?\\d+ [Yy]ards\\)")
            #INCARNATEW Penalty, UNS: Unsportsmanlike Conduct UNS: Unsportsmanlike Conduct (7 Yards) to the InWrd 2 for a 1ST down
            m = match(team_penalty_unsfoul_unsfoul_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_type, m[3])
                push!(foul_status, "enforced")
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                push!(foul_transgressor, "No data")
                break
            end
        end
    elseif occursin(team_penalty_number, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_number") end
        for penalty in penalty_list_occurred, team in [off_abbrv_catch, def_abbrv_catch]
            
            team_penalty_number_regex = 
            Regex("$team +$penalties_regex_txt,?(?: UN(?:R|S):| ball on)? ($penalty)\\.? +\\((?:-| )?\\d+ [Yy]a?r?ds(?:(?:,| -)? [A-Za-z ]+)?\\)")
            #WESTRN MICHIGAN Penalty, Delay of Game (-5 Yards) to the WMich 34
            m = match(team_penalty_number_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
        end
    elseif occursin(team_nopenalty_number, txt)
        if DEBUG_PENALTY println("  Trying: team_nopenalty_number") end
        for team in [off_abbrv_catch, def_abbrv_catch]
            
            team_nopenalty_number_regex = 
            Regex("$team +$penalties_regex_txt,? +\\((?:-| )?-?\\d+ [Yy]ards\\)")
            #AKRON Penalty,  (-5 Yards) to the CMich 42
            m = match(team_nopenalty_number_regex, txt)
            if !isnothing(m)
                push!(foul_type, "No data")
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
        end
    end

    if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

function team_penalty_name_case_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    penalties_regex_txt = "(?:Penalty|PENALTY)"

    # team_penalty_name_name = Regex("(?:Penalty|PENALTY),? (?:(?:[A-Za-z012]+) )+\\($name_penalty_regex & $name_penalty_regex(?: for \\d+ yards ?)?\\)")
    # team_penalty_name_kick = Regex("(?:Penalty|PENALTY),? (?:(?:[A-Za-z012]+) )+\\($name_penalty_regex KICK\\)")
    # team_penalty_name = Regex("(?:Penalty|PENALTY),? (?:(?:[A-Za-z012]) ?)+\\((?:Targeting: )?$name_penalty_regex(?: ejected| ejected for targeting)?\\)")
    # team_penalty_uns_name = Regex("(?:Penalty|PENALTY),? UNS: (?:(?:[A-Za-z012]+) )+\\($name_penalty_regex(?: ejected| ejected for targeting)?\\)")
    # team_penalty_ballon_name = Regex("(?:Penalty|PENALTY),? (?:(?:[A-Za-z012]+) )+ball on [A-Z]+\\d+ \\($name_penalty_regex\\)")
    # team_penalty_revname = Regex("(?:Penalty|PENALTY),? (?:(?:[A-Za-z012]+) )+\\($name_lastfirst_penalty_regex(?:,? ejected|,? ejected for targeting)?\\)")
    # team_penalty_revname_lastonly = Regex("(?:Penalty|PENALTY),? (?:(?:[A-Za-z012]+) )+\\($name_regex(?:,? ejected|,? ejected for targeting)?\\)")
    # team_penalty_penalty_name = Regex("(?:Penalty|PENALTY),? (?:(?:[A-Za-z012]+) )+\\($name_penalty_regex\\)")

    team_penalty_name_name = Regex("(?:Penalty|PENALTY),? (?:(?:[A-Za-z012-]) ?)+\\($name_penalty_regex & $name_penalty_regex(?: for \\d+ yards ?)?\\)")
    team_penalty_name_kick = Regex("(?:Penalty|PENALTY),? (?:(?:[A-Za-z012-]) ?)+\\($name_penalty_regex KICK\\)")
    team_penalty_name = Regex("(?:Penalty|PENALTY),?(?: UNS:)? (?:(?:[A-Za-z012\\.-]) ?)+\\((?:Targeting: )?$name_penalty_regex(?: ejected| ejected for targeting)?\\)")
    team_penalty_uns_revname = Regex("(?:Penalty|PENALTY),?(?: UNS:)? (?:(?:[A-Za-z012\\.-]) ?)+\\($name_lastfirst_regex\\) \\d+")
    team_penalty_name_noparens = Regex("(?:Penalty|PENALTY),?(?: UNS:)? (?:(?:[A-Za-z012\\.-]) ?)+ on $name_penalty_regex")
    team_penalty_headcoach_name = Regex("(?:Penalty|PENALTY),?(?: UNS:)? (?:(?:[A-Za-z012\\.-]) ?)+ *Head Coach $name_penalty_regex")
    team_penalty_uns_name = Regex("(?:Penalty|PENALTY),? UN(?:R|S): (?:(?:[A-Za-z012-]) ?)+\\($name_penalty_regex(?: ejected| ejected for targeting)?\\)")
    team_penalty_ballon_name = Regex("(?:Penalty|PENALTY),? (?:(?:[A-Za-z012-]) ?)+ball on [A-Z]+\\d+ \\($name_penalty_regex\\)")
    team_penalty_revname = Regex("(?:Penalty|PENALTY),? (?:(?:[A-Za-z012-]) ?)+\\($name_lastfirst_penalty_regex(?:,? ejected|,? ejected for targeting)?\\)")
    team_penalty_revname_lastonly = Regex("(?:Penalty|PENALTY),? (?:(?:[A-Za-z012-]) ?)+\\($name_regex(?:,? ejected|,? ejected for targeting)?\\)")
    # team_penalty_penalty_name = Regex("(?:Penalty|PENALTY),? (?:(?:[A-Za-z012-]) ?)+\\($name_penalty_regex\\)")
    team_penalty_doublefoul_name = Regex("(?:Penalty|PENALTY),? (?:(?:[A-Za-z012-]) ?)+\\(Double Personal Foul on $name_penalty_regex\\)")
    team_nopenalty_name = Regex("(?:Penalty|PENALTY),? +\\($name_penalty_regex(?: ejected| ejected for targeting)?\\)")
    team_penalty_octothrope = r"[A-Z]+ (?:Penalty|PENALTY),?, (?:(?:[A-Za-z012-]) ?)+ \(#\)"
    team_penalty_endofplay_penalty_name = Regex("$penalties_regex_txt,? .+ End Of Play $penalties_regex_txt,? $penalty_general_regex\\.? \\($name_penalty_regex\\)")
    

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    m = "failed"
    
    if DEBUG_PENALTY println("Case: team_penalty_name_case") end
    if occursin(team_penalty_name_name, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_name_name") end
        for penalty in penalty_list_occurred, team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            
            team_penalty_name_name_regex = 
            Regex("$team $penalties_regex_txt,? ($penalty) +\\($name_penalty_regex & $name_penalty_regex(?: for \\d+ yards ?)?\\)")
            #WESTRN MICHIGAN Penalty, Offensive Holding (Eric Boyden) to the AFA 20
            m = match(team_penalty_name_name_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, m[3])
                push!(foul_transgressor, m[4])
                break
            end
        end
    elseif occursin(team_penalty_name_kick, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_name_kick") end
        for penalty in penalty_list_occurred, team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            
            team_penalty_name_kick_regex = 
            Regex("$team $penalties_regex_txt,? ($penalty) +\\($name_penalty_regex KICK\\)")
            #GEORGIA TECH PENALTY FACEMASK (Coby Weiss KICK)
            m = match(team_penalty_name_kick_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, m[3])
                break
            end
        end
    elseif occursin(team_penalty_name, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_name") end
        for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            
            team_penalty_name_regex = 
            Regex("$team (?:Targeting )?$penalties_regex_txt,?(?: UNS:)? ($penalty2)\\.? *\\((?:Targeting: )?$name_penalty_regex(?: ejected| ejected for targeting)?\\)")
            #WESTRN MICHIGAN Penalty, Offensive Holding (Eric Boyden) to the AFA 20
            m = match(team_penalty_name_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, m[3])
                break
            end
            if isnothing(m)
                team_penalty_name_regex = 
                Regex("$team $penalties_regex_txt,? ($penalty2)(?: Penalty)? \\($name_penalty_regex\\)")
                #WEST VIRGINIA Penalty, Targeting Penalty (Kenny Robinson Jr.) to the WVirg 5 for a 1ST down.  WVU #2 (K. Robinson) has been ejected for targeting.
                #MEMPHIS Penalty, Defensive Pass Interference (Sylvonta Oliver) to the Memph 6 for a 1ST down
                m = match(team_penalty_name_regex, txt)
                if !isnothing(m)
                    push!(foul_type, m[2])
                    push!(foul_status, "enforced")
                    push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_transgressor, m[3])
                    break
                end
            end
            if isnothing(m)
                # println("SEE penalty peanlty")
                team_penalty_penalty_name_regex = 
                Regex("$team $penalties_regex_txt,?(?: UNS:)? ($penalty1) ($penalty2) +\\($name_penalty_regex(?: ejected| ejected for targeting)?\\)")
                #LSU Penalty Unsportsmanlike Conduct (Key, Arden)
                m = match(team_penalty_penalty_name_regex, txt)
                if !isnothing(m)
                    push!(foul_type, m[2])
                    push!(foul_type, m[3])
                    push!(foul_status, "Ambiguous")
                    push!(foul_status, "Ambiguous")
                    push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_transgressor, "Ambiguous")
                    push!(foul_transgressor, "Ambiguous")
                    break
                end
            end
            if isnothing(m)
                team_penalty_endofplay_penalty_name_regex = 
                Regex("$team $penalties_regex_txt,? .+ End Of Play $penalties_regex_txt,? ($penalty2)\\.? \\($name_penalty_regex\\)")
                #TEMPLE Penalty, at TLS47, End Of Play PENALTY Personal Foul. (Randle Jones) to the Tulsa 47
                m = match(team_penalty_endofplay_penalty_name_regex, txt)
                if !isnothing(m)
                    push!(foul_type, m[2])
                    push!(foul_status, "enforced")
                    push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                    push!(foul_transgressor, m[3])
                    break
                end
            end
        end

    elseif occursin(team_penalty_uns_revname, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_uns_revname") end
        for penalty1 in penalty_list_occurred, team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            
            team_penalty_name_regex = 
            Regex("$team $penalties_regex_txt,?(?: UNS:?)? ($penalty1) \\($name_lastfirst_regex\\) \\d+")
            #HAWAII Penalty, UNS: Unsportsmanlike Conduct (Tufaga,Isaiah) 15 yards
            m = match(team_penalty_name_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, m[3])
                break
            end
            
        end

    elseif occursin(team_penalty_ballon_name, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_ballon_name") end
        for penalty in penalty_list_occurred, team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
      
            team_penalty_ballon_name_regex = 
            Regex("$team $penalties_regex_txt,? ($penalty) ball on [A-Z]+\\d+ +\\($name_penalty_regex(?: ejected| ejected for targeting)?\\)")
            #MARSHALL Penalty, unsportsmanlike conduct ball on FAU35 (Josh Ball) to the FlAtl 35 for a 1ST down
            m = match(team_penalty_ballon_name_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, m[3])
                break
            end
        end

    elseif occursin(team_penalty_name_noparens, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_name_noparens") end
        for penalty in penalty_list_occurred, team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            
            team_penalty_name_noparens_regex = 
            Regex("$team $penalties_regex_txt,? ($penalty) on $name_penalty_regex")
            #MIAMI FL Penalty, Targeting on Michael Jackson Sr. (15 Yards) to the MiaFl 26 for a 1ST down. (Jackson ejected).
            m = match(team_penalty_name_noparens_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, strip(m[3]))
                break
            end
        end
    elseif occursin(team_penalty_headcoach_name, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_headcoach_name") end
        for penalty in penalty_list_occurred, team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            
            team_penalty_headcoach_name_regex = 
            Regex("$team $penalties_regex_txt,?(?: UNS:)? ($penalty) +Head Coach $name_penalty_regex")
            #FRESNO ST Penalty, Unsportsmanlike Conduct  Head Coach J. Tedford (-15 Yards) to the Houst 16
            m = match(team_penalty_headcoach_name_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "Coach $(strip(m[3]))")
                break
            end
        end
    #ballon was here
    elseif occursin(team_penalty_uns_name, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_uns_name") end
        for penalty in penalty_list_occurred, team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            
            team_penalty_uns_name_regex = 
            Regex("$team $penalties_regex_txt,?(?: UN(?:R|S):)? ($penalty) +\\($name_penalty_regex(?: ejected| ejected for targeting)?\\)")
            #WESTRN MICHIGAN Penalty, Offensive Holding (Eric Boyden) to the AFA 20
            m = match(team_penalty_uns_name_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, m[3])
                break
            end
        end
    elseif occursin(team_penalty_revname, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_revname") end
        for penalty in penalty_list_occurred, team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            
            team_penalty_revname_regex = 
            Regex("$team $penalties_regex_txt,?(?: UNS:)? ($penalty) +\\($name_lastfirst_penalty_regex(?: ejected| ejected for targeting)?\\)")
            #LSU Penalty Unsportsmanlike Conduct (Key, Arden)
            m = match(team_penalty_revname_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, process_name(m[3]))
                break
            end
        end
    elseif occursin(team_penalty_revname_lastonly, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_revname_lastonly") end
        for penalty in penalty_list_occurred, team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            
            team_penalty_revname_lastonly_regex = 
            Regex("$team $penalties_regex_txt,?(?: UNS:)? ($penalty) +\\($name_regex(?:,? ejected|,? ejected for targeting)?\\)")
            #LSU Penalty Unsportsmanlike Conduct (Key, Arden)
            m = match(team_penalty_revname_lastonly_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, process_name(m[3]))
                break
            end
        end
    elseif occursin(team_penalty_doublefoul_name, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_doublefoul_name") end
        for penalty in penalty_list_occurred, team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            
            team_penalty_doublefoul_name_regex = 
            Regex("$team $penalties_regex_txt,?(?: UNS:)? ($penalty) +\\(Double Personal Foul on $name_penalty_regex\\)")
            #OREGON Penalty, Unsportsmanlike Conduct (Double Personal Foul on Austin Faoliu) to the Oregn 8 for a 1ST down
            m = match(team_penalty_doublefoul_name_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, process_name(m[3]))
                push!(foul_transgressor, process_name(m[3]))
                break
            end
        end
    elseif occursin(team_nopenalty_name, txt)
        if DEBUG_PENALTY println("  Trying: team_nopenalty_name") end
        for team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            team_nopenalty_name_regex = 
            Regex("$team $penalties_regex_txt,? +\\($name_penalty_regex(?: ejected| ejected for targeting)?\\)")
            #WESTRN MICHIGAN Penalty, Offensive Holding (Eric Boyden) to the AFA 20
            m = match(team_nopenalty_name_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
        end
    elseif occursin(team_penalty_octothrope, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_octothrope") end
        for penalty in penalty_list_occurred, team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            team_penalty_octothrope_regex = 
            Regex("$team $penalties_regex_txt,? ($penalty) \\(#\\)")
            #KENTUCKY Penalty, Defensive Pass Interference (#) to the Kent 15 for a 1ST down
            m = match(team_penalty_octothrope_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
        end
    end

    if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

function team_penalty_na_case_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    penalties_regex_txt = "(?:Penalty|PENALTY)"

    team_penalty_na = r"(?:Penalty|PENALTY),? (?:(?:[A-Za-z012]) ?)+\(N\/?A\)"
    team_nopenalty_na = r"(?:Penalty|PENALTY),? +\(N\/?A\)"

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    m = "failed"

    if occursin(team_penalty_na, txt)
        if DEBUG_PENALTY println( "  Trying: team_penalty_na") end
        for penalty in penalty_list_occurred, team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            
            team_penalty_na_regex = 
            Regex("$team $penalties_regex_txt,? ($penalty) +\\(N\\/?A\\)")
            #NICHOLLS ST Penalty, false start (N/A) to the AFA 48
            m = match(team_penalty_na_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
        end
    elseif occursin(team_nopenalty_na, txt)
        if DEBUG_PENALTY println( "  Trying: team_nopenalty_na") end
        for team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            
            team_nopenalty_na_regex = 
            Regex("$team $penalties_regex_txt,? +\\(N\\/?A\\)")
            #NICHOLLS ST Penalty, false start (N/A) to the AFA 48
            m = match(team_nopenalty_na_regex, txt)
            if !isnothing(m)
                push!(foul_type, "No data")
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
        end
    end

    if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

function team_penalty_yards_case_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    penalties_regex_txt = "(?:Penalty|PENALTY)"

    team_penalty_yards = r"(?:Penalty|PENALTY),? (?:(?:[A-Za-z012\.-]) ?)+\( [Yy]ards\)"
    team_nopenalty_yards = r"(?:Penalty|PENALTY),? +\( [Yy]ards\)"

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    m = "failed"

    if occursin(team_penalty_yards, txt)
        if DEBUG_PENALTY println( "  Trying: team_penalty_yards") end
        for penalty in penalty_list_occurred, team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            
            team_penalty_yards_regex = 
            Regex("$team $penalties_regex_txt,? ($penalty)\\.? +\\( [Yy]ards\\)")
            #AIR FORCE Penalty, personal foul ( Yards) to the AFA 44 for a 1ST down
            m = match(team_penalty_yards_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
        end
    elseif occursin(team_nopenalty_yards, txt)
        if DEBUG_PENALTY println( "  Trying: team_nopenalty_yards") end
        for team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            
            team_nopenalty_yards_regex = 
            Regex("$team $penalties_regex_txt,? +\\( [Yy]ards\\)")
            #NICHOLLS ST Penalty, false start (N/A) to the AFA 48
            m = match(team_nopenalty_yards_regex, txt)
            if !isnothing(m)
                push!(foul_type, "No data")
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
        end
    end

    if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

function specialcase_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    penalties_regex_txt = "(?:Penalty|PENALTY)"

    penalty_team_noplay = r"(?:Penalty|PENALTY) [A-Z]+ (?:(?:[A-Za-z012]) ?)+(?:,|\.)? NO PLAY"
    team_penalty_junk_name = Regex("[A-Z]+ (?:Penalty|PENALTY).+(?: UNS:)? (?:(?:[A-Za-z012-]) ?)+\\($name_penalty_regex\\)")
    team_penalty_junk_name_ejected = Regex("[A-Z]+ (?:Penalty|PENALTY).+\\($name_penalty_regex ejected for targeting\\)")
    offsetting = r"(?:Penalty|PENALTY).+ [Oo]ff-?[Ss]etting"
    team_penalty_on_pat = r"[A-Z]+ (?:(?:[A-Za-z012]) ?)+(?:Penalty|PENALTY) on PAT"
    team_penalty_lossofdown = r"[A-Z]+ (?:Penalty|PENALTY),? (?:(?:[A-Za-z012]) ?)+,? loss of down"
    penalty_x2_team_x2 = r"(?:Penalty|PENALTY) ([A-Z]+)(?: UNS:)? (?:(?:[A-Za-z012]) ?)+ (\1)(?: UNS:)? (?:(?:[A-Za-z012]) ?)+"
    team_penalty_stop = r"[A-Z]+ (?:Penalty|PENALTY),? (?:(?:[A-Za-z012]) ?)+\."
    # team_foul_penalty_intheendzone = r"[A-Z]+ (?:(?:[A-Za-z012]) ?)+ (?:Penalty|PENALTY),? in the endzone"
    end_phrase = "(?:in the endzone|to the)"
    team_foul_penalty_phrase = Regex("[A-Z]+ (?:(?:[A-Za-z012]) ?)+ (?:Penalty|PENALTY),? $end_phrase")
    team_penalty_foul_phrase = Regex("[A-Z]+ (?:Penalty|PENALTY),? (?:(?:[A-Za-z012]) ?)+ $end_phrase")
    team_penalty_ballon_peanlty_foul_yards = r"[A-Z]+ (?:Penalty|PENALTY),? ball on .+ (?:Penalty|PENALTY),? (?:(?:[A-Za-z012]) ?)+ \(-?\d* [Yy]ards\)"
    penalty_noteam = r"(?:Penalty|PENALTY),? team (?:(?:[A-Za-z012]) ?)+ \d+"
    
    

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    m = "failed"

    if occursin(penalty_team_noplay, txt)
        if DEBUG_PENALTY println( "  Trying: penalty_team_noplay") end
        for penalty in penalty_list_occurred, team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            
            penalty_team_noplay_regex = 
            Regex("$penalties_regex_txt,? $team ($penalty)(?:,|\\.| to the .+)? NO PLAY")
            #PENALTY AKRON pass interference, NO PLAY.
            #PENALTY NORTHERNIL illegal cut to the NORTHERNIL0, NO PLAY, TEAM SAFETY
            m = match(penalty_team_noplay_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
        end
    elseif occursin(team_penalty_junk_name, txt)
        if DEBUG_PENALTY println( "  Trying: team_penalty_junk_name") end
        for penalty in penalty_list_occurred, team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            
            team_penalty_junk_name_regex = 
            Regex("$team $penalties_regex_txt,?.+(?: UNS:)? ($penalty) +\\($name_penalty_regex\\)")
            #MIAMI OH Penalty, Kimpler,Ben at BSU31 Kimpler,Ben return UNS: Unsportsmanlike Conduct (Ivan Pace Jr.) to the BalSt 46
            m = match(team_penalty_junk_name_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
        end
    elseif occursin(team_penalty_junk_name_ejected, txt)
        if DEBUG_PENALTY println( "  Trying: team_penalty_junk_name_ejected") end
        for team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            
            team_penalty_junk_name_ejected_regex = 
            Regex("$team $penalties_regex_txt,?.+\\($name_penalty_regex ejected for targeting\\)")
            #WESTRN MICHIGAN Penalty to the CMich 27 for a 1ST down. (L. Ekwoge ejected for targeting).
            m = match(team_penalty_junk_name_ejected_regex, txt)
            if !isnothing(m)
                push!(foul_type, "Targeting")
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, m[2])
                break
            end
        end
    elseif occursin(offsetting, txt)
        if DEBUG_PENALTY println( "  Trying: offsetting") end
        for penalty in penalty_list_occurred
            
            offsetting_regex = 
            Regex("$penalties_regex_txt,? ($penalty) [Oo]ff-?[Ss]etting")
            #Penalty, Unsportsmanlike Conduct Off-Setting to the Kent 20
            m = match(offsetting_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[1])
                push!(foul_type, m[1])
                push!(foul_status, "offseting")
                push!(foul_status, "offseting")
                push!(foul_team, offense)
                push!(foul_team, defense)
                push!(foul_transgressor, "No data")
                push!(foul_transgressor, "No data")
                break
            end
        end
    elseif occursin(team_penalty_on_pat, txt)
        if DEBUG_PENALTY println( "  Trying: team_peanlty_on_pat") end
        for penalty in penalty_list_occurred, team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            
            team_peanlty_on_pat_regex = 
            Regex("$team ($penalty) $penalties_regex_txt,? on PAT")
            #NORTH TEXAS Illegal Formation Penalty 
            m = match(team_peanlty_on_pat_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
        end
    elseif occursin(team_penalty_lossofdown, txt)
        if DEBUG_PENALTY println( "  Trying: team_penalty_lossofdown") end
        for penalty in penalty_list_occurred, team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            
            team_penalty_lossofdown_regex = 
            Regex("$team $penalties_regex_txt,? ($penalty),? loss of down")
            #PURDUE Penalty, Intentional Grounding, loss of down
            m = match(team_penalty_lossofdown_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
        end
    elseif occursin(penalty_x2_team_x2, txt)
        if DEBUG_PENALTY println( "  Trying: penalty_x2_team_x2") end
        for penalty1 in penalty_list_occurred, penalty2 in penalty_list_occurred, team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            
            penalty_x2_team_x2_regex = 
            Regex("$penalties_regex_txt,? $team(?: UNS:)? ($penalty1) $team(?: UNS:)? ($penalty2)")
            #PENALTY PUR Delay Of Game PUR UNS: Unsportsmanlike Conduct 20 yards from OSU16 to OSU36. NO PLAY.
            m = match(penalty_x2_team_x2_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_type, m[4])
                push!(foul_status, "enforced")
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                push!(foul_transgressor, "No data")
                break
            end
        end
    elseif occursin(team_penalty_stop, txt)
        if DEBUG_PENALTY println( "  Trying: team_penalty_stop") end
        for penalty in penalty_list_occurred, team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            

            team_penalty_stop_regex = 
            Regex("$team $penalties_regex_txt,? ($penalty)\\.")
            #SOUTHERN MISS Penalty, Unsportsmanlike Conduct.
            m = match(team_penalty_stop_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
        end
    elseif occursin(team_foul_penalty_phrase, txt)
        if DEBUG_PENALTY println("  Trying: team_foul_penalty_phrase") end
        for penalty in penalty_list_occurred, team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            

            team_foul_penalty_phrase_regex = 
            Regex("$team ($penalty) $penalties_regex_txt,? $end_phrase")
            #TEXAS A&M Personal Foul Penalty in the endzone, SAFETY.
            m = match(team_foul_penalty_phrase_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
        end
    elseif occursin(team_penalty_foul_phrase, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_foul_phrase") end
        for penalty in penalty_list_occurred, team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            
            team_penalty_foul_phrase_regex = 
            Regex("$team $penalties_regex_txt,? ($penalty) $end_phrase")
            #UNLV Penalty, False Start to the UNLV 18
            m = match(team_penalty_foul_phrase_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
        end
    elseif occursin(team_penalty_ballon_peanlty_foul_yards, txt)
        if DEBUG_PENALTY println("  Trying: team_penalty_ballon_peanlty_foul_yards") end
        for penalty in penalty_list_occurred, team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            

        team_penalty_ballon_peanlty_foul_yards_regex = 
            Regex("$team $penalties_regex_txt,? ball on .+ $penalties_regex_txt,? ($penalty) \\(-?\\d* [Yy]ards\\)")
            #ARIZONA Penalty, ball on ASU47, PENALTY offside (-5 Yards) to the Ariz 48
            m = match(team_penalty_ballon_peanlty_foul_yards_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
        end
    elseif occursin(penalty_noteam, txt)
        if DEBUG_PENALTY println("  Trying: penalty_noteam") end
        for penalty in penalty_list_occurred
            
            penalty_noteam_regex = 
            Regex("$penalties_regex_txt,? team ($penalty) \\d+")
            #Penalty team holding 6 yds to the Temp 0, NO PLAY, Team Safety
            m = match(penalty_noteam_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[1])
                push!(foul_status, "enforced")
                push!(foul_team, "No data")
                push!(foul_transgressor, "No data")
                break
            end
        end
    end

    if DEBUG_PENALTY println(m) end

    foul_type, foul_status, foul_team, foul_transgressor
end

############################################################################################################################################################
function rest_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_type_vec)
    penalties_regex_txt = "(?:Penalty|PENALTY)"

    #I think this is a temp problem and won't occur when process_game calls it... maybe
    off_abbrv_catch = replace(off_abbrv_catch, "\xc9" => "É")
    off_abbrv_catch = replace(off_abbrv_catch, "\xe9" => "é")
    def_abbrv_catch = replace(def_abbrv_catch, "\xc9" => "É")
    def_abbrv_catch = replace(def_abbrv_catch, "\xe9" => "é")
    
    penalty_penalty_case = r"(?:Penalty|PENALTY).+(?:Penalty|PENALTY)"
    penalty_team_team_case = r"(?:Penalty|PENALTY) [A-Z&]+ .+ \(TEAM\)"
    penalty_team_number_case = r"(?:Penalty|PENALTY) [A-Z&-]+(?:20\d+|\(\d\))?,?.+(?:\((?:-| )?\d+|\d+ y(?:ar)?ds?)"
    # penalty_team_name_case = r"(?:Penalty|PENALTY) (?:[A-Z&_-]+(?:\d+|\(\d\))?|[A-Z]+[a-z]+|[A-Z][a-z]+[A-Z]?\d*),? .+ \((?: |,|#\d+ )?(?:de )?[A-Z]+[a-z]*"
    penalty_team_name_case = r"(?:Penalty|PENALTY) (?:[A-Z&_-]+(?:\d+|\(\d\))?|[A-Z]+[a-z]+|[A-Z][a-z]+[A-Z]?\d*),? .+ \((?: |,|#\d+ )?(?:de )?[A-Z]*[a-z]*"
    team_peanlty_team_case = r"(?:[A-Z&]+|[A-Z][a-z]+)+ +(?:Penalty|PENALTY).+\(TEAM\)"
    team_penalty_number_case = r"(?:[A-Z&]+|[A-Z][a-z]+)+ +(?:Penalty|PENALTY).+ (?:\((?:-| )?\d+|\d+ yards)"
    team_penalty_name_case = r"(?:[A-Z&]+(?:\d+|\(\d\))?|[A-Z]+[a-z]+|[A-Z][a-z]+[A-Z]?\d*) (?:Penalty|PENALTY).+\(?[A-Z]+[a-z]*"
    team_penalty_na_case = r"(?:[A-Z&]+(?:\d+|\(\d\))?|[A-Z]+[a-z]+|[A-Z][a-z]+[A-Z]?\d*) (?:Penalty|PENALTY).+\(N\/?A"
    team_penalty_yards_case = r"(?:[A-Z&]+(?:\d+|\(\d\))?|[A-Z]+[a-z]+|[A-Z][a-z]+[A-Z]?\d*) (?:Penalty|PENALTY).+\( [Yy]ards\)"
    
    
        
    penalty_list_occurred = Vector{String}()#[]
    for penalty in penalty_type_vec
        # if occursin(Regex("$penalties_regex_txt (?:$team1|$team2) ($penalty)"), txt)
        # if occursin(Regex("(?:$team1|$team2|$team3) $penalty"), txt)
        if occursin(Regex("$penalty"), txt)
            push!(penalty_list_occurred, penalty)
        end
    end
    if DEBUG_PENALTY println("penalty_list_occurred: $penalty_list_occurred") end

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]
    
    if occursin(penalty_penalty_case, txt)
        if DEBUG_PENALTY println(" calling: penalty_penalty_case_aux") end
        foul_type, foul_status, foul_team, foul_transgressor = penalty_penalty_case_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    #Major case change
    if isempty(foul_type) && occursin(penalty_team_team_case, txt)
        if DEBUG_PENALTY println(" calling: penalty_team_team_case_aux") end
        foul_type, foul_status, foul_team, foul_transgressor = penalty_team_team_case_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    #Major case change
    if isempty(foul_type) && occursin(penalty_team_number_case, txt)
        if DEBUG_PENALTY println(" calling: penalty_team_number_case_aux") end
        foul_type, foul_status, foul_team, foul_transgressor = penalty_team_number_case_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    #Major case change
    if isempty(foul_type) && occursin(penalty_team_name_case, txt)
        if DEBUG_PENALTY println(" calling: penalty_team_name_case_aux") end
        foul_type, foul_status, foul_team, foul_transgressor = penalty_team_name_case_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    #Major case change
    if isempty(foul_type) && occursin(team_peanlty_team_case, txt)
        if DEBUG_PENALTY println(" calling: team_peanlty_team_case_aux") end
        foul_type, foul_status, foul_team, foul_transgressor = team_peanlty_team_case_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    #Major case change
    if isempty(foul_type) && occursin(team_penalty_na_case, txt)
        if DEBUG_PENALTY println(" calling: team_penalty_na_case_aux") end
        foul_type, foul_status, foul_team, foul_transgressor = team_penalty_na_case_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    #Major case change
    if isempty(foul_type) && occursin(team_penalty_name_case, txt)
        if DEBUG_PENALTY println(" calling: team_penalty_name_case_aux") end
        foul_type, foul_status, foul_team, foul_transgressor = team_penalty_name_case_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    #Major case change
    if isempty(foul_type) && occursin(team_penalty_number_case, txt)
        if DEBUG_PENALTY println(" calling: team_penalty_number_case_aux") end
        foul_type, foul_status, foul_team, foul_transgressor = team_penalty_number_case_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    #Major case change
    if isempty(foul_type) && occursin(team_penalty_yards_case, txt)
        if DEBUG_PENALTY println(" calling: team_penalty_yards_case_aux") end
        foul_type, foul_status, foul_team, foul_transgressor = team_penalty_yards_case_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end

    if isempty(foul_type)
        if DEBUG_PENALTY println("Missed trying specialcase_aux") end
        foul_type, foul_status, foul_team, foul_transgressor = specialcase_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_list_occurred)
    end
    
    foul_type, foul_status, foul_team, foul_transgressor
end
#END rest_aux section



############################################################################################################################################################
#BEGIN penalized_aux section
function  penalized_aux(txt, offense, defense, off_abbrv_catch, def_abbrv_catch, penalty_type_vec)

    penalized_regex = "(?:PENALIZED|Penalized)"
    penalized_penalty_regex = Regex("[A-Za-z]+-(?:[A-Z][a-z '\\.]+)+$penalized_regex")
    penalized_nopenalty_regex = Regex("[A-Za-z]+-$penalized_regex -?\\d+ yards for")
    name_regex_new = "((?:(?:[A-Z\\p{Lu}][a-z\\p{Ll}'-]+)+|(?:[A-Z\\p{Lu}]\\.)+)(?: de| von)? (?:(?:[A-Z\\p{Lu}][a-z\\p{Ll}'-]+)+)(?: Jr\\.| III| II)?)"

    foul_type = Vector{String}()#[]
    foul_status = Vector{String}()#[]
    foul_team = Vector{String}()#[]
    foul_transgressor = Vector{String}()#[]

    # println("penalty = $penalty")

    penalty_list_occurred = Vector{String}()#[]
    for penalty in penalty_type_vec
        # if occursin(Regex("$penalties_regex_txt (?:$team1|$team2) ($penalty)"), txt)
        # if occursin(Regex("(?:$team1|$team2|$team3) $penalty"), txt)
        if occursin(Regex("$penalty"), txt)
            push!(penalty_list_occurred, penalty)
        end
    end
    if DEBUG_PENALTY println("penalty_list_occurred: $penalty_list_occurred") end

    if occursin(penalized_penalty_regex, txt)
        if DEBUG_PENALTY println("  Trying: penalized_penalty") end
        for penalty in penalty_list_occurred, team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            
            team_penalty_regex = 
            Regex("$team-$name_regex_new $penalized_regex -?\\d+ yards for ($penalty)")
            # println("Regex = $team_penalty_regex")
            #Penalty team holding 6 yds to the Temp 0, NO PLAY, Team Safety
            m = match(team_penalty_regex, txt)
            # println("m = $m")
            if !isnothing(m)
                push!(foul_type, m[3])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, m[2])
                break
            end
        end
    elseif occursin(penalized_nopenalty_regex, txt)
        if DEBUG_PENALTY println("  Trying: penalized_nopenalty") end
        for penalty in penalty_list_occurred, team in sort([off_abbrv_catch, def_abbrv_catch], rev=true)
            
            team_penalty_regex = 
            Regex("$team-$penalized_regex -?\\d+ yards for ($penalty)")
            #Penalty team holding 6 yds to the Temp 0, NO PLAY, Team Safety
            m = match(team_penalty_regex, txt)
            if !isnothing(m)
                push!(foul_type, m[2])
                push!(foul_status, "enforced")
                push!(foul_team, get_team_name((m[1]), offense, off_abbrv_catch, defense, def_abbrv_catch))
                push!(foul_transgressor, "No data")
                break
            end
        end
    end

    foul_type, foul_status, foul_team, foul_transgressor
end

#END penalized_aux section