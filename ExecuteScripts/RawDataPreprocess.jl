using Revise, WaltonForaging
ispath("/home/beatriz/Documents/") ? (main_path ="/home/beatriz/Documents/") : (main_path = "/Users/dariosarra/Documents/Lab/Walton/WaltonForaging")
fig_dir = joinpath(main_path,"Figures")
# pokes = DataFrame(CSV.read(joinpath(main_path,"Miscellaneous/Poke_data.csv")))#, DataFrame)
# pokes2 = DataFrame(CSV.read(joinpath(main_path,"Miscellaneous/New_Poke_data.csv")))#, DataFrame)
pokes = CSV.read(joinpath(main_path,"Miscellaneous/States_Poke_data.csv"), DataFrame)
##
Exp = "DAphotometry"#"5HTPharma"
FileList = readdir(joinpath(main_path,Exp,"RawData"))
filter!(r -> ismatch(r".txt",r), FileList)
session = joinpath(main_path,Exp,"RawData",FileList[1])
#=
Depending on when the p line is written, during forge port poke or during travel port poke,
T  = poke time required to get reward (retrospective?), poke time required to travel
    (initial value to threshold 2000)
IFT = always tells you the initial average of the dist for which the richness is taken
AFT = during reward collection average dist for that specific reward (the updated average),
    during travel for how long in the previous forage before leaving
There is a timeout for going back to travel if animal don't engage in foraging
=#
##
session
pokes = process_raw_session(session; observe = true)
combine(groupby(pokes,:Patch), :RewardAvailable => x -> sum(.!ismissing.(x)))
bouts = process_bouts(pokes; observe = true)
open_html_table(bouts)
union(pokes.PokeIn)
##
AllBouts = DataFrame()
for file in FileList
    session = joinpath(main_path,Exp,"RawData",file)
    pokes = process_raw_session(session; observe = false)
    bouts = process_bouts(pokes; observe = false)
    path = joinpath(main_path,Exp,"Processed",replace(file,"txt"=>"csv"))
    CSV.write(path, bouts)
    if isempty(AllBouts)
        AllBouts = bouts
    else
        append!(AllBouts,bouts)
    end
end
