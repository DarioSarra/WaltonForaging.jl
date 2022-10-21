function renamerawtable!(rawt)
        rename!(rawt, Symbol("Experiment name ") => :ExperimentName,
                Symbol("Task name") => :TaskName,
                Symbol("Task file hash") => :TaskFileHash,
                Symbol("Setup ID") => :SetupID,
                Symbol("Subject ID") => :SubjectID,
                Symbol("Start date") => :StartDate)
        rawt[!, :name] = [get(PortDict,x,x) for x in rawt.name]
end

function parallelise_states(rawt)
        df_state = filter(r -> r.type == "state", rawt)
        df_joint = filter(r -> r.type == "event", rawt)

        df_joint[!,:state] = Vector{AbstractString}(undef,nrow(df_joint))
        df_joint[!,:statetime] = Vector{Float64}(undef,nrow(df_joint))

        gp_ev = groupby(df_joint,[:SubjectID, :StartDate])
        gp_st = groupby(df_state,[:SubjectID, :StartDate])
        for (e_subdf, s_subdf) in zip(gp_ev, gp_st)
                for e in eachrow(e_subdf)
                        i = findlast(s_subdf.time .< e.time)
                        isnothing(i) ? (idx = nrow(s_subdf)) : (idx = i)
                        e.state = s_subdf[idx, :name]
                        e.statetime = s_subdf[idx, :time]
                end
        end
        return select(df_joint,Not(:value))
end

parallelise_prints(rawt) = parallelise_prints(filter(r -> r.type == "event", rawt), rawt)

function parallelise_prints(df_joint, rawt)
        df_print = make_print_df(rawt)
        newcols = [:B_n, :R_n, :P_n, :RP_n, :RB_n, :PB_n, :P, :T, :AFT, :IFT, :TT]
        for n in newcols
                df_joint[!,n] = Vector{Float64}(undef,nrow(df_joint))
        end

        gp_ev = groupby(df_joint,[:SubjectID, :StartDate])
        gp_print = groupby(df_print,[:SubjectID, :StartDate])
        for (e_subdf, p_subdf) in zip(gp_ev, gp_print)
                for e in eachrow(e_subdf)
                        i = findlast(p_subdf.time .< e.time)
                        isnothing(i) ? (idx = nrow(p_subdf)) : (idx = i)
                        for n in newcols
                                e[n] = p_subdf[idx,n]
                        end
                end
        end
        return df_joint
end

function make_print_df(rawt)
        df_print = filter(r -> r.type == "print", rawt)
        filter!(r -> !contains(r.value,"remaining_patches"), df_print)
        select!(df_print,[:Column1,:type,:time, :value,:SubjectID,:StartDate])
        extract_printinfo!(df_print)
        return df_print
end

function extract_printinfo!(printdf)
        for n in [:B_n, :R_n, :P_n, :RP_n, :RB_n, :PB_n, :P, :T, :AFT, :IFT, :TT]
                printdf[!,n] = Vector{Float64}(undef,nrow(printdf))
        end
        gp = groupby(printdf,[:SubjectID, :StartDate])
        for sub_df in gp
                # val_init = DataFrame(B_n = 1.0, R_n = 0.0, P_n = 1.0,
                #         RP_n = 0.0, RB_n = 0.0, PB_n = 1.0,
                #         P = 0.0, T = 0.0, AFT = 0.0, IFT = 0.0, TT = 0.0)
                # idx = findfirst(ismatch.(r"AFT:",sub_df.value))
                # update_values!(sub_df[idx,:value],val_init)
                val_init = init_values(printdf)
                for r in eachrow(sub_df)
                        line = r.value
                        update_values!(line,val_init)
                        for c in propertynames(val_init)
                                r[c] = val_init[1, c]
                        end
                end
        end
        return select(printdf,[:SubjectID, :StartDate, :time,
                :B_n, :R_n, :P_n, :RP_n, :RB_n, :PB_n, :P, :T, :AFT, :IFT, :TT,:value])
end

function init_values(printdf)
        val_init = DataFrame(B_n = 1.0, R_n = 0.0, P_n = 1.0,
                RP_n = 0.0, RB_n = 0.0, PB_n = 1.0,
                P = 0.0, T = 0.0, AFT = 0.0, IFT = 0.0, TT = 0.0)
        idx = findfirst(ismatch.(r"AFT:",printdf.value))
        line = printdf[idx,:value]
        m = match(r"P:",line)
        update_values!(line[m.offset:end], val_init)
        return val_init
end

function update_values!(line,val_df)
        l1 = replace(line, "#" => "_n")
        l2 = split(l1," ")
        l3 = split.(l2, ":")
        for l in l3
                val_df[1, Symbol(l[1])] = parse(Float64,l[2])
        end
end

function readstate(line)
        if contains(line, "reward")
                return "reward"
        elseif contains(line,"travel")
                return "travel"
        else
                return "forage"
        end
end

function correct_travelstart!(df)
        gp = groupby(df,[:SubjectID, :StartDate])
        for subdf in gp
                idxs = findall(subdf.globalstate .== "forage" .&& subdf.name .== "TravPoke")
                for i in idxs
                        subdf[i+1,:globalstate] == "travel" && (subdf[i,:globalstate] = "travel")
                end
        end
end
