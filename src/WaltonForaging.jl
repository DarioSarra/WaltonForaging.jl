module WaltonForaging

using Reexport
#add CSV@0.8.5
@reexport using CSV, DataFrames, CategoricalArrays, StatsPlots, BrowseTables, StatsBase, MixedModels
@reexport using Optim, Distributions, Random
@reexport using Polynomials
@reexport using LsqFit, Roots
import Statistics: median, std

abstract type AbstractModel end
include("Analysis_fun.jl")
include("preprocess.jl")
include("RewRateUpdates.jl")
include("RhoComparison.jl")
include("Loglikelihood.jl")
include("ModelTests.jl")
include(joinpath("RawDataPreprocess","RawData.jl"))
include(joinpath("RawDataPreprocess","Countpokes.jl"))
include(joinpath("RawDataPreprocess","TableRawData.jl"))
include(joinpath("Bouts","TableBouts.jl"))
include(joinpath("GraphicalPredictions","FittingMVT.jl"))
include(joinpath("GraphicalPredictions","BasicExponentials.jl"))





export survivalrate_algorythm, cumulative_algorythm, hazardrate_algorythm, function_analysis
export median, std
export convert_in_table, table_raw_data
export preprocess_pokes!, trial_info!, bout_info!, travel_info!, leave_info!
export preprocess_bouts, ismatch
export get_rew_rate, env_get_rew_rate, patch_get_rew_rate, Poutcome
export AbstractModel, RhoComparison, params, fit, init
export EventDict, process_raw_session, process_bouts
# export MVTtangent, fit_cumulative, GainModel
export MVTtangent, fit_ExpoModel, ExpoModel
export ParetoModel, fit_pareto
export basic, inverse
end
