using Revise, WaltonForaging
if ispath("/home/beatriz/Documents/Datasets/WaltonForaging")
    main_path ="/home/beatriz/Documents/Datasets/WaltonForaging"
elseif ispath("/Users/dariosarra/Documents/Lab/Walton/WaltonForaging")
        main_path = "/Users/dariosarra/Documents/Lab/Walton/WaltonForaging"
elseif ispath(joinpath("C:\\Users","dario","OneDrive","Documents","Lab","Walton","WaltonForaging"))
        main_path = joinpath("C:\\Users","dario","OneDrive","Documents","Lab","Walton","WaltonForaging")
end
# Exp = "DAphotometry"
Exp = "5HTPharma"
## To do adjust reward assignment shift
rawt = CSV.read(joinpath(main_path,"data",Exp,"Processed","RawTable.csv"), DataFrame)
df = process_rawtable(rawt)
pokes = process_pokes(df)
open_html_table(rawt[1:500,:])
    open_html_table(df[1:500,:])
    open_html_table(pokes[1:500,:])

## prblem with printline assignment
printdf = make_print_df(rawt)
open_html_table(printdf[1:500,:])

#
## to do Patch counting after travel complete, Summed forage time, delta forage time,

df1 = select(df, [:SubjectID, :StartDate, :Time, :Duration,:Port, :Rew,:Patch,
        :Status,:Travel, :Richness,
        :RewInPatch,:RewInBlock, :PatchInBlock, :Block])
df1[!, :Correct] = [get(PortStatusDict,p,missing) == s for (p,s) in zip(df.Port,df.Status)]
idx = findall(ismissing.(prov))
expected_missings = ["travel_tone_increment",
    "travel_out_of_poke",
    "travel_resumed",
    "travel_complete",
    "task_disengagment"]
any(.![x in expected_missings for x in unique(df.Port[idx])])
dropmissing!(df1,:Correct)
filter!(r -> r.Correct, df1)
##
f_pokes = ismatch.(r"^Poke",df1.Port)
shifted_rew = vcat(ismatch.(r"^reward$", df1.Status)[2:end], [false])
df1[!, :Rewarded] = convert(Vector{Bool},f_pokes .&& shifted_rew)
shifted_travel = vcat(ismatch.(r"^travel$", df1.Status)[2:end], [false])
df1[!, :Leave] = convert(Vector{Bool},f_pokes .&& shifted_travel)
open_html_table(df1[1:500,:])
df2 = filter(r-> r.Status == "forage", df1)
transform!(groupby(df2, [:SubjectID,:StartDate,:Rew]),:Duration => cumsum => :SummedForagingByRew)
open_html_table(df2[1:500,:])
