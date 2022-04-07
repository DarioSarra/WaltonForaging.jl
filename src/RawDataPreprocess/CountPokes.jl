function jumpcount(eventcount)
    c = 0
    [x ? c += 1 : 0 for x in eventcount]
end

function ispokeout(pokeID,event)
    event == pokeID*"_out"
end

function findpokesout!(df)
    idx = findall(df.PokeIn)
    df[!,:PokeOut] .= false
    df[!,:PokeOut_count] .= 0
    for i in idx
        c = df[i,:PokeIn_count]
        pokeID = df[i,:Event]
        po_idx = findfirst(e -> ispokeout(pokeID,e),df[i+1:end,:Event]) + i
        isnothing(po_idx) && println("Poke out not found $c")
        df[po_idx,:PokeOut] = true
        df[po_idx,:PokeOut_count] = c
    end
end

# function correct_pokes!(df)
#     ins = findall(df.PokeIn)
#     outs = findall(df.PokeOut)
#     length(ins) != length(outs) && error("poke_in and poke_out count not matching")
#     wrongs_idx = findall(outs[1:end-1] .> ins[2:end])
#     for i in wrongs_idx
#         i_out = outs[i]
#         df[i_out,:PokeOut] = false
#         i_in = ins[2:end][i]
#         df[i_in,:PokeIn] = false
#     end
# end
#
# """
#     count_pokes(event_vec::AbstractVector)
#
# Using Event column resulting from `table_raw_data(session_path::String)`
# reads the event string to identify the beginning a new poke
# and counts them to use this as a grouping factor for events related to the same
# poke. Crucially it only begin counting from the first poke_in event excluding
# beginning of sessions where not the entire poke was registered: meaning Poke=0
# Poke beginning is identified with regex: a string containing exactly "poke_"
# followed by any single digit (/d) and exactly concluding after it (\$)
# """
# function count_pokes!(prov::AbstractDataFrame)
#     prov[!,:PokeIn] = ismatch.(r"poke_\d$", prov.Event)
#     prov[!,:PokeIn_count] = jumpcount(prov.PokeIn)
#     findpokesout!(prov)
#     correct_pokes!(prov)
#     # pokes_in = [ismatch(r"^poke_\d$",ev) for ev in event_vec]
#     prov[!,:PreCount] = accumulate(+,prov.PokeIn,init = 0)
#     # pre = DataFrame(ev = event_vec, p = accumulate(+,pokes_in,init = 0))
#     transform!(groupby(prov,:PreCount), :Event => adjust_poke_count => :CleanPoke)
#     prov[!,:Poke] = [c ? p : missing for (c,p) in zip(prov.CleanPoke,prov.PreCount)]
#
# end
#
# function adjust_poke_count(ev_vec)
#     rm = .!isnothing.(match.(r"(^poke_\d_out$)|(^out_((left)|(right))$)|(^travel_out_of_poke$)", ev_vec))
#     if any(rm)
#         if findlast(rm) == length(ev_vec)
#             return trues(length(ev_vec))
#         else
#             return vcat(trues(findlast(rm)), falses(length(ev_vec)-findlast(rm)))
#         end
#     else
#         return falses(length(ev_vec))
#     end
# end
