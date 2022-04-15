function process_bouts(df0::AbstractDataFrame; observe = false)
    df1 = filter!(r -> !ismissing(r.Poke) && !r.Incorrect, df0)
    bdf = combine(groupby(df1,:Patch)) do dd
        count_bout_by_patch(dd)
    end
    sort!(df1,[:Patch])
    df1[!,:Bout] = bdf.bout

    # transform!(groupby(df1,:Patch), :RewardAvailable => count_bout_bypatch => :Bout)
    df1 = df1[:,[:Richness, :Travel,:State,:Poke,:ActivePort,
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
                Rewarded = missing,
                )
                for x in [:Patch,:State,:Richness,:Travel, :ActivePort,:SubjectID,
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
                Rewarded = any(.!ismissing.(dd.RewardAvailable)),
                # Giveup = any(ismatch.(r"^TravPoke",dd.Port))
            )
            for x in [:Patch,:State,:Richness,:Travel, :ActivePort,:SubjectID,
                    :Taskname, :Experimentname, :Startdate]
                df2[!,x] .= dd[forage_idx,x][1]
            end
        end
        return df2
    end
    sort!(bouts,[:Patch,:Bout,:In])
    bouts[!,:GiveUp] = vcat(ismatch.(r"^Travel",bouts[2:end,:State]),[false])
    bouts = bouts[:,[:In,:Out, :ForageTime_total, :ForageTime_Sum,
            :Pokes, :Rewarded, :GiveUp, :Bout,
            :Patch,:State,:Richness,:Travel, :ActivePort,
            :SubjectID,:Taskname, :Experimentname, :Startdate
        ]]

    observe && open_html_table(bouts)
    return bouts
end
##
function count_bout_by_patch(df1)
    bdf = df1[:,[:Port,:RewardAvailable,:State]]
    bdf[!,:bout] .= 1
    c = 1
    bdf[!,:rewarding] .= false
    rewarding = false
    bdf[!,:rewarded] .= false
    rewarded = false
    bdf[!,:traveling] .= false
    traveling = false
    for r in eachrow(bdf)
        !ismissing(r.RewardAvailable) && (rewarding = true)
        rewarding && ismatch(r"^Rew",r.Port) && (rewarded = true)
        if rewarded && ismatch(r"^Poke",r.Port)
            c += 1
            rewarded = false
            ismissing(r.RewardAvailable) ? rewarding = false : rewarding = true
        end
        if !traveling && ismatch(r"^Travel$", r.State)
            c += 1
            traveling = true
        end
        if traveling && ismatch(r"^Forage$", r.State)
            traveling = false
        end
        r.rewarding = rewarding
        r.rewarded = rewarded
        r.traveling = traveling
        r.bout = c
    end
    return bdf
end
# function count_bout(df::AbstractDataFrame)
#     res = []
#     c = 1
#     # travel = false
#     rewarded = false
#     consumed = false
#     state = df[1,:State]
#     ## add consumed condition to change bout
#     for r in eachrow(df)
#         !ismissing(r.RewardAvailable) && (rewarded = true)
#         (ismatch(r"^Rew",r.Port) && (rewarded == true)) && (consumed = true)
#         if consumed && ismatch(r"^Poke",r.Port) && r.State == "Forage"
#             rewarded = false
#             consumed = false
#             c += 1
#             # elseif travel && ismatch(r"^P",r.Port) && r.State == "Forage"
#             #     travel = false
#             #     c += 1
#         elseif r.State != state && ismatch(r"(^Poke)|(^Trav)",r.Port)
#             state = r.State
#             c += 1
#         end
#         # r.State == "Travel" ? (travel = true) : (travel = false)
#         push!(res,c)
#     end
#     return res
# end

# function count_bout_bypatch(RewardAvailable)#df::AbstractDataFrame)
#     c = 1
#     res = []
#     for r in RewardAvailable
#         push!(res,c)
#         !ismissing(r) && (c += 1)
#     end
#     return res
# end

function count_bout_bypatch(df)
    res = []
    c = 1
    rewarding = false
    rewarded = false
    traveling = false
    for r in eachrow(df)
        !ismissing(r.RewardAvailable) && (rewarding = true)
        rewarding && ismatch(r"^Rew",r.Port) && (rewarded = true)
        if rewarded && ismatch(r"^Poke",r.Port)
            c += 1
            rewarded = false
            rewarding = false
        end
        if !traveling && ismatch(r"^Travel$", r.State)
            c += 1
            traveling = true
        end
        if traveling && ismatch(r"^Forage$", r.State)
            traveling = false
        end
        push!(res,c)
    end
    df[!,:Bout] = res
    return df[:,[:Patch, :Bout,:Poke, :State, :ActivePort, :Port, :Incorrect, :PokeIn, :PokeOut, :Duration,
        :Richness, :Travel, :P, :TravelComplete, :RewardAvailable, :RewardDelivery, :RewardConsumption,
        :Rsync_count, :Rsync_time, :StateIn, :StateOut, :T, :AFT, :IFT, :SubjectID, :Taskname,
        :Experimentname, :Startdate]]
end

# function count_bout_df(df)
#     bdf = DataFrame(C = repmat([1], nrow(df)))
#     bdf[!,]
# end
