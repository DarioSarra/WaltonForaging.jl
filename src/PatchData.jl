function process_bout(df::AbstractDataFrame)
    combine(groupby(df,:Patch)) do dd
        @. !ismissing(dd.RewardAvailable)
    end
end
