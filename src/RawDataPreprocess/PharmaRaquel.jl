df[!,:MouseID] = [ismatch(r"RP\d$",x) ? "RP0"*x[end] : x for x in df.SubjectID]
df[!,:Day] = [x[1:10] for x in df.StartDate]
##
Cit_days = ["2021/03/01","2021/03/04"]
MDL_days = ["2021/03/08","2021/03/11"]
SB_days = ["2021/03/15","2021/03/18"]
GBR_days = ["2021/03/22","2021/03/25"]
Ato_days = ["2021/03/29","2021/04/01"]
AllDays = vcat(Cit_days,MDL_days,SB_days,GBR_days,Ato_days)
PhaseDict = Dict{String,String}()
for (name,vals) in zip(["Cit","MDL","SB","GBR","Ato"], [Cit_days,MDL_days,SB_days,GBR_days,Ato_days])
    for i in vals
        PhaseDict[i] = name
    end
end
df[!,:Phase] = [get(PhaseDict,x,"None") for x in df.Day]
##
Group_A = ["RP01","RP03","RP05","RP07","RP09","RP11","RP13","RP15","RP17"]
Group_B = ["RP02","RP04","RP06","RP08","RP10","RP12","RP14","RP16","RP18"]
df[!,:Group] = [x in Group_A ? "A" : "B" for x in df.MouseID]
##
GroupDict = Dict{String,String}()
for (name,vals) in zip(["Cit","MDL","SB","GBR","Ato"], [Cit_days,MDL_days,SB_days,GBR_days,Ato_days])
    for (g,v) in zip(["B","A"],vals)
        GroupDict[v*"_"*g] = name
    end
    for (g,v) in zip(["A","B"],vals)
        GroupDict[v*"_"*g] = "VEH"
    end
end
transform!(df, [:Day,:Group] => ByRow((d,g)-> get(GroupDict,d*"_"*g,"None")) => :Treatment)
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
