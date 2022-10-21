using Revise, WaltonForaging
if ispath("/home/beatriz/Documents/")
    main_path ="/home/beatriz/Documents/"
elseif ispath("/Users/dariosarra/Documents/Lab/Walton/WaltonForaging")
        main_path = "/Users/dariosarra/Documents/Lab/Walton/WaltonForaging"
elseif ispath(joinpath("C:\\Users","dario","OneDrive","Documents","Lab","Walton","WaltonForaging"))
        main_path = joinpath("C:\\Users","dario","OneDrive","Documents","Lab","Walton","WaltonForaging")
end
# Exp = "DAphotometry"
Exp = "5HTPharma"
##
rawt = CSV.read(joinpath(main_path,"data",Exp,"Processed","RawTable.csv"), DataFrame)
open_html_table(rawt[1:500,:])
df = process_rawtable(rawt)

findrichness!(df)
open_html_table(df[1:500,:])

countmap(df.IFT)
RichnessDict_keys  = sort(collect(keys(countmap(df.IFT))))
RichnessDict = Dict(x => y for (x,y) in zip(RichnessDict_keys,[missing, "rich", "medium", "poor"]))

df.IFT
