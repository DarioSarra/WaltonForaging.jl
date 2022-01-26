function Likelihood(m::RhoComparison,df)
    # if I start using subdf for patches conditions I will need:
    # an initial env reward rate before splitting per session (maybe a separate variable to feed to loglikelihood)
    # how do I minimize the same patch reset value for the whole session?

    env_alpha, patch_alpha, beta, reset_val, bias = tuple(params(m)...)
    final_env_rho = sum(df.REWARD/df[end,:TIME])
    # transform!(df, [:REWARD,:BIN] => ((R,B) -> get_rew_rate(R,B, env_alpha, final_env_rho)) => :EnvRewRate)
    transform!(df,[:REWARD,:BIN,:ENV_INITIALVALUE,:NEWSESSION] => ((r,b,i,n) -> env_get_rew_rate(r,b,i,n,env_alpha)) => :EnvRewRate)
    transform!(df, [:REWARD,:BIN,:NEWTRIAL] => ((r,b,n) -> patch_get_rew_rate(r, b, reset_val, n, patch_alpha)) => :PatchRewRate)
    transform!(df, [:EnvRewRate,:PatchRewRate,:LEAVE] => ByRow((e,p,l) -> Poutcome(m,e,p,l)) => :Probability)
    return filter(r -> r.SIDE == "travel", df).Probability
end

function  nll_data(m::AbstractModel,df)
    # -sum(v*Log_LikeliHood(m, k...) for (k, v) in cm)
    -sum(log.(Likelihood(m,df)))
end

function Distributions.fit(::Type{T},df::DataFrames.AbstractDataFrame) where T<:WaltonForaging.AbstractModel
    m = init(T, df)
    res = optimize(params(m)) do param
        all(param .> 1e-10) || return 1e10
        ((param[1] < 1) && (param[2] < 1) && (param[4] < 1)) || return 1e10
        params(m) .= param
        return nll_data(m, df)
    end
    params(m) .= Optim.minimizer(res)
    return m
end
