using Revise, WaltonForaging
if ispath("/home/beatriz/Documents/Datasets/WaltonForaging")
    main_path ="/home/beatriz/Documents/Datasets/WaltonForaging"
elseif ispath("/Users/dariosarra/Documents/Lab/Walton/WaltonForaging")
        main_path = "/Users/dariosarra/Documents/Lab/Walton/WaltonForaging"
elseif ispath(joinpath("C:\\Users","dario","OneDrive","Documents","Lab","Walton","WaltonForaging"))
        main_path = joinpath("C:\\Users","dario","OneDrive","Documents","Lab","Walton","WaltonForaging")
end
# Exp = "DAphotometry"
Exp = "5HTPharma"
## Get raw data
# rawt = CSV.read(joinpath(main_path,"data",Exp,"Processed","RawTable.csv"), DataFrame)
# open_html_table(rawt[1:1000,:])
# df = process_rawtable(rawt)
# CSV.write(joinpath(main_path,"data",Exp,"Processed","JuliaRawTable.csv"),df)
df = CSV.read(joinpath(main_path,"data",Exp,"Processed","JuliaRawTable.csv"), DataFrame)
# open_html_table(df[1:500,:])
## Process pokes
pokes = process_pokes(df)
transform!(pokes, :SubjectID => ByRow(x -> (ismatch(r"RP\d$",x) ? "RP0"*x[end] : x)) => :SubjectID)
bouts = process_bouts(pokes)
RaquelPharmaCalendar!(pokes)
RaquelPharmaCalendar!(bouts)
CSV.write(joinpath(main_path,"data",Exp,"Processed","PokesTable.csv"),pokes)
CSV.write(joinpath(main_path,"data",Exp,"Processed","BoutsTable.csv"),bouts)
##
pokes = CSV.read(joinpath(main_path,"data",Exp,"Processed","PokesTable.csv"), DataFrame)
bouts = CSV.read(joinpath(main_path,"data",Exp,"Processed","BoutsTable.csv"), DataFrame)
##
testb= dropmissing(bouts,:SummedForage)
unique(testb.Treatment)
filter!(r->r.Treatment == "Baseline", testb)
## define x span
@df testb density(:SummedForage./1000, xlims = (0,10))
maxtime = 20000
xspan = range(0,maxtime, step = 1000)
gr(size = (400,400), xticks = 0:1:20)
## Naive survival
naive_df = filter(r -> r.Leave && !r.Rewarded && r.SummedForage <=maxtime,testb)
naive_surv = combine(groupby(naive_df,:SubjectID)) do dd
                dd2 = DataFrame(Bin = collect(xspan))
                dd2[!, :Survival] = [sum(dd.SummedForage .> b)/nrow(dd) for b in dd2.Bin]
                return dd2
        end
naive_res = combine(groupby(naive_surv,:Bin), :Survival .=> [mean, sem])
@df naive_res plot(:Bin/1000, :Survival_mean, ribbon = :Survival_sem, label = "Naive")
## Kaplan-Meier
using Survival
Distributions.fit(KaplanMeier,testb.SummedForage, testb.Rewarded)
km_df = filter(r -> r.SummedForage <=maxtime,testb)
km_surv = combine(groupby(km_df,:SubjectID)) do dd
                roundedforage = round.(dd.SummedForage./1000, digits = 0)
                # Coding of event times is true for actual event time, false for right censored
                km = Distributions.fit(KaplanMeier,roundedforage, .!dd.Rewarded)
                dd2 = DataFrame(Bin = km.times, Survival = km.survival)
                for v in maximum(dd2.Bin)+1:1:maxtime/1000
                        push!(dd2, (v, 0.0), promote=false) # add bins not calculated beyond max reached
                        push!(dd2,(0.0,1.0), promote=false) # add first bin starting at 1
                end
                return dd2
        end
open_html_table(km_surv)
km_res = combine(groupby(km_surv,:Bin), :Survival .=> [mean, sem])
@df km_res plot!(:Bin, :Survival_mean, ribbon = :Survival_sem, label = "Kaplan-Meier")
