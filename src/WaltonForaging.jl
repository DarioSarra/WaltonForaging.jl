module WaltonForaging

using Reexport
#add CSV@0.8.5
@reexport using CSV, DataFrames, CategoricalArrays, StatsPlots, BrowseTables, StatsBase, MixedModels
@reexport using Optim, Distributions, Random
import Statistics: median, std

abstract type AbstractModel end
include("Analysis_fun.jl")
include("preprocess.jl")
include("RewRateUpdates.jl")
include("RhoComparison.jl")
include("Loglikelihood.jl")
include("ModelTests.jl")
include("RawData.jl")




export survivalrate_algorythm, cumulative_algorythm, hazardrate_algorythm, function_analysis
export median, std
export preprocess_pokes!, trial_info!, bout_info!, travel_info!, leave_info!
export preprocess_bouts
export get_rew_rate, env_get_rew_rate, patch_get_rew_rate, Poutcome
export AbstractModel, RhoComparison, params, fit, init
export EventDict, process_raw_session
end
