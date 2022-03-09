using Revise, WaltonForaging
ispath("/home/beatriz/Documents/") ? (main_path ="/home/beatriz/Documents/") : (main_path = "/Users/dariosarra/Documents/Lab/Walton/WaltonForaging")
fig_dir = joinpath(main_path,"Figures")
# pokes = DataFrame(CSV.read(joinpath(main_path,"Miscellaneous/Poke_data.csv")))#, DataFrame)
# pokes2 = DataFrame(CSV.read(joinpath(main_path,"Miscellaneous/New_Poke_data.csv")))#, DataFrame)
pokes = CSV.read(joinpath(main_path,"Miscellaneous/States_Poke_data.csv"), DataFrame)
##
FileList = readdir(joinpath(main_path,"RawData","5HTPharma"))
session = joinpath(main_path,"RawData","5HTPharma",FileList[2])
#=
Depending on when the p line is written, during forge port poke or during travel port poke,
T  = poke time required to get reward (retrospective?), poke time required to travel
    (initial value to threshold 2000)
IFT = always tells you the initial average of the dist for which the richness is taken
AFT = during reward collection average dist for that specific reward (the updated average),
    during travel for how long in the previous forage before leaving
There is a timeout for going back to travel if animal don't engage in foraging
=#
pokes = process_raw_session(session; observe = true)
process_raw_session("buh")
open_html_table(df)
ispath(session)
