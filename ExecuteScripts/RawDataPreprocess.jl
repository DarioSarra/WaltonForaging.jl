using Revise, WaltonForaging
if ispath("/home/beatriz/Documents/")
    main_path ="/home/beatriz/Documents/"
elseif ispath("/Users/dariosarra/Documents/Lab/Walton/WaltonForaging")
        main_path = "/Users/dariosarra/Documents/Lab/Walton/WaltonForaging"
elseif ispath(joinpath("C:\\Users","dario","OneDrive","Documents","Lab","Walton","WaltonForaging"))
        main_path = joinpath("C:\\Users","dario","OneDrive","Documents","Lab","Walton","WaltonForaging")
end
# Exp = "DAphotometry"
Exp = "5HTPharma"
fig_dir = joinpath(main_path,Exp, "Figures")
##
a = 0+34
##
# FileList = readdir(joinpath(main_path,Exp,"RawData"))
# filter!(r -> ismatch(r".txt",r), FileList)
# filter!(r -> !ismatch(r"RP10-2021-02-26-150714.txt",r), FileList) ##Incomplete file in Pharma data
# filter!(r -> !ismatch(r"RP10-2021-02-26-161201.txt",r), FileList) ##Incomplete file in Pharma data
# AllPokes, AllBouts = process_foraging(main_path,Exp)
# pharmainfo = joinpath(replace(@__DIR__,basename(@__DIR__)=>""),
#     "src","RawDataPreprocess","PharmaRaquel.jl")
# include(pharmainfo)
# bout_path = joinpath(main_path,Exp,"Processed","AllBouts_20220615.csv")
# CSV.write(bout_path, AllBouts)
# pokes_path = joinpath(main_path,Exp,"Processed","AllPokes_20220615.csv")
# CSV.write(pokes_path, AllPokes)
##
AllBouts = CSV.read(joinpath(main_path,Exp,"Processed","AllBouts_20220615.csv"), DataFrame)
AllPokes = CSV.read(joinpath(main_path,Exp,"Processed","AllPokes_20220615.csv"), DataFrame)
##
dropmissing(AllBouts)
open_html_table(AllBouts[1:10,:])
##
cit  = filter(r->r.Phase == "Cit",dropmissing(AllBouts))
fm1 = StatsBase.fit(MixedModel, @formula(ForageTime_Sum ~ 1 + Pokes + Richness + Travel + Treatment + (1+Richness*Pokes*Travel|MouseID)), cit)
##
check = combine(groupby(AllBouts,[:Phase,:Group,:Treatment,:MouseID]),
    :Day => (x -> join(union(x),",")) => :Day,
    :Richness => (x -> join(sort(union(x)),",")) => :Richness,
    :Richness => (x -> length(union(x))) => :RichnessN,
    :Travel => (x -> join(sort(union(skipmissing(x))),",")) => :Travel,
    :Travel => (x -> length(union(skipmissing(x)))) => :TravelN,
    :Patch => maximum => :PatchesN
    )
filter!(r -> r.Phase != "None", check)
sort!(check,[:RichnessN,:TravelN])
open_html_table(check)
##
union(AllBouts.MouseID)
union(AllBouts.SubjectID)
check_names = [ismatch(r"RP\d$",x) ? "RP0"*x[end] : x for x in union(AllBouts.SubjectID)]
union(check_names)
## process_patches(AllBouts)
unique(AllBouts.State)
AllBouts.Reward
df1 = combine(groupby(AllBouts,[:MouseID,:Day,:Patch])) do dd
    df2 = DataFrame(
        Forage_sum = sum(skipmissing(dd[dd.State .== "Forage", :ForageTime_Sum])),
        Forage_tot = sum(skipmissing(dd[dd.State .== "Forage", :ForageTime_total])),
        Travel_sum = sum(skipmissing(dd[dd.State .== "Travel", :ForageTime_Sum])),
        Travel_tot = sum(skipmissing(dd[dd.State .== "Travel", :ForageTime_total])),
        RewardLatency = mean(skipmissing(dd[dd.State .== "Forage", :ForageTime_Sum])),
        Bouts = nrow(dd[dd.State .== "Forage",:]),
        Rewards = sum(skipmissing(dd.Rewarded))
    )
    for x in [:Richness,:Travel, :ActivePort, :Taskname, :Experimentname, :Startdate]
        df2[!,x] .= dd[1,x]
    end
    return df2
end
open_html_table(df1[1:100,:])
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
