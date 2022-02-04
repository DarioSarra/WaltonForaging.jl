function  nll_data(m::AbstractModel,df)
    # -sum(v*Log_LikeliHood(m, k...) for (k, v) in cm)
    -sum(log.(Likelihood(m,df)))
end

function check_params(m::AbstractModel)
    (all(params(m) .> 1e-5) && (all([(v < l) for (v,l) in zip(params(m), m.limits)])))
end

function Distributions.fit(m::WaltonForaging.AbstractModel,df::DataFrames.AbstractDataFrame)
    res = optimize(params(m), NelderMead(), Optim.Options(iterations = 5000)) do param
        (all(param .> 1e-5) && (all([(v < l) for (v,l) in zip(param, m.limits)]))) || return 1e10
        updateparams!(m,param)
        return nll_data(m, df)
    end
    updateparams!(m,Optim.minimizer(res))
    return m, res
end

function Distributions.fit(::Type{T},df::DataFrames.AbstractDataFrame) where T <:WaltonForaging.AbstractModel
    m = init(T)
    Distributions.fit(m,df)
end
