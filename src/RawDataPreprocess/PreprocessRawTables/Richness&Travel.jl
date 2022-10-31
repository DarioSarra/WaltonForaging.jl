function findtravel!(df)
    gp = groupby(df,[:SubjectID, :StartDate, :P_n])
    transform!(gp, [:globalstate, :T] => ((s,t) -> calc_travel(s,t)) => :Travel)
end

function calc_travel(state,t_val)
    filt_t = t_val[state.== "travel"]
    if isempty(filt_t)
        res = missing
    else
        res = minimum(filt_t) < 2500 ? "short" : "long"
    end
    return res
end

function correct_travelstart!(df)
    gp = groupby(df,[:SubjectID, :StartDate])
        for subdf in gp
        #find all travel pokes in forage state
        idxs = findall(subdf.globalstate .== "forage" .&& subdf.name .== "TravPoke")
        #loop into the found indexes
        # check if the next poke would be in a travel state
        # if true, updates the previous travel poke state to travel
        for i in idxs
                if i == nrow(subdf)
                        subdf[i,:globalstate] = "travel"
                else
                        subdf[i+1,:globalstate] == "travel" && (subdf[i,:globalstate] = "travel")
                end
        end
    end
end

function findrichness!(df)
    RichnessDict_keys = sort(collect(keys(countmap(df.IFT))))
    RichnessDict = Dict(x => y for (x,y) in zip(RichnessDict_keys,["rich", "medium", "poor"]))
    transform!(groupby(df,[:SubjectID, :StartDate]),:IFT => ByRow(x -> get(RichnessDict,x, missing)) => :Richness)
end
