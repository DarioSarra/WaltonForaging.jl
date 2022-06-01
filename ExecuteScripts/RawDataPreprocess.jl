using Revise, WaltonForaging
ispath("/home/beatriz/Documents/") ? (main_path ="/home/beatriz/Documents/") : (main_path = "/Users/dariosarra/Documents/Lab/Walton/WaltonForaging")
# Exp = "DAphotometry"
Exp = "5HTPharma"
fig_dir = joinpath(main_path,Exp, "Figures")
# pokes = DataFrame(CSV.read(joinpath(main_path,"Miscellaneous/Poke_data.csv")))#, DataFrame)
# pokes2 = DataFrame(CSV.read(joinpath(main_path,"Miscellaneous/New_Poke_data.csv")))#, DataFrame)
pokes = CSV.read(joinpath(main_path,"Miscellaneous/States_Poke_data.csv"), DataFrame)
##
FileList = readdir(joinpath(main_path,Exp,"RawData"))
filter!(r -> ismatch(r".txt",r), FileList)
filter!(r -> !ismatch(r"RP10-2021-02-26-150714.txt",r), FileList) ##Incomplete file in Pharma data
filter!(r -> !ismatch(r"RP10-2021-02-26-161201.txt",r), FileList) ##Incomplete file in Pharma data
##
AllBouts = DataFrame()
for file in FileList[1:end]
    println(file)
    session = joinpath(main_path,Exp,"RawData",file)
    pokes = process_raw_session(session; observe = false)
    bouts = process_bouts(pokes; observe = false)
    # path = joinpath(main_path,Exp,"Processed",replace(file,"txt"=>"csv"))
    # CSV.write(path, bouts)
    if isempty(AllBouts)
        AllBouts = bouts
        allowmissing!(AllBouts)
    else
        append!(AllBouts,bouts)
    end
end
AllBouts[!,:Day] = [string(x[1:10]) for x in AllBouts.Startdate]
AllBouts[!,:MouseID] = [ismatch.(r"RP\d$",x) ? "RP0"*x[end] : x for x in AllBouts.SubjectID]
path = joinpath(main_path,Exp,"Processed","AllBouts_20220601.csv")
CSV.write(path, AllBouts)
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
PhaseDict
AllBouts[!,:Phase] = [get(PhaseDict,x,"None") for x in AllBouts.Day]
##
Group_A = ["RP01","RP03","RP05","RP07","RP09","RP11","RP13","RP15","RP17"]
Group_B = ["RP02","RP04","RP06","RP08","RP10","RP12","RP14","RP16","RP18"]
AllBouts[!,:Group] = [x in Group_A ? "A" : "B" for x in AllBouts.MouseID]
GroupDict = Dict{String,String}()
for (name,vals) in zip(["Cit","MDL","SB","GBR","Ato"], [Cit_days,MDL_days,SB_days,GBR_days,Ato_days])
    for (g,v) in zip(["B","A"],vals)
        GroupDict[v*"_"*g] = name
    end
    for (g,v) in zip(["A","B"],vals)
        GroupDict[v*"_"*g] = "VEH"
    end
end
GroupDict
transform!(AllBouts, [:Day,:Group] => ByRow((d,g)-> get(GroupDict,d*"_"*g,"None")) => :Treatment)
##
filter(r -> r.Treatment)
g_df = combine(groupby(AllBouts,[:MouseID,:Group]), :Treatment => t -> [union(t)])
g_df = combine(groupby(AllBouts,[:Treatment,:Group]),
    :MouseID => (t -> [union(t)]) => :MouseID,
    :Day => (t -> [union(t)]) => :Day)
open_html_table(g_df)
##
session = joinpath(main_path,Exp,"RawData",FileList[1])
#=
Depending on when the p line is written, during forge port poke or during travel port poke,
T  = poke time required to get reward (retrospective?), poke time required to travel
    (initial value to threshold 2000)
IFT = always tells you the initial average of the dist for which the richness is taken
AFT = during reward collection average dist for that specific reward (the updated average),
    during travel for how long in the previous forage before leaving
There is a timeout for going back to travel if animal don't engage in foraging
=#
##
session = filter(r -> ismatch(r"RP10-2021-02-25-152749.txt",r), FileList)[1]
pokes = process_raw_session(joinpath(main_path,Exp,"RawData",session); observe = true)
combine(groupby(pokes,:Patch), :RewardAvailable => x -> sum(.!ismissing.(x)))
bouts = process_bouts(pokes; observe = true)

##
nrow(AllBouts)
check_idx = findfirst(AllBouts.SubjectID .== "fp17" .&&
    AllBouts.Startdate .== "2019/06/2015:06:16" .&&
    AllBouts.Patch .== 53)

open_html_table(AllBouts[check_idx-10:check_idx+10,:])
findfirst(ismissing(AllBouts.In))
##
test = filter(r -> r.State == "Forage" && r.GiveUp && !ismissing(r.ForageTime_Sum), AllBouts)
test.Richness = categorical(test.Richness)
levels!(test.Richness,["poor","medium","rich"])
test.Travel = categorical(test.Travel)
levels!(test.Travel,["Short","Long"])
df1 = combine(groupby(test,[:Travel,:Richness,:SubjectID]),:ForageTime_Sum .=> mean => :ForageTime)
df2 = combine(groupby(df1,[:Travel,:Richness]),:ForageTime .=> [mean, sem])
@df df2 scatter(:Richness,:ForageTime_mean,group = :Travel,yerror=:ForageTime_sem,
    ylims=(1000,3000), legend = :outerright,
    ylabel = "Average forage time \n from last reward at leaving", xlabel = "Patch richness",
    legendtitle = "Travel type")
savefig("/Users/dariosarra/Documents/Lab/Walton/WaltonForaging/DAphotometry/CoarseAnalysis_LastBout.pdf")
##
test = filter(r -> r.State == "Forage", AllBouts)
test.Richness = categorical(test.Richness)
levels!(test.Richness,["poor","medium","rich"])
test.Travel = categorical(test.Travel)
levels!(test.Travel,["Short","Long"])
df1 = combine(groupby(test,[:Travel,:Richness,:Patch,:SubjectID,:Startdate]),:ForageTime_Sum .=>
    (x->sum(skipmissing(x))) => :ForageTime)
df2 = combine(groupby(df1,[:Travel,:Richness,:SubjectID]),:ForageTime .=> mean => :ForageTime)
df3 = combine(groupby(df2,[:Travel,:Richness]),:ForageTime .=> [mean, sem])
@df df3 scatter(:Richness,:ForageTime_mean, group = :Travel, yerror =:ForageTime_sem,
    ylims = (2000,9000), legend = :outerright,
    ylabel = "Average forage time \n from last reward at leaving", xlabel = "Patch richness",
    legendtitle = "Travel type")
savefig("/Users/dariosarra/Documents/Lab/Walton/WaltonForaging/DAphotometry/CoarseAnalysis2_FullPatch.pdf")
