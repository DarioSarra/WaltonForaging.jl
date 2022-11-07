function process_pokes(df0)
    df1 = select(df0, [:SubjectID, :StartDate, :Time, :Duration,:Port, :Rew,:Patch,
            :Status,:Travel, :Richness,
            :RewInPatch,:RewInBlock, :PatchInBlock, :Block])
    remove_incomplete_pokes!(df1)
    correct_pokes!(df1)
    rewarded_pokes!(df1)
    leaving_pokes!(df1)
    count_bouts!(df1)
    correct_counting!(df1,:Patch,:Trial)
    correct_counting!(df1,:Block,:Series)
    count_trials!(df1)
    foragetimes!(df1)
    collectedrewards!(df1)
    df1[!,:Richness] = categorical(df1.Richness)
    levels!(df1.Richness,["poor","medium", "rich"])
    df1[!,:Travel] = categorical(df1.Travel)
    levels!(df1.Travel,["short", "long"])
    return select(df1,[:SubjectID, :StartDate, :Status, :Port,
            :Time, :Duration, :SummedForage, :ElapsedForage,
            :Rewarded, :Leave,
            :Bout, :Trial, :Series, :Travel, :Richness,
            :PokeInBout, :PokeInTrial, :TrialInSeries,
            :RewardsInTrial, :RewardsInSeries, :RewardsInSession])
end

#remove pokes that are missiing eithere the in or out timestamp
function remove_incomplete_pokes!(df)
    df[!,:Filt] = .![!ismissing(r.Port) && ismatch(r"poke_\d_out",r.Port)  for r in eachrow(df)]
    filter!(r-> r.Filt, df)
    select!(df,Not(:Filt))
end

#remove pokes performed in inactive ports depending on the task state
function correct_pokes!(df)
    df[!, :Correct] = [get(PortStatusDict,p,missing) == s for (p,s) in zip(df.Port,df.Status)]
    idx = findall(ismissing.(df.Correct))
    expected_missings = ["travel_tone_increment",
        "travel_out_of_poke",
        "travel_resumed",
        "travel_complete",
        "task_disengagment"]
    if any(.![x in expected_missings for x in unique(df.Port[idx])])
        error("found unknown event in $(unique(df.Port[idx])) for listed $(expected_missings)")
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

#=bouts number is determined only for pokes happening in the forage state.
the bout count is retroactively assigned to pokes in travel or reward state
using findprev or findnext depending on the state=#
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
#=# because patch count is updated after one or more travel pokes
    we need to backwards update some of the counting to include the first
    travel pokes
=#
function correct_counting!(df,original,corrected)

    combine(groupby(df,[:SubjectID,:StartDate])) do dd
        idx = vcat(dd[1:end-1, original] .!= dd[2:end,original],false)
        dd[!,corrected] = Int64.(dd[:, original])
        for i in findall(idx)
            #sometimes the printline output is delayed by a few travel pokes,
            #so we increment count by one until the first previous non-travel poke
            while dd[i,:Port] == "TravPoke"
                dd[i,corrected] += 1
                i -= 1
                i == 0 && break
            end
        end
    end
end

function count_trials!(df)
    transform!(groupby(df,[:SubjectID,:StartDate,:Bout,:Status]),
        :SubjectID => (x -> 1:length(x)) => :PokeInBout)

    transform!(groupby(df,[:SubjectID,:StartDate,:Trial,:Status]),
        :SubjectID => (x -> 1:length(x)) => :PokeInTrial)

    transform!(groupby(df,[:SubjectID,:StartDate,:Series,:Status]),
        :Leave => (x -> Int64.(vcat([0],cumsum(x[1:end-1])))) => :TrialInSeries,
        :SubjectID => (x -> 1:length(x)) => :PokeInSeries)

end

function foragetimes!(df)
    transform!(groupby(df,[:SubjectID,:StartDate,:Bout,:Status]),
        :Duration => cumsum => :SummedForage,
        [:Time, :Duration] => ((in,dur) -> in .+ dur .- in[1]) => :ElapsedForage)

end

function collectedrewards!(df)
    # transform!(groupby(df,[:SubjectID,:StartDate]), :Rew => (x -> x .- 1) => :RewardsInSession)
    # transform!(groupby(df,[:SubjectID,:StartDate,:Trial]), :Rew => (x -> x .- 1) => :RewardsInTrial)
    transform!(groupby(df,[:SubjectID,:StartDate]), :Rewarded =>
        (x -> Int64.(vcat([0],cumsum(x[1:end-1])))) => :RewardsInSession)
    transform!(groupby(df,[:SubjectID,:StartDate,:Series]), :Rewarded =>
        (x -> Int64.(vcat([0],cumsum(x[1:end-1])))) => :RewardsInSeries)
    transform!(groupby(df,[:SubjectID,:StartDate,:Trial]), :Rewarded =>
        (x -> Int64.(vcat([0],cumsum(x[1:end-1])))) => :RewardsInTrial)

end
