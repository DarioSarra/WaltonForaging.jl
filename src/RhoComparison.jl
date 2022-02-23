mutable struct RhoComparison <: AbstractModel
    params::NamedTuple{(:env_alpha,:patch_aplha,:beta,:reset,:bias), NTuple{5,Float64}}
    limits::NTuple{5,Float64}
end

function init(::Type{WaltonForaging.RhoComparison})
    return RhoComparison(
        (env_alpha = rand(0.0:0.0001:0.1), #=alpha_environment = [0,0.1] learning rate of environment=#
            patch_aplha = rand(0.0:0.0001:0.2), #=alpha_patch = [0, 0.2] learning rate of the patch=#
            beta = rand(2:0.0001:10), #=beta = [2, 10] noise parameter or inverse temperature=#
            reset = rand(0.0:0.0001:0.5), #=reset = [0, 0.5] patch env rew rate at the entrance of a trials, because it has decayed in the last trial=#
            bias = 0.1 #=bias = [2, 10] bias towards staying in the softmax=#
        ),
        (1.0, 1.0, Inf64, 1.0, Inf64)
    )
end

Distributions.params(m::RhoComparison) = collect(m.params)

function updateparams!(m::RhoComparison,v::Vector{Float64})
    (length(v) == 5) || error("Incorrect number of params for $(typeof(m))")
    env_alpha,patch_aplha,beta,reset,bias = tuple(v...)
    m.params = (;env_alpha,patch_aplha,beta,reset,bias)
end

function Pstay(m::RhoComparison, env_rew_rate::Float64, patch_rew_rate::Float64)
    env_alpha, patch_alpha, beta, reset_val, bias = tuple(params(m)...)
    return exp(bias + beta*patch_rew_rate)/(exp(bias + beta*patch_rew_rate) + exp(beta*env_rew_rate))
end

function Pleave(m::RhoComparison, env_rew_rate::Float64, patch_rew_rate::Float64)
    env_alpha, patch_alpha, beta, reset_val, bias = tuple(params(m)...)
    # return 1 - exp(bias + beta*patch_rew_rate)/exp(bias + beta*patch_rew_rate) + exp(beta*env_rew_rate)
    return exp(beta*env_rew_rate)/(exp(beta*env_rew_rate) + exp(bias + beta*patch_rew_rate))
end

function Poutcome(m::RhoComparison, env_rew_rate::Float64, patch_rew_rate::Float64, leave::Int64)
    if leave == 1
        Pleave(m, env_rew_rate, patch_rew_rate)
    elseif leave == 0
        Pstay(m, env_rew_rate, patch_rew_rate)
    else
        error("Wrong argument for Poutcome calculation: $leave")
    end
end

function Likelihood(m::RhoComparison,df)
    # if I start using subdf for patches conditions I will need:
    # an initial env reward rate before splitting per session (maybe a separate variable to feed to loglikelihood)
    # how do I minimize the same patch reset value for the whole session?

    env_alpha, patch_alpha, beta, reset_val, bias = tuple(params(m)...)
    final_env_rho = sum(df.REWARD/df[end,:TIME])
    transform!(df,[:REWARD,:BIN,:ENV_INITIALVALUE,:NEWSESSION] => ((r,b,i,n) -> env_get_rew_rate(r,b,i,n,env_alpha)) => :EnvRewRate)
    transform!(df, [:REWARD,:BIN,:NEWTRIAL] => ((r,b,n) -> patch_get_rew_rate(r, b, reset_val, n, patch_alpha)) => :PatchRewRate)
    transform!(df, [:EnvRewRate,:PatchRewRate,:LEAVE] => ByRow((e,p,l) -> Poutcome(m,e,p,l)) => :Probability)
    return filter(r -> r.SIDE == "travel", df).Probability
end

function MixedModels.simulate(m::RhoComparison,df)
    transform(df, :Probability => (x-> convert(Float64, x < rand())) => :SimulatedModel)
end
