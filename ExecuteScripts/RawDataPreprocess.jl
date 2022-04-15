using Revise, WaltonForaging
ispath("/home/beatriz/Documents/") ? (main_path ="/home/beatriz/Documents/") : (main_path = "/Users/dariosarra/Documents/Lab/Walton/WaltonForaging")
fig_dir = joinpath(main_path,"Figures")
# pokes = DataFrame(CSV.read(joinpath(main_path,"Miscellaneous/Poke_data.csv")))#, DataFrame)
# pokes2 = DataFrame(CSV.read(joinpath(main_path,"Miscellaneous/New_Poke_data.csv")))#, DataFrame)
pokes = CSV.read(joinpath(main_path,"Miscellaneous/States_Poke_data.csv"), DataFrame)
##
Exp = "DAphotometry"#"5HTPharma"
FileList = readdir(joinpath(main_path,Exp,"RawData"))
filter!(r -> ismatch(r".txt",r), FileList)
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
session
pokes = process_raw_session(session; observe = true)
combine(groupby(pokes,:Patch), :RewardAvailable => x -> sum(.!ismissing.(x)))
bouts = process_bouts(pokes; observe = true)
##
findfirst(FileList.== "fp14-2019-05-30-172855.txt")
AllBouts = DataFrame()
for file in FileList[1:end]
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
    println(file)
end
path = joinpath(main_path,Exp,"Processed","AllBouts.csv")
CSV.write(path, AllBouts)
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
