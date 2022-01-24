module WaltonForaging

using Reexport
#add CSV@0.8.5
@reexport using CSV, DataFrames, CategoricalArrays, StatsPlots, BrowseTables, StatsBase, MixedModels
# @reexport using Bootstrap, Optim, Distributions
import Statistics: median, std

include("Analysis_fun.jl")
include("preprocess.jl")
include("RewRateUpdates.jl")


export survivalrate_algorythm, cumulative_algorythm, hazardrate_algorythm, function_analysis
export median, std
export preprocess_pokes, trial_info!, bout_info!, travel_info, leave_info!
export preprocess_bouts
export get_rew_rate
end
