"""
    table_raw_data(lines, eachlines)

From a raw data txt file creates a table and group data counting pokes
"""
function table_raw_data(lines, eachlines)
    prov = convert_in_table(lines, eachlines)
    # count_pokes!(prov) ##complex calculation look up functions on separate file
    prov[!,:PokeIn] = ismatch.(r"poke_\d$", prov.Event)
    prov[!,:PokeIn_count] = WaltonForaging.jumpcount(prov.PokeIn)
    WaltonForaging.findpokesout!(prov)
    maximum(prov.PokeIn_count) == maximum(prov.PokeOut_count)
    prov[!,:Poke] = Vector{Union{Missing,Int}}(missing,nrow(prov))
    clean_iterator = filter(x -> !ismissing(x) && x!=0 ,prov.PokeIn_count)
    for x in clean_iterator#1:maximum(prov.PokeIn_count)
        prov[findfirst(prov.PokeIn_count .== x) : findfirst(prov.PokeOut_count .== x),
            :Poke] .= x
    end
    prov[!,:Rsync_count] = accumulate(+,[ismatch(r"rsync$",ev) for ev in prov.Event], init = 0)
    return prov
end
"""
    convert_in_table(session_path::String)

From a raw data txt file creates a table that is filled in 3 ways
1 - Read first 5 lines containing session's global information
2 - Identify Plines to globally update subsequent T, AFT, IFT values in separate columns
3 - reads line by line to identify: Time, EventName and EventType in separate columns
"""

function convert_in_table(lines, eachlines)
    prov = DataFrame(Time=Float64[],Event = String[],
        Type = String[], P = Float64[],  T = Float64[],
        AFT = Float64[], IFT = Float64[])
    P, T, AFT, IFT = WaltonForaging.initialvalues(lines)
    for l in eachlines
        isempty(l) && continue
        if WaltonForaging.ismatch.(r"AFT:",l) #if the line contain AFT read it using special parsing
            P, T, AFT, IFT = WaltonForaging.parsePline(l)
        elseif l[1] == 'D'
            r = split(l, " ")
            time = parse(Float64,r[2])
            code = r[3]
            push!(prov,(Time = time,
                Event = get(WaltonForaging.InfoDict,code,"nope: $code"),
                Type = parse(Float64,code) <=16 ? "State" : "Action",
                P = P, T = T, AFT = AFT, IFT = IFT))
        end
    end
    return prov
end

"""
    initialvalues(session_path::String)

Opens a raw data file as a vector of string and identifies the first P-line
containing T, AFT and IFT info to initiate `table_raw_data(session_path)`
"""
function initialvalues(lines)
    idx = findfirst(ismatch.(r"AFT:",lines))
    isnothing(idx) && error("first P line not found")
    first_Pline = lines[idx]
    P, T, AFT, IFT = parsePline(first_Pline)
    return P, T, AFT, IFT
end

"""
    parsePline(line::String)

When feeded a P line in the format
P 36861 R#:5 P#:1 RP#:5 P:-1 T:3694 AFT:3445 IFT:227.5831
    (numbers are just an example)
split the string using space character in a vector
takes the last 3 elements [T:3694,AFT:3445,IFT:227.5831]
Iterates the elements split them using column character
Parse the second element after column in a Float values
returns the 3 values in a tuple (3694,3445,227.5831)
Therefore results have to be assign in the returning variables in the
correct order: T, AFT, IF
"""
function parsePline(line::String)
    pre = split(line," ")
    starting_vals = vcat(pre[4],pre[end-2:end])
    tuple([parse(Float64,split(v,":")[2]) for v in starting_vals]...)
end
