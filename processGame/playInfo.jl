function play_info(cols)
    # Plays to get: 
    #  Blocked Field Goal Touchdown (need more examples to make regexs for more than the main case) 
    #  Pass (not sure what to make of this, only two observations... so come back later)

    # Pretty sure I can remove the FG variable. I think I changed my mind on how to handle that. Was FG = true/false (I think).
    # Fieldgoals: merge recoverer and returner (change returner to recoverer... I think).

    #Any play that involve a touchdown needs:
    # passer, receiver, interceptor, runner, forcer, recoverer, tackler, PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver
    #since a 2-pt conversion can be fumbled/intercepted and returned for a score.

    #Have I accounted for Onside kicks? Don't see it.

    play_text = cols[1]
    play_type = cols[2]
    offense  = cols[3]
    defense  = cols[4]

    if !ismissing(play_text)
        # println("Play text before:\n$(play_text)")
        play_text = replace(play_text, r"\s{2,}"=>" ")
        play_text = replace(play_text, "\xc9" => "É")
        play_text = replace(play_text, "\xe9" => "é")
        # println("Play text after:\n$(play_text)")
    else
        play_text = ""
    end

    school_colors = CSV.File("../school_colors/school_colors.csv", delim=';') |> DataFrame
    off_abbrv = replace(school_colors[school_colors.School .== offense, :Abbreviation_regex][1], "("=>"(?:")
    def_abbrv = replace(school_colors[school_colors.School .== defense, :Abbreviation_regex][1], "("=>"(?:")
    # println("def_abbrv = $(def_abbrv)")
    #Must go after school_colors above
    offense = replace(offense, "\xc9" => "É")
    offense = replace(offense, "\xe9" => "é")
    defense = replace(defense, "\xc9" => "É")
    defense = replace(defense, "\xe9" => "é")   
    off_abbrv = replace(off_abbrv, "\xc9" => "É")
    off_abbrv = replace(off_abbrv, "\xe9" => "é")
    def_abbrv = replace(def_abbrv, "\xc9" => "É")
    def_abbrv = replace(def_abbrv, "\xe9" => "é")
    
    
    # println("$(play_type)\n$(play_text)\n")

    runner = missing # Player name
    passer = missing # Player name
    receiver = missing # Player name
    interceptor = missing # Player name
    PAT_kicker = missing # Player name
    PAT_type = missing # made, missed, blocked, failed
    two_point = missing # true/false
    two_point_type = missing # run, pass, failed
    two_point_runner = missing # Player name
    two_point_passer = missing # Player name
    two_point_receiver = missing # Player name
    kicker = missing # Player name
    kick_type = missing #touchback, returned, fair-catch, on-side:kicking/receiving, unknown, ?fumbled
    returner = missing # Player name
    recoverer = missing # Player name on blocked FG/punts/fumbles...
    blocker = missing # Player name
    FG_type = missing # made, missed, blocked, failed, returned
    punter = missing # Player name
    punt_type  = missing #  blocked, failed
    tackler = missing # Player name
    forcer = missing # Player name
    fumbler = missing # Player name
    timeout_team = missing # Team name taking timeout
    timeout_time = missing # Time of timeout

    if DEBUG_PLAY_INFO println("play_info: $play_text") end

    #Rush plays
    if play_type == "Rushing Touchdown"
        runner, PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = play_rush_td(play_text)
    elseif play_type == "Rush"     
        runner = play_rush(play_text)
    elseif play_type == "Fumble Recovery (Opponent)"
        fumbler, forcer, recoverer = play_fumble_recovery_opponent([play_text, offense, defense, off_abbrv, def_abbrv])
    elseif play_type == "Fumble Recovery (Own)"
        fumbler, forcer, recoverer = play_fumble_recovery_own(play_text)
    elseif play_type == "Fumble Return Touchdown"
        passer, receiver, interceptor, runner, forcer, recoverer, tackler, PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = play_fumble_return_td(play_text)

    #Pass plays
    elseif play_type == "Pass Reception"
        passer, receiver = play_reception(play_text)
    elseif play_type == "Pass Incompletion"
        passer, receiver, forcer = play_incomplete(play_text)
    elseif play_type == "Passing Touchdown"
        passer, receiver, PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = play_pass_td(play_text)
    elseif play_type == "Interception"
        passer, receiver, interceptor = play_interception(play_text)
    elseif play_type == "Pass Interception Return"
        passer, interceptor, receiver = play_interception_returned(play_text)
    elseif play_type == "Interception Return Touchdown"
        passer, interceptor, PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = play_interception_return_td(play_text)
    elseif play_type == "Sack"
        passer, tackler = play_sack(play_text)

    #Kickoffs
    elseif play_type == "Kickoff" || play_type == "Kickoff Return (Offense)"
        kicker, kick_type, returner = play_kickoff(play_text)
    elseif play_type == "Kickoff Return Touchdown"
        kicker, returner, PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = play_kickoff_return_td(play_text)
    ##Onside?

    #Fieldgoals
    elseif play_type == "Blocked Field Goal Touchdown"
        kicker, recoverer, blocker, PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver, FG, FG_type = play_blocked_fieldgoal_return_td(play_text)
    elseif play_type == "Missed Field Goal Return Touchdown"
        kicker, returner, PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver, FG, FG_type = play_missed_fieldgoal_return_td(play_text)
    
    elseif play_type == "Field Goal Good"
        kicker, FG_type = play_fieldgoal_good(play_text)
    elseif play_type == "Field Goal Missed"
        kicker, FG_type = play_fieldgoal_missed(play_text)    
    elseif play_type == "Missed Field Goal Return"
        kicker, returner, FG_type = play_fieldgoal_missed_return(play_text)    
    # elseif play_type == "Missed Field Goal Return Touchdown"
    #     kicker, returner, FG_type = play_fieldgoal_missed_return_td(play_text)
    elseif play_type == "Blocked Field Goal"
        kicker, blocker, returner, FG_type = play_blocked_fieldgoal(play_text)

    #Punts
    elseif play_type == "Punt"
        punter, returner, punt_type = play_punt(play_text)
    elseif play_type == "Punt Return Touchdown"
        punter, receiver, returner, blocker, PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver, punt_type = play_punt_return_td(play_text)     
    elseif play_type == "Blocked Punt"
        punter, blocker, returner, punt_type = play_blocked_punt(play_text)
    elseif play_type == "Blocked Punt Touchdown"
        punter, returner, blocker, PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver, punt_type = play_blocked_punt_td(play_text)
    
    #Other scoring
    elseif play_type == "Two Point Pass"
        two_point, two_point_type, two_point_passer, two_point_receiver = play_pass_twopoint(play_text)
    elseif play_type == "Two Point Rush"
        two_point, two_point_type, two_point_runner = play_rush_twopoint(play_text)
    elseif play_type == "Defensive 2pt Conversion"
        two_point_runner = play_2pt_conversion(play_text)
    elseif play_type == "Safety"
        passer, runner, tackler = play_safety(play_text)

    #Timeout
    elseif play_type == "Timeout"
        timeout_team, timeout_time = play_timeout(play_text)
    end



    # [runner, passer, receiver, interceptor, PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver,
    #     kicker, kick_type, returner, recoverer, blocker, FG_type, punter, punt, punt_type, tackler, forcer, fumbler]
    [runner, passer, receiver, interceptor, tackler, forcer, fumbler, recoverer, PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver,
        kicker, kick_type, returner, blocker, FG_type, punter, punt_type, timeout_team, timeout_time]
end

# play_info aux functions #####################################################################################################################

function play_rush_td(cols)
    play_text = cols

    runner = missing # Player name
    PAT_kicker = missing # Player name
    PAT_type = missing # made, missed, blocked, failed
    two_point = missing # true/false
    two_point_type = missing # rush, pass, failed
    two_point_runner = missing # Player name
    two_point_passer = missing # Player name
    two_point_receiver = missing # Player name

    # name_regex = "(((?:[A-Z\\p{Lu}'-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+|(?:de))|(?:[A-Z\\p{Lu}-]\\.?)?\\s?)+)" #most general name regex

    rush_run_regex = Regex("$(name_regex) ?run")
    rush_digit_run_regex = Regex("$(name_regex) ?\\d+")
    
    if occursin(rush_run_regex, play_text)
        runner = strip(match(rush_run_regex, play_text)[1])
        PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = points_after(play_text)
    elseif occursin(rush_digit_run_regex, play_text)
        runner = strip(match(rush_digit_run_regex, play_text)[1])
        PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = points_after(play_text)
    else
        "Error"
    end
    
    [runner, PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver]
end

function play_rush(cols)
    play_text = cols

    runner = missing # Player name
    
    #play_text = replace(play_text, r"N/A"=>"No Data")

    #kicker_single_initial_regex = r"^([A-Z\p{Lu}-]\s*(?:[A-Z\p{Lu}-][a-z\p{Ll}A-Z&\p{Lu}'\.-]+\s?)+)\s*punt for"
    runner_regex = Regex("^$(name_regex)(?:run|rush)")
    runner_specialcase1_regex = Regex("- 2b run for")
    runner_specialcase2_regex = Regex("[Tt]eam run for")
    runner_specialcase3_regex = Regex("Penalty, Offensive holding \\($(name_regex)\\) to the")

    if ismissing(play_text)
        runner = "No Data"
    else
        if occursin(runner_specialcase1_regex, play_text)
            runner = "No Data"
        elseif occursin(runner_specialcase2_regex, play_text) || occursin(runner_specialcase3_regex, play_text) 
            runner = "No Data"
        elseif occursin(runner_regex, play_text)
            runner = strip(match(runner_regex, play_text)[1])
        else
            ##########################################################################################################
            runner = "Reprocess2mnyErrors2catch"
            # @warn "Fcn: play_rush" game play_text
            ##########################################################################################################
        end
    end

    runner
end

function play_fumble_recovery_opponent(cols)
    play_text = cols[1]
    offense = cols[2]
    defense = cols[3]
    off_abbrv = cols[4]
    def_abbrv = cols[5]

    # println("offense = $(offense), defense = $(defense)")

    fumbler = missing # Player name
    recoverer = missing # Player name
    forcer = missing # Player name

    #kicker_single_initial_regex = r"^([A-Z\p{Lu}-]\s*(?:[A-Z\p{Lu}-][a-z\p{Ll}A-Z&\p{Lu}'\.-]+\s?)+)\s*punt for"
    fumbler_nodata_regex = r"\d+\s*,?\s*fumbled"
    fumbler_specialcase1_regex = Regex("^$(name_regex)\\d+ [Yy][Dd] Fumble")
    fumbler_specialcase2_regex = Regex("fumble by $(name_regex)")
    # fumbler_regex = Regex("$(name_regex)\\s*fumbled")
    fumbler_regex = Regex("$(name_regex) *fumbled")
    # recoverer_nodata_regex = Regex("recovered by")
    recoverer_def_regex = Regex("recovered by $(def_abbrv) $(name_regex)")
    recoverer_regex = Regex("recovered by $(name_regex)")
    forcer_regex = Regex("forced by $(name_regex)")
    
    # println("Called: play_fumble_recovery_opponent")
    if occursin(fumbler_nodata_regex, play_text)
        # println("  Trying: fumbler_nodata_regex")
        fumbler = "No Data"
    elseif occursin(fumbler_specialcase1_regex, play_text)
        # println("  Trying: fumbler_specialcase1_regex")
        fumbler = strip(match(fumbler_specialcase1_regex, play_text)[1])
    elseif occursin(fumbler_specialcase2_regex, play_text)
        # println("  Trying: fumbler_specialcase2_regex")
        fumbler = strip(match(fumbler_specialcase2_regex, play_text)[1])
    elseif occursin(fumbler_regex, play_text)
        # println("  Trying: fumbler_regex")
        fumbler = strip(match(fumbler_regex, play_text)[1])
    else
        fumbler = "RELOOK AT DATA"
    end
    if occursin(recoverer_def_regex, play_text)
        # println("  Trying: recoverer_def_regex")
        recoverer = strip(match(recoverer_def_regex, play_text)[1])
    elseif occursin(recoverer_regex, play_text)
        # println("  Trying: recoverer_regex")
        recoverer = strip(match(recoverer_regex, play_text)[1])
    else
        recoverer = "No Data"
    end
    if occursin(forcer_regex, play_text)
        # println("  Trying: forcer_regex")
        forcer = strip(match(forcer_regex, play_text)[1])
    end
    [fumbler, forcer, recoverer]
end

function play_fumble_recovery_own(cols)
    play_text = cols

    fumbler = missing # Player name
    recoverer = missing # Player name
    forcer = missing # Player name

    #kicker_single_initial_regex = r"^([A-Z\p{Lu}-]\s*(?:[A-Z\p{Lu}-][a-z\p{Ll}A-Z&\p{Lu}'\.-]+\s?)+)\s*punt for"
    fumbler_nodata_regex = r"\d+\s*,?\s*fumbled"
    fumbler_specialcase1_regex = Regex("$(name_regex)\\d+ [Yy][Dd] Fumble")#r"^((?:[A-Z\p{Lu}-][a-z\p{Ll}A-Z&\p{Lu}'\.-]+\s?)+)\d+ [Yy][Dd] Fumble"
    fumbler_regex = Regex("$(name_regex)fumbled")#r"((?:[A-Z\p{Lu}-][a-z\p{Ll}A-Z&\p{Lu}'\.-]+\s?)+)\s*fumbled"
    # recoverer_nodata_regex = Regex("recovered by $(name_regex)(?:$|,)")#r"recovered by (?:[A-Z\p{Lu}-][a-z\p{Ll}A-Z&\p{Lu}'\.-]+|de)+\s*($|,)"
    recoverer_nodata_regex = r"recovered by (((?:[A-Z\\p{Lu}'-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+|(?:de))|(?:[A-Z\\p{Lu}-]\\.?)?\\s?)+)($|,)"
    recoverer_regex = Regex("recovered by $(name_regex)")#r"recovered by (?:[A-Z\p{Lu}-][a-z\p{Ll}A-Z&\p{Lu}'\.-]+|de)+ (((?:[A-Z\p{Lu}-][a-z\p{Ll}A-Z&\p{Lu}'\.-]+|de)\s?)+)"
    forcer_regex = Regex("forced by $(name_regex)")
    
    if occursin(fumbler_nodata_regex, play_text)
        fumbler = "No Data"
    elseif occursin(fumbler_specialcase1_regex, play_text)
        fumbler = strip(match(fumbler_specialcase1_regex, play_text)[1])
    elseif occursin(fumbler_regex, play_text)
        fumbler = strip(match(fumbler_regex, play_text)[1])
    else
        fumbler = "RELOOK AT DATA"
    end
    if occursin(recoverer_nodata_regex, play_text)
        recoverer = "No Data"
    elseif occursin(recoverer_regex, play_text)
        recoverer = strip(match(recoverer_regex, play_text)[1])
    end
    if occursin(forcer_regex, play_text)
        forcer = strip(match(forcer_regex, play_text)[1])
    end
    [fumbler, forcer, recoverer]
end

function play_fumble_return_td(cols)
    play_text = cols

    passer = missing # Player name
    receiver = missing # Player name
    interceptor = missing # Player name
    runner = missing # Player name
    forcer = missing # Player name
    recoverer = missing # Player name
    tackler = missing # Player name
    PAT_kicker = missing # Player name
    PAT_type = missing # made, missed, blocked, failed
    two_point = missing # true/false
    two_point_type = missing # rush, pass, failed
    two_point_runner = missing # Player name
    two_point_passer = missing # Player name
    two_point_receiver = missing # Player name
    
    fumble_return_regex = r"Fumble Return"
    fumble_return_recoverer_regex = Regex("$(name_regex)\\d")
    fumble_return_recoverer_return_regex = Regex("$(name_regex)\\d+ Yd Fumble Return")
    
    fumble_recovery_regex = r"Fumble Recovery"
    fumble_recovery_recoverer_regex = Regex("$(name_regex)(?:(?:\\d)|(?:Fumble Recovery in end zone))")

    sacked_passer_regex = Regex("$(name_regex)sacked")
    sacked_tackler_regex1 = Regex("by $(name_regex)by for")
    sacked_tackler_regex2 = Regex("by $(name_regex),")
    sacked_recoverer_regex1 = Regex("recovered by $(name_regex)(?:,|(?:at the)|(?:\\d))")
    sacked_recoverer_regex2 = Regex("fumbled?,? $(name_regex)\\d")

    run_for_regex = r"run for"
    run_for_runner_regex = Regex("^$(name_regex)run for")
    run_for_forcer_regex = Regex("forced by $(name_regex),")
    run_for_recoverer_regex = Regex("recovered by $(name_regex)")

    pass_complete_regex = r"pass complete"
    pass_complete_passer_regex = Regex("^$(name_regex)run for")
    pass_complete_receiver_regex = Regex("pass complete to $(name_regex)for")
    pass_complete_forcer_regex = Regex("forced by $(name_regex),")
    pass_complete_recoverer_regex = Regex("recovered by $(name_regex)")

    pass_intercepted_regex = r"pass intercepted"
    pass_intercepted_passer_regex = Regex("^$(name_regex)pass intercepted")
    pass_intercepted_interceptor_regex = Regex("pass intercepted, $(name_regex)")
    pass_intercepted_forcer_regex = Regex("forced by $(name_regex),")
    pass_intercepted_recoverer_regex = Regex("recovered by $(name_regex)")

    #Got to rewrite this: check for who recovered, then check if pass/sack/etc
    if occursin(fumble_return_regex, play_text)
        # println("Block 1")
        if occursin(fumble_return_recoverer_regex, play_text)
            recoverer = strip(match(fumble_return_recoverer_regex, play_text)[1])
        else
            recoverer = strip(match(fumble_return_recoverer_return_regex, play_text)[1])
        end
        PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = points_after(play_text)
    elseif occursin(fumble_recovery_regex, play_text)
        # println("Block 2")
        recoverer = strip(match(fumble_recovery_recoverer_regex, play_text)[1])
        PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = points_after(play_text)
    elseif occursin("sacked", play_text)
        # println("Block 3")
        passer = strip(match(sacked_passer_regex, play_text)[1])
        if occursin(sacked_tackler_regex1, play_text)
            tackler = strip(match(sacked_tackler_regex1, play_text)[1])
        elseif occursin(sacked_tackler_regex2, play_text)
            tackler = strip(match(sacked_tackler_regex2, play_text)[1])
        else
            "No data"
        end
        if occursin(sacked_recoverer_regex1, play_text)
            recoverer = strip(match(sacked_recoverer_regex1, play_text)[1])
        elseif occursin(sacked_recoverer_regex2, play_text)
            recoverer = strip(match(sacked_recoverer_regex2, play_text)[1])
        else
            "No data"
        end
        PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = points_after(play_text)
    elseif occursin(run_for_regex, play_text)
        # println("Block 4")
        if occursin(run_for_runner_regex, play_text)
            runner = strip(match(run_for_runner_regex, play_text)[1])
        elseif occursin(run_for_forcer_regex, play_text)
            forcer = strip(match(run_for_forcer_regex, play_text)[1])
        elseif occursin(run_for_recoverer_regex, play_text)
            recoverer = strip(match(run_for_recoverer_regex, play_text)[1])
        end
        PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = points_after(play_text)
    elseif occursin(pass_complete_regex, play_text)
        # println("Block 5")
        if occursin(pass_complete_passer_regex, play_text)
            passer = strip(match(pass_complete_passer_regex, play_text)[1])
        elseif occursin(pass_complete_receiver_regex, play_text)
            receiver = strip(match(pass_complete_receiver_regex, play_text)[1])
        elseif occursin(pass_complete_forcer_regex, play_text)
            forcer = strip(match(pass_complete_forcer_regex, play_text)[1])            
        elseif occursin(pass_complete_recoverer_regex, play_text)
            recoverer = strip(match(pass_complete_recoverer_regex, play_text)[1])
        end
        PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = points_after(play_text)
    elseif occursin(pass_intercepted_regex, play_text)
        # println("Block 6")
        if occursin(pass_intercepted_passer_regex, play_text)
            passer = strip(match(pass_intercepted_passer_regex, play_text)[1])
        elseif occursin(pass_intercepted_interceptor_regex, play_text)
            interceptor = strip(match(pass_intercepted_interceptor_regex, play_text)[1])
        elseif occursin(pass_intercepted_forcer_regex, play_text)
            forcer = strip(match(pass_intercepted_forcer_regex, play_text)[1])            
        elseif occursin(pass_intercepted_recoverer_regex, play_text)
            recoverer = strip(match(pass_intercepted_recoverer_regex, play_text)[1])
        end
        PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = points_after(play_text)
    else
        "Error"
        @warn "Fcn: play_fumble_return_td" game play_text
    end
    
    #[passer, receiver, interceptor, runner, forcer, recoverer, tackler, PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver, punt, punt_type]
    [passer, receiver, interceptor, runner, forcer, recoverer, tackler, PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver]
end

function play_reception(cols)
    play_text = cols

    passer = missing # Player name
    receiver = missing # Player name

    passer_regex = Regex("^$(name_regex)pass")
    passer_specialcase1_regex = Regex("^$(name_regex)fumbled snap")
    passer_specialcase2_regex = Regex("pass from $(name_regex)")
    passer_specialcase3_regex = Regex("^to")
    # receiver_specialcase1_regex = Regex("^$(name_regex)\\d+\\s*[Yy][Dd]\\s*pass from")
    receiver_specialcase1_regex = Regex("^$(name_regex)\\d+ *[Yy][Dd] *pass from")
    receiver_regex = Regex("(?:complete to|pass to|pass complete for a SAFETY to|^to) $(name_regex)")
            
    if ismissing(play_text)
        passer ="No Data"
    else
        if occursin("kickoff",play_text)
            play_text, junk = split(play_text, " kickoff")
            #println(play_text)
        end

        if occursin(r" intercepted ", play_text)
            passer = "ERROR in DATA"
        elseif occursin(r" run ", play_text)
            passer = "ERROR in DATA"
        else
            if occursin(passer_regex, play_text)
                passer = strip(match(passer_regex, play_text)[1])
            elseif occursin(passer_specialcase1_regex, play_text)
                passer = strip(match(passer_specialcase1_regex, play_text)[1])
            elseif occursin(passer_specialcase2_regex, play_text)
                passer = strip(match(passer_specialcase2_regex, play_text)[1])
            elseif occursin(passer_specialcase3_regex, play_text)
                passer = "No Data"
            end

            if occursin(receiver_specialcase1_regex, play_text)
                receiver = strip(match(receiver_specialcase1_regex, play_text)[1])
            elseif occursin(receiver_regex, play_text)
                receiver = strip(match(receiver_regex, play_text)[1])
            else
                receiver = "No Data"
            end
        end
    end

    [passer, receiver]
end

function play_incomplete(cols)
    play_text = cols

    passer = missing # Player name
    receiver = missing # Player name
    forcer = missing # Player name

    passer_regex = Regex("^$(name_regex)pass")
    passer_lastfirst_regex = Regex("^$(name_lastfirst_regex) pass")
    passer_specialcase1_regex = Regex("^$(name_regex)fumbled snap")
    receiver_specialcase1_regex = r"(?:pass incomplete|incomplete pass)(?:$|,|.)"
    receiver_specialcase2_regex = r"pass incomplete (?:[A-Z\\p{Lu}-]+\s?)+ (?:Penalty|punt)"
    receiver_specialcase3_regex = r"pass incomplete (?:\(|for a )"
    receiver_regex = Regex("(?:incomplete to|incomplete|intended for) $(name_regex)")
    forcer_regex = Regex("broken up by $(name_regex)")
    incomplete_pass_regex = Regex("$(name_regex) incomplete pass")
    
    # play_text = replace(play_text, r"\s+-\s+"=>" ")
    
    if ismissing(play_text)
        passer ="No Data"
    elseif occursin(r" complete ", play_text)
        passer = "ERROR in DATA"
    elseif occursin(r" run ", play_text)
        passer = "ERROR in DATA"
    elseif play_text == "#NAME?"
        passer = "ERROR in DATA"
    elseif occursin(r"^(?:[A-Z\\p{Lu}-]+\s?)+ Penalty", play_text)
        passer = "ERROR in DATA"
    else
        play_text = replace(play_text, r"N/A"=>"No Data")

        if occursin(passer_regex, play_text)
            passer = strip(match(passer_regex, play_text)[1])
        elseif occursin(passer_lastfirst_regex, play_text)
            passer = strip(match(passer_lastfirst_regex, play_text)[1])
            lastpart, firstpart = split(passer, ",")
            passer = strip(firstpart)*" "*strip(lastpart)
        elseif occursin(passer_specialcase1_regex, play_text)
            passer = strip(match(passer_specialcase1_regex, play_text)[1])
        end

        if occursin(receiver_regex, play_text)
            receiver = strip(match(receiver_regex, play_text)[1])
        elseif occursin(receiver_specialcase1_regex, play_text)
            receiver = "No Data"
        elseif occursin(receiver_specialcase2_regex, play_text)
            receiver = "No Data"
        elseif occursin(receiver_specialcase3_regex, play_text)
            receiver = "No Data"
        else
            "Process Error"
        end

        if occursin(forcer_regex, play_text)
            forcer = strip(match(forcer_regex, play_text)[1])
        end

        if occursin(incomplete_pass_regex, play_text)
            passer = strip(match(incomplete_pass_regex, play_text)[1])
        end
    end

    [passer, receiver, forcer]
end

function play_pass_td(cols)
    play_text = cols

    # println("Play text: $play_text")

    passer = missing # Player name
    receiver = missing # Player name
    PAT_kicker = missing # Player name
    PAT_type = missing # made, missed, blocked, failed
    two_point = missing # true/false
    two_point_type = missing # rush, pass, failed
    two_point_runner = missing # Player name
    two_point_passer = missing # Player name
    two_point_receiver = missing # Player name

    complete_to_regex = r"pass complete to"
    complete_to_passer_regex = Regex("$(name_regex)pass complete to")
    complete_to_passer_nodata_regex = r"^pass complete to"
    complete_to_receiver_nodata_regex = Regex("pass complete to for")
    complete_to_receiver_regex = Regex("pass complete to $(name_regex) ?for")
    pass_from_regex = r"pass from"
    pass_from_passer_regex = Regex("pass from $(name_regex)")
    pass_from_receiver_regex = Regex("$(name_regex) \\d")
    pass_from_receiver_nodata_regex = r"\d+ [Yy][Dd] pass from"
    #specialcase_unicode_problem = "Tanner Lee pass complete to Dant"
    
    play_text = replace(play_text, "N/A"=>"No Data")
    play_text = replace(play_text, r"- \d+\w+"=>"No Data")

    if occursin(complete_to_regex, play_text)
        if occursin(complete_to_passer_nodata_regex, play_text)
            passer = "No Data"
        else
            passer = strip(match(complete_to_passer_regex, play_text)[1])
        end
        if occursin(complete_to_receiver_nodata_regex, play_text)
            receiver = "No Data"
        else
            receiver = strip(match(complete_to_receiver_regex, play_text)[1])
        end
        PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = points_after(play_text)
    elseif occursin(pass_from_regex, play_text)
        passer = strip(match(pass_from_passer_regex, play_text)[1])
        if occursin(pass_from_receiver_regex, play_text)
            receiver = strip(match(pass_from_receiver_regex, play_text)[1])
        elseif occursin(pass_from_receiver_nodata_regex, play_text)
            receiver = "No Data"
        else
            receiver = "Process Error"
        end
        PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = points_after(play_text)
    else
        "Error"
        @warn "Fcn: play_pass_td" game play_text
    end
    
    [passer, receiver, PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver]
end

function play_interception(cols)
    play_text = cols

    passer = missing # Player name
    receiver = missing # Player name
    interceptor = missing # Player name

    #kicker_single_initial_regex = r"^([A-Z\p{Lu}-]\s*(?:[A-Z\p{Lu}-][a-z\p{Ll}A-Z&\p{Lu}'\.-]+\s?)+)\s*punt for"
    passer_regex = Regex("^$(name_regex)pass")
    receiver_regex = Regex("intended for $(name_regex)")
    interceptor_regex = Regex("intercepted by $(name_regex)RETURNED")
    
    if play_text == "pass intercepted"
        passer = "No Data"
    else
        passer = strip(match(passer_regex, play_text)[1])
        if occursin(receiver_regex, play_text)
            receiver = strip(match(receiver_regex, play_text)[1])
        end
        if occursin(interceptor_regex, play_text)
            interceptor = strip(match(interceptor_regex, play_text)[1])
        end
    end

    [passer, receiver, interceptor]
end

function play_interception_returned(cols)
    play_text = cols

    passer = missing # Player name
    interceptor = missing # Player name
    receiver = missing # Player name
    
    passer_regex = Regex("^$(name_regex)pass")
    interceptor_touchback_regex = Regex("intercepted, touchback. $(name_regex)return")
    interceptor_touchback_nodata_regex = r"intercepted, touchback.\s*return"
    interceptor_specialcase1_regex = r"intercepted for a 1ST down return"
    interceptor_specialcase2_regex = Regex("intercepted for a\\s*(?:1ST down|TD)?\\s*$(name_regex)return")
    interceptor_nodata_regex = r"intercepted\s*return"
    interceptor_by_regex = Regex("intercepted,? (?:by )?$(name_regex)(?:RETURNED|return|for|,|in)")
    interceptor_team_regex = Regex("intercepted by $(name_regex_nc) $(name_regex)")
    interceptor_regex = Regex("intercepted(?:\\.|,)? $(name_regex)(?:return|at)")
    receiver_regex = Regex("intended for $(name_regex)\\.")
    
    
    play_text = replace(play_text, r"\s+-\s+"=>" ")
    play_text = replace(play_text, r"N/A"=>"No Data")
    

    if occursin(r"incomplete", play_text)
        passer = "ERROR in DATA"
    else
        if occursin(passer_regex, play_text)
            passer = strip(match(passer_regex, play_text)[1])
        else
            passer = "No Data"
        end
        if occursin(interceptor_touchback_regex, play_text)
            interceptor = strip(match(interceptor_touchback_regex, play_text)[1])
        elseif occursin(interceptor_touchback_nodata_regex, play_text)
            interceptor = "No Data"
        elseif occursin(interceptor_nodata_regex, play_text)
            interceptor = "No Data"
        elseif occursin(interceptor_specialcase1_regex, play_text)
            interceptor = "No Data"
        elseif occursin(interceptor_specialcase2_regex, play_text)
            interceptor = strip(match(interceptor_specialcase2_regex, play_text)[1])
        elseif occursin(interceptor_by_regex, play_text)
            interceptor = strip(match(interceptor_by_regex, play_text)[1])
        elseif occursin(interceptor_team_regex, play_text)
            interceptor = strip(match(interceptor_team_regex, play_text)[1])
        elseif occursin(interceptor_regex, play_text)
            interceptor = strip(match(interceptor_regex, play_text)[1])
        else
            interceptor = "process error"
        end
    
        if occursin(receiver_regex, play_text)
            receiver = strip(match(receiver_regex, play_text)[1])
        end
    end

    [passer, interceptor, receiver]
end

function play_interception_return_td(cols)
    play_text = cols

    passer = missing # Player name
    interceptor = missing # Player name
    PAT_kicker = missing # Player name
    PAT_type = missing # made, missed, blocked, failed
    two_point = missing # true/false
    two_point_type = missing # rush, pass, failed
    two_point_runner = missing # Player name
    two_point_passer = missing # Player name
    two_point_receiver = missing # Player name

    td_return_regex = r"TD return for no gain for"
    td_return_passer_regex = Regex("$(name_regex)pass intercepted")
    td_return_name_regex = r"return for no gain for a TD"
    td_return_name_passer_regex = Regex("$(name_regex)pass intercepted for a TD")
    td_return_name_intercepter_regex = Regex("$(name_regex)return for \\d+ yds for a TD")
    td_return_noname_intercepter_regex = Regex("TD return for no gain for a TD")
    pass_intercepted_regex = r"pass intercepted"
    pass_intercepted_passer_by_regex = Regex("^$(name_regex)pass intercepted for a TD (?:by)?")
    pass_intercepted_passer_regex = Regex("^$(name_regex)pass intercepted")
    pass_intercepted_interceptor_by_regex = Regex("pass intercepted (?:for a TD )?by $(name_regex)")
    pass_intercepted_interceptor_regex = Regex("(?:TD )?$(name_regex)return(?:ed)? (?:for)?")
    interception_return_regex = r"Interception Return"
    #interception_return_passer_regex = r"((?:[A-Z\p{Lu}-][a-z\p{Ll}A-Z&\p{Lu}'\.-]+\s?)+) \d"
    interception_return_interceptor_regex = Regex("$(name_regex) \\d")
    
    if occursin(td_return_regex, play_text)
        passer = strip(match(td_return_passer_regex, play_text)[1])
        interceptor = "No data"
        PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = points_after(play_text)
    elseif occursin(td_return_name_regex, play_text)
        passer = strip(match(td_return_name_passer_regex, play_text)[1])
        if occursin(td_return_name_intercepter_regex, play_text)
            interceptor = strip(match(td_return_name_intercepter_regex, play_text)[1])
        elseif occursin(td_return_noname_intercepter_regex, play_text)
            interceptor = "No Data"
        end
        PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = points_after(play_text)
    elseif occursin(pass_intercepted_regex, play_text)
        if occursin(pass_intercepted_passer_by_regex, play_text)
            passer = strip(match(pass_intercepted_passer_by_regex, play_text)[1])
        else
            passer = strip(match(pass_intercepted_passer_regex, play_text)[1])
        end
        if occursin(pass_intercepted_interceptor_by_regex, play_text)
            interceptor = strip(match(pass_intercepted_interceptor_by_regex, play_text)[1])
        else
            interceptor = strip(match(pass_intercepted_interceptor_regex, play_text)[1])
        end        
        PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = points_after(play_text)
    elseif occursin(interception_return_regex, play_text)
        passer = "No data"
        interceptor = strip(match(interception_return_interceptor_regex, play_text)[1])
        PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = points_after(play_text)
    else
        "Error"
        @warn "Fcn: play_interception_return_td" game play_text
    end

    [passer, interceptor, PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver]
end

function play_sack(cols)
    play_text = cols

    passer = missing # Player name
    tackler = missing # Player name

    passer_regex = Regex("(?:^|,\\s*)$(name_regex)sacked")
    passer_specialcase1_regex = Regex("\\d+ [Yy][Dd] [Ff]umble [Rr]eturn")
    passer_specialcase2_regex = Regex("^$(name_regex)(?:rush|run) for a loss")
    tackler_specialcase1_regex = Regex("^$(name_regex)sacked\\s*(?:for|for a loss of)?\\s*(?:\\d+ yards?|at)")
    tackler_specialcase2_regex = Regex("\\d+ [Yy][Dd] [Ff]umble [Rr]eturn")
    tackler_specialcase3_regex = Regex("(?:rush|run) for a loss of \\d+ yards to the")
    tackler_regex = Regex("sacked by $(name_regex)")
        
    # if ismissing(play_text)
    if play_text == ""
        passer ="No Data"
    else
        play_text = replace(play_text, r"N/A"=>"No Data")

        if occursin(passer_regex, play_text)
            passer = strip(match(passer_regex, play_text)[1])
        elseif occursin(passer_specialcase1_regex, play_text)
            passer = "ERROR in DATA?"
        elseif occursin(passer_specialcase2_regex, play_text)
            passer = strip(match(passer_specialcase2_regex, play_text)[1])
        else
            passer = strip(match(passer_regex, play_text)[1])
        end

        if occursin(tackler_specialcase1_regex, play_text)
            tackler = "No Data"
        elseif occursin(tackler_specialcase3_regex, play_text)
            tackler = "No Data"
        elseif occursin(tackler_regex, play_text)
            tackler = strip(match(tackler_regex, play_text)[1])
        elseif occursin(tackler_specialcase2_regex, play_text)
            tackler = "ERROR in DATA?"
        else
            tackler = strip(match(tackler_regex, play_text)[1])
        end
    end

    [passer, tackler]
end

function play_kickoff(cols)
    play_text = cols

    kicker = missing # Player name
    kick_type = missing #touchback, returned, fair-catch, on-side:kicking/receiving, unknown, ?fumbled
    returner = missing # Player name

    onside_regex = r"on-side"
    on_sides_kicker_regex = r"^(?:((?:[A-Z\p{Lu}-][a-z\p{Ll}A-Z&\p{Lu}'\.-]+\s?)+)|(?:(N\/A)\s?))on-side"
    onside_recoverteam_regex = Regex("recovered by $(name_regex)at")
    onside_recoverteam_nodata_regex = Regex("$(name_regex)return for (?:\\d+ [Yy][Dd] |no gain | )to the")
    onside_recoverteam_allcaps_regex = r"recovered by ((?:[A-Z\p{Lu}&-]+\s?)+)at"
    onside_recoverteam_outofbounds_regex = r"kick out of bounds"
    
    faircatch_regex = r"fair catch"
    faircatch_kicker_regex = r"^(?:((?:[A-Z\p{Lu}-][a-z\p{Ll}A-Z&\p{Lu}'\.-]+\s?)+)|(?:(N\/A)\s?))kickoff for"
    faircatch_kicker_regex2 = Regex("$(name_regex)kickoff for")
    faircatch_receiver_regex = r"fair catch by (?:((?:[A-Z\p{Lu}-][a-z\p{Ll}A-Z&\p{Lu}'\.-]+\s?)+)|(?:(N\/A)\s?))(?:at the)?"
    faircatch_receiver_return_regex = Regex("$(name_regex)return for (?:\\d+|(?:no gain)|a)")
    faircatch_receiver_nodata1_regex = r"fair catch at the"
    faircatch_receiver_nodata2_regex = r"downed at the"
    faircatch_receiver_nodata3_regex = r"illegal fair catch signal"

    #kicker_regex = r"^((?:[A-Z\p{Lu}-][a-z\p{Ll}A-Z&\p{Lu}'\.-]+\s?)+)kick"
    kicker_regex = Regex("$(name_regex)[Kk]ick")
    kicker_parenthesis_regex = Regex("\\($(name_regex)[Kk]ick\\)")
    kicker_nodata_regex = r"^kickoff for \d+"
    #kickoff_return_regex = r"(?:((?:[A-Z\p{Lu}][a-z\p{Ll}',\.-]+\s?)+)|(\s+))return for (?:\d+|(?:no gain)|a)"
    kickoff_return_regex = Regex("$(name_regex)return for (?:\\d+|(?:no gain)|a)")
    kickoff_return_first_regex = Regex("^$(name_regex)\\d+ [Yy][Dd] [Kk]ickoff [Rr]eturn")
    # kickoff_return_specialcase1_regex = Regex("^Isaiah McKenzie \\d+ [Yy][Dd] [Kk]ickoff [Rr]eturn") #The 'K' is breaking my name regex, fix! Ex: Isaiah McKenzie 90 Yd Kickoff Return (Marshall Morgan Kick)
    

    touchback_regex = r"((?:touchback)|(?:TOUCHBACK))\.?"
    kickoff_nodata_regex = r"kickoff for \d+ yds$"
    
    if ismissing(play_text) || (play_text == "kickoff")
        kicker = "No Data"
        kick_type = "No Data"
        returner = "No Data"
    else
        play_text = replace(play_text, r"N/A"=>"No Data")   
        play_text = replace(play_text, r"^\s*-\s+"=>" ")

        if occursin(onside_regex, play_text)
            kicker = strip(match(on_sides_kicker_regex, play_text)[1])
            if occursin(onside_recoverteam_outofbounds_regex, play_text)
                recover_team = missing
                kick_type = "out-of-bounds"
            elseif occursin(onside_recoverteam_nodata_regex, play_text)
                kick_type = "on-side"
            elseif occursin(onside_recoverteam_allcaps_regex, play_text)
                recover_team = strip(match(onside_recoverteam_allcaps_regex, play_text)[1])
                recover_team = titlecase(recover_team)
                kick_type = "on-side "*recover_team
            else
                recover_team = strip(match(onside_recoverteam_regex, play_text)[1])
                kick_type = "on-side"*recover_team
            end
        elseif occursin(faircatch_regex, play_text)
            if occursin(faircatch_kicker_regex, play_text)
                kicker = strip(match(faircatch_kicker_regex, play_text)[1])
            else
                kicker = strip(match(faircatch_kicker_regex2, play_text)[1])
            end
            kick_type = "fair-catch"
            if occursin(faircatch_receiver_return_regex, play_text)
                returner = strip(match(faircatch_receiver_return_regex, play_text)[1])
            elseif occursin(faircatch_receiver_nodata1_regex, play_text)
                returner = "No Data"
            elseif occursin(faircatch_receiver_nodata2_regex, play_text)
                returner = "No Data"
            elseif occursin(faircatch_receiver_nodata3_regex, play_text)
                returner = "No Data"
            elseif occursin(faircatch_receiver_return_regex, play_text)
                returner = strip(match(faircatch_receiver_return_regex, play_text)[1])
            else
                returner = strip(match(faircatch_receiver_regex, play_text)[1])
            end
        else
            if occursin(kicker_nodata_regex, play_text)
                kicker = "No Data"
            elseif occursin(kicker_parenthesis_regex, play_text)
                kicker = strip(match(kicker_parenthesis_regex, play_text)[1])
            else
                kicker = strip(match(kicker_regex, play_text)[1])
            end
            if occursin("return for", play_text) || occursin("Kickoff Return", play_text)
                if occursin(kickoff_return_first_regex, play_text)
                    returner = strip(match(kickoff_return_first_regex, play_text)[1])
                # elseif occursin(kickoff_return_specialcase1_regex, play_text)
                #     returner = strip(match(kickoff_return_specialcase1_regex, play_text)[1])
                else
                    returner = strip(match(kickoff_return_regex, play_text)[1])
                end
                if returner == ""
                    returner = "No data"
                end
            else
                returner = "No data"
            end
            if occursin(touchback_regex, play_text)
                kick_type = "touchback"
            elseif occursin(kickoff_nodata_regex, play_text)
                kick_type = "no data"
            else
                kick_type = "returned"
            end
        end
    end

    #if on-side process for which team recovered

    [kicker, kick_type, returner]
end

function play_kickoff_return_td(cols)
    play_text = cols

    kicker = missing # Player name
    returner = missing # Player name
    PAT_kicker = missing # Player name
    PAT_type = missing # made, missed, blocked, failed
    two_point = missing # true/false
    two_point_type = missing # rush, pass, failed
    two_point_runner = missing # Player name
    two_point_passer = missing # Player name
    two_point_receiver = missing # Player name

    kickoff_for_regex = r"kickoff for \d"
    kickoff_for_kicker_regex = Regex("$(name_regex)kickoff for \\d")
    kickoff_for_returner_regex = Regex("$(name_regex)return for \\d")
    kickoff_for_returner_nodata_regex = r"kickoff for \d+ yds for a touchback"
    kickoff_return_regex = r"Kickoff Return"
    kickoff_return_kicker_regex = Regex("\\($(name_regex) [Kk]ick\\)")
    kickoff_return_kicker_nodata1_regex = Regex("$(name_regex) \\d+ Yd Kickoff Return \\(")
    kickoff_return_returner_regex = Regex("TD $(name_regex)return for no gain for a TD")
    kickoff_return_returner2_regex = Regex("^$(name_regex)")
    
    play_text = replace(play_text, r"^- \d+"=>"No Data")

    if occursin(kickoff_for_regex, play_text)
        kicker = strip(match(kickoff_for_kicker_regex, play_text)[1])
        if occursin(kickoff_for_returner_nodata_regex, play_text)
            returner = "No Data"
        else
            returner = strip(match(kickoff_for_returner_regex, play_text)[1])
        end
        PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = points_after(play_text)
    elseif occursin(kickoff_return_regex, play_text)
        # if occursin(kickoff_return_kicker_regex, play_text)
        #     kicker = strip(match(kickoff_return_kicker_regex, play_text)[1])
        # elseif occursin(kickoff_return_kicker_nodata1_regex, play_text)
            kicker = "No Data"
        # end
        if occursin(kickoff_return_returner_regex, play_text)
            returner = strip(match(kickoff_return_returner_regex, play_text)[1])
        else
            returner = strip(match(kickoff_return_returner2_regex, play_text)[1])
        end
        PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = points_after(play_text)
    else
        "Error"
        @warn "Fcn: play_kickoff_return_td" game play_text
    end
    
    [kicker, returner, PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver]
end

function play_blocked_fieldgoal_return_td(cols)
    play_text = cols

    kicker = missing # Player name
    recoverer = missing # Player name
    blocker = missing # Player name
    PAT_kicker = missing # Player name
    PAT_type = missing # made, missed, blocked, failed
    two_point = missing # true/false
    two_point_type = missing # rush, pass, failed
    two_point_runner = missing # Player name
    two_point_passer = missing # Player name
    two_point_receiver = missing # Player name
    FG = false
    FG_type = "blocked" # made, missed, blocked, failed, returned

    return_of_blocked_regex = r"Return of Blocked Field Goal"
    return_of_blocked_recoverer_regex = Regex("$(name_regex)\\d+ Yd Return of Blocked Field Goal")
    
    fg_blocked_regex = r"FG BLOCKED blocked by"
    fg_blocked_kicker_regex = Regex("^$(name_regex)\\d+")
    fg_blocked_blocker_regex = Regex("FG BLOCKED blocked by $(name_regex)return for no gain for a TD")
    fg_blocked_recoverer_regex = Regex("TD $(name_regex)return for no gain for a TD")
    
    
    if occursin(return_of_blocked_regex, play_text)
        kicker = "No data"
        recoverer = strip(match(return_of_blocked_recoverer_regex, play_text)[1])
        PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = points_after(play_text)
    # elseif occursin(fg_blocked_regex, play_text)
    #     kicker = strip(match(fg_blocked_kicker_regex, play_text)[1])
    #     recoverer = strip(match(, play_text)[1])
    #     blocker = strip(match(, play_text)[1])
    #     PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = points_after(play_text)
    else
        "Error"
        @warn "Fcn: play_blocked_fieldgoal_return_td" game play_text
    end

    [kicker, recoverer, blocker, PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver, FG, FG_type]
end

function play_missed_fieldgoal_return_td(cols)
    play_text = cols

    kicker = missing # Player name
    returner = missing # Player name
    PAT_kicker = missing # Player name
    PAT_type = missing # made, missed, blocked, failed
    two_point = missing # true/false
    two_point_type = missing # rush, pass, failed
    two_point_runner = missing # Player name
    two_point_passer = missing # Player name
    two_point_receiver = missing # Player name
    FG = false
    FG_type = "missed" # made, missed, blocked, failed, returned
   
    fg_returned_regex = r"FG RETURNED"
    fg_returned_kicker_regex = Regex("^$(name_regex) ?\\d+")
    fg_returned_kicker_returned_regex = Regex("^$(name_regex)\\d+ yd FG RETURNED")
    fg_returned_returner_regex = Regex("TD $(name_regex)return for \\d")
    fg_returned_returner_for_regex = Regex("$(name_regex)return for \\d+")
    
    fg_missed_regex = r"FG MISSED"
    fg_missed_kicker_regex = Regex("^$(name_regex)\\d")
    fg_missed_returner_regex = Regex("TD $(name_regex)return for \\d")
    fg_missed_returner_tdlast_regex = Regex("$(name_regex)return for \\d")

    return_of_missed_regex = r"Return of Missed Field Goal"
    return_of_missed_returner_regex = Regex("^$(name_regex)\\d")
    
    if occursin(fg_returned_regex, play_text)
        #println("Block 1")
        if occursin(fg_returned_kicker_regex, play_text)
            kicker = strip(match(fg_returned_kicker_regex, play_text)[1])
        else
            kicker = strip(match(fg_returned_kicker_returned_regex, play_text)[1])
        end
        if occursin(fg_returned_returner_regex, play_text)
            returner = strip(match(fg_returned_returner_regex, play_text)[1])
        else
            returner = strip(match(fg_returned_returner_for_regex, play_text)[1])
        end        
        PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = points_after(play_text)
    elseif occursin(fg_missed_regex, play_text)
        #println("Block 2")
        kicker = strip(match(fg_missed_kicker_regex, play_text)[1])
        if occursin(fg_missed_returner_regex, play_text)
            returner = strip(match(fg_missed_returner_regex, play_text)[1])
        else
            returner = strip(match(fg_missed_returner_tdlast_regex, play_text)[1])
        end
        PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = points_after(play_text)
    elseif occursin(return_of_missed_regex, play_text)
        #println("Block 3")
        kicker = "No data"
        returner = strip(match(return_of_missed_returner_regex, play_text)[1])
        PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = points_after(play_text)        
    else
        "Error"
        @warn "Fcn: play_missed_fieldgoal_return_td" game play_text
    end

    [kicker, returner, PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver, FG, FG_type]
end

function play_fieldgoal_good(cols)
    play_text = cols

    kicker = missing # Player name
    FG_type = "made" # made, missed, blocked, failed, returned
    
    kicker_regex = Regex("^$(name_regex)\\d")
    
    kicker = strip(match(kicker_regex, play_text)[1])
    
    [kicker, FG_type]
end

function play_fieldgoal_missed(cols)
    play_text = cols

    kicker = missing # Player name
    FG_type = "missed" # made, missed, blocked, failed, returned
    
    kicker_regex = Regex("^$(name_regex)\\d")
    
    kicker = strip(match(kicker_regex, play_text)[1])
    
    [kicker, FG_type]
end

function play_fieldgoal_missed_return(cols)
    play_text = cols

    kicker = missing # Player name
    FG_type = "returned" # made, missed, blocked, failed, returned
    returner = missing # Player name

    kicker_regex = Regex("^$(name_regex)\\d")
    returner_nodata_regex = r",\s*return for"
    returner_regex = Regex("$(name_regex)return for")
    returner_returned_by_regex = Regex("returned by $(name_regex)for")
    
    kicker = strip(match(kicker_regex, play_text)[1])
    if occursin(returner_nodata_regex, play_text)
        returner = "No data"
    elseif occursin(returner_regex, play_text)
        returner = strip(match(returner_regex, play_text)[1])
    elseif occursin(returner_returned_by_regex, play_text)
        returner = strip(match(returner_returned_by_regex, play_text)[1])
    else
        returner = "No data"
    end
    
    [kicker, returner, FG_type]
end

function play_fieldgoal_missed_return_td(cols)
    play_text = cols

    kicker = missing # Player name
    FG_type = "returned" # made, missed, blocked, failed, returned
    returner = missing # Player name

    kicker_regex = Regex("^$(name_regex)\\d+\\s*[Yy][Dd]\\s*FG\\s*(RETURNED|MISSED)")
    kicker_regex2 = Regex("^$(name_regex)\\d+ yd FG RETURNED")
    returner_only_regex = Regex("$(name_regex)\\s*\\d+\\s*[Yy][Dd]\\s*[Rr]eturn of")
    returner_regex = Regex("$(name_regex)return for")
    
    if occursin(kicker_regex, play_text)
        kicker = strip(match(kicker_regex, play_text)[1])
    elseif occursin(kicker_regex2, play_text)
        kicker = strip(match(kicker_regex2, play_text)[1])
    else
        kicker = "No data"
    end
    if occursin(returner_only_regex, play_text)
        returner = strip(match(returner_only_regex, play_text)[1])
    else
        returner = strip(match(returner_regex, play_text)[1])
    end
    
    [kicker, returner, FG_type]
end

function play_blocked_fieldgoal(cols)
    play_text = cols

    play_text = replace(play_text, r" null"=>"")
    # println(play_text)

    kicker = missing # Player name
    FG_type = "blocked" # made, missed, blocked, failed, returned
    blocker = missing # Player name
    returner = missing # Player name

    kicker_regex = Regex("^$(name_regex)\\d")
    blocker_missing_regex = r"FG BLOCKED blocked by(\s*$|\s*,)"
    blocker_NA_regex = r"FG BLOCKED blocked by N/A"
    blocker_1st_regex = Regex("FG BLOCKED\\s*for a 1ST down blocked by\\s+$(name_regex)")
    blocker_regex1 = Regex("FG BLOCKED blocked by\\s+$(name_regex)")
    blocker_regex2 = Regex("FG BLOCKED by\\s+$(name_regex)")
    returner_regex = Regex("$(name_regex)return for (\\d+|no gain)")
    recovered_regex = Regex(",\\s+recovered by\\s+$(name_regex),")    

    kicker = strip(match(kicker_regex, play_text)[1])
    if occursin(blocker_missing_regex, play_text)
        blocker = "No data"
    elseif occursin(blocker_1st_regex, play_text)
        blocker = strip(match(blocker_1st_regex, play_text)[1])
    elseif occursin(blocker_regex1, play_text)
        blocker = strip(match(blocker_regex1, play_text)[1])
    elseif occursin(blocker_NA_regex, play_text)
        blocker = "No data"
    elseif occursin(blocker_regex2, play_text)
        blocker = strip(match(blocker_regex2, play_text)[1])
    end

    if occursin(returner_regex, play_text)
        returner = strip(match(returner_regex, play_text)[1])
    elseif occursin(recovered_regex, play_text)
        returner = strip(match(recovered_regex, play_text)[1])
    end

    [kicker, blocker, returner, FG_type]
end

function play_punt(cols)
    play_text = cols

    punter = missing # Player name
    punt_type = missing #touchback, returned, fair-catch, on-side:kicking/receiving, unknown, ?fumbled
    returner = missing # Player name
    
    #punter_single_initial_regex = Regex("^([A-Z\p{Lu}-]\s*(?:[A-Z\p{Lu}-][a-z\p{Ll}A-Z&\p{Lu}'\.-]+\s?)+)\s*punt for")
    punter_regex = Regex("^$(name_regex) ?punt")
    punt_type_regex = r"(downed|fair catch|returns|touchback|out-of-bounds)"
    returner_single_initial_faircatch_regex = r"fair catch by ([A-Z\p{Lu}-]\s*(?:[A-Z\p{Lu}-][a-z\p{Ll}A-Z&\p{Lu}'\.-]+\s?)+)"
    returner_faircatch_by_regex = Regex("fair catch by $(name_regex)")
    returner_faircatch_at_regex = Regex("fair catch at the")
    returner_returns_regex = Regex("$(name_regex) returns for")
    
    if ismissing(play_text)
        punter = "No data"
        punt_type = "No data"
    elseif play_text == "N/A punt"
        punter = "No data"
        punt_type = "No data"
    # elseif occursin(punter_kickoff_regex, play_text)
    #     punter = strip(match(punter_kickoff_regex, play_text)[1])
    #     returner = strip(match(returner_returns_regex, play_text)[1])
    #     punt_type = "kickoff/punt"
    else
        play_text = replace(play_text, r"N/A"=>"No Data")
        play_text = replace(play_text, r"\s+-\s+"=>" ")
        
        if occursin(punter_regex, play_text)
            punter = strip(match(punter_regex, play_text)[1])
        # elseif occursin(punter_single_initial_regex, play_text)
        #     punter = strip(match(punter_single_initial_regex, play_text)[1])
        else
            punter = "No Data"
        end
        if occursin(punt_type_regex, play_text)
            punt_type = strip(match(punt_type_regex, play_text)[1])
            if punt_type == "fair catch"
                if occursin(returner_single_initial_faircatch_regex, play_text)
                    returner = strip(match(returner_single_initial_faircatch_regex, play_text)[1])
                elseif occursin(returner_faircatch_by_regex, play_text)
                    returner = strip(match(returner_faircatch_by_regex, play_text)[1])
                elseif occursin(returner_faircatch_at_regex, play_text)
                    returner = "No data"
                else
                    println("Missed play_punt")
                    @warn "Fcn: play_punt" game play_text
                end
            elseif punt_type == "returns"
                if occursin(returner_returns_regex, play_text)
                    returner = strip(match(returner_returns_regex, play_text)[1])
                else
                    returner = "No data"
                end
            end  
        else
            punt_type = "success?"
        end
    end
    
    if punt_type == "returns"
        punt_type = "returned"
    end

    [punter, returner, punt_type]
end

function play_punt_return_td(cols)
    play_text = cols

    punter = missing # Player name
    receiver = missing # Player name
    returner = missing # Player name
    blocker = missing # Player name
    recoverer = missing # Player name
    PAT_kicker = missing # Player name
    PAT_type = missing # made, missed, blocked, failed
    two_point = missing # true/false
    two_point_type = missing # rush, pass, failed
    two_point_runner = missing # Player name
    two_point_passer = missing # Player name
    two_point_receiver = missing # Player name
    punt_type  = "returned" #  blocked, failed
   
    # name_regex = "(((?:[A-Z\\p{Lu}'-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+|(?:de))|(?:[A-Z\\p{Lu}-]\\.?)?\\s?)+)" #most general name regex

    punt_return_regex = r"[Yy]d Punt Return"
    punt_return_receiver_regex = Regex("^TD $(name_regex)\\d")
    punt_return_receiver2_regex = Regex("^$(name_regex)\\d+ Yd Punt Return")
    
    punt_for_regex = r"punt blocked by"
    punt_for_punter_regex = Regex("^$(name_regex)punt for")
    punt_for_punter_by_regex = Regex("^$(name_regex)punt blocked by")
    punt_for_recoverer_regex = Regex("$(name_regex)returns for \\d")
    punt_for_recoverer_blockedbysqr_regex = Regex("blocked by $(name_regex)blocked by")

    play_text = replace(play_text, "TEAM"=>"No Data")

    if occursin(punt_return_regex, play_text)
        punter = "No data"
        if occursin(punt_return_receiver_regex, play_text)
            recoverer = strip(match(punt_return_receiver_regex, play_text)[1])
        else
            recoverer = strip(match(punt_return_receiver2_regex, play_text)[1])
        end
        PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = points_after(play_text)
    elseif occursin(punt_for_regex, play_text)
        if occursin(punt_for_punter_regex, play_text)
            punter = strip(match(punt_for_punter_regex, play_text)[1])
        else
            punter = strip(match(punt_for_punter_by_regex, play_text)[1])
        end
        if occursin(punt_for_recoverer_blockedbysqr_regex, play_text)
            recoverer = "No Data"
        else
            recoverer = strip(match(punt_for_recoverer_regex, play_text)[1])
        end
        PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = points_after(play_text)
    elseif occursin("Blocked", play_text)
        punter, recoverer, blocker, PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver, punt_type = play_blocked_punt_td(play_text)
    else
        "Error"
        @warn "Fcn: play_punt_return_td" game play_text
    end

    [punter, receiver, returner, blocker, PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver, punt_type]
end

function play_blocked_punt(cols)
    play_text = cols

    punter = missing # Player name
    punt_type = "blocked" #touchback, returned, fair-catch, on-side:kicking/receiving, unknown, ?fumbled
    blocker = missing # Player name
    returner = missing # Player name
    
    # name_regex = "(((?:[A-Z\\p{Lu}'-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+|(?:de))|(?:[A-Z\\p{Lu}-]\\.?)?\\s?)+)" #most general name regex
    # Regex("$(name_regex)

    punter_regex = Regex("^$(name_regex)punt blocked")
    punter_alt_regex = Regex("^$(name_regex)punt (\\d+|for)")
    blocker_regex = Regex("blocked by $(name_regex)")
    returner_regex = Regex("$(name_regex)return for")
    
    if occursin(punter_regex, play_text)
        punter = strip(match(punter_regex, play_text)[1])
    elseif occursin(punter_alt_regex, play_text)
        punter = strip(match(punter_alt_regex, play_text)[1])
    else
        punter = "No data"
    end
    if occursin(blocker_regex, play_text)
        blocker = strip(match(blocker_regex, play_text)[1])
    else
        blocker = "No data"
    end
    if occursin(returner_regex, play_text)
        returner = strip(match(returner_regex, play_text)[1])
    end
    
    [punter, blocker, returner, punt_type]
end

function play_blocked_punt_td(cols)
    play_text = cols

    # name_regex = "(((?:[A-Z\\p{Lu}'-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+|(?:de))|(?:[A-Z\\p{Lu}-]\\.?)?\\s?)+)" #most general name regex

    punter = missing # Player name
    blocker = missing # Player name
    recoverer = missing # Player name
    PAT_kicker = missing # Player name
    PAT_type = missing # made, missed, blocked, failed
    two_point = missing # true/false
    two_point_type = missing # rush, pass, failed
    two_point_runner = missing # Player name
    two_point_passer = missing # Player name
    two_point_receiver = missing # Player name
    punt_type  = "blocked" #  blocked, failed
   
    return_of_blocked_regex = r"Return of Blocked Punt"
    return_of_blocked_recoverer_regex = Regex("^TD $(name_regex)\\d")
    return_of_blocked_recoverer2_regex = Regex("^$(name_regex)\\d+ Yd Return of Blocked Punt")
    
    punt_blocked_regex = r"punt blocked by"
    punt_blocked_punter_regex = Regex("^$(name_regex)punt blocked by")
    punt_blocked_blocker_regex = Regex("punt blocked by $(name_regex),?")
    punt_blocked_recoverer_regex = Regex("$(name_regex)return for \\d")

    if occursin(return_of_blocked_regex, play_text)
        punter = "No data"
        if occursin(return_of_blocked_recoverer_regex, play_text)
            recoverer = strip(match(return_of_blocked_recoverer_regex, play_text)[1])
        else
            recoverer = strip(match(return_of_blocked_recoverer2_regex, play_text)[1])
        end
        PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = points_after(play_text)
    elseif occursin(punt_blocked_regex, play_text)
        if occursin(punt_blocked_punter_regex, play_text)
            punter = strip(match(punt_blocked_punter_regex, play_text)[1])
        else
            punter = "No Data"
        end
        blocker = strip(match(punt_blocked_blocker_regex, play_text)[1])
        recoverer = strip(match(punt_blocked_recoverer_regex, play_text)[1])
        PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver = points_after(play_text)
    else
        "Error"
        @warn "Fcn: play_blocked_punt_td" game play_text
    end

    [punter, recoverer, blocker, PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver, punt_type]
end

function play_pass_twopoint(cols)
    play_text = cols

    # println("Play text: $play_text")

    two_point = true
    two_point_type = "pass"
    two_point_passer = missing # Player name
    two_point_receiver = missing # Player name

    # name_regex = "(((?:[A-Z\\p{Lu}'-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+|(?:de))|(?:[A-Z\\p{Lu}-]\\.?)?\\s?)+)" #most general name regex
    # Regex("$(name_regex)

    complete_to_regex = r"pass complete to"
    complete_to_passer_regex = Regex("$(name_regex)pass complete to")
    complete_to_receiver_regex = Regex("pass complete to $(name_regex)for")
    pass_from_regex = r"pass from"
    pass_from_passer_regex = Regex("pass from $(name_regex)")
    pass_from_receiver_regex = Regex("$(name_regex)\\d")
    
    if occursin(complete_to_regex, play_text)
        two_point_passer = strip(match(complete_to_passer_regex, play_text)[1])
        two_point_receiver = strip(match(complete_to_receiver_regex, play_text)[1])
    elseif occursin(pass_from_regex, play_text)
        two_point_passer = strip(match(pass_from_passer_regex, play_text)[1])
        two_point_receiver = strip(match(pass_from_receiver_regex, play_text)[1])
    else
        "Error"
    end
    
    [two_point, two_point_type, two_point_passer, two_point_receiver]
end

function play_rush_twopoint(cols)
    play_text = cols

    two_point = true
    two_point_type = "rush"
    two_point_runner = missing # Player name

    # name_regex = "(((?:[A-Z\\p{Lu}'-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+|(?:de))|(?:[A-Z\\p{Lu}-]\\.?)?\\s?)+)" #most general name regex
    # Regex("$(name_regex)

    rush_run_regex = Regex("$(name_regex)run")
    rush_digit_run_regex = Regex("$(name_regex)\\d")
    
    if occursin(rush_run_regex, play_text)
        two_point_runner = strip(match(rush_run_regex, play_text)[1])
    elseif occursin(rush_digit_run_regex, play_text)
        two_point_runner = strip(match(rush_digit_run_regex, play_text)[1])
    else
        "Error"
        @warn "Fcn: play_rush_twopoint" game play_text
    end
    
    [two_point, two_point_type, two_point_runner]
end

function play_2pt_conversion(cols)
    play_text = cols

    two_point_runner = missing # Player name
        
    # name_regex = "(((?:[A-Z\\p{Lu}'-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+|(?:de))|(?:[A-Z\\p{Lu}-]\\.?)?\\s?)+)" #most general name regex

    two_point_runner_regex1 = Regex("^$(name_regex)return for")
    two_point_runner_regex2 = Regex("^$(name_regex)Defensive PAT")
    
    if ismissing(play_text)
        passer ="No Data"
    else
        if occursin(two_point_runner_regex1, play_text)
            two_point_runner = strip(match(two_point_runner_regex1, play_text)[1])
        else
            two_point_runner = strip(match(two_point_runner_regex2, play_text)[1])
        end
    end

    two_point_runner
end

function play_safety(cols)
    play_text = cols

    runner = missing # Player name
    passer = missing # Player name
    tackler = missing # Player name
        
    # name_regex = "(((?:[A-Z\\p{Lu}'-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+|(?:de))|(?:[A-Z\\p{Lu}-]\\.?)?\\s?)+)" #most general name regex
    

    runner_regex = Regex("^$(name_regex)run for")
    runner_nodata_regex = Regex("^run for")
    passer_regex = Regex("^$(name_regex)sacked (?:by|for)")
    passer_lastfirst_regex = Regex("^$(name_lastfirst_regex) (?:sacked (?:by|for)|pass)")
    passer_caplastfirst_regex = Regex("^$(name_caplastfirst_regex) (?:sacked (?:by|for)|pass)")
    passer_specialcase1_regex = Regex("Illegal Forward Pass")
    tackler_specialcase1_regex = Regex("[Ii]ntentional [Gg]rounding")
    tackler_sack_regex = Regex("sacked by $(name_regex)")
    
    if ismissing(play_text)
        passer ="No Data"
    elseif play_text == "Team Safety"
        passer = "No Data"
        runner = "No Data"
        tackler = "No Data"
    elseif occursin(Regex("^$(name_regex)Safety"), play_text)
        passer = "No Data"
        runner = "No Data"
        tackler = "No Data"
    else
        play_text = replace(play_text, r"(?:Team|TEAM)"=>"No Data")

        if occursin(r"run ", play_text)
            if occursin(runner_nodata_regex, play_text)
                runner = "No Data"
            else
                runner = strip(match(runner_regex, play_text)[1])
            end
        end

        if occursin(r" sacked ", play_text)
            if occursin(passer_specialcase1_regex, play_text)
                passer = "No Data"
            elseif occursin(passer_lastfirst_regex, play_text)
                passer = strip(match(passer_lastfirst_regex, play_text)[1])
                lastpart, firstpart = split(passer, ",")
                passer = strip(firstpart)*" "*strip(lastpart)
            elseif occursin(passer_caplastfirst_regex, play_text)
                passer = strip(match(passer_caplastfirst_regex, play_text)[1])
                lastpart, firstpart = split(passer, ",")
                lastpart = uppercasefirst(lowercase(lastpart))
                passer = strip(firstpart)*" "*strip(lastpart)
            else
                passer = strip(match(passer_regex, play_text)[1])
            end
            if occursin(tackler_specialcase1_regex, play_text)
                tackler = "No Data"
            elseif occursin(tackler_sack_regex, play_text)
                tackler = strip(match(tackler_sack_regex, play_text)[1])
            else
                tackler = "No Data"
            end
        end
    end

    [passer, runner, tackler]
end



function play_timeout(cols)
    play_text = cols
    
    timeout_team = missing # Team name taking timeout
    timeout_time = missing # Time of timeout

    team_name_abbrevs = ["BYU", "JMU", "LSU", "SFA", "SMU", "TCU", "UAB", "UCF", "UCLA", "UNLV", "USC", "UTEP", "VMI"]
    team_name_abbrevs_not = ["SE LOUISIANA", "SE MISSOURI", "UC DAVIS", "UL LAFAYETTE", "UL MONROE", "UT SAN ANTONIO"]
    team_name_specalcase = ["INCARNATEW", "MCNEESE ST", "NORTHERNIL", "TEXASSAN", "OLDDOMINION"]

    team_caps_regex = "((?:(?:[A-Z\\p{Lu}'-]+)\\s?)+)" # Team name all caps

    team_time_regex = Regex("Timeout $(team_caps_regex),? clock (\\d\\d:\\d\\d)")
    team_regex = Regex("Timeout $(team_caps_regex)")
    team_specialcase1_regex = r"Arkansas Razorbacks timeout."

    if occursin(team_time_regex, play_text)
        timeout_team = strip(match(team_time_regex, play_text)[1])
        timeout_time = strip(match(team_time_regex, play_text)[2])
    elseif occursin(team_regex, play_text)
        timeout_team = strip(match(team_regex, play_text)[1])
        timeout_time = "No Data"
    elseif occursin(team_specialcase1_regex, play_text)
        timeout_team = "Arkansas"
        timeout_time = "No Data"
    end

    if ismissing(timeout_team)
        timeout_team = "No Data"
    elseif timeout_team ∈ team_name_abbrevs_not
        for i in 1:length(timeout_team)
            if length(timeout_team[i]) > 2
                timeout_team[i] = titlecase(timeout_team[i])
            end
        end
    elseif timeout_team ∈ team_name_specalcase
        if timeout_team == "INCARNATEW"
            timeout_team = "Incarnate Word"
        elseif timeout_team == "MCNEESE ST"
            timeout_team = "McNeese St"
        elseif timeout_team == "NORTHERNIL"
            timeout_team = "Northern Illinois"
        elseif timeout_team == "TEXASSAN"
            timeout_team = "UT San Antonio"
        elseif timeout_team == "OLDDOMINION"
            timeout_team = "Old Dominion"
        end
    elseif timeout_team ∉ team_name_abbrevs
        timeout_team = titlecase(timeout_team)
    end

    [timeout_team, timeout_time]
end

# play_info aux aux function ####################################################################################################

function points_after(cols)
    play_text = cols

    PAT_kicker = missing # Player name
    PAT_type = missing # made, missed, blocked, failed
    two_point = missing # true/false
    two_point_type = missing # rush, pass, failed
    two_point_runner = missing # Player name
    two_point_passer = missing # Player name
    two_point_receiver = missing # Player name

    # name_regex = "(((?:[A-Z\\p{Lu}'-][a-z\\p{Ll}A-Z&\\p{Lu}'\\.-]+|(?:de))|(?:[A-Z\\p{Lu}-]\\.?)?\\s?)+)" #most general name regex

    kick_regex = r"Kick|KICK"
    kicker_made_regex = Regex("Kickoff Return \\($(name_regex) Kick\\)")
    kicker_regex = r"(?:((?:[A-Z\p{Lu}-][a-z\p{Ll}A-Z&\p{Lu}'\.-]+\s?)+) (?:Kick|KICK))"
    kicker_blocked_regex = Regex("$(name_regex)(?:PAT )?BLOCKED")
    kicker_missed_regex = r"(?:((?:[A-Z\p{Lu}-][a-z\p{Ll}A-Z&\p{Lu}'\.-]+\s?)+)(?: PAT)? MISSED)"
    runner_regex = r"(?:((?:[A-Z\p{Lu}-][a-z\p{Ll}A-Z&\p{Lu}'\.-]+\s?)+) Run [Ff]or Two-[Pp]oint Conversion)"
    runner_nodata_regex = r"( Run For Two-point Conversion)"
    passer_regex = Regex("$(name_regex)[Pp]ass")
    passer_regex2 = Regex("Two pt pass, $(name_regex)[Pp]ass")
    receiver_regex = Regex("[Pp]ass\\s+to $(name_regex)for")
    receiver_regex2 = Regex("[Pp]ass\\s+to $(name_regex)GOOD")
    passer_reciever_regex = Regex("$(name_regex)[Pp]ass to $(name_regex)for Two-Point Conversion")

    if occursin("Kickoff Return (", play_text)
        if occursin("Kick ", play_text)
            PAT_kicker = strip(replace(match(kicker_made_regex, play_text)[1], "PAT" => ""))
            PAT_type = "made"
        elseif occursin("Two-Point Conversion", play_text)
            if occursin("passer_reciever_regex", play_text)
                two_point_passer = strip(match(passer_reciever_regex, play_text)[1])
                two_point_receiver = strip(match(passer_reciever_regex, play_text)[3])
                two_point = true
            end
        end
    elseif occursin(kick_regex, play_text)
        if occursin("( KICK)", play_text) || occursin("( Kick)", play_text)
            PAT_kicker = "Not recorded"
            PAT_type = "made"
        else
            PAT_kicker = strip(match(kicker_regex, play_text)[1])
            PAT_type = "made"
        end
    elseif occursin("BLOCKED", play_text)
        substr = play_text[end-25:end]
        # PAT_kicker = strip(replace(match(kicker_blocked_regex, play_text)[1], "PAT" => ""))
        PAT_kicker = strip(replace(match(kicker_blocked_regex, substr)[1], "PAT" => ""))
        PAT_type = "blocked"
    elseif occursin("MISSED", play_text)
        PAT_kicker = strip(match(kicker_missed_regex, play_text)[1])
        PAT_type = "missed"
    elseif occursin("Team Extra Point Attempt Failed", play_text)
        PAT_kicker = "Not recorded"
        PAT_type = "failed"
    elseif occursin("Two-Point Conversion [Ff]ailed", play_text) || occursin("Two-Point Pass Conversion Failed", play_text) || occursin("Two-Point Run Conversion Failed", play_text)
        two_point = false
        two_point_type = "failed"
    elseif occursin(r"Run [Ff]or Two-[Pp]oint Conversion", play_text)
        if occursin(runner_nodata_regex, play_text)
            two_point_runner = "No Data"
        else
            two_point_runner = strip(match(runner_regex, play_text)[1])
        end
        two_point = true
        two_point_type = "rush"
    #Fix logic: why do I think a pass has occurred, also why was this not picked up above?
    elseif occursin("Two-Point Conversion", play_text)
        if occursin(r"Two-Point Conversion [Ff]ailed", play_text)
            two_point_receiver = missing
        elseif occursin(receiver_regex, play_text)
            two_point_passer = strip(match(passer_regex, play_text)[1])
            two_point_receiver = strip(match(receiver_regex, play_text)[1])            
        else
            two_point_receiver = "No Data"
        end
        two_point = true
        two_point_type = "pass"
    elseif occursin("Two pt pass", play_text)
        two_point_passer = strip(match(passer_regex2, play_text)[1])
        two_point_receiver = strip(match(receiver_regex2, play_text)[1])
        two_point = true
        two_point_type = "pass"
    end
    PAT_kicker,  PAT_type, two_point, two_point_type, two_point_runner, two_point_passer, two_point_receiver
end

