using Revise, WaltonForaging
ispath("/home/beatriz/Documents/") ? (main_path ="/home/beatriz/Documents/") : (main_path = "/Users/dariosarra/Documents/Lab/Walton/WaltonForaging")
# Exp = "DAphotometry"
Exp = "5HTPharma"

Bout_path = joinpath(main_path,Exp,"Processed","full_PharmaData.csv")
bouts = CSV.read(Bout_path, DataFrame)
Baseline_days = ["2021/02/09","2021/02/10","2021/02/11","2021/02/12","2021/02/16", "2021/02/17","2021/02/18","2021/02/19","2021/02/22"]
transform!(bouts, [:Day, :Phase] => ByRow((d,p) -> in(d,Baseline_days) ? "Training" : p) => :Phase)
println(propertynames(bouts))
ex = filter(r-> r.MouseID == "RP01" && r.Day =="2021/03/11", bouts)
open_html_table(ex)
union(bouts.Travel)
findfirst(ismissing.(bouts.Travel))
patches = combine(groupby(bouts,[:MouseID,:Day,:Patch]),
    [:Group, :Phase, :Treatment, :Bout, :State, :ActivePort, :Richness, :Travel] .=> first .=>
        [:Group, :Phase, :Treatment, :Bout, :State, :ActivePort, :Richness, :Travel],
    :Rewarded => (x -> sum(skipmissing(x))) => :Rewards,
    :ForageTime_Sum => (x -> sum(skipmissing(x[1:end-1]))) => :ForageTime_sum,
    :ForageTime_Sum => (x -> x[end]) => :TravelTime_sum,
    :ForageTime_Sum => (x -> length(x) > 1 ? x[end-1] : 0) => :ForageTime_last,
    :ForageTime_total => (x -> sum(skipmissing(x[1:end-1]))) => :ForageTime_total,
    :ForageTime_total => (x -> x[end]) => :TravelTime_total,
    :Pokes => (x -> sum(skipmissing(x[1:end-1]))) => :Pokes,
    :Rewarded => (x -> length(x) > 1 ? x[end-1] : missing) => :LeaveRewarded
    )

open_html_table(patches[1:500,:])
unique(patches.Treatment)
Rdf2 = combine(Rdf1, :Rewards .=> [mean,std])
check = combine(groupby(bouts,[:MouseID,:Day,:Patch]), :ForageTime_Sum => length => :Size)
sort!(check,:Size)
ex2 = filter(r-> r.MouseID == "RP01" && r.Day =="2021/03/11", patches)
open_html_table(ex2)
##
patches.Treatment = CategoricalArray(patches.Treatment)
levels!(patches.Treatment,[ "None", "VEH", "Cit", "MDL", "SB", "GBR", "Ato"])
dropmissing!(patches)
patches.Travel = CategoricalArray(patches.Travel)
levels!(patches.Travel,[ "Short", "Long"])
patches.Richness = CategoricalArray(patches.Richness)
levels!(patches.Richness,[ "poor", "medium","rich"])
##
using MixedModels
f1 =  @formula(ForageTime_last ~ 1 + Travel+Richness+Treatment+(1|MouseID))
gm = MixedModels.fit(MixedModel, f1,patches)
##
df1 = combine(groupby(patches,[:MouseID, :Treatment, :Phase,:Richness, :Travel]),
    :ForageTime_last => mean => :ForageTime_last
)
open_html_table(df1)
df2 = combine(groupby(df1,[:Treatment, :Phase,:Richness, :Travel]),
    :ForageTime_last .=> [mean, sem]
)
open_html_table(df2)
##
p = []
for x in groupby(df2,:Phase)
    plt = @df x groupedbar(:Richness, :ForageTime_last_mean./1000, group = :Treatment, yerror = :ForageTime_last_sem./1000,
    title = :Phase[end], legend = false, titlefontsize = 9)
    push!(p,plt)
end
p2 = plot(p...)
##
joinpath(main_path,Exp,"Figures","basic.png")
savefig(p2, joinpath(main_path,Exp,"Figures","basic.pdf"))
