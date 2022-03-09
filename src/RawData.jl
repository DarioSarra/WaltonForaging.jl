#= This dictionary translate numbers into the corresponding information:
    values [1,16] are state-info values [17,35] are event-info
=#
InfoDict = Dict(
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

"""
    process_raw_session(session_path::String; observe = false)

Given a string indicating the path to a rawdata text file produce a table
where each row is a poke in a specific port and columns containing timing
and state info about that poke. If observe is true opens intermediate and
final tables in html for review
"""
function process_raw_session(session_path::String; observe = false)
    !ispath(session_path) && error("\"$(session_path)\" is not a viable path")
    prov = table_raw_data(session_path)
    observe && open_html_table(prov)
    pokes = combine(groupby(prov, :Poke)) do dd
        adjustevents(dd)
    end
    pokes.Travel = [ismissing(x) ? missing : x < 2500 ? "Short" : "Long" for x in pokes.T]
    k = sort(collect(keys(countmap(pokes.IFT))))
    Rdict = Dict(x => y for (x,y) in zip(k,["rich", "medium", "poor", missing]))
    pokes.Richness = [get(Rdict,x,"nope") for x in pokes.IFT]
    for x in [:Experiment, :Task, :TaskFileHash, :SetUpID, :SubjectID]
        pokes[!, x] .= prov[1,x]
    end
    observe && open_html_table(pokes)
    return pokes
end

"""
    table_raw_data(session_path::String)

From a raw data txt file creates a table that is filled in 3 ways
1 - Read first 5 lines containing session's global information
2 - Identify Plines to globally update subsequent T, AFT, IFT values in separate columns
3 - reads line by line to identify: Time, EventName and EventType in separate columns
Last identify the start and end of each poking behaviour and groups them through counting
"""
function table_raw_data(session_path::String)
    prov = DataFrame(Time=Float64[],Event = String[],
        Type = String[], T = Float64[],
        AFT = Float64[], IFT = Float64[])
    Experiment, Task, TaskFileHash, SetUpID, SubjectID, T, AFT, IFT = initialvalues(session_path)
    for l in eachline(session_path)
        isempty(l) && continue
        if !isnothing(match.(r"AFT:",l)) #if the line contain AFT read it using special parsing
            T, AFT, IFT = parsePline(l)
        elseif l[1] == 'D'
            r = split(l, " ")
            time = parse(Float64,r[2])
            code = r[3]
            push!(prov,(Time = time,
                Event = get(InfoDict,code,"nope: $code"),
                Type = parse(Float64,code) <=16 ? "State" : "Action",
                T = T, AFT = AFT, IFT = IFT))
        end
    end
    transform!(prov, :Event => count_pokes => :Poke)
    for (x,y) in zip([:Experiment, :Task, :TaskFileHash, :SetUpID, :SubjectID],
        [Experiment, Task, TaskFileHash, SetUpID, SubjectID])
        prov[!, x] .= y
    end
    return prov
end

"""
    initialvalues(session_path::String)

Opens a raw data file as a vector of string and identifies the first P-line
containing T, AFT and IFT info to initiate `table_raw_data(session_path)`
"""
function initialvalues(session_path::String)
    lines = readlines(session_path)
    line = lines[findfirst(.!isnothing.(match.(r"AFT:",lines)))]
    T, AFT, IFT = parsePline(line)
    Experiment, Task, TaskFileHash, SetUpID, SubjectID = parseGlobalInfo(lines)
    return Experiment, Task, TaskFileHash, SetUpID, SubjectID, T, AFT, IFT
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
    starting_vals = split(line," ")[end-2:end]
    tuple([parse(Float64,split(v,":")[2]) for v in starting_vals]...)
end

"""
    parseGlobalInfo(lines::AbstractVector{String})

When feeded a raw data text file in a vector of string format, uses the first
five elements to extract session's global information. The output is a tuple
therefore the returning variable must respect the correct order:
Experiment, Task, TaskFileHash, SetUpID, SubjectID

"""
function parseGlobalInfo(lines::AbstractVector{String})
    session_info_string = lines[1:5]
    tuple([replace(split(x,":")[2]," "=>"") for x in session_info_string]...)
end

"""
    count_pokes(event_vec::AbstractVector)

Using Event column resulting from `table_raw_data(session_path::String)`
reads the event string to identify the beginning a new poke
and counts them to use this as a grouping factor for events related to the same
poke. Crucially it only begin counting from the first poke_in event excluding
beginning of sessions where not the entire poke was registered: meaning Poke=0
Poke beginning is identified with regex: a string containing exactly "poke_"
followed by any single digit (/d) and exactly concluding after it (\$)
"""
function count_pokes(event_vec::AbstractVector)
    pokes_in = [!isnothing(match(r"poke_\d$",ev)) for ev in event_vec]
    accumulate(+,pokes_in,init = 0)
end

"""
    adjustevents(df::AbstractDataFrame)
Using a GroupedDataFrame per poke, originating from
`table_raw_data(session_path::String)`extracts the info about identity
or timing of variable of interest and collect them in separate columns
"""
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

"""
    findport(vec::AbstractVector{String})

Using Event column resulting from a by-poke subgroup (from
`table_raw_data(session_path::String)`) filters all element not matching
string containing exactly "poke_" followed by one digit (/d) and NOT concluding
there exactly (in case there is a poke_out without poke_in at the beginning of
the session). Then use the matching result to identify to which port the
subgroup information belong
"""
function findport(vec::AbstractVector{String})
    filter(!isnothing,match.(r"^poke_\d",vec))[1].match
end

"""
    event_time(expression::Regex,df::AbstractDataFrame)
Use a regular expression to find a matching string in the Event column
in the by-poke subgroup (from `table_raw_data(session_path::String)`) and
return the corresponding value from the Time column
"""
function event_time(expression::Regex,df::AbstractDataFrame)
    pos = findstring(expression,df.Event)
    isnothing(pos) ? missing : df[pos, :Time]
end

"""
    findstring(expression::Regex,vec::AbstractVector{String})
Use a regular expression to find the index of the first element in a vector of
Strings that matches the expression
"""
function findstring(expression::Regex,vec::AbstractVector{String})
    findfirst(.!isnothing.(match.(expression,vec)))
end
