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
mice = union(pokes.MOUSE)
test_multiple_sessions = filter(r -> r.MOUSE == mice[1],pokes)
@time fit(RhoComparison,test_multiple_sessions)
function fit_handler(test_multiple_sessions)
    res = []
    for i in 1:10
        push!(res,fit(RhoComparison,test_multiple_sessions))
    end
    return res
end

Francois_res = (env_alpha = 0.003, patch_aplha = 0.266, beta = 6.26, reset = 0.339, bias = 4.147)
open_html_table(test_multiple_sessions[1:5000,:])
open_html_table(test_multiple_sessions[1:10,:])
-sum(log.(test_multiple_sessions.Probability))

##
mice = union(pokes.MOUSE)
days = union(pokes.DATE)
pokes = CSV.read(joinpath(main_path,"Miscellaneous/States_Poke_data.csv"), DataFrame)
open_html_table(pokes[1:100,:])
sum(df.BIN)
sum(df.REWARD)
##
env_alpha, patch_alpha, beta, reset_val, bias = (0.003, 0.25, 6, 0.3, 4)
transform!(df,[:REWARD,:BIN,:ENV_INITIALVALUE,:NEWSESSION] => ((r,b,i,n) -> env_get_rew_rate(r,b,i,n,env_alpha)) => :EnvRewRate)
transform!(df, [:REWARD,:BIN,:NEWTRIAL] => ((r,b,n) -> patch_get_rew_rate(r, b, reset_val, n, patch_alpha)) => :PatchRewRate)
# m = init(RhoComparison, df)
m = RhoComparison([0.003, 0.25, 6, 0.3, 4])
transform!(df, [:EnvRewRate,:PatchRewRate,:LEAVE] => ByRow((e,p,l) -> Poutcome(m,e,p,l)) => :Probability)
-sum(log.(filter(r -> r.SIDE == "travel", df).Probability))
open_html_table(df[1:1498,:])
exp(bias + beta*patch_rew_rate)/(exp(bias + beta*patch_rew_rate) + exp(beta*env_rew_rate))
beta = 6
bias = 4
log()
patch_rew_rate = df.PatchRewRate[1]
env_rew_rate = df.EnvRewRate[1]
exp(bias + beta*patch_rew_rate)/(exp(bias + beta*patch_rew_rate) + exp(beta*env_rew_rate))
##
x = 0.16874999999999998
x + 0.25*(1 - x)

##
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
