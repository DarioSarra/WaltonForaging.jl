using Revise, WaltonForaging
## Leaving times threshold rate
gr(size = (600,600))
patch = ["poor", "medium","rich"]
travel = ["long", "short"]
stim = [false, true]
Thr_SimulatedStim  =  DataFrame(patch = String[], travel = String[], stim = Bool[], time = Float64[],
    color = Symbol[], line = Symbol[], group = String[])
for p in patch
    pv = p == "rich" ? 3 : p == "medium" ? 2 : 1
    for t in travel
        tv = t == "short" ? -1 : 1
        l = t == "short" ? :solid : :dash
        tgroup = t =="short" ? "Short Travel" : "Long Travel"
        for s in stim
            if s
                pre = t == "short" ? 2.5 : 1
                sv = 1.3 - pre*(0.4)
                c = :blue
                sgroup = " Stim"
            else
                sv = 0
                c = :black
                sgroup = " No stim"
            end
            value = 3 * pv + tv + sv
            label = tgroup * sgroup
            push!(Thr_SimulatedStim, (patch = p, travel = t, stim = s, time = value, color = c, line = l, group = label))
        end
    end
end
@df Thr_SimulatedStim plot(:patch,:time, group = :group,
    legend = :topleft, color = :color, linestyle = :line,
    ylabel = "Patch leaving time (simulated)",
    xlabel = "Patch Richness", ylims = (0,11))
##
folder = "/Users/dariosarra/Dropbox (Personal)/2022_BBSRC_Foraging/Figures/Illustrative_Serotonin_effects"
savefig(joinpath(folder,"Bhv_trheshold1.pdf"))
##
thr_df1 = combine(groupby(Thr_SimulatedStim,[:patch, :stim]), :time => mean)
change_thr_patch=unstack(thr_df1, :stim, :time_mean)
change_thr_patch[!,:change] = change_thr_patch[:,3] - change_thr_patch[:,2]
change_thr_patch[!,:color] .= :cyan
change_thr_patch[!,:Hypothesis] .= "Global"
@df change_thr_patch bar(:patch, :change,
    ylabel = "Stimulated change in patch leving time", xlabel = "Patch Richness",
    color = :blue, legend = false, ylims = (0,1))
    # @df change_Stim_patch plot!(:patch, :change,linestyle = :dot, color = :grey)
##
savefig(joinpath(folder,"Bhv_trheshold2.pdf"))
##
thr_df2 = combine(groupby(Thr_SimulatedStim,[:travel, :stim]), :time => mean)
change_thr_trav=unstack(thr_df2, :stim, :time_mean)
change_thr_trav[!,:change] = change_thr_trav[:,3] - change_thr_trav[:,2]
change_thr_trav[!,:color] .= :cyan
change_thr_trav[!,:Hypothesis] .= "Global"
@df change_thr_trav bar(:travel, :change,
    ylabel = "Stimulated change in patch leving time",
    xlabel = "Travel distance", color = :blue, legend = false, ylims = (0,1))
##
savefig(joinpath(folder,"Bhv_trheshold3.pdf"))
##


open_html_table(change_thr_trav)
open_html_table(change_lr_trav)


##
patch = ["poor","rich"]
time = [0,1,2,3]
stim = [false, true]
SimulatedPhoto  =  DataFrame(time = Float64[], patch = String[], stim = Bool[], RPE = Float64[],
    color = Symbol[], line = Symbol[], group = String[])
for t in time
    for p in patch
        pv = p == "poor" ? 1.2 : 0.8
        c = p == "poor" ? :brown : :green
        pgroup = p == "poor" ? "Poor patch" : "Rich patch"
        for s in stim
            sv = s ? 0.85 : 1
            l = s ? :dash : :solid
            sgroup = s ? " Stim" : " No stim"
            value = (pv*sv)*t + 1
            label = pgroup * sgroup
            push!(SimulatedPhoto,(time = t, patch = p, stim = s, RPE = value,
                color = c, line = l, group = label))
        end
    end
end
@df SimulatedPhoto plot(:time, :RPE, group = :group,
    legend = :topleft, color = :color, linestyle = :line,
    ylabel = "RPE response at reward (simulated)",
    xlabel = "Elapsed time")
#"u expect reward to have not reduce as much"
##
savefig(joinpath(folder,"DA_trheshold1.pdf"))
##
df1 = combine(groupby(SimulatedPhoto,[:patch, :stim]), :RPE => mean)
change_Stim_patch = unstack(df1, :stim, :RPE_mean)
change_Stim_patch[!,:change] = change_Stim_patch[:,3] - change_Stim_patch[:,2]
@df change_Stim_patch bar(:patch, abs.(:change),
    ylabel = "Stimulated RPE absolute magnitude change", xlabel = "Patch Richness",
    color = :blue, legend = false)
    # @df change_Stim_patch plot!(:patch, :change,linestyle = :dot, color = :grey)
##
savefig(joinpath(folder,"DA_trheshold2.pdf"))
##
Trav_change = vcat(change_thr_trav,change_lr_trav)
Trav_change.color = [x == "long" ? :grey : :lightgrey for x in Trav_change.travel]
@df Trav_change groupedbar(:Hypothesis, :change, group = :travel,
    color = :color, ylims=(0,1), bar_width=0.4)
##
Patch_change = vcat(change_thr_patch,change_lr_patch)
posdic = Dict("poor" => 1, "medium" => 2, "rich" => 3)
colordic = Dict("poor" => :red, "medium" => :orange, "rich" => :yellow)
Patch_change.color = [get(colordic,x,0) for x in Patch_change.patch]
Patch_change[!,:pos] = [get(posdic,x,0) for x in Patch_change.patch]
@df Patch_change groupedbar(:Hypothesis, :change, group = :pos,
    color = :color, ylims=(0,1), bar_width=0.9)
    # xticks = ([1,2,3],["poor","medium", "rich"]))
