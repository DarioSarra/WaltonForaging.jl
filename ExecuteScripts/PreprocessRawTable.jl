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
## Get raw data
# rawt = CSV.read(joinpath(main_path,"data",Exp,"Processed","RawTable.csv"), DataFrame)
# df = process_rawtable(rawt)
# CSV.write(joinpath(main_path,"data",Exp,"Processed","JuliaRawTable.csv"),df)
df = CSV.read(joinpath(main_path,"data",Exp,"Processed","JuliaRawTable.csv"), DataFrame)
## Process pokes
i = findall([!ismissing(r.name) && ismatch(r"poke_\d_out",r.name)  for r in eachrow(rawt)])
findall(rawt[i,:time].> 2000)
open_html_table(rawt[i-500:i+500,:])
df[!,:SubjectID] = [ismatch(r"RP\d$",x) ? "RP0"*x[end] : x for x in df.SubjectID]
unique(df[:, :SubjectID])
pokes = process_pokes(df)
open_html_table(rawt[1:1000,:])
open_html_table(df[1:500,:])
open_html_table(pokes[1:5000,:])
##
x = pokes.StartDate[1]
##
an_pokes = filter(r-> r.Status == "forage" &&
    !ismissing(r.Bout) &&
    !ismissing(r.Travel),
    pokes)

contrasts = Dict(
    :Richness => DummyCoding(; base ="medium"),
    :Travel => DummyCoding(; base ="short"),
    :Rewarded => DummyCoding(; base = false),
    :Leave => DummyCoding(; base = false),

    :Time => Center(1),
    :Duration => Center(171),
    :SummedForage => Center(683),
    :ElapsedForage => Center(1361),
    :Bout => Center(1),
    :Trial => Center(1),

    :SubjectID => Grouping()
    )

form = @formula(Leave ~ 1 + SummedForage + ElapsedForage + Bout + Rewarded + Richness +
    (1|SubjectID) + (SummedForage|SubjectID) + (ElapsedForage|SubjectID) + (Bout|SubjectID) + (Rewarded|SubjectID) + (Richness|SubjectID))

form2 = @formula(Leave ~ 1 + SummedForage + Richness + Travel + (1|SubjectID))
mdl = MixedModels.fit(MixedModel,form2, an_pokes, Bernoulli(); contrasts)

unique(an_pokes.SubjectID)
unique(an_pokes.StartDate)
