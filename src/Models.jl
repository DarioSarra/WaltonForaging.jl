abstract type AbstractModel end

struct RhoComparison <: AbstractModel
    params::Vector{Float64}
    env_rho::Float64
end

function init(::Type{WaltonForaging.RhoComparison}, df)
    env_alpha = rand(0.0:0.0001:0.1)
    final_env_rho = sum(df.REWARD/df[end,:TIME])
    reset_val = rand(0.0:0.0001:0.5)
    patch_alpha = rand(0.0:0.0001:0.2)
    return RhoComparison([
        env_alpha, #=alpha_environment = [0,0.1] learning rate of environment=#
        patch_alpha, #=alpha_patch = [0, 0.2] learning rate of the patch=#
        rand(2:0.0001:10), #=beta = [2, 10] noise parameter or inverse temperature=#
        reset_val, #=reset = [0, 0.5] patch env rew rate at the entrance of a trials, because it has decayed in the last trial=#
        0.1 #=bias = [2, 10] bias towards staying in the softmax=#
        ], final_env_rho)
end

Distributions.params(m::RhoComparison) = m.params

function Pstay(m::RhoComparison, env_rew_rate, patch_rew_rate)
    env_alpha, patch_alpha, beta, reset_val, bias = tuple(params(m)...)
    return exp(bias + beta*patch_rew_rate)/(exp(bias + beta*patch_rew_rate) + exp(beta*env_rew_rate))
end

function Pleave(m::RhoComparison, env_rew_rate, patch_rew_rate)
    env_alpha, patch_alpha, beta, reset_val, bias = tuple(params(m)...)
    # return 1 - exp(bias + beta*patch_rew_rate)/exp(bias + beta*patch_rew_rate) + exp(beta*env_rew_rate)
    return exp(beta*env_rew_rate)/(exp(beta*env_rew_rate) + exp(bias + beta*patch_rew_rate))
end

function Poutcome(m::RhoComparison, env_rew_rate, patch_rew_rate, leave)
    if leave == 1
        Pleave(m::RhoComparison, env_rew_rate, patch_rew_rate)
    elseif leave == 0
        Pstay(m::RhoComparison, env_rew_rate, patch_rew_rate)
    else
        error("Wrong argument for Poutcome calculation: $leave")
    end
end
