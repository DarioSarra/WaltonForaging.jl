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
PortDict
rawt[!, :name] = [get(PortDict,x,x) for x in rawt.name]
open_html_table(rawt[1:1000,:])

df = filter(r -> r.type == "print", rawt)
open_html_table(df)
line = df[1,:value]
line = df[2,:value]
line = df[3,:value]

line[1:3] == "B#:"
