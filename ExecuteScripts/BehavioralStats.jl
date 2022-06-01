using Revise, WaltonForaging
ispath("/home/beatriz/Documents/") ? (main_path ="/home/beatriz/Documents/") : (main_path = "/Users/dariosarra/Documents/Lab/Walton/WaltonForaging")
# Exp = "DAphotometry"
Exp = "5HTPharma"

Bout_path = joinpath(main_path,Exp,"Processed","AllBouts.csv")
bouts = CSV.read(Bout_path, DataFrame)

open_html_table(bouts[1:500,:])

Rdf1 = combine(groupby(bouts,[:SubjectID,:Startdate]), :Rewarded => (x -> sum(skipmissing(x))) => :Rewards)
Rdf2 = combine(Rdf1, :Rewards .=> [mean,std])
