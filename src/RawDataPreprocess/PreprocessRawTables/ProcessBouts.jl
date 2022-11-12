function process_bouts(df0)
    df1 = filter(r->r.Status != "reward" && #removes pokes in the reward port
        !ismissing(r.Bout), #remove bout of pokes in the travel port at the end of the session
         df0)
    df2 = combine(groupby(df1,[:SubjectID,:StartDate,:Bout])) do dd
        f_dd = filter(r->r.Status == "forage", dd)
        t_dd = filter(r->r.Status == "travel", dd)
        prov_df = DataFrame(
            ForagePokes = nrow(f_dd),
            TravelPokes = nrow(t_dd)
        )
        for c in [:Trial, :Port, :Rewarded, :Richness, :Travel, :Leave, :Status]
            nrow(f_dd) == 0 ? (val = 0) : (val = f_dd[end, c])
            prov_df[!,c] .= val
        end
        for c in [:SummedForage, :ElapsedForage]
            nrow(f_dd) == 0 ? (val = 0) : (val = f_dd[end, c])
            prov_df[!,c] .= val
            nrow(t_dd) == 0 ? (t_val = 0) : (t_val = t_dd[end, c])
            prov_df[!, Symbol(replace(string(c), "Forage" => "Travel"))] .= t_val
        end
        return prov_df
    end
    transform!(groupby(df2,[:SubjectID,:StartDate,:Trial]), :Rewarded => cumsum => :RewardsInTrial)
    transform!(groupby(df2,[:SubjectID,:StartDate]), :Rewarded => cumsum => :RewardsInSession)
    return df2
end
