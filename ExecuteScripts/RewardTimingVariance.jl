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
pokes = CSV.read(joinpath(main_path,"data",Exp,"Processed","PokesTable.csv"), DataFrame)
bouts = CSV.read(joinpath(main_path,"data",Exp,"Processed","BoutsTable.csv"), DataFrame)
function longer(v) 
    boolean_res = v[2:end] - v[1:end-1] .> 0
    string_res = [x ? "longer" : "shorter" for x in boolean_res]
    cat_res = categorical(vcat([missing], string_res))
    levels!(cat_res,["longer", "shorter"])
    return cat_res
end
v
open_html_table(bouts[1:100,:])
##
testb = dropmissing(bouts,[:SummedForage,:ElapsedForage])
filter!(r->r.Treatment == "Baseline", testb)
transform!(groupby(testb,[:SubjectID,:StartDate,:Trial]),
    :SummedForage => longer => :SummedTiming,
    :ElapsedForage => longer => :ElapsedTiming)
transform!(testb, :Richness => ByRow(x -> get(RichnessToTimeDict,x, missing)) => :RichnessValue)
transform!(testb,
    :SummedForage => zscore,
    )
open_html_table(testb[1:10,:])
testb.SummedForage_zscore
testb[!,:Event] = EventTime.(testb.SummedForage, .!testb.Rewarded)
## Cox by mouse
res_cox = combine(groupby(testb,:SubjectID)) do dd
    model = coxph(@formula(Event ~ Travel + Richness + RewardsInTrial + SummedTiming), dd)
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
##
@df res_cox scatter(:Estimate, :Name, xticks = :auto, xrotation = 45, markercolor = :lightgrey,
    label = "subject coeff", legend = :bottomright)
    vline!([0,0], linestyle = :dash, linecolor = :black, label = "")
    @df test_cox scatter!(:Mean, :Name, xerror = :CI,
    markercolor = :red, markersize = 6, color = :black,
    label = "t-test estimate")