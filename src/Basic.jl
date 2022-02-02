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
p = (a=4,b=3,c=2,d=1)
collect(p)
##
mutable struct testmodel
    params::NamedTuple{(:env_alpha,:patch_aplha,:beta,:reset,:bias), NTuple{5,Float64}}
end

function init(::Type{testmodel})
    return testmodel((
        env_alpha = rand(0.0:0.0001:0.1), #=alpha_environment = [0,0.1] learning rate of environment=#
        patch_aplha = rand(0.0:0.0001:0.2), #=alpha_patch = [0, 0.2] learning rate of the patch=#
        beta = rand(2:0.0001:10), #=beta = [2, 10] noise parameter or inverse temperature=#
        reset = rand(0.0:0.0001:0.5), #=reset = [0, 0.5] patch env rew rate at the entrance of a trials, because it has decayed in the last trial=#
        bias = 0.1 #=bias = [2, 10] bias towards staying in the softmax=#
        ))
end

Distributions.params(m::testmodel) = collect(m.params)
##
t = init(testmodel)
env_alpha,patch_aplha,beta,reset,bias = tuple(rand(5)...)
t. params = (;env_alpha,patch_aplha,beta,reset,bias)
t
typeof(rand(5))
function updateparams!(m::testmodel,v::Vector{Float64})
    (length(v) == 5) || error("Incorrect number of params for $(typeof(m))")
    env_alpha,patch_aplha,beta,reset,bias = tuple(v...)
    m.params = (;env_alpha,patch_aplha,beta,reset,bias)
end
updateparams!(t,rand(2))
t
