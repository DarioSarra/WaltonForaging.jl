function process_plines(session_path::String; observe = false)
    !ispath(session_path) && error("\"$(session_path)\" is not a viable path")
    lines = readlines(session_path)
    eachlines = eachline(session_path)
end

function convert_plines(lines, eachlines)
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
