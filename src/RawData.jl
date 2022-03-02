EventDict = Dict(
    "1"=>"delay_forage_left",
    "2"=>"start_forage_left",
    "3"=>"in_left",
    "4"=>"out_left",
    "5"=>"reward_left_available",
    "6"=>"reward_left",
    "7"=>"reward_consumption_left",
    "8"=>"delay_forage_right",
    "9"=>"start_forage_right",
    "10"=>"in_right",
    "11"=>"out_right",
    "12"=>"reward_right_available",
    "13"=>"reward_right",
    "14"=>"reward_consumption_right",
    "15"=>"travel",
    "16"=>"travel_available",
    "17"=>"poke_4",
    "18"=>"poke_4_out",
    "19"=>"poke_2",
    "20"=>"poke_2_out",
    "21"=>"poke_3",
    "22"=>"poke_3_out",
    "23"=>"poke_6",
    "24" =>"poke_6_out",
    "25"=>"poke_9",
    "26"=>"poke_9_out",
    "27"=>"session_timer",
    "28"=>"forage_timer",
    "29"=>"travel_tone_increment",
    "30"=>"travel_out_of_poke",
    "31"=>"travel_resumed",
    "32"=>"travel_complete",
    "33"=>"task_disengagment",
    "34"=>"post_travel_delay_timer",
    "35"=>"reward_consumption_timer"
)

StateDict = Dict(
    "1"=>"delay_forage_left",
    "2"=>"start_forage_left",
    "3"=>"in_left",
    "4"=>"out_left",
    "5"=>"reward_left_available",
    "6"=>"reward_left",
    "7"=>"reward_consumption_left",
    "8"=>"delay_forage_right",
    "9"=>"start_forage_right",
    "10"=>"in_right",
    "11"=>"out_right",
    "12"=>"reward_right_available",
    "13"=>"reward_right",
    "14"=>"reward_consumption_right",
    "15"=>"travel",
    "16"=>"travel_available"
)

function process_raw_session(session_path)
    prov = table_raw_data(session_path)
    transform!(prov, :Event => count_pokes => :Poke)
    pokes = combine(groupby(prov, :Poke)) do dd
        adjustevents(dd)
    end
    pokes.Travel = [ismissing(x) ? missing : x < 2500 ? "Short" : "Long" for x in pokes.T]
    k = sort(collect(keys(countmap(pokes.IFT))))
    Rdict = Dict(x => y for (x,y) in zip(k,["rich", "medium", "poor", missing]))
    pokes.Richness = [get(Rdict,x,"nope") for x in pokes.IFT]
    return pokes
end

function table_raw_data(session_path::String)
    T, AFT, IFT = initialvalues(session_path)
    prov = DataFrame(Time=Float64[],Event = String[],
        Type = String[], T = Float64[],
        AFT = Float64[], IFT = Float64[])
    for l in eachline(session_path)
        isempty(l) && continue
        if !isnothing(match.(r"AFT:",l))
            T, AFT, IFT = parsePline(l)
        elseif l[1] == 'D'
            r = split(l, " ")
            time = parse(Float64,r[2])
            code = r[3]
            push!(prov,(Time = time,
                Event = get(EventDict,code,"nope: $code"),
                Type = parse(Float64,code) <=16 ? "State" : "Action",
                T = T, AFT = AFT, IFT = IFT))
        end
    end
    return prov
end

function initialvalues(session_path)
    lines = readlines(session_path)
    line = lines[findfirst(.!isnothing.(match.(r"AFT:",lines)))]
    parsePline(line)
    # starting_vals = split(starting_vals_string," ")[end-2:end]
    # T,AFT,IFT = tuple([parse(Float64,split(v,":")[2]) for v in starting_vals]...)
end

function parsePline(line::String)
    starting_vals = split(line," ")[end-2:end]
    tuple([parse(Float64,split(v,":")[2]) for v in starting_vals]...)
end

function count_pokes(event_vec::AbstractVector)
    pokes_in = ispoking.(event_vec)
    accumulate(+,pokes_in,init = 0)
end

ispoking(ev) = !isnothing(match(r"poke_\d",ev)) && isnothing(match(r"poke_\d_out",ev))

function adjustevents(df::AbstractDataFrame)
    DataFrame(
        Port = findport(df.Event),
        PokeIn = event_time(r"^poke_\d$", df),
        PokeOut = event_time(r"^poke_\d_out$",df),
        StateIn = event_time(r"^(^in_((right)|(left))$)|(reward_((right)|(left)))$", df),
        StateOut = event_time(r"^out_(right)|(left)$", df),
        RewardAvailable = event_time(r"^reward_((right)|(left))_available$",df),
        RewardConsumption = event_time(r"^reward_consumption_((right)|(left))$",df),
        T = df[1,:T] == df[end,:T] ? df[1,:T] : missing,
        AFT = df[1,:AFT] == df[end,:AFT] ? df[1,:AFT] : missing,
        IFT = df[1,:IFT] == df[end,:IFT] ? df[1,:IFT] : missing
        )
end

function findport(vec::AbstractVector{String})
    filter(!isnothing,match.(r"^poke_\d",vec))[1].match
end

function event_time(expression::Regex,df::AbstractDataFrame)
    pos = findstring(expression,df.Event)
    isnothing(pos) ? missing : df[pos, :Time]
end

function findstring(expression::Regex,vec::AbstractVector{String})
    findfirst(.!isnothing.(match.(expression,vec)))
end
