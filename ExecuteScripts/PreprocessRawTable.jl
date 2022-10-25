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
open_html_table(pokes[1:5000,:])

## to do Patch counting after travel complete, Summed forage time, delta forage time,
function foragetimes!(df0)
    df1 = filter(r -> r.Status == "forage", df0)
    # count_bouts(rew_vec, leave_vec) = vcat([1], cumsum(rew_vec .|| leave_vec)[1:end-1] .+1)
    transform!(groupby(df1,[:SubjectID,:StartDate,:Bout]),
        :Duration => cumsum => :SummedForage,
        :Time => ((t) -> t .- t[1]) => :ElapsedForage)
    leftjoin!(df0,df1, on = propertynames(df0), matchmissing = :equal)
end
