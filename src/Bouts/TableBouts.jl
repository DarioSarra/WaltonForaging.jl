function process_bouts(df0::AbstractDataFrame; observe = false)
    df1 = filter!(r -> !ismissing(r.Poke) && !r.Incorrect, df0)
    bdf = combine(groupby(df1,:Patch)) do dd
        count_bout_by_patch(dd)
    end
    sort!(df1,[:Patch])
    df1[!,:Bout] = bdf.bout
    df1[!,:Bout_consumed] = bdf.bout_consumed
    df1 = df1[:,[:Richness, :Travel,:State,:Poke,#:ActivePort,
        :Port, :PokeIn, :PokeOut, :Duration,
        :Patch, :Bout,:RewardAvailable, :RewardConsumption,
        :SubjectID, :Taskname, :Experimentname, :Startdate]]
    observe && open_html_table(df1)
    bouts = combine(groupby(df1,[:Bout, :Patch])) do dd
        if dd[1,:State] == "Forage"
            forage_idx = findall(ismatch.(r"^Poke",dd.Port))
        elseif dd[1,:State] == "Travel"
            forage_idx = findall(ismatch.(r"^Trav",dd.Port))
        end
        if isempty(forage_idx)
            println("Bout #$(dd[1,:Bout]), Patch #$(dd[1,:Patch]) has no pokes matching state $(dd[1,:State])")
            df2 = DataFrame(
                In = missing,
                Out = missing,
                ForageTime_total = missing,
                ForageTime_Sum = missing,
                Pokes = missing,
                Reward_p = missing,
                Reward_c = missing,
                RewardAvailable = missing,
                RewardConsumption = missing,
                )
                for x in [:Patch,:State,:Richness,:Travel,:SubjectID,# :ActivePort,
                        :Taskname, :Experimentname, :Startdate]
                    df2[!,x] .= dd[1,x]
                end
        else
            df2 = DataFrame(
                In = dd[forage_idx[1],:PokeIn],
                Out = dd[forage_idx[end],:PokeOut],
                ForageTime_total = dd[forage_idx[end],:PokeOut] - dd[forage_idx[1],:PokeIn],
                ForageTime_Sum = sum(dd[forage_idx,:Duration]),
                Pokes = length(forage_idx),
                Reward_p = any(.!ismissing.(dd.RewardAvailable)),
                Reward_c = any(.!ismissing.(dd.RewardConsumption)),
                RewardAvailable = isnothing(findfirst(.!ismissing.(dd.RewardAvailable))) ? missing :
                    dd[findfirst(.!ismissing.(dd.RewardAvailable)),:RewardAvailable],
                RewardConsumption = isnothing(findfirst(.!ismissing.(dd.RewardConsumption))) ? missing :
                    dd[findfirst(.!ismissing.(dd.RewardConsumption)),:RewardConsumption]
            )
            for x in [:Patch,:State,:Richness,:Travel, :SubjectID,#:ActivePort,
                    :Taskname, :Experimentname, :Startdate]
                df2[!,x] .= dd[forage_idx,x][1]
            end
        end
        return df2
    end
    sort!(bouts,[:Patch,:Bout,:In])
    bouts[!,:GiveUp] = vcat(ismatch.(r"^Travel",bouts[2:end,:State]),[false])
    bouts[!,:RewardLatency] = bouts.RewardConsumption .- bouts.RewardAvailable
    bouts = bouts[:,[:In,:Out, :ForageTime_total, :ForageTime_Sum,
            :Pokes, :Reward_p, :Reward_c, :RewardLatency, :GiveUp, :Bout,
            :Patch,:State,:Richness,:Travel, #:ActivePort,
            :SubjectID,:Taskname, :Experimentname, :Startdate
        ]]

    observe && open_html_table(bouts)
    return bouts
end
##
function count_bout_by_patch(df1)
    bdf = df1[:,[:Port,:RewardAvailable,:State]]
    bdf[!,:bout] .= 1
    b = 1
    bdf[!,:bout_consumed] .= 1
    c = 1
    bdf[!,:rewarding] .= false
    rewarding = false
    bdf[!,:rewarded] .= false
    rewarded = false
    bdf[!,:traveling] .= false
    traveling = false
    for r in eachrow(bdf)
        # !ismissing(r.RewardAvailable) && (b += 1)
        !ismissing(r.RewardAvailable) && (rewarding = true)
        rewarding && ismatch(r"^Rew",r.Port) && (rewarded = true)
        if rewarded && ismatch(r"^Poke",r.Port)
            c += 1
            b += 1
            rewarded = false
            ismissing(r.RewardAvailable) ? rewarding = false : rewarding = true
        end
        if !traveling && ismatch(r"^Travel$", r.State)
            c += 1
            b += 1
            traveling = true
        end
        if traveling && ismatch(r"^Forage$", r.State)
            traveling = false
        end
        r.bout = b
        r.rewarding = rewarding
        r.rewarded = rewarded
        r.traveling = traveling
        r.bout_consumed = c
    end
    return bdf
end
