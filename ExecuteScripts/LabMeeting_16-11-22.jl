using Revise, WaltonForaging
if ispath("/home/beatriz/Documents/Datasets/WaltonForaging")
    main_path ="/home/beatriz/Documents/Datasets/WaltonForaging"
elseif ispath("/Users/dariosarra/Documents/Lab/Oxford/Walton/WaltonForaging")
        main_path = "/Users/dariosarra/Documents/Lab/Oxford/Walton/WaltonForaging"
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
testb = dropmissing(bouts,:SummedForage)
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
@df naive_res plot(:Bin/1000, :Survival_mean, ribbon = :Survival_sem, label = "Naive",
    ylabel = "Survival Rate", xlabel = "elapsed time (s)", tickfontsize = 7)
fig_path = "/Users/dariosarra/Documents/Lab/Oxford/Walton/Presentations/Lab_meeting20221116"
savefig(joinpath(fig_path,"NaiveSurvival.pdf"))
## Kaplan-Meier
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
km_res = combine(groupby(km_surv,:Bin), :Survival .=> [mean, sem])
@df km_res plot!(:Bin, :Survival_mean, ribbon = :Survival_sem, label = "Kaplan-Meier")
savefig(joinpath(fig_path,"KaplanMeierSurvival.pdf"))
##
Distributions.fit(KaplanMeier,testb.SummedForage, testb.Rewarded)
Distributions.fit(NelsonAalen,testb.SummedForage, testb.Rewarded)
travel_df = filter(r -> r.SummedForage <=maxtime && !ismissing(r.Travel),testb)
travel = combine(groupby(travel_df,[:SubjectID, :Travel])) do dd
                roundedforage = round.(dd.SummedForage./1000, digits = 0)
                # Coding of event times is true for actual event time, false for right censored
                km = Distributions.fit(KaplanMeier,roundedforage, .!dd.Rewarded)
                haz = Distributions.fit(NelsonAalen,roundedforage, .!dd.Rewarded)
                dd2 = DataFrame(Bin = km.times, Survival = km.survival, CumHazard = haz.chaz)
                # for v in maximum(dd2.Bin)+1:1:maxtime/1000
                #         push!(dd2, (v, 0.0), promote=false) # add bins not calculated beyond max reached
                #         push!(dd2,(0.0,1.0), promote=false) # add first bin starting at 1
                # end
                return dd2
        end
open_html_table(travel)
travel_res = combine(groupby(travel,[:Bin,:Travel]), :Survival .=> [mean, sem], :CumHazard .=> [mean, sem])
@df travel_res plot(:Bin, :Survival_mean, yerror = :Survival_sem,
    group = :Travel,
    ylabel = "Survival Rate", xlabel = "elapsed time (s)", tickfontsize = 7)
savefig(joinpath(fig_path,"Survival_Travel.pdf"))
@df travel_res plot(:Bin, :CumHazard_mean, yerror = :CumHazard_sem,
        group = :Travel, legend = :topleft,
        ylabel = "Cumulative Hazard", xlabel = "elapsed time (s)", tickfontsize = 7)
savefig(joinpath(fig_path,"CumHazard_Travel.pdf"))
## median Survival
mediansurv = combine(groupby(travel, [:SubjectID,:Travel]), [:Survival,:Bin] =>
    ((s,t) -> t[findlast(s.>=0.5)]) => :MedianSurv)
mediansurv = unstack(mediansurv,:SubjectID,:Travel,:MedianSurv)
mst = SignedRankTest(Float64.(mediansurv.short), Float64.(mediansurv.long))
##Cox regression
travel_df[!,:Event] = EventTime.(travel_df.SummedForage, .!travel_df.Rewarded)
model = coxph(@formula(Event ~ Travel + Richness + RewardsInTrial), travel_df)
coefnames(model)
coef(model)
stderror(model)
DataFrame(coeftable(model))
## Cox by mouse
res_cox = combine(groupby(travel_df,:SubjectID)) do dd
        model = coxph(@formula(Event ~ Travel + Richness + RewardsInTrial), dd)
        return DataFrame(coeftable(model))
end
test_cox = combine(groupby(res_cox,:Name)) do dd
        test = OneSampleTTest(dd.Estimate)
        ci1,ci2 = confint(test)
        DataFrame(P = pvalue(test),
                Mean = test.xbar,
                CI = ci2-test.xbar,
                OrigCI = confint(test))
end
open_html_table(test_cox)
@df res_cox scatter(:Estimate, :Name, xticks = :auto, xrotation = 45, markercolor = :lightgrey,
        label = "subject coeff")
        vline!([0,0], linestyle = :dash, linecolor = :black, label = "")
        @df test_cox scatter!(:Mean, :Name, xerror = :CI,
        markercolor = :red, markersize = 6, color = :black,
        label = "t-test estimate")
savefig(joinpath(fig_path,"Cox.pdf"))
##
form1 = @formula(Leave ~ 1 + SummedForage + Travel + Richness + RewardsInTrial +
    (1 + SummedForage + Travel + Richness + RewardsInTrial|SubjectID))
mdl1 = MixedModels.fit(MixedModel,form1, travel_df, Bernoulli())
##
form2 = @formula(Leave ~ 1 + SummedForage * Travel + SummedForage * Richness +
    SummedForage * RewardsInTrial +
    (1 + SummedForage + Travel + Richness + RewardsInTrial|SubjectID))
mdl2 = MixedModels.fit(MixedModel,form2, travel_df, Bernoulli())
##
mdf = DataFrame(coeftable(mdl1))
rename!(mdf, Symbol("Std. Error") => :Err, Symbol("Coef.") => :Estimate)
@df mdf scatter(:Estimate, :Name, xerror= :Err,
        xticks = :auto, xrotation = 45, markercolor = :red,
        markersize = 6, color = :black,
        label = "Logistic MixedModel estimates", legend = false)
        vline!([0,0], linestyle = :dash, linecolor = :black, label = "")
##
sort!(travel_res,[:Travel,:Bin])
open_html_table(travel_res)
Haz_df = transform(groupby(travel_res,:Travel), :Survival_mean => (x -> vcat(diff(x),[0])) => :DiffSurv)
transform!(groupby(Haz_df,:Travel),[:Survival_mean, :DiffSurv] =>
        ByRow((s,d) -> -(d/s)) => :HazardRate
)
transform!(groupby(Haz_df,:Travel), :HazardRate => cumsum)
open_html_table(Haz_df)
## Logrank attempt
N_ev_df1 = combine(groupby(travel_df,[:Travel, :SubjectID])) do dd
    DataFrame(Total = nrow(dd), Censored = sum(dd.Rewarded), N_ev = nrow(dd) - sum(dd.Rewarded))
end
N_ev_df2 = combine(groupby(N_ev_df1,:Travel), :N_ev => mean => :N_ev)
Ex_ev_df1 = combine(groupby(travel,[:Travel, :SubjectID])) do dd
    DataFrame(Ex_ev = sum(dd.Survival))
end
Ex_ev_df2 = combine(groupby(Ex_ev_df1,:Travel), :Ex_ev => mean => :Ex_ev)
LogRank_df = innerjoin(N_ev_df2,Ex_ev_df2, on = :Travel)
LogRank_df[!,:LogRank] =
transform!(LogRank_df, [:N_ev, :Ex_ev] => ByRow((n,e) -> ((n-e)^2)/e) => :LogRank)
pdf(Chisq(1), sum(LogRank_df.LogRank))
open_html_table(check)
number_of_events_g1 = nrow(filter(r-> !r.Rewarded,travel_df))
expected_events_g1
##
