using Revise, WaltonForaging
##

ispath("/home/beatriz/Documents/") ? (main_path ="/home/beatriz/Documents/") : (main_path = "/Users/dariosarra/Documents/Lab/Walton/LForaging")
fig_dir = joinpath(main_path,"Figures")
# pokes = DataFrame(CSV.read(joinpath(main_path,"Miscellaneous/Poke_data.csv")))#, DataFrame)
# pokes2 = DataFrame(CSV.read(joinpath(main_path,"Miscellaneous/New_Poke_data.csv")))#, DataFrame)
pokes = CSV.read(joinpath(main_path,"Miscellaneous/States_Poke_data.csv"), DataFrame)
preprocess_pokes!(pokes)
open_html_table(pokes[1:2000,:])
##
pokes[!,:BIN] = Int64.(round.(pokes.DURATION ./ 0.1))
filter!(r-> r.BIN >= 1, pokes)
pokes[!,:PatchRewRate] = get_rew_rate(pokes.REWARD,pokes.BIN, 0.1, 2)
transform!(groupby(pokes,[:MOUSE,:DATE]), [:REWARD,:BIN] => (R,B) -> get_rew_rate(R,B, 0.1, 2) => :PatchRewRate)

##
mice = union(pokes.MOUSE)
days = union(pokes.DATE)
test = filter(r -> r.MOUSE == mice[1] && r.DATE == days[1], pokes)
check = fit(RhoComparison,test)
open_html_table(test[1:500,:])
mice[1]
days[1]
sum(test.BIN)
##
@df pokes density(:DURATION, group = :KIND, xrotation = 45)
savefig(joinpath(fig_dir,"Poke_Duration_density.png"))

@df pokes histogram(:DURATION, xrotation = 45, bins = 100)
savefig(joinpath(fig_dir,"Poke_Duration_histogram.png"))
##
fdf = filter(r-> r.SIDE != "travel", pokes)
fdf.MOUSE = categorical(fdf.MOUSE)
fdf.KIND = levels!(categorical(fdf.KIND),["poor", "medium", "rich"])
fdf.SIDE = categorical(fdf.SIDE)
fdf.TRAVEL = levels!(categorical(fdf.TRAVEL),["short", "long"])
fdf.REWARD = categorical(Bool.(fdf.REWARD))
f1 =  @formula(LEAVE ~ 1 + OUT_TRIAL+OUT_BOUT+DURATION+REWARD+TRAVEL+KIND + (1|MOUSE))
gm = fit(MixedModel, f1,fdf, Bernoulli())

##
pltdf = filter(r->r.DURATION <=2,fdf)
poke_rich, poke_rich_df =
    function_analysis(pltdf,:DURATION, cumulative_algorythm; grouping = :KIND, calc = :bootstrapping, xaxis = 0:0.1:2)
plot(poke_rich, ylabel = "Cumulative", xlabel = "Poke duration")
savefig(joinpath(fig_dir,"CumPokeRich.png"))
plt_trav = filter(r-> r.SIDE == "travel" && r.DURATION <=2, pokes)
dropmissing!(plt_trav)
poke_trav, poke_trav_df =
    function_analysis(plt_trav,:DURATION, cumulative_algorythm; grouping = :TRAVEL, calc = :bootstrapping, xaxis = 0:0.1:2)
plot(poke_trav, ylabel = "Cumulative", xlabel = "Poke duration")
savefig(joinpath(fig_dir,"CumPokeTrav.png"))
##
gd = groupby(filter(r->r.SIDE != "travel",pokes),[:MOUSE,:DATE,:TRIAL])
pre_trials = combine(gd) do dd
    DataFrame(
        DURATION_FULL = dd[end, :OUT_TRIAL],
        DURATION_SUM = round.(sum(dd.DURATION),digits =1),
        LAST_BOUT_FULL = dd[dd.LEAVE,:OUT_BOUT],
        LAST_BOUT_SUM = round.(sum(dd[dd.BOUT .== dd[dd.LEAVE,:BOUT],:DURATION]),digits =1),
        REWARDS = maximum(dd.BOUT),
        LAST_REWARD = Bool(dd[end,:REWARD]),
        SIDE = dd[1,:SIDE],
        KIND = dd[1,:KIND]
    )
end
open_html_table(pre_trials)

gd_tr = groupby(filter(r->r.SIDE == "travel",pokes),[:MOUSE,:DATE,:TRIAL])
trials_tr = combine(gd_tr) do dd
    DataFrame(
        TRAVEL_FULL = dd[end, :OUT_TRIAL],
        TRAVEL_SUM = round.(sum(dd.DURATION),digits = 1),
        TRAVEL_KIND = dd[1,:KIND]
    )
end
trials_tr.TRIAL = trials_tr.TRIAL .+1

trials = leftjoin(pre_trials, trials_tr, on = [:MOUSE,:DATE,:TRIAL])
open_html_table(pre_trials)
##
bout_sum_rich, bout_sum_rich_df =
    function_analysis(trials,:LAST_BOUT_SUM, cumulative_algorythm; grouping = :KIND, calc = :bootstrapping, xaxis = 0:0.5:10)
plot(bout_sum_rich, legend = :bottomright, fillalpha = 0.3, ylabel = "Cumulative", xlabel = "Last Bout duration (SUM)")
savefig(joinpath(fig_dir,"CumBoutSumRich.png"))
bout_full_rich, bout_full_rich_df =
    function_analysis(trials,:LAST_BOUT_FULL, cumulative_algorythm; grouping = :KIND, calc = :bootstrapping, xaxis = 0:1:40)
plot(bout_full_rich, legend = :bottomright, fillalpha = 0.3, ylabel = "Cumulative", xlabel = "Last Bout duration (FULL)")
savefig(joinpath(fig_dir,"CumBoutFullRich.png"))
##
trv_pltdf = filter(r->!ismissing(r.TRAVEL_KIND),trials)
bout_sum_rich, bout_sum_rich_df =
    function_analysis(trv_pltdf,:LAST_BOUT_SUM, cumulative_algorythm; grouping = :TRAVEL_KIND, calc = :bootstrapping, xaxis = 0:0.5:10)
plot(bout_sum_rich, legend = :bottomright, fillalpha = 0.3, ylabel = "Cumulative", xlabel = "Last Bout duration (SUM)")
savefig(joinpath(fig_dir,"CumBoutSumTrav.png"))
bout_full_rich, bout_full_rich_df =
    function_analysis(trv_pltdf,:LAST_BOUT_FULL, cumulative_algorythm; grouping = :TRAVEL_KIND, calc = :bootstrapping, xaxis = 0:1:40)
plot(bout_full_rich, legend = :bottomright, fillalpha = 0.3, ylabel = "Cumulative", xlabel = "Last Bout duration (FULL)")
savefig(joinpath(fig_dir,"CumBoutFullTrav.png"))
##
trial_sum_rich, trial_sum_rich_df =
    function_analysis(trials,:DURATION_SUM, cumulative_algorythm; grouping = :KIND, calc = :bootstrapping, xaxis = 0:1:30)
plot(trial_sum_rich, legend = :bottomright, fillalpha = 0.3, ylabel = "Cumulative", xlabel = "Trial duration (SUM)")
savefig(joinpath(fig_dir,"CumTrialSumRich.png"))
trial_full_rich, trial_full_rich_df =
    function_analysis(trials,:DURATION_FULL, cumulative_algorythm; grouping = :KIND, calc = :bootstrapping, xaxis = 0:5:100)
plot(trial_full_rich, legend = :bottomright, fillalpha = 0.3, ylabel = "Cumulative", xlabel = "Trial duration (FULL)")
savefig(joinpath(fig_dir,"CumTrialFullRich.png"))
##
trv_pltdf = filter(r->!ismissing(r.TRAVEL_KIND),trials)
trial_sum_rich, trial_sum_rich_df =
    function_analysis(trv_pltdf,:DURATION_SUM, cumulative_algorythm; grouping = :TRAVEL_KIND, calc = :bootstrapping, xaxis = 0:1:30)
plot(trial_sum_rich, legend = :bottomright, fillalpha = 0.3, ylabel = "Cumulative", xlabel = "Trial duration (SUM)")
savefig(joinpath(fig_dir,"CumTrialSumTrav.png"))
trial_full_rich, trial_full_rich_df =
    function_analysis(trv_pltdf,:DURATION_FULL, cumulative_algorythm; grouping = :TRAVEL_KIND, calc = :bootstrapping, xaxis = 0:5:100)
plot(trial_full_rich, legend = :bottomright, fillalpha = 0.3, ylabel = "Cumulative", xlabel = "Trial duration (FULL)")
savefig(joinpath(fig_dir,"CumTrialFullTrav.png"))
##
gs0 = trials
gs0.DURATION_FULL = round.(gs0.DURATION_FULL)
filter!(r->r.DURATION_FULL <=60, gs0)
gs1 = combine(groupby(gs0,[:MOUSE,:DURATION_FULL,:KIND]),
    :LAST_BOUT_FULL	.=> [mean,sem]
)

gs2 = combine(groupby(gs1,[:DURATION_FULL,:KIND]),
    :LAST_BOUT_FULL_mean .=> [mean,sem] .=> [:LAST_BOUT_FULL_mean,:LAST_BOUT_FULL_sem]
)

sort!(gs2,:DURATION_FULL)
@df gs2 plot(:DURATION_FULL, :LAST_BOUT_FULL_mean, ribbon = :LAST_BOUT_FULL_sem, group = :KIND,
    xlabel = "Trial Duration (Full)", ylabel = "Last Bout Duration (Full)")
savefig(joinpath(fig_dir,"Full(BoutxTrav)_Kind.png"))
##
gs0 = trials
gs0.DURATION_FULL = round.(gs0.DURATION_FULL)
filter!(r->r.DURATION_FULL <=60, gs0)
gs1 = combine(groupby(gs0,[:MOUSE,:DURATION_FULL,:TRAVEL_KIND]),
    :LAST_BOUT_FULL	.=> [mean,sem]
)

gs2 = combine(groupby(gs1,[:DURATION_FULL,:TRAVEL_KIND]),
    :LAST_BOUT_FULL_mean .=> [mean,sem] .=> [:LAST_BOUT_FULL_mean,:LAST_BOUT_FULL_sem]
)

sort!(gs2,:DURATION_FULL)
filter!(r->!ismissing(r.TRAVEL_KIND), gs2)
@df gs2 plot(:DURATION_FULL, :LAST_BOUT_FULL_mean, ribbon = :LAST_BOUT_FULL_sem, group = :TRAVEL_KIND,
    xlabel = "Trial Duration (Full)", ylabel = "Last Bout Duration (Full)")
savefig(joinpath(fig_dir,"Full(BoutxTrav)_Travel.png"))
##
sum(trials.LAST_REWARD)/nrow(trials)
