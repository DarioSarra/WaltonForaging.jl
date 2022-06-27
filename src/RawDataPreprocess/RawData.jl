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
    "35"=>"reward_consumption_timer",
    "36"=>"rsync"
)

PortDict = Dict(
    "poke_2"=>"PokeLeft",
    "poke_4"=>"RewLeft",
    "poke_3"=>"PokeRight",
    "poke_6"=>"RewRight",
    "poke_9"=>"TravPoke"
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
    lines = readlines(session_path)
    eachlines = eachline(session_path)
    prov = table_raw_data(lines, eachlines) #translate the text document to an equivalent table
    observe && open_html_table(prov)
    pokes = combine(groupby(prov, :Poke)) do dd
        adjustevents(dd) ## groupby poke count to create a table with all info about each poke per row
    end
    sort!(pokes,:PokeIn)
    # pokes[!,:Duration] = pokes.PokeOut - pokes.PokeIn
    RichnessDict_keys = sort(collect(keys(countmap(pokes.IFT))))
    RichnessDict = Dict(x => y for (x,y) in zip(RichnessDict_keys,["rich", "medium", "poor", missing]))
    pokes[!,:State] = find_task_state(pokes) #understand if the poke is during foraging or travelling
    pokes[:,:Port] = [get(PortDict,x, x) for x in pokes.Port] #tranlaste poke numbers to readable equivalent left, right and travel
    idx = findall(ismatch.(r"^reward_consumption_",pokes.Port))
    #reward consumption is used to count bouts/harvests
    for i in idx
        port = ismatch(r"left",pokes[i,:Port]) ? "RewLeft" : "RewRight"
        rewardedpoke = findprev(ismatch.(Regex(port),pokes.Port),i)
        pokes[rewardedpoke,:RewardConsumption] = pokes[i,:PokeIn]
    end
    # transform!(pokes,[:Port,:TravelComplete] => ((p,t)->activeside(p,t)) => :ActivePort)
    incorrectpokes!(pokes)
    transform!(pokes, :State => count_patches => :Patch)
    # check the travel duration looking at T values for pokes in travel state. The last patch might not have such info
    transform!(groupby(pokes,:Patch), [:T, :State] => ((t,s) -> determine_travel(t,s)) => :Travel)
    # shift Travel info to the following patch since travel duration affects following not preceeding behaviour
    pokes.Travel = vcat([missing],pokes[1:end-1, :Travel])
    transform!(groupby(pokes,:Patch), :IFT => (x -> determine_richness(x,RichnessDict)) => :Richness)

    #occasionally pokeout have missing values in that case it search for the poke_out value accoriding to the poke_out number
    checkPokeOut  = ismissing.(pokes.PokeOut) .&& ismatch.(r"^Poke",pokes.Port)
    if any(checkPokeOut)
        for i in findall(checkPokeOut)
            pnum = pokes[i,:Poke]
            if ismissing(pokes[i,:Poke])
                println("poke deleted skipping poke out time correction")
                continue
            end
            pos = findfirst(prov.PokeOut_count .== pnum)
            pokes[i,:PokeOut] = prov[pos,:Time]
        end
    end

    pokes[!,:Duration] = pokes.PokeOut - pokes.PokeIn

    session_info = parseGlobalInfo(lines)
    for (x,y) in session_info
        pokes[!, x] .= y
    end
    pokes =  pokes[:,[:Richness, :Travel,:State,:Poke,#:ActivePort,
        :Incorrect,:Port, :PokeIn, :PokeOut, :Duration,
        :Patch, :P,#:Bout,:AlternativePatch,
        :TravelOnset,:TravelComplete,
        :RewardAvailable, :RewardDelivery, :RewardConsumption,
        :Rsync_count, :Rsync_time, :StateIn, :StateOut, :T, :AFT, :IFT,
        :SubjectID, :Taskname, :Experimentname, :Startdate]]
    sort!(pokes,:PokeIn)
    observe && open_html_table(pokes)
    return pokes
end


"""
    parseGlobalInfo(lines::AbstractVector{String})

When feeded a raw data text file in a vector of string format, uses the first
five elements to extract session's global information. The output is a tuple
therefore the returning variable must respect the correct order:
Experiment, Task, TaskFileHash, SetUpID, SubjectID

"""
function parseGlobalInfo(lines::AbstractVector{String})
    # session_info_string = filter(l-> !isempty(l) && l[1] == 'I',lines)
    # tuple([replace(split(x,":")[2]," "=>"") for x in session_info_string]...)
    session_info_string = filter(l-> !isempty(l) && l[1] == 'I',lines)
    tuple([replace(split(x,":")[2]," "=>"") for x in session_info_string]...)
    session_info_string = replace.(session_info_string,"I "=> "")
    session_info_string = replace.(session_info_string," : "=> "|")
    session_info_string = replace.(session_info_string," "=> "")
    session_info = Dict()#(;)
    for x in session_info_string
        n,v = split(x,"|")
        session_info = merge(session_info,Dict(Symbol(n)=>v))
    end
    return session_info
end


"""
    adjustevents(df::AbstractDataFrame)
Using a GroupedDataFrame per poke, originating from
`table_raw_data(session_path::String)`extracts the info about identity
or timing of variable of interest and collect them in separate columns
"""
function adjustevents(df::AbstractDataFrame)
    if !ismissing(df[1,:Poke])
        port = findport(df.Event)
        DataFrame(
            Port = port,#findport(df.Event),
            PokeIn = event_time(Regex(port), df),#event_time(r"^poke_\d$", df),
            PokeOut = event_time(Regex(port*"_out"), df),#event_time(r"^poke_\d_out$",df),
            StateIn = event_time(r"(^in_((right)|(left))$)|(^travel$)", df),
            StateOut = event_time(r"^out_((right)|(left))$", df),
            RewardAvailable = event_time(r"^reward_((right)|(left))_available$",df),
            RewardDelivery = event_time(r"^reward_((right)|(left))$",df),
            RewardConsumption = event_time(r"^reward_consumption_((right)|(left))$",df),
            TravelOnset = event_time(r"^travel$",df),
            TravelComplete = event_time(r"^travel_complete$",df),
            Rsync_count = findrsynccount(df),
            Rsync_time = event_time(r"^rsync$",df),
            P = df[end,:P], #always take the latest Patch value
            T = df[end,:T], #always take the latest T value
            AFT = df[1,:AFT] == df[end,:AFT] ? df[1,:AFT] : missing, #if AFT changes report missing val
            IFT = df[1,:IFT] == df[end,:IFT] ? df[1,:IFT] : missing #if IFT changes report missing val
            )
    else
        pre = DataFrame(
            Port = df.Event,
            PokeIn = df.Time,
            PokeOut = Vector{Union{Float64,Missing}}(missing,nrow(df)),
            StateIn = Vector{Union{Float64,Missing}}(missing,nrow(df)),
            StateOut = Vector{Union{Float64,Missing}}(missing,nrow(df)),
            RewardAvailable = Vector{Union{Float64,Missing}}(missing,nrow(df)),
            RewardDelivery = Vector{Union{Float64,Missing}}(missing,nrow(df)),
            RewardConsumption = Vector{Union{Float64,Missing}}(missing,nrow(df)),
            TravelOnset = Vector{Union{Float64,Missing}}(missing,nrow(df)),
            TravelComplete = Vector{Union{Float64,Missing}}(missing,nrow(df)),
            Rsync_count = Vector{Union{Float64,Missing}}(missing,nrow(df)),
            Rsync_time = Vector{Union{Float64,Missing}}(missing,nrow(df)),
            P = Vector{Union{Float64,Missing}}(missing,nrow(df)),
            T = Vector{Union{Float64,Missing}}(missing,nrow(df)),
            AFT = Vector{Union{Float64,Missing}}(missing,nrow(df)),
            IFT = Vector{Union{Float64,Missing}}(missing,nrow(df)),
            )
        pre[pre.Port .== "rsync", :Rsync_time] .= pre[pre.Port .== "rsync", :PokeIn]
        pre[pre.Port .== "rsync", :Rsync_count] .= df[df.Event .== "rsync", :Rsync_count]
        return pre
    end
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
    poke_id = match.(r"^poke_\d",vec)
    all(isnothing.(poke_id)) ? missing : filter(!isnothing,poke_id)[1].match
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
function findstring(expression::Regex,vec::AbstractVector)
    # findfirst(.!isnothing.(match.(expression,vec)))
    findfirst(ismatch.(expression,vec))
end

ismatch(r::Regex,s) = !isnothing(match(r, s))

function findrsynccount(df::AbstractDataFrame)
    pos = findfirst(.!isnothing.(match.(r"^rsync$",df.Event)))
    isnothing(pos) ? missing : df[pos,:Rsync_count]
end

function alternative_count_patches(vec::AbstractVector{AbstractString})
    res = Vector{Int64}(undef,0)
    count = 1
    foraging = true
    for x in vec
        if ismatch(r"^poke_[0-8]$",x) && !foraging
            count += 1
            foraging = true
        elseif ismatch(r"^poke_9$",x) && foraging
            foraging = false
        end
        push!(res,count)
    end
    return res
end

function find_task_state(df::AbstractDataFrame)
    state = "Forage"
    travel = false
    res = []
    # the order of updating travel and pushing is important to get the right state in each row
    for x in eachrow(df)
        #if the animal is poking in the travel port and the state signals a travel onset, set travel true
        if ismatch(r"^poke_9", x.Port) && !ismissing(x.TravelOnset) # && (!travel)
            travel = true
            push!(res, travel ? "Travel" : "Forage")
            # catch if in the same poke the animal ends the travel via travel complete info
            if !ismissing(x.TravelComplete)
                travel = false
            end
        #if state signals start forage or  travel complete, set travel false
        elseif (travel) && ((ismatch(r"^start_forage_",x.Port)) || (!ismissing(x.TravelComplete)))
            push!(res, travel ? "Travel" : "Forage")
            travel = false
        else
            push!(res, travel ? "Travel" : "Forage")
        end
    end
    return res
end

function activeside(ev_vec::AbstractVector{AbstractString},trav_vec)
    first_idx = findstring(r"^start_forage",ev_vec)
    side = activeside(ev_vec[first_idx])
    ActivePort = repeat([side],length(ev_vec))
    # change_idx = findall(.!ismissing.(trav_vec))
    change_idx = findall(ismatch.(r"^start_forage_",ev_vec))
    for i in change_idx
        ActivePort[i:end] .= activeside(ev_vec[i])
        # side == "Left" ? (side = "Right") : (side = "Left")
        # ActivePort[i:end] .= side #activeside(ev_vec[i])
    end
    return ActivePort
end

activeside(x::String) = ismatch(r"start_forage_left",x) ? "Left" : "Right"

function incorrectpokes!(df::AbstractDataFrame)
    # wrongside = @. !ismatch(Regex(df.ActivePort),df.Port) && ismatch(r"^Poke", df.Port)
    travelling = @. df.State == "Travel" && ismatch(r"(^Poke)|(^Rew)", df.Port)
    # df[!,:Incorrect] = @. wrongside || travelling
    df[!,:Incorrect] = travelling

end

function count_patches(state_vec::AbstractVector)
    c = 1
    res = [1]
    for i in 2:length(state_vec)
        (state_vec[i-1] == "Travel") && (state_vec[i] == "Forage") && (c += 1)
        push!(res,c)
    end
    return res
end

function determine_travel(t_vals, state_vals)
    clean_state = filter(x -> !ismissing(x), state_vals)
    f_t = t_vals[clean_state .== "Travel"]
    clean_t = filter(x -> !ismissing(x), f_t)
    isempty(clean_t) ? missing : minimum(clean_t) < 2500 ? "Short" : "Long"
end

function determine_richness(vec, Rdict)
    clean = filter(x -> !ismissing(x), vec)
    isempty(clean) ? missing : get(Rdict,minimum(clean),"nope")
end
