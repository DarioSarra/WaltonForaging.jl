function process_pokes(df0)
    df1 = select(df0, [:SubjectID, :StartDate, :Time, :Duration,:Port, :Rew,:Patch,
            :Status,:Travel, :Richness,
            :RewInPatch,:RewInBlock, :PatchInBlock, :Block])
    correct_pokes!(df1)
    rewarded_pokes!(df1)
    leaving_pokes!(df1)
    df1[!,:Bouts] = vcat([1], cumsum(df1.Rewarded .|| df1.Leave)[1:end-1] .+1)
    return df1
end

function correct_pokes!(df)
    df[!, :Correct] = [get(PortStatusDict,p,missing) == s for (p,s) in zip(df.Port,df.Status)]
    idx = findall(ismissing.(df.Correct))
    expected_missings = ["travel_tone_increment",
        "travel_out_of_poke",
        "travel_resumed",
        "travel_complete",
        "task_disengagment"]
    if any(.![x in expected_missings for x in unique(df.Port[idx])])
        error("found unknown event in $(expected_missings)")
    else
        dropmissing!(df,:Correct)
        filter!(r -> r.Correct, df)
    end
end

function rewarded_pokes!(df)
    f_pokes = ismatch.(r"^Poke",df.Port)
    shifted_rew = vcat(ismatch.(r"^reward$", df.Status)[2:end], [false])
    df[!, :Rewarded] = convert(Vector{Bool},f_pokes .&& shifted_rew)
end

function leaving_pokes!(df)
    f_pokes = ismatch.(r"^Poke",df.Port)
    shifted_travel = vcat(ismatch.(r"^travel$", df.Status)[2:end], [false])
    df[!, :Leave] = convert(Vector{Bool},f_pokes .&& shifted_travel)
end
