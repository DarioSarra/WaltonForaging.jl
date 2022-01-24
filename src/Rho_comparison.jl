abstract type AbstractModel end

struct PoissonLapseUniform <: AbstractModel
    params::Vector{Float64}
    max::Int
end
function init(::Type{<:PoissonLapseUniform}, cm::Dict)
    m = maximum(key.Omissions_plus_one for key in keys(cm))
    return PoissonLapseUniform([10, 2, 0.1], m)
end

Distributions.params(p::PoissonLapseUniform) = p.params
Base.maximum(m::PoissonLapseUniform) = m.max

function Distributions.cdf(p::PoissonLapseUniform, x::Int)
    T, r, ϵ = params(p)
    d = Gamma(T, 1/r)
    # ϵ = 0
    # 1-ϵ e faccio Gamma, ϵ e faccio uniform, sommare e' uguale a "oppure" in probabilita'
    return (1-ϵ)*cdf(d, x) + ϵ*x/p.max
end

struct RhoComparison <: AbstractModel
    params::Vector{Float64}
    env_rho::Float64
    patch_rho::Float64
end

function init(::Type{<:RhoComparison}, df)
    final_env_rho = sum(df.REWARD/df[end,:TIME])
    return RhoComparison([
        rand(0.0:0.0001:0.1), #=alpha_environment = [0,0.1] learning rate of environment=#
        rand(0.0:0.0001:0.2), #=alpha_patch = [0, 0.2] learning rate of the patch=#
        rand(2:0.0001:10), #=beta = [2, 10] noise parameter or inverse temperature=#
        rand(0.0:0.0001:0.5), #=reset = [0, 0.5] patch env rew rate at the entrance of a trials, because it has decayed in the last trial=#
        0.1 #=bias = [2, 10] bias towards staying in the softmax=#
        ], final_env_rho, final_env_rho)
end

Distributions.params(m::RhoComparison) = m.params
# you need to calculate the likelihood for the entire session, then sum and minimize -log
# function Log_LikeliHood(m::AbstractModel, rew, leaves)
#
# end
