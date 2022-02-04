function trial_info!(df)
    transform!(groupby(df,[:MOUSE,:DATE, :TRIAL,:SIDE]),
        :IN => (x -> collect(1:length(x))) => :POKE_TRIAL,
        :IN => (x-> Int64.(vcat(zeros(length(x)-1), [1]))) => :LEAVE,
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

function travel_info!(df)
    trav_df = combine(groupby(df,[:MOUSE,:DATE, :TRIAL]),
        :KIND => last => :TRAVEL
    )
    trav_df.TRAVEL = [x in ["short", "long"] ? x : "last" for x in trav_df.TRAVEL]
    leftjoin!(df, trav_df, on = [:MOUSE,:DATE,:TRIAL])
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

function add_time_bins!(df; binsize = 0.1)
    transform!(df,:DURATION => (ByRow(d -> Int64(round(d/binsize)))) => :BIN)
    # transform!(df,:DURATION => (ByRow(d -> Int64(ceil(d/binsize)))) => :BIN)
    filter!(r-> (r.BIN >= 1 || Bool(r.REWARD) || Bool(r.LEAVE)), df)
    replace!(df.BIN, 0 => 1)
    # filter!(r-> r.BIN >= 1, df)

end

function preprocess_pokes!(df; binsize = 0.1)
    trial_info!(df)
    bout_info!(df)
    travel_info!(df)
    find_bouts!(df)
    cleaned_times!(df)
    transform!(df,:REWARD => ByRow(Int64) => :REWARD)
    select!(df,[:MOUSE,:DATE,:SIDE,:KIND,:TRAVEL,:BOUT,:TRIAL,:BOUT_TRIAL,:POKE_TRIAL,:REWARD,:LEAVE,
        :IN, :OUT, :IN_TRIAL, :OUT_TRIAL, :IN_BOUT, :OUT_BOUT, :DURATION,:TIME]);
    add_time_bins!(df; binsize = binsize)
    transform!(groupby(df,[:MOUSE,:DATE]),
        [:REWARD,:BIN] => ((r,b) -> sum(r)/sum(b)) => :ENV_INITIALVALUE,
        :TRIAL => (t -> Int64.(vcat([1],zeros(length(t)-1)))) => :NEWSESSION
        )
    transform!(groupby(df,[:MOUSE,:DATE,:TRIAL]),
        :REWARD => (t -> Int64.(vcat([1],zeros(length(t)-1)))) => :NEWTRIAL
        )
end

function preprocess_bouts(df)
    bouts = filter(r -> r.SIDE != "travel", df)
    transform!(groupby(bouts,[:MOUSE,:DATE,:BOUT]),
        :DURATION => (t -> round.(cumsum(t), digits = 5)) => :WAITING_TIME
    )
    filter!(r -> (Bool(r.LEAVE) .| Bool(r.REWARD)), bouts)
    bouts = bouts[:,[:DATE,:MOUSE,:SIDE,:KIND,:TRAVEL,:TRIAL, :BOUT,:REWARD,:LEAVE,:DURATION,:TIME,:WAITING_TIME,:IN,:OUT,:IN_TRIAL,:OUT_TRIAL]]
    return bouts
end
Int64.(trues(4))
