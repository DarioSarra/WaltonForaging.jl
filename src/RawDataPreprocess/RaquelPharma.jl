ismonday = x->Dates.dayofweek(x) == Dates.Monday;
istuesday = x->Dates.dayofweek(x) == Dates.Tuesday;
iswednesday = x->Dates.dayofweek(x) == Dates.Wednesday;
isthursday = x->Dates.dayofweek(x) == Dates.Thursday;
isfriday = x->Dates.dayofweek(x) == Dates.Friday;
issaturday = x->Dates.dayofweek(x) == Dates.Saturday;
issunday = x->Dates.dayofweek(x) == Dates.Sunday;


function RaquelPharmaCalendar!(df)
    dateformat = DateFormat("y/m/d")
    df[!,:Day] = [Dates.Date(x[1:10],dateformat) for x in df.StartDate]
    ## Define phases
    Train_days = [Date(2021,02,22),Date(2021,02,28)]
    Cit_days = [Date(2021,03,01),Date(2021,03,04)]
    MDL_days = [Date(2021,03,08),Date(2021,03,11)]
    SB_days = [Date(2021,03,15),Date(2021,03,18)]
    GBR_days = [Date(2021,03,22),Date(2021,03,25)]
    Ato_days = [Date(2021,03,29),Date(2021,04,01)]
    AllDays = vcat(Cit_days,MDL_days,SB_days,GBR_days,Ato_days)
    PhaseDict = Dict()
    for (p,n) in zip([Train_days,Cit_days,MDL_days,SB_days,GBR_days,Ato_days],["Trained","CIT","MDL","SB","GBR","ATO"])
        period = collect(range(firstdayofweek(p[1]), lastdayofweek(p[2]), step = Day(1)))
        for d in period
            PhaseDict[d] = n
        end
    end
    df[!,:Phase] = [get(PhaseDict,x,"None") for x in df.Day]
    ## Define groups
    Group_A = ["RP01","RP03","RP05","RP07","RP09","RP11","RP13","RP15","RP17"]
    Group_B = ["RP02","RP04","RP06","RP08","RP10","RP12","RP14","RP16","RP18"]
    df[!,:Group] = [x in Group_A ? "A" : "B" for x in df.SubjectID]
    ## define treatment accoridng to phase and weekday
    df[!,:Treatment] .= "None"
    for (key, subdf) in pairs(groupby(df,[:Phase,:Group, :Day]))
        key.Phase == "None" || key.Phase == "Trained" && continue
        if ismonday(key.Day)
            if key.Group == "A"
                subdf[!,:Treatment] .= "VEH"
            elseif key.Group == "B"
                subdf[!,:Treatment] .= key.Phase
            end
        elseif isthursday(key.Day)
            if key.Group == "A"
                subdf[!,:Treatment] .= key.Phase
            elseif key.Group == "B"
                subdf[!,:Treatment] .= "VEH"
            end
        else
            subdf[!,:Treatment] .= "Baseline"
        end
    end
    ##
    # GroupDict = Dict{String,String}()
    # for (name,vals) in zip(["Cit","MDL","SB","GBR","Ato"], [Cit_days,MDL_days,SB_days,GBR_days,Ato_days])
    #     for (g,v) in zip(["B","A"],vals)
    #         GroupDict[string(v)*"_"*g] = name
    #     end
    #     for (g,v) in zip(["A","B"],vals)
    #         GroupDict[string(v)*"_"*g] = "VEH"
    #     end
    # end
    # transform!(df, [:Day,:Group] => ByRow((d,g)-> get(GroupDict,string(d)*"_"*g,"None")) => :Treatment)
end
##
# AllPokes[!,:MouseID] = [ismatch(r"RP\d$",x) ? "RP0"*x[end] : x for x in AllPokes.SubjectID]
# AllBouts[!,:MouseID] = [ismatch(r"RP\d$",x) ? "RP0"*x[end] : x for x in AllBouts.SubjectID]
# AllPokes[!,:Day] = [x[1:10] for x in AllPokes.Startdate]
# AllBouts[!,:Day] = [x[1:10] for x in AllBouts.Startdate]
# ##
# Cit_days = ["2021/03/01","2021/03/04"]
# MDL_days = ["2021/03/08","2021/03/11"]
# SB_days = ["2021/03/15","2021/03/18"]
# GBR_days = ["2021/03/22","2021/03/25"]
# Ato_days = ["2021/03/29","2021/04/01"]
# AllDays = vcat(Cit_days,MDL_days,SB_days,GBR_days,Ato_days)
# PhaseDict = Dict{String,String}()
# for (name,vals) in zip(["Cit","MDL","SB","GBR","Ato"], [Cit_days,MDL_days,SB_days,GBR_days,Ato_days])
#     for i in vals
#         PhaseDict[i] = name
#     end
# end
# AllPokes[!,:Phase] = [get(PhaseDict,x,"None") for x in AllPokes.Day]
# AllBouts[!,:Phase] = [get(PhaseDict,x,"None") for x in AllBouts.Day]
# ##
# Group_A = ["RP01","RP03","RP05","RP07","RP09","RP11","RP13","RP15","RP17"]
# Group_B = ["RP02","RP04","RP06","RP08","RP10","RP12","RP14","RP16","RP18"]
# AllPokes[!,:Group] = [x in Group_A ? "A" : "B" for x in AllPokes.MouseID]
# AllBouts[!,:Group] = [x in Group_A ? "A" : "B" for x in AllBouts.MouseID]
# ##
# GroupDict = Dict{String,String}()
# for (name,vals) in zip(["Cit","MDL","SB","GBR","Ato"], [Cit_days,MDL_days,SB_days,GBR_days,Ato_days])
#     for (g,v) in zip(["B","A"],vals)
#         GroupDict[v*"_"*g] = name
#     end
#     for (g,v) in zip(["A","B"],vals)
#         GroupDict[v*"_"*g] = "VEH"
#     end
# end
# transform!(AllPokes, [:Day,:Group] => ByRow((d,g)-> get(GroupDict,d*"_"*g,"None")) => :Treatment)
# transform!(AllBouts, [:Day,:Group] => ByRow((d,g)-> get(GroupDict,d*"_"*g,"None")) => :Treatment)
