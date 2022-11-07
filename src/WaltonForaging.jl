module WaltonForaging

using Reexport
#add CSV@0.8.5
@reexport using CSV, DataFrames, CategoricalArrays, StatsPlots, BrowseTables, StatsBase, MixedModels, StandardizedPredictors, Effects
@reexport using Optim, Distributions, Random, Dates
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
include(joinpath("RawDataPreprocess","Constants.jl"))
include(joinpath("RawDataPreprocess","RaquelPharma.jl"))
include(joinpath("RawDataPreprocess","PreprocessRawTables","ReshapeRawTable.jl"))
include(joinpath("RawDataPreprocess","PreprocessRawTables","Richness&Travel.jl"))
include(joinpath("RawDataPreprocess","PreprocessRawTables","ProcessPokes.jl"))


include(joinpath("RawDataPreprocess","RawData.jl"))
include(joinpath("RawDataPreprocess","CountPokes.jl"))
include(joinpath("RawDataPreprocess","TableRawData.jl"))
include(joinpath("Bouts","TableBouts.jl"))
include(joinpath("Bouts","ProcessTables.jl"))
include(joinpath("GraphicalPredictions","FittingMVT.jl"))
include(joinpath("GraphicalPredictions","BasicExponentials.jl"))



## Post table import code
export InfoDict, PortDict, PortStatusDict
export survivalrate_algorythm, cumulative_algorythm, hazardrate_algorythm, function_analysis
export median, std
export renamerawtable, parallelise_states, make_print_df, parallelise_prints, init_values
export findrichness!, findtravel!
export process_rawtable, process_pokes
export RaquelPharmaCalendar!

## Pre table import code
export convert_in_table, table_raw_data
export preprocess_pokes!, trial_info!, bout_info!, travel_info!, leave_info!
export process_foraging, preprocess_bouts, ismatch
export get_rew_rate, env_get_rew_rate, patch_get_rew_rate, Poutcome
export AbstractModel, RhoComparison, params, fit, init
export EventDict, process_raw_session, process_bouts
export MVTtangent, fit_ExpoModel, ExpoModel
export ParetoModel, fit_pareto
export basic, inverse
end
