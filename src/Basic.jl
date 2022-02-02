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
function fit_handler(test_multiple_sessions)
    res = []
    for i in 1:10
        model,optimizer = fit(RhoComparison,test_multiple_sessions)
        push!(res,(Distributions.params(model), Optim.converged(optimizer)))
    end
    return res
end
##
# @time fit(RhoComparison,test_multiple_sessions)
# updateparams!
##
##
Francois_res = (env_alpha = 0.003, patch_aplha = 0.266, beta = 6.26, reset = 0.339, bias = 4.147)
open_html_table(test_multiple_sessions[1:5000,:])
open_html_table(test_multiple_sessions[1:10,:])
-sum(log.(test_multiple_sessions.Probability))
##
m = init(RhoComparison)
WaltonForaging.updateparams!(m, [1.0,2.0,3.0,4.0,5.0])
m
all([(v < l) for (v,l) in zip(params(m), m.limits)])
