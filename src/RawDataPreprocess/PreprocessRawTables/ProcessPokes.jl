function process_pokes(df0)
    df1 = select(df0, [:SubjectID, :StartDate, :Time, :Duration,:Port, :Rew,:Patch,
            :Status,:Travel, :Richness,
            :RewInPatch,:RewInBlock, :PatchInBlock, :Block])
    correct_pokes!(df1)
    rewarded_pokes!(df1)
    leaving_pokes!(df1)
    count_bouts!(df1)
    count_trials!(df1)
    foragetimes!(df1)
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

function count_bouts!(df0)
    df1 = filter(r -> r.Status == "forage", df0)
    count_bouts(rew_vec, leave_vec) = vcat([1], cumsum(rew_vec .|| leave_vec)[1:end-1] .+1)
    transform!(groupby(df1,[:SubjectID,:StartDate]),
        [:Rewarded, :Leave] => ((r,l) -> count_bouts(r,l)) => :Bout)
    leftjoin!(df0,df1, on = propertynames(df0), matchmissing = :equal)
    assign_bouts!(df0,"reward", findprev)
    assign_bouts!(df0,"travel", findnext)
end

function assign_bouts!(df, status,which)
    combine(groupby(df,[:SubjectID,:StartDate])) do dd
        idx = findall(ismissing.(dd.Bout) .&& dd.Status .== status)
        for i in idx
            ref = which(.!ismissing.(dd.Bout),i)
            isnothing(ref) && continue
            dd[i,:Bout] = dd[ref,:Bout]
        end
    end
end

function count_trials!(df)
    # because patch is updated after the first travel poke we need to backwards update the trial count
    combine(groupby(df,[:SubjectID,:StartDate])) do dd
        idx = vcat(dd[1:end-1, :Patch] .!= dd[2:end,:Patch],false)
        dd[!,:Trial] = Int64.(dd.Patch)
        for i in findall(idx)
            #sometimes it takes more than one traavel poke to get the print line
            #so we update until the first previous non-travel poke
            while dd[i,:Port] == "TravPoke"
                dd[i,:Trial] = dd[i,:Trial] + 1
                i-=1
            end
        end
    end
end

function foragetimes!(df0)
    # df1 = filter(r -> r.Status == "forage", df0)
    # count_bouts(rew_vec, leave_vec) = vcat([1], cumsum(rew_vec .|| leave_vec)[1:end-1] .+1)
    transform!(groupby(df0,[:SubjectID,:StartDate,:Bout,:Status]),
        :Duration => cumsum => :SummedForage,
        [:Time, :Duration] => ((in,dur) -> in .+ dur .- in[1]) => :ElapsedForage)
    # leftjoin!(df0,df1, on = propertynames(df0), matchmissing = :equal)
end
