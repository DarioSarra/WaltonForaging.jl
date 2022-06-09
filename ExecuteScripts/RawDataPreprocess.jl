using Revise, WaltonForaging
ispath("/home/beatriz/Documents/") ? (main_path ="/home/beatriz/Documents/") : (main_path = "/Users/dariosarra/Documents/Lab/Walton/WaltonForaging")
# Exp = "DAphotometry"
Exp = "5HTPharma"
fig_dir = joinpath(main_path,Exp, "Figures")
pokes = CSV.read(joinpath(main_path,"Miscellaneous/States_Poke_data.csv"), DataFrame)
##
FileList = readdir(joinpath(main_path,Exp,"RawData"))
filter!(r -> ismatch(r".txt",r), FileList)
filter!(r -> !ismatch(r"RP10-2021-02-26-150714.txt",r), FileList) ##Incomplete file in Pharma data
filter!(r -> !ismatch(r"RP10-2021-02-26-161201.txt",r), FileList) ##Incomplete file in Pharma data
##
# AllPokes, AllBouts = process_foraging(main_path,Exp)
# pharmainfo = joinpath(replace(@__DIR__,basename(@__DIR__)=>""),
#     "src","RawDataPreprocess","PharmaRaquel.jl")
# include(pharmainfo)
# bout_path = joinpath(main_path,Exp,"Processed","AllBouts2_20220609.csv")
# CSV.write(bout_path, AllBouts)
# pokes_path = joinpath(main_path,Exp,"Processed","AllPokes2_20220609.csv")
# CSV.write(pokes_path, AllPokes)
##
AllBouts = CSV.read(joinpath(main_path,Exp,"Processed","AllBouts2_20220609.csv"), DataFrame)
AllPokes = CSV.read(joinpath(main_path,Exp,"Processed","AllPokes2_20220609.csv"), DataFrame)
##
open_html_table(AllBouts[findall(ismissing.(AllBouts.Travel)),:])
##
g_df = combine(groupby(AllBouts,[:Treatment,:Group]),
    :MouseID => (t -> [union(t)]) => :MouseID,
    :Day => (t -> [union(t)]) => :Day)
open_html_table(g_df)
##
open_html_table(AllBouts[1:10,:])
bouts = AllBouts[:,[:MouseID,:Day,:Group,:Phase,:Treatment,
    :Bout, :Patch, :State,:ActivePort,:Richness, :Travel,
    :In, :Out, :ForageTime_total, :ForageTime_Sum,
    :Pokes, :Rewarded, :GiveUp]]
open_html_table(bouts[1:100,:])
##
path = joinpath(main_path,Exp,"Processed","full_PharmaData.csv")
CSV.write(path, bouts)
##
fbouts = filter(r -> r.Phase != "None", bouts)
path = joinpath(main_path,Exp,"Processed","filtered_PharmaData.csv")
CSV.write(path, fbouts)
open_html_table(fbouts[1:500,:])
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
