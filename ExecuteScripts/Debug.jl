using Revise, WaltonForaging
ispath("/home/beatriz/Documents/") ? (main_path ="/home/beatriz/Documents/") : (main_path = "/Users/dariosarra/Documents/Lab/Walton/WaltonForaging")
# Exp = "DAphotometry"
Exp = "5HTPharma"
session_path = joinpath(main_path,Exp,"RawData","RP1-2021-04-01-145340.txt")
observe = true

!ispath(session_path) && error("\"$(session_path)\" is not a viable path")
lines = readlines(session_path)
eachlines = eachline(session_path)
prov = table_raw_data(lines, eachlines)
observe && open_html_table(prov)
pokes = combine(groupby(prov, :Poke)) do dd
    WaltonForaging.adjustevents(dd)
end
sort!(pokes,:PokeIn)
open_html_table(pokes)
# pokes[!,:Duration] = pokes.PokeOut - pokes.PokeIn
RichnessDict_keys = sort(collect(keys(countmap(pokes.IFT))))
RichnessDict = Dict(x => y for (x,y) in zip(RichnessDict_keys,["rich", "medium", "poor", missing]))
pokes[!,:State] = WaltonForaging.find_task_state(pokes)
pokes[:,:Port] = [get(WaltonForaging.PortDict,x, x) for x in pokes.Port]

idx = findall(ismatch.(r"^reward_consumption_",pokes.Port))
for i in idx
    port = ismatch(r"left",pokes[i,:Port]) ? "RewLeft" : "RewRight"
    rewardedpoke = findprev(ismatch.(Regex(port),pokes.Port),i)
    pokes[rewardedpoke,:RewardConsumption] = pokes[i,:PokeIn]
end
transform!(pokes,[:Port,:TravelComplete] => ((p,t)->WaltonForaging.activeside(p,t)) => :ActivePort)
# pokes[!,:Incorrect] = @. !ismatch(Regex(pokes.ActivePort),pokes.Port) && ismatch(r"^Poke", pokes.Port)
WaltonForaging.incorrectpokes!(pokes)
transform!(pokes, :State => WaltonForaging.count_patches => :Patch)
open_html_table(pokes)
transform!(groupby(pokes,:Patch), [:T, :State] => ((t,s) -> WaltonForaging.determine_travel(t,s)) => :Travel)
open_html_table(pokes)

transform!(groupby(pokes,:Patch), :IFT => (x -> WaltonForaging.determine_richness(x,RichnessDict)) => :Richness)
open_html_table(pokes)

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

session_info = parseGlobalInfo(lines)
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
observe && open_html_table(pokes)
