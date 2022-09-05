# Notes ########################################################################
# I think if you took that first penalties chart
# And made it the average# per game and layered that with each team’s count in their game against Bama, that might tell a story.#
# by krnxprs on Dec 5, 2021 | 2:47 PM reply  rec  flag


# Packages #####################################################################
library(tidyverse)
library(openxlsx)
library(stringi)
library(kableExtra)
library(rjson)


################################################################################
# Penalties new thought. Grab after penalty, then process#######################
plays <-
  read.csv(
    "../../data/all_games/all_games.csv"
  )

school_colors <-
  read.xlsx(
    "../school_colors/school_colors.xlsx"
  )

school_colors <- read.csv("../school_colors/school_colors.csv", header = TRUE,sep = ",", fileEncoding="UTF-8-BOM")
school_colors

"%ni%" <- Negate("%in%")


#school_colors$Penalty

#----------------------------------------------------------------------------------------------------------------------
txt.list <- c()
for (txt in plays$Play.text)
{
  res <- str_match(txt, "[Dd]eclined")[1]
  if (!is.na(res[1]))
  {
    txt.list <- append(txt.list, txt)
  }
}
txt.list

penalties.declined <-
  plays %>% filter(Play.text %in% txt.list) %>% select(Offense, Defense, Play.type, Play.text)
write.csv(penalties.declined, file = "penalties-declined.csv", row.names =
            F)

#----------------------------------------------------------------------------------------------------------------------

# str_match(play.text$Play.text[1], penalties.regex)[1]
# foulType(play.text$Play.text[1])
# foulType(play.text.penalties$Play.text[5])

# foul Functions ######################################################################################################
# foulType.checkName <- function(res1, offense, defense, school_colors)
# {
#   if(is.na(str_match(res1,(school_colors %>% filter(School == offense))$Penalty)[1]))
#   {
#     if(is.na(str_match(res1,(school_colors %>% filter(School == defense))$Penalty)[1]))
#     {
#       res1 <- NA
#     }
#   }
#   res1
# }

penalty.type.list <- read.csv("../../data/FBS/penalty-types.csv")




foulTeam.checkName <- function(res1, offense, defense, school_colors)
{
  if(!is.na(str_match(res1,(school_colors %>% filter(School == offense))$Penalty)[1]))
  {
    if(!is.na(str_match(res1,(school_colors %>% filter(School == defense))$Penalty)[1]))
    {
      res1 <- NA
    }
  }
  res1
}

foulTeam <- function(txt, offense, defense, school_colors)
{
  mydebug = TRUE
  
  penalties.regex <- "(Penalty)|(PENALTY)|(Penalty)|(PENALTY)"
  declined.regex <- "[Dd]eclined"
  enforced.regex <- "[Ee]nforced"
  
  team.penalties.enforcedDeclined.split.regex <- 
    "declined ((?:[A-Z\\p{Lu}-]+\\s?)+)\\b"
  team.penalties.enforcedDeclined.combine.regex <- 
    "((?:[A-Z\\p{Lu}-]+\\s?)+)\\b(?:(?:Penalty)|(?:PENALTY)|(?:Penalty)|(?:PENALTY))"
  team.penalties.before.regex <-
    "(?:PENALTY|Penalty),? Before the snap,? ([A-Z\\p{Lu}-]+) "
  team.penalties.regex.pre.lower <-
    "(Penalty\\s(([A-Z&\\p{Lu}-]{2,}\\s?)+))"
  team.penalties.regex.pre.upper <-
    "(PENALTY\\s(([A-Z&\\p{Lu}-]{2,}\\s?)+))"
  team.penalties.regex.post.lower <-
    "((([A-Z&\\p{Lu}-]{2,}\\s?)+)\\sPenalty)"
  team.penalties.regex.post.upper <-
    "((([A-Z&\\p{Lu}-]{2,}\\s?)+)\\sPENALTY)"
  team.penalties.regex.titlecase.pre.lower <-
    "(Penalty\\s(([A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}-]+\\s?)+))"
  team.penalties.regex.titlecase.pre.upper <-
    "(PENALTY\\s(([A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}-]+\\s?)+))"
  team.penalties.regex.titlecase.post.lower <-
    "((([A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}-]+\\s?)+)\\sPenalty)"
  team.penalties.regex.titlecase.post.upper <-
    "((([A-Z\\p{Lu}-][a-z\\p{Ll}A-Z&\\p{Lu}-]+\\s?)+)\\sPENALTY)"
  team.penalties.regex.spacedUppers <- 
    "(?:PENALTY|Penalty),? ([A-Z] [A-Z])"
  penalty.codes <-
    c(
      "OF",
      "CIT",
      "IL",
      "IS",
      "BI",
      "IF",
      "IP",
      "IM",
      "TGB",
      "FL",
      "RO",
      "OFF",
      "IB",
      "PS",
      "FD",
      "PFRP",
      "RU",
      "UR",
      "DL",
      "HL",
      "IR"
    )
  
  if(!is.na(str_match(tolower(txt), enforced.regex)[1]) & !is.na(str_match(tolower(txt), declined.regex)[1]))
  {
    if(!is.na(str_match(txt, team.penalties.enforcedDeclined.split.regex)[2]))
    {
      res1 <- trimws(str_match(txt, team.penalties.enforcedDeclined.split.regex)[2], which = "both")
      if(mydebug) {print(paste("team.penalties.enforcedDeclined.split.regex:", res1))}
    }else if(!is.na(str_match(txt, team.penalties.enforcedDeclined.combine.regex)[2])){
      res1 <- trimws(str_match(txt, team.penalties.enforcedDeclined.combine.regex)[2], which = "both")
      if(mydebug) {print(paste("team.penalties.enforcedDeclined.combine.regex:", res1))}
    }
  }else if(is.na(str_match(tolower(txt), declined.regex)[1])){
    #Need to convert to a loop!
    #Gets penalty that contains "Before the snap"
    res1 <-
      trimws(gsub(
        penalties.regex,
        "",
        str_match(txt, team.penalties.before.regex)[2]
      ), which = "both")
    if(mydebug) {print(paste("team.penalties.enforcedDeclined.combine.regex:", res1))}
    if (is.na(res1))
    {
      #Gets penalty where Penalty comes before school name
      res1 <-
        trimws(gsub(
          penalties.regex,
          "",
          str_match(txt, team.penalties.regex.pre.lower)[1]
        ), which = "both")
      res1 <- foulTeam.checkName(res1, offense, defense, school_colors)
      if(mydebug) {print(paste("team.penalties.enforcedDeclined.combine.regex:", res1))}
      if (is.na(res1))
      {
        #Gets penalty where Penalty comes after school name
        res1 <-
          trimws(gsub(
            penalties.regex,
            "",
            str_match(txt, team.penalties.regex.pre.upper)[1]
          ), which = "both")
        res1 <- foulTeam.checkName(res1, offense, defense, school_colors)
        if(mydebug) {print(paste("team.penalties.regex.pre.upper:", res1))}
        if (is.na(res1))
        {
          #Gets penalty where Penalty comes after school name
          res1 <-
            trimws(gsub(
              penalties.regex,
              "",
              str_match(txt, team.penalties.regex.post.lower)[1]
            ), which = "both")
          res1 <- foulTeam.checkName(res1, offense, defense, school_colors)
          if(mydebug) {print(paste("team.penalties.regex.post.lower:", res1))}
          if (is.na(res1))
          {
            #Gets penalty where Penalty comes after school name
            res1 <-
              trimws(gsub(
                penalties.regex,
                "",
                str_match(txt, team.penalties.regex.post.upper)[1]
              ), which = "both")
            res1 <- foulTeam.checkName(res1, offense, defense, school_colors)
            if(mydebug) {print(paste("team.penalties.regex.post.upper:", res1))}
            if (is.na(res1) )
            {
              #Gets penalty where school name is in Titlecase instead of all CAPS
              res1 <-
                toupper(trimws(gsub(
                  penalties.regex,
                  "",
                  str_match(txt, team.penalties.regex.titlecase.pre.lower)[1]
                ), which = "both"))
              res1 <- foulTeam.checkName(res1, offense, defense, school_colors)
              if(mydebug) {print(paste("team.penalties.regex.titlecase.pre.lower:", res1))}
              if (is.na(res1) )
              {
                #Gets penalty where school name is in Titlecase instead of all CAPS
                res1 <-
                  toupper(trimws(gsub(
                    penalties.regex,
                    "",
                    str_match(txt, team.penalties.regex.titlecase.pre.upper)[1]
                  ), which = "both"))
                res1 <- foulTeam.checkName(res1, offense, defense, school_colors)
                if(mydebug) {print(paste("team.penalties.regex.titlecase.pre.upper:", res1))}
                if (is.na(res1) )
                {
                  #Gets penalty where school name is in Titlecase instead of all CAPS
                  res1 <-
                    toupper(trimws(gsub(
                      penalties.regex,
                      "",
                      str_match(txt, team.penalties.regex.titlecase.post.lower)[1]
                    ), which = "both"))
                  res1 <- foulTeam.checkName(res1, offense, defense, school_colors)
                  if(mydebug) {print(paste("team.penalties.regex.titlecase.post.lower:", res1))}
                  if (is.na(res1) )
                  {
                    #Gets penalty where school name is in Titlecase instead of all CAPS
                    res1 <-
                      toupper(trimws(gsub(
                        penalties.regex,
                        "",
                        str_match(txt, team.penalties.regex.titlecase.post.upper)[1]
                      ), which = "both"))
                    if(mydebug) {print(paste("team.penalties.regex.titlecase.post.upper:", res1))}
                    #Special cases
                    res1 <- foulTeam.checkName(res1, offense, defense, school_colors)
                    if(mydebug) {print(paste("foulTeam.checkName:", res1))}
                    if (is.na(res1) )
                    {
                      res1 <-
                        toupper(trimws(gsub(
                          penalties.regex,
                          "",
                          str_match(txt, team.penalties.regex.spacedUppers)[1]
                        ), which = "both"))
                      if(mydebug) {print(paste("team.penalties.regex.spacedUppers:", res1))}
                      res1 <- foulTeam.checkName(res1, offense, defense, school_colors)
                      if(mydebug) {print(paste("foulTeam.checkName:", res1))}
                    }
                    
                  }
                }
              }
            }
          }
        }
      }
    }
  } else if(!is.na(str_match(tolower(txt), declined.regex)[1])){
    res1 <- NA
    if(mydebug) {print(paste("declined.regex:", res1))}
  }
  
  regex.team.o <-
    gsub("&amp;", "&", (school_colors %>% filter(School == offense))$Penalty)
  regex.team.d <-
    gsub("&amp;", "&", (school_colors %>% filter(School == defense))$Penalty)
  if (!is.na(str_match(res1, regex.team.o)[1]))
  {
    res1 <- offense
  } else if (!is.na(str_match(res1, regex.team.d)[1])) {
    res1 <- defense
  } else if (is.na(res1)) {
    res1 <- NA
  } else{
    res1 <- paste0("Add team code for: ", res1)
  }
  res1
}

foulType <- function(txt)
{
  #Fix: if declined and accept another penalty, parse more: South Carolina, Tennessee
  
  penalty.type.list <- read.csv("../../data/FBS/penalty-types.csv")
  
  "%ni%" <- Negate("%in%")
  
  penalty.codes <-
    c(
      "BI",
      "DL",
      "FD",
      "FL",
      "HL",
      "IB",
      "IF",
      "IK",
      "IL",
      "IM",
      "IP",
      "IR",
      "IS",
      "OF",
      "PS",
      "RO",
      "RU",
      "UR",
      "CIT",
      "OFF",
      "TGB",
      "PFRP"
    )
  #repeat.regex <- "^([A-za-z]+)\\s\\1$"
  penalties.regex <- "(Penalty)|(PENALTY)|(Penalty)|(PENALTY)"
  regex.text.after.penalty <- "((PENALTY|Penalty).+)"
  declined.regex <- "[Dd]eclined"
  enforced.regex <- "[Ee]nforced"
  
  type.penalties.enforcedDeclined.split.regex <- 
    "declined;? (?:[A-Z\\p{Lu}-]+\\s?)+\\b ((?:[A-Z\\p{Lu}a-z\\p{Ll}-]+\\s?)+) on"
  # type.penalties.enforcedDeclined.combine.regex <- 
  #   "(?:[A-Z\\p{Lu}-]+\\s?)+\\b(?:(?:Penalty)|(?:PENALTY)|(?:Penalty)|(?:PENALTY)), ((?:[A-Z\\p{Lu}a-z\\p{Ll}-]+\\s?)+) on"
  type.penalties.enforcedDeclined.combine.regex.stage1 <- 
    "(?:[A-Z\\p{Lu}-]+\\s?)+\\b(?:(?:Penalty)|(?:PENALTY)|(?:Penalty)|(?:PENALTY)),?\\s*(.+)"
  
  #01#(PENALTY|Penalty),?.+declined;? [A-Z]+ ((\w+\s)+)(on\()
  #02#(?:PENALTY|Penalty),? (?:[A-Z]{2,}) State ((?:\w+\s)+)[\d\(]
  #03#(?:PENALTY|Penalty),? [A-Z]{2,}(?: [A-Z]{2,}),? ((?:\w+\s)+?)\s*[\d\(]
  #04#(?:PENALTY|Penalty),? [A-Z]{2,},? ((?:\w+\s)+?)\s*[\d\(]
  #0x#(?:PENALTY|Penalty),? fumbled snap.+?(?:PENALTY|Penalty),? Before the snap,? ((?:\w+\s)+?)(?:on|enforced|\d)
  #05#(?:PENALTY|Penalty),? ((?:\w+\s)+)[\d\(]
  #06#(?:PENALTY|Penalty),? [A-Z]+ ((?:\w+\s)+)on
  #07#(?:PENALTY|Penalty),? ((?:\w+\s)+)(?:on|enforced)
  #08#(?:PENALTY|Penalty),? Before the snap,? [A-Z]+ ((?:\w+\s)+?)(?:on|enforced|\d)
  #09#(?:PENALTY|Penalty),?(\s+)\(
  #10#(?:PENALTY|Penalty),? [A-Z]{2,} [A-Z]{2,}: ((?:\w+\s)+)[\d\(]
  #11#(?:PENALTY|Penalty),? [A-Z]{2,}: ((?:\w+\s)+)[\d\(]
  #11#(?:PENALTY|Penalty),? [A-Z]{2,} ([A-Z]{2,}) [\d\(]
  #??#(PENALTY|Penalty),? ((\w+,?\s)+)+ Don't recall what this finds, remove for now
  foul.type.regex <-
    # c(
    #   #"(?:PENALTY|Penalty),?.+declined;? [A-Z-]+ ((\\w+\\s)+)(on|\\()"
    #   "(?:PENALTY|Penalty),? (?:[A-Z-]{2,}) State ((?:\\w+\\s)+)[\\d\\(]"
    #   ,"(?:PENALTY|Penalty),? [A-Z-]{2,}(?: [A-Z-]{2,}),? ((?:\\w+\\s)+?)\\s*[\\d\\(]"
    #   ,"(?:PENALTY|Penalty),? [A-Z-]{2,},? ((?:\\w+\\s)+?)\\s*[\\d\\(]"
    #   ,"(?:PENALTY|Penalty),? fumbled snap.+?(?:PENALTY|Penalty),? Before the snap,? ((?:\\w+\\s)+?)(?:on|enforced|\\d)"
    #   ,"(?:PENALTY|Penalty),? ((?:\\w+\\s)+)[\\d\\(]"
    #   ,"(?:PENALTY|Penalty),? [A-Z-]+ ((?:\\w+\\s)+)on"
    #   ,"(?:PENALTY|Penalty),? ((?:\\w+\\s)+)(?:on|enforced)"
    #   ,"(?:PENALTY|Penalty),? Before the snap,? [A-Z-]+ ((?:\\w+\\s)+?)(?:on|enforced|\\d)"
    #   ,"(?:PENALTY|Penalty),?(\\s+)\\("
  #   ,"(?:PENALTY|Penalty),? [A-Z-]{2,} [A-Z-]{2,}: ((?:\\w+\\s)+)[\\d\\(]"
  #   ,"(?:PENALTY|Penalty),? [A-Z-]{2,}: ((?:\\w+\\s)+)[\\d\\(]"
  #   ,"(?:PENALTY|Penalty),? [A-Z-]{2,} ([A-Z-]{2,}) [\\d\\(]"
  #   #,"(PENALTY|Penalty),? ((\\w+,?\\s)+)+"
  # )
  c(
    #"(?:PENALTY|Penalty),?.+declined;? [A-Z-]+ ((\\w+\\s)+)(on|\\()"
    "(?:PENALTY|Penalty),? (?:[A-Z-]{2,}) State ((?:\\w+\\s)+)[\\d\\(]"
    ,"(?:PENALTY|Penalty),? [A-Z-]{2,}(?: [A-Z-]{2,}),? ((?:\\w+\\s)+?)\\s*[\\d\\(]"
    ,"(?:PENALTY|Penalty),? (12 (\\w+\\s)+)[\\d|\\(]"
    ,"(?:PENALTY|Penalty),? [A-Z-]{2,},? ((?:\\w+\\s)+?)\\s*[\\d\\(]"
    #,"(?:PENALTY|Penalty),? [A-Z-]{2,},? ((?:\\w+\\s)+?)\\s*(?:\\(|enforced|\\d)"
    #,"(?:PENALTY|Penalty),? [A-Z-]{2,},? ((?:\\w+\\s)+?)\\s*(?:\\(|enforced|\\d|on)"
    ,"(?:PENALTY|Penalty),? fumbled snap.+?(?:PENALTY|Penalty),? Before the snap,? ((?:\\w+\\s)+?)(?:on|enforced|\\d)"
    ,"(?:PENALTY|Penalty),? ((?:[A-Za-z]+\\s)+)[\\d\\(]"
    ,"(?:PENALTY|Penalty),? [A-Z0-9-]+ ((?:\\w+\\s)+)on"
    ,"(?:PENALTY|Penalty),? [A-Z0-9-]+ ((?:\\w+\\s)+)\\("
    ,"(?:PENALTY|Penalty),? ((?:\\w+\\s)+)(?:on|enforced)"
    ,"(?:PENALTY|Penalty),? Before the snap,? [A-Z-]+ ((?:\\w+\\s)+?)(?:on|enforced|\\d)"
    ,"(?:PENALTY|Penalty),?(\\s+)\\("
    ,"(?:PENALTY|Penalty),? [A-Z-]{2,} [A-Z-]{2,}: ((?:\\w+\\s)+)[\\d\\(]"
    ,"(?:PENALTY|Penalty),? [A-Z-]{2,}: ((?:\\w+\\s)+)[\\d\\(]"
    ,"(?:PENALTY|Penalty),? [A-Z-]{2,} ([A-Z-]{2,}) [\\d\\(]"
    ,"(?:PENALTY|Penalty),? .+ (Targeting)"
    #,"(PENALTY|Penalty),? ((\\w+,?\\s)+)+"
  )
  foul.type.group <- c(2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2)#, 3)
  
  #print(paste("Original:",txt))
  res2 <- NA
  if(!is.na(str_match(tolower(txt), enforced.regex)[1]) & !is.na(str_match(tolower(txt), declined.regex)[1]))
  {
    if(!is.na(str_match(txt, type.penalties.enforcedDeclined.split.regex)[2]))
    {
      res2 <- trimws(str_match(txt, type.penalties.enforcedDeclined.split.regex)[2], which = "both")
    }else{
      temp_txt <- str_match(txt, type.penalties.enforcedDeclined.combine.regex.stage1)[2]
      penalty.split <- unlist(str_split(temp_txt, " "))
      
      for(i in 1:3)
      {
        for(j in 1:3)
        {
          declined <- paste(penalty.split[1:i], collapse = " ")
          enforced <- paste(penalty.split[(i+1):(i+j)], collapse = " ")
          if(stri_trans_totitle(declined) %in% unlist(penalty.type.list, use.names = FALSE) & stri_trans_totitle(enforced) %in% unlist(penalty.type.list, use.names = FALSE))
          {
            res2 <- enforced
            break
          }
        }
      }
    }
  }else if(is.na(str_match(tolower(txt), "off-? ?setting")[1]) & is.na(str_match(tolower(txt), declined.regex)[1])) {
    txt <- str_match(txt, regex.text.after.penalty)[1]
    #print(paste("Penalty:",txt))
    
    res2 <-
      trimws(str_match(txt, foul.type.regex[[1]])[2], which = "both")
    #print(paste("i = 1:",res2))
    i <- 2
    while (is.na(res2))
    {
      if (i > length(foul.type.regex))
      {
        res2 <- "Missing"
        break
      }
      res2 <-
        trimws(str_match(txt, foul.type.regex[[i]])[foul.type.group[[i]]], which = "both")
      #print(paste("i = ", i,":",res2))
      i <- i + 1
    }
    
    if (res2 == "")
    {
      res2 <- "Missing"
      #Check if followingis penalties or other text
    } else if (res2 %ni% penalty.codes) {
      if (res2 == "Offsides") {
        res2 <- "Offside"
      }
      res2 <- stri_trans_totitle(res2)
      if (res2 == "Personal Foul Targeting") {
        res2 <- "Personal Foul, Targeting"
      }
      # if (!is.na(str_match(res2, repeat.regex)[1])) {
      #   res2 <- str_match(res2, repeat.regex)[2]
      # }
    }
  }
  
  res2
}

foulTransgressor <- function(txt)
{
  #.*\((([A-Z\p{Lu}a-z\p{Ll}',\.-]+\s?)+)\)
  penalty.who.regex <-
    ".*\\(((?:[A-Z\\p{Lu}][a-z\\p{Ll}',\\.-]+\\s?)+)\\)"
  trimws(str_match(txt, penalty.who.regex)[2], which = "both")
}
#----------------------------------------------------------------------------------------------------------------------------------------------------
# # Test functions
# team <- "Colorado"
# play.text <- plays %>%
#   #filter(Offense == team | Defense == team, Year == 2021) %>%
#   filter(Offense == team | Defense == team) %>%
#   select("Offense", "Defense", "Play.text")
# # write.csv(play.text, file = "play.text.csv", row.names=F)
# #play.text
# 
# txt.list <- c()
# for (txt in play.text$Play.text)
# {
#   res <- str_match(txt, penalties.regex)[1]
#   if (!is.na(res[1]))
#   {
#     txt.list <- append(txt.list, txt)
#   }
# }
# #txt.list
# 
# play.text.penalties <-
#   play.text %>% filter(Play.text %in% txt.list)
# 
# t.penalty.after <-
#   lapply(play.text.penalties$Play.text,
#          str_match,
#          regex.text.after.penalty)
# for (i in 1:length(t.penalty.after))
# {
#   t.penalty.after[[i]] <- t.penalty.after[[i]][1]
# }
# play.text.penalties <-
#   play.text.penalties %>% add_column(Penalty = unlist(t.penalty.after))
# 
# i <- 1024
# play.text.penalties$Play.text[i]
# foulTeam(play.text.penalties$Play.text[i], play.text.penalties$Offense[i], play.text.penalties$Defense[i], school_colors)
#foulTeam("McKee,Tanner pass incomplete to Yurosek,Benjamin PENALTY U W Offside (Tupuola-Fetui,Zion) 5 yards from U W41 to U W36, 1ST DOWN. NO PLAY.", "Stanford", "Washington", school_colors)
#----------------------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------------------------
#
txt <- "TEXAS A&M Penalty, Delay of Game (5 Yards) to the Alab 40"

foulTeam(txt, "Alabama", "Texas A&M", school_colors)

team.penalties.regex.post.lower <-
  "((([A-Z&\\p{Lu}-]{2,}\\s?)+)\\sPenalty)"
team.penalties.regex.post.upper <-
  "((([A-Z&\\p{Lu}-]{2,}\\s?)+)\\sPENALTY)"

res1 <-
  trimws(gsub(
    penalties.regex,
    "",
    str_match(txt, team.penalties.regex.post.lower)[1]
  ), which = "both")
res1
foulTeam.checkName(res1, "Alabama", "TEXAS A&M", school_colors)
#----------------------------------------------------------------------------------------------------------------------------------------------------

{
  regex.text.after.penalty <- "((PENALTY|Penalty).+)"
  penalties.regex <- "(Penalty)|(PENALTY)|(Penalty)|(PENALTY)"
  team.penalties.before.regex <-
    "(?:PENALTY|Penalty),? Before the snap,? ([A-Z\\p{Lu}]+) "
  #team.penalties.regex <- "((Penalty\\s(([A-Z&\\p{Lu}]{2,}\\s?)+))|(PENALTY\\s(([A-Z&\\p{Lu}]{2,}\\s?)+))|((([A-Z&\\p{Lu}]{2,}\\s?)+)\\sPenalty)|((([A-Z&\\p{Lu}]{2,}\\s?)+)\\sPENALTY))"
  team.penalties.regex.pre <-
    "((Penalty\\s(([A-Z&\\p{Lu}]{2,}\\s?)+))|(PENALTY\\s(([A-Z&\\p{Lu}]{2,}\\s?)+)))"
  team.penalties.regex.post <-
    "(((([A-Z&\\p{Lu}]{2,}\\s?)+)\\sPenalty)|((([A-Z&\\p{Lu}]{2,}\\s?)+)\\sPENALTY))"
  team.penalties.regex.titlecase <-
    "((Penalty\\s(([A-Z\\p{Lu}][a-z\\p{Ll}A-Z&\\p{Lu}]+\\s?)+))|(PENALTY\\s(([A-Z\\p{Lu}][a-z\\p{Ll}A-Z&\\p{Lu}]+\\s?)+))|((([A-Z\\p{Lu}][a-z\\p{Ll}A-Z&\\p{Lu}]+\\s?)+)\\sPenalty)|((([A-Z\\p{Lu}][a-z\\p{Ll}A-Z&\\p{Lu}]+\\s?)+)\\sPENALTY))"
  penalty.who.regex <-
    ".*\\(((?:[A-Z\\p{Lu}][a-z\\p{Ll}',\\.-]+\\s?)+)\\)"
}

##############################################################################################################
#To be fixed:
# App St "CLT IF"
# Arizona St "ARZ UNS", "ASU IB", "ASU IF", "TD ARIZONA"
# Ball St "Western Illinois |	Add team code for: UNS"
# Cal vs Nev Grabed player name instead of team name "ELIJAH"
##############################################################################################################


#team <- "Alabama"
#team <- "Arkansas"
#team <- "Auburn"
#team <- "Florida"
#team <- "Georgia"
#team <- "Kentucky"
#team <- "LSU"
#team <- "Mississippi State"
#team <- "Missouri"
#team <- "Ole Miss"
#team <- "South Carolina"
#team <- "Tennessee"
team <- "Texas A&M"
#team <- "Vanderbilt"
#team <- "Cincinnati"
#team <- "Michigan"
#team <- "Boston College"
#team <- "Virginia Tech"
#team <- "Nevada"
#team <- "Oklahoma State"
#team <- "Stanford"
#team <- "Tulsa"
#team <- "Florida Atlantic"

year <- 2021
week <- "wk06"
seasontype <- "regular"
#plays <- read.csv(paste0("../../../../data/", team,"_",year,"_",week,"_",seasontype,".csv"))
plays <- read.csv(paste0("../../data/", team,"_",year,"_",week,"_",seasontype,".csv"))

penalty.list <- c()
# team.list <- read.csv("../../data/FBS/teams-fbs-2021.csv", header = TRUE)
# for(team in unlist(team.list))
{
  print(team)
  
  play.text <- plays %>%
    #filter(Offense == team | Defense == team, Year == 2021) %>%
    filter(Offense == team | Defense == team) %>%
    select("Offense", "Defense", "Play.text")
  # write.csv(play.text, file = "play.text.csv", row.names=F)
  #play.text
  
  txt.list <- c()
  for (txt in play.text$Play.text)
  {
    res <- str_match(txt, penalties.regex)[1]
    if (!is.na(res[1]))
    {
      txt.list <- append(txt.list, txt)
    }
  }
  #txt.list
  
  play.text.penalties <-
    play.text %>% filter(Play.text %in% txt.list)
  
  t.penalty.after <-
    lapply(play.text.penalties$Play.text,
           str_match,
           regex.text.after.penalty)
  for (i in 1:length(t.penalty.after))
  {
    t.penalty.after[[i]] <- t.penalty.after[[i]][1]
  }
  play.text.penalties <-
    play.text.penalties %>% add_column(Penalty = unlist(t.penalty.after))
  #write.csv(play.text.penalties, file = paste0(team,"-playtext-penalty.csv"), row.names=F)
  
  
  print("Finding res1")
  team.o.lst <- c()
  team.d.lst <- c()
  penalty.info.team <- c()
  for (i in 1:length(play.text.penalties$Offense))
  {
    res1 <-
      foulTeam(
        play.text.penalties$Play.text[i],
        play.text.penalties$Offense[i],
        play.text.penalties$Defense[i],
        school_colors
      )
    penalty.info.team <- append(penalty.info.team, res1)
    team.d.lst <- append(team.d.lst,play.text.penalties$Defense[i])
    team.o.lst <- append(team.o.lst,play.text.penalties$Offense[i])
  }
  i <- 2
  play.text.penalties$Play.text[i]
  {
  str_match(play.text.penalties$Play.text[i], team.penalties.regex.pre)[1]
  str_match(play.text.penalties$Play.text[i], team.penalties.regex.post)[1]
  res1 <- trimws(gsub(penalties.regex, "", str_match(play.text.penalties$Play.text[i], team.penalties.before.regex)[2]), which = "both")
  res1
  res1 <- trimws(gsub(penalties.regex, "", str_match(play.text.penalties$Play.text[i], team.penalties.regex.pre)[1]), which = "both")
  res1
  res1 <- trimws(gsub(penalties.regex, "", str_match(play.text.penalties$Play.text[i], team.penalties.regex.post)[1]), which = "both")
  res1
  res1 <- toupper(trimws(gsub(penalties.regex, "", str_match(play.text.penalties$Play.text[i], team.penalties.regex.titlecase)[1]), which = "both"))
  res1
  team.o <-  play.text.penalties$Offense[i]
  team.d <-  play.text.penalties$Defense[i]
  team.o
  team.d
  regex.team.o <- gsub("&amp;", "&", (school_colors %>% filter(School == team.o))$Penalty)
  regex.team.d <- gsub("&amp;", "&", (school_colors %>% filter(School == team.d))$Penalty)
  regex.team.o
  regex.team.d
  #gsub("&amp;", "&", regex.team.d)
  !is.na(str_match(res1, regex.team.o)[1])
  !is.na(str_match(res1, regex.team.d)[1])
  if(!is.na(str_match(res1, regex.team.o)[1]))
  {
    res1 <- team.o
  }else if(!is.na(str_match(res1, regex.team.d)[1])){
    res1 <- team.d
  }else{
    res1 <- paste0("Add team code for: ", res1)
  }
  }
  res1
  foulTeam(play.text.penalties$Play.text[i], play.text.penalties$Offense[i], play.text.penalties$Defense[i], school_colors)

  
  print("Finding res2")
  penalty.info.type <- c()
  for (txt in play.text.penalties$Play.text)
  {
    res2 <- foulType(txt)
    penalty.info.type <- append(penalty.info.type, res2)
  }
  
  print("Finding res3")
  penalty.info.player <- c()
  for (txt in play.text.penalties$Play.text)
  {
    #print(txt)
    res3 <- foulTransgressor(txt)
    penalty.info.player <- append(penalty.info.player, res3)
  }
  
  penalty.info.df <-
    tibble(
      Offense = team.o.lst,
      Defense = team.d.lst,
      Team = penalty.info.team,
      Type = penalty.info.type,
      Player = penalty.info.player,
      Play.Text = play.text.penalties$Play.text,
      Penalty.text = play.text.penalties$Penalty
    )
  #sort(unique(penalty.info.type))
  write.csv(
    penalty.info.df,
    file = paste0(team, "-penalty-info.df.csv"),
    row.names = F
  )
  penalty.list <- append(penalty.list, penalty.info.type)
}
  #

write.csv(
  sort(unique(penalty.list)),
  file = "penalty-list.csv",
  row.names = F
)

sort(unique(penalty.info.type))
write.csv(
  sort(unique(penalty.info.type)),
  file = "penalty-type.csv",
  row.names = F
)
#

# Accepted/declined experiments--------------------------------------------------
play.text.declined <-
  play.text %>% filter(Play.text %in% txt.list) %>% filter(!is.na(str_match(Play.text, "[Dd]eclined")))
play.text.declined
write.csv(
  play.text.declined,
  file = paste0(team, "-declined-penalty.csv"),
  row.names = F
)
play.text.declined.accepted <-
  play.text.declined %>% filter(!is.na(str_match(Play.text, "[Aa]ccepted")))
play.text.declined.accepted

play.text.penalties$Play.text[3]

i <- 39
play.text$Play.text[i]
foulTeam(play.text$Play.text[i], play.text$Offense[i], play.text$Defense[i], school_colors)
foulType(play.text$Play.text[i])
foulTransgressor(play.text$Play.text[i])
#




################################################################################################################
# team <- "Arkansas"
# plays %>% filter(Offense == team | Defense == team, Play.text == "Josh Sanchez punt for 47 yds , Nathan Parodi returns for 33 yds to the ARKANSAS 40 ARKANSAS Penalty, Holding Holding on ZIMOS, Zach enforced ( Yards) declined")








# ################################################################################
# plays <- read.csv("../../data/all_games/all_games.csv")
#
#
# # Play types ###################################################################
# play.type <- plays %>% select("Play.type")
# play.type <- unique(unlist(play.type))
# #write.csv(play.type, "../../data/FBS/play_types.csv")
#
# placeholder <- plays %>% filter(Play.type == "placeholder")
# Uncategorized <- plays %>% filter(Play.type == "Uncategorized")
# blank <- plays %>% filter(Play.type == "")
#
# count.play.types <- plays %>% select("Play.type") %>% group_by(Play.type) %>% summarise(n=n())
# ggplot(count.play.types, aes(Play.type)) +
#   geom_bar()
#
# count.year.play.types <- plays %>% select("Year", "Play.type") %>% group_by(Year, Play.type) %>% summarise(n=n())















# Play text: get text and list of team abbreviations ####################################################################

penalties.teamName.Text <- function(team, play.text)
{
  team.penalties.regex <-
    "(((([A-Z&]+\\s?)+)\\sPenalty)|((([A-Z&]+\\s?)+)\\sPENALTY)|(Penalty\\s(([A-Z&]+\\s?)+))|(PENALTY\\s(([A-Z&]+\\s?)+)))"
  penalties.regex <- "(Penalty)|(PENALTY)|(Penalty)|(PENALTY)"
  txt.list <- c()
  play.text.only <- c()
  for (txt in play.text$Play.text)
  {
    #res <- str_replace(str_match(txt, team.penalties.regex)[1], "\\s?Penalty\\s?|\\s?PENALTY\\s?", "")
    res <- str_match(txt, team.penalties.regex)[1]
    if (!is.na(res[1]))
    {
      txt.list <- append(txt.list, res[1])
      play.text.only <- append(play.text.only, txt)
    }
  }
  # txt.list
  # play.text.only
  
  
  
  play.text.penalties <-
    play.text %>% filter(Play.text %in% play.text.only)
  #play.text.penalties
  
  #play.text.penalties$Play.text[[1]]
  name.list <- c()
  for (txt in play.text.penalties$Play.text)
  {
    #res <- str_match(txt, team.penalties.regex)[1]
    res <-
      trimws(gsub(
        penalties.regex,
        "",
        str_match(txt, team.penalties.regex)[1]
      ), which = "both")
    name.list <- append(name.list, res)
    #print(res)
  }
  #name.list
  
  
  #trimws(gsub(penalties.regex, "", str_match(play.text.penalties$Play.text[[1]], team.penalties.regex)[1]), which = "both")
  
  name.list <-  unique(name.list)
  #name.list
  write.csv(name.list,
            file = paste0(team, "-opps-penalty.csv"),
            row.names = F)
  write.csv(
    play.text.penalties,
    file = paste0(team, "-play-text.csv"),
    row.names = F
  )
}

#team.penalties.regex <- "(([A-Z&]+\\s)+Penalty)|(([A-Z&]+\\s+)PENALTY)|(Penalty\\s([A-Z&]+\\s)+)|(PENALTY\\s([A-Z&]+\\s)+)"
#team.pr <- "Alabama"
team.pr <- "Michigan"
#team.pr <- "Texas Tech"
#team.pr <- Coastal Carolina
#team.pr <- North Texas
#team.pr <- Idaho
#team.pr <- Illinois
#team.pr <- Ohio
#team.pr <- Rutgers
#team.pr <- UT San Antonio
#team.pr <- Liberty
#team.pr <- Minnesota
#team.pr <- Oregon
#team.pr <- Georgia Southern



play.text.teamName.text <- plays %>%
  #filter(Offense == team.pr | Defense == team.pr, Year == 2021) %>%
  filter(Offense == team.pr | Defense == team.pr) %>%
  select("Offense", "Defense", "Play.text")
#play.text.teamName.text

penalties.teamName.Text(team.pr, play.text.teamName.text)




# Other ########################################################################

# Setup to get yards for fumbles Own recovered (Opponent recovered is unsuccessful)
fumble.rec.own <-
  plays %>% filter(Play.type == "Fumble Recovery (Own)") %>% select("Play.type", "Yards.gained", "Play.text")
#write.csv(fumble.rec.own, "fumbles_rec_own.csv")

unlist(fumble.rec.own$Play.text[1])
toString(unlist(fumble.rec.own$Play.text[1]))

str_match(toString(fumble.rec.own$Play.text[1]), "for (\\d+) yds|yards.*")[2]

results <- c("sep=;")
#fileConn <- file("strmatch1.csv")
for (i in 1:1000)
{
  curr.str <- toString(fumble.rec.own$Play.text[i])
  print(curr.str)
  res <- str_match(curr.str, "for (\\d+) yd|yds|yards|yard.*")[2]
  print(res)
  results[i + 1] <- paste(res, "; ", curr.str)
}
#writeLines(results, fileConn)
#close(fileConn)

















# Color from JSON ##############################################################
year <- 2021
#team.data <- matrix(,nrow = 0, ncol=27)
team.data <-
  matrix(
    c(
      "id",
      "school",
      "mascot",
      "abbreviation",
      "alt_name1",
      "alt_name2",
      "alt_name3",
      "conference",
      "division",
      "color",
      "alt_color",
      "logo",
      "logo_alt",
      "venue_id",
      "name",
      "city",
      "state",
      "zip",
      "country_code",
      "timezone",
      "latitude",
      "longitude",
      "elevation",
      "capacity",
      "year_constructed",
      "grass",
      "dome"
    ),
    nrow = 1,
    ncol = 27
  )
team.data.json <-
  fromJSON(
    file = paste0(
      "../../data/FBS/FBS-teams-",
      year,
      ".json"
    )
  )

#team.data <-  rbind(team.data, c("id", "school", "mascot", "abbreviation", "alt_name1", "alt_name2", "alt_name3", "conference", "division", "color", "alt_color", "logo", "logo_alt", "venue_id", "name", "city", "state", "zip", "country_code", "timezone", "latitude", "longitude", "elevation", "capacity", "year_constructed", "grass", "dome"))
team.data
for (i in 1:length(team.data.json))
{
  team.data <-  rbind(
    team.data,
    c(
      ifelse(is.null(team.data.json[[i]][["id"]]) , NA , team.data.json[[i]][["id"]]),
      ifelse(is.null(team.data.json[[i]][["school"]]) , NA , team.data.json[[i]][["school"]]),
      ifelse(is.null(team.data.json[[i]][["mascot"]]) , NA , team.data.json[[i]][["mascot"]]),
      ifelse(is.null(team.data.json[[i]][["abbreviation"]]) , NA , team.data.json[[i]][["abbreviation"]]),
      ifelse(is.null(team.data.json[[i]][["alt_name1"]]) , NA , team.data.json[[i]][["alt_name1"]]),
      ifelse(is.null(team.data.json[[i]][["alt_name2"]]) , NA , team.data.json[[i]][["alt_name2"]]),
      ifelse(is.null(team.data.json[[i]][["alt_name3"]]) , NA , team.data.json[[i]][["alt_name3"]]),
      ifelse(is.null(team.data.json[[i]][["conference"]]) , NA , team.data.json[[i]][["conference"]]),
      ifelse(is.null(team.data.json[[i]][["division"]]) , NA , team.data.json[[i]][["division"]]),
      ifelse(is.null(team.data.json[[i]][["color"]]) , NA , team.data.json[[i]][["color"]]),
      ifelse(is.null(team.data.json[[i]][["alt_color"]]) , NA , team.data.json[[i]][["alt_color"]]),
      ifelse(is.null(team.data.json[[i]][["logos"]][[1]]) , NA , team.data.json[[i]][["logos"]][[1]]),
      ifelse(is.null(team.data.json[[i]][["logos"]][[2]]) , NA , team.data.json[[i]][["logos"]][[2]]),
      ifelse(is.null(team.data.json[[i]][["location"]][["venue_id"]]) , NA , team.data.json[[i]][["location"]][["venue_id"]]),
      ifelse(is.null(team.data.json[[i]][["location"]][["name"]]) , NA , team.data.json[[i]][["location"]][["name"]]),
      ifelse(is.null(team.data.json[[i]][["location"]][["city"]]) , NA , team.data.json[[i]][["location"]][["city"]]),
      ifelse(is.null(team.data.json[[i]][["location"]][["state"]]) , NA , team.data.json[[i]][["location"]][["state"]]),
      ifelse(is.null(team.data.json[[i]][["location"]][["zip"]]) , NA , team.data.json[[i]][["location"]][["zip"]]),
      ifelse(is.null(team.data.json[[i]][["location"]][["country_code"]]) , NA , team.data.json[[i]][["location"]][["country_code"]]),
      ifelse(is.null(team.data.json[[i]][["location"]][["timezone"]]) , NA , team.data.json[[i]][["location"]][["timezone"]]),
      ifelse(is.null(team.data.json[[i]][["location"]][["latitude"]]) , NA , team.data.json[[i]][["location"]][["latitude"]]),
      ifelse(is.null(team.data.json[[i]][["location"]][["longitude"]]) , NA , team.data.json[[i]][["location"]][["longitude"]]),
      ifelse(is.null(team.data.json[[i]][["location"]][["elevation"]]) , NA , team.data.json[[i]][["location"]][["elevation"]]),
      ifelse(is.null(team.data.json[[i]][["location"]][["capacity"]]) , NA , team.data.json[[i]][["location"]][["capacity"]]),
      ifelse(is.null(team.data.json[[i]][["location"]][["year_constructed"]]) , NA , team.data.json[[i]][["location"]][["year_constructed"]]),
      ifelse(is.null(team.data.json[[i]][["location"]][["grass"]]) , NA , team.data.json[[i]][["location"]][["grass"]]),
      ifelse(is.null(team.data.json[[i]][["location"]][["dome"]]) , NA , team.data.json[[i]][["location"]][["dome"]])
    )
  )
}

team.data

write.csv(
  team.data,
  file = paste0(
    "../../data/FBS/FBS-teams-",
    year,
    ".csv"
  ),
  row.names = F
)

is.null(team.data.json[[i]][["id"]])


team.data

str(team.data.json[[3]])

team.data.json[[1]][["school"]]
team.data.json[[1]][["color"]]
team.data.json[[1]][["alt_color"]]

team.data.json[[1]][["logos"]][[1]]

team.data.json[[1]][["location"]][["name"]]
