function trial_info!(df)
    transform!(groupby(df,[:MOUSE,:DATE, :TRIAL,:SIDE]),
        :IN => (x -> collect(1:length(x))) => :POKE_TRIAL,
        :REWARD => (x -> pushfirst!(Int64.(cumsum(x)[1:end-1].+1),1)) => :BOUT_TRIAL,
        :IN => (i -> round.(i .- i[1], digits = 5)) => :IN_TRIAL,
        [:IN, :OUT] => ((i,o) -> round.(o .- i[1], digits = 5)) => :OUT_TRIAL,
    )
end

function bout_info!(df)
    transform!(groupby(df,[:MOUSE,:DATE, :TRIAL,:SIDE, :BOUT_TRIAL]),
        :IN => (i -> round.(i .- i[1], digits = 5)) => :IN_BOUT,
        [:IN, :OUT] => ((i,o) -> round.(o .- i[1], digits = 5)) => :OUT_BOUT,
        [:IN, :OUT] => ((i,o) -> round.(o .- i, digits = 5)) => :DURATION,
    )
end

function travel_info(df)
    trav_df = combine(groupby(df,[:MOUSE,:DATE, :TRIAL]),
        :KIND => last => :TRAVEL
    )
    df = leftjoin(df, trav_df, on = [:MOUSE,:DATE,:TRIAL])
end

function leave_info!(df)
    transform!(groupby(df,[:MOUSE,:DATE, :TRIAL,:SIDE]),
        :IN => (x-> vcat(falses(length(x)-1), [true])) => :LEAVE
    )
end

function count_bouts(R,L,S)
    T = Bool.(S .== "travel")
    v = (R .| L) .& (.!T)
    pushfirst!(Int64.(cumsum(v)[1:end-1].+1),1)
end

function find_bouts!(df)
    df.REWARD = Bool.(df.REWARD)
    transform!(groupby(df, [:MOUSE,:DATE]),
        [:REWARD,:LEAVE, :SIDE] => ((R,L,S) -> count_bouts(R,L,S)) => :BOUT
    )
end

function cleaned_times!(df)
    transform!(groupby(df,[:MOUSE,:DATE]),
        :DURATION => (t -> round.(cumsum(t), digits = 5)) => :TIME
    )
end

function preprocess_pokes(df)
    trial_info!(df)
    bout_info!(df)
    df = travel_info(df)
    leave_info!(df)
    find_bouts!(df)
    cleaned_times!(df)
    transform!(df,:REWARD => ByRow(Int64) => :REWARD)
    transform!(df,:LEAVE => ByRow(Int64) => :LEAVE)

end

function preprocess_bouts(df)
    bouts = filter(r -> r.SIDE != "travel", df)
    transform!(groupby(bouts,[:MOUSE,:DATE,:BOUT]),
        :DURATION => (t -> round.(cumsum(t), digits = 5)) => :WAITING_TIME
    )
    filter!(r -> (r.LEAVE .| r.REWARD), bouts)
    bouts = bouts[:,[:DATE,:MOUSE,:SIDE,:KIND,:TRAVEL,:TRIAL, :BOUT,:REWARD,:LEAVE,:DURATION,:TIME,:WAITING_TIME,:IN,:OUT,:IN_TRIAL,:OUT_TRIAL]]
    return bouts
end
Int64.(trues(4))
