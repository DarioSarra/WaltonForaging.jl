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
# FileList = readdir(joinpath(main_path,Exp,"RawData"))
# filter!(r -> ismatch(r".txt",r), FileList)
# filter!(r -> !ismatch(r"RP10-2021-02-26-150714.txt",r), FileList) ##Incomplete file in Pharma data
# filter!(r -> !ismatch(r"RP10-2021-02-26-161201.txt",r), FileList) ##Incomplete file in Pharma data
# AllPokes, AllBouts = process_foraging(main_path,Exp)
# pharmainfo = joinpath(replace(@__DIR__,basename(@__DIR__)=>""),
#     "src","RawDataPreprocess","PharmaRaquel.jl")
# include(pharmainfo)
# bout_path = joinpath(main_path,Exp,"Processed","AllBouts_20220627.csv")
# CSV.write(bout_path, AllBouts)
# pokes_path = joinpath(main_path,Exp,"Processed","AllPokes_20220627.csv")
# CSV.write(pokes_path, AllPokes)
##
AllBouts = CSV.read(joinpath(main_path,Exp,"Processed","AllBouts_20220627.csv"), DataFrame)
AllPokes = CSV.read(joinpath(main_path,Exp,"Processed","AllPokes_20220627.csv"), DataFrame)
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
check_bouts = combine(groupby(AllBouts,[:Day,:MouseID]),
    :Reward_p => (x -> sum(.!ismissing.(x))) => :Reward_p,
    :Reward_p => (x -> [union(x)]) => :Reward_p_cases,
    :Reward_c => (x -> sum(skipmissing(x))) => :Reward_c,
    :Patch => maximum)
sort!(check_bouts,[:Day,:MouseID])
filter!(r -> r.Day >= "2021/03/01",check_bouts)
open_html_table(check_bouts)
# open_html_table(filter(r-> r.MouseID == "RP18" && r.Day == "2021/03/29", AllBouts))
##
check_pokes = combine(groupby(AllPokes,[:Day,:MouseID]),
    :RewardAvailable => (x -> sum(.!ismissing.(x))) => :Reward_p,
    :RewardDelivery => (x -> sum(.!ismissing.(x))) => :Reward_d,
    :RewardConsumption => (x -> sum(.!ismissing.(x))) => :Reward_c)
sort!(check,[:Day,:MouseID])
filter!(r -> r.Day >= "2021/03/01",check_pokes)
open_html_table(check_pokes)
##
Import = CSV.read(joinpath(main_path,Exp,"Processed","AllSessionsSummary.csv"), DataFrame)
open_html_table(Import)
##
file = "RP18-2021-03-01-153105.txt"
session_path = joinpath(main_path,Exp,"RawData",file)
pokes = process_raw_session(session_path; observe = false)
sum(.!ismissing.(pokes.RewardAvailable))
pokes2 = filter(r -> r.MouseID == "RP18" && r.Day == "2021/03/01",AllPokes)
sum(.!ismissing.(pokes2.RewardAvailable))
pokes3 = filter(r -> !ismissing(r.Poke) && !r.Incorrect,pokes)
findall(pokes.Incorrect .&& .!ismissing.(pokes.RewardAvailable))
sum(.!ismissing.(pokes3.RewardAvailable))
findall(.!ismissing.(pokes.Poke))
findall(.!pokes.Incorrect)
findall(.!ismissing.(pokes.RewardAvailable))
findall((pokes.Incorrect) .&& (.!ismissing.(pokes.RewardAvailable)))
open_html_table(pokes[400:460,:])
##
sum(.!ismissing.(pokes.TravelComplete))
change_idx = findall(ismatch.(r"^start_forage_",pokes.Port))

sum(.!ismissing.(pokes.TravelComplete))
##
lines = readlines(session_path)
eachlines = eachline(session_path)
prov = table_raw_data(lines, eachlines) #translate the text document to an equivalent table
idx = findall(ismissing.(prov.Poke))
for i in idx
    res = findprev(!ismissing,prov.Poke,i)
    if !isnothing(res)
        prov[i,:Poke] = prov[res,:Poke]
    end
end
findall(ismissing.(prov.Poke))
pokes = combine(groupby(prov, :Poke)) do dd
    WaltonForaging.adjustevents(dd) ## groupby poke count to create a table with all info about each poke per row
end

sum(.!ismissing.(pokes.RewardAvailable))
RichnessDict_keys = sort(collect(keys(countmap(pokes.IFT))))
RichnessDict = Dict(x => y for (x,y) in zip(RichnessDict_keys,["rich", "medium", "poor", missing]))
pokes[!,:State] = WaltonForaging.find_task_state(pokes) #understand if the poke is during foraging or travelling
pokes[:,:Port] = [get(WaltonForaging.PortDict,x, x) for x in pokes.Port] #tranlaste poke numbers to readable equivalent left, right and travel
idx = findall(ismatch.(r"^reward_consumption_",pokes.Port))
for i in idx
    port = ismatch(r"left",pokes[i,:Port]) ? "RewLeft" : "RewRight"
    rewardedpoke = findprev(ismatch.(Regex(port),pokes.Port),i)
    pokes[rewardedpoke,:RewardConsumption] = pokes[i,:PokeIn]
end
transform!(pokes,[:Port,:TravelComplete] => ((p,t)->WaltonForaging.activeside(p,t)) => :ActivePort)
sum(.!ismissing.(pokes.RewardAvailable))
WaltonForaging.incorrectpokes!(pokes)

##
transform!(pokes, :State => WaltonForaging.count_patches => :Patch)
# check the travel duration looking at T values for pokes in travel state. The last patch might not have such info
transform!(groupby(pokes,:Patch), [:T, :State] =>
    ((t,s) -> WaltonForaging.determine_travel(t,s)) => :Travel)

# shift Travel info to the following patch since travel duration affects following not preceeding behaviour
pokes.Travel = vcat([missing],pokes[1:end-1, :Travel])
transform!(groupby(pokes,:Patch), :IFT =>
    (x -> WaltonForaging.determine_richness(x,RichnessDict)) => :Richness)
#occasionally pokeout have missing values in that case it search for the poke_out value accoriding to the poke_out number
checkPokeOut  = ismissing.(pokes.PokeOut) .&& ismatch.(r"^Poke",pokes.Port)
if any(checkPokeOut)
    for i in findall(checkPokeOut)
        pnum = pokes[i,:Poke]
        if ismissing(pokes[i,:Poke])
            println("poke deleted skipping poke out time correction")
            continue
        end
        pos = findfirst(prov.PokeOut_count .== pnum)
        pokes[i,:PokeOut] = prov[pos,:Time]
    end
end
pokes[!,:Duration] = pokes.PokeOut - pokes.PokeIn
session_info = WaltonForaging.parseGlobalInfo(lines)
for (x,y) in session_info
    pokes[!, x] .= y
end
pokes =  pokes[:,[:Richness, :Travel,:State,:Poke,:ActivePort,
    :Incorrect,:Port, :PokeIn, :PokeOut, :Duration,
    :Patch, :P,#:Bout,:AlternativePatch,
    :TravelOnset,:TravelComplete,
    :RewardAvailable, :RewardDelivery, :RewardConsumption,
    :Rsync_count, :Rsync_time, :StateIn, :StateOut, :T, :AFT, :IFT,
    :SubjectID, :Taskname, :Experimentname, :Startdate]]
sort!(pokes,:PokeIn)
##

##
WaltonForaging.incorrectpokes!(pokes)
sum(.!ismissing.(pokes.RewardAvailable))
transform!(pokes, :State => count_patches => :Patch)
open_html_table(pokes[3719:3735,:])
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
