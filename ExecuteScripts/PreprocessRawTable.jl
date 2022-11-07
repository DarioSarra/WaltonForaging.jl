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
# open_html_table(rawt[1:1000,:])
# df = process_rawtable(rawt)
# CSV.write(joinpath(main_path,"data",Exp,"Processed","JuliaRawTable.csv"),df)
df = CSV.read(joinpath(main_path,"data",Exp,"Processed","JuliaRawTable.csv"), DataFrame)
# open_html_table(df[1:500,:])
## Process pokes
pokes = process_pokes(df)
open_html_table(pokes[1:500,:])
CSV.write(joinpath(main_path,"data",Exp,"Processed","PokesTable.csv"),df)
# pokes = CSV.read(joinpath(main_path,"data",Exp,"Processed","PokesTable.csv"), DataFrame)
##
unique(pokes[:, :SubjectID])
transform!(pokes, :SubjectID => ByRow(x -> (ismatch(r"RP\d$",x) ? "RP0"*x[end] : x)) => :SubjectID)
unique(pokes[:, :SubjectID])
##
RaquelPharmaCalendar!(pokes)
open_html_table(pokes[1:500,:])
countmap(pokes.Treatment)
unique(sort(pokes.Day))
Date(2021,02,28) in unique(sort(pokes.Day))
ismonday = x->Dates.dayofweek(x) == Dates.Monday;
issunday = x->Dates.dayofweek(x) == Dates.Sunday;
Dates.toprev(issunday, Date(2021,03,01))
##
an_pokes = filter(r-> r.Status == "forage" &&
    !ismissing(r.Bout) &&
    !ismissing(r.Travel) &&
    r.Phase == "CIT",
    pokes)

contrasts = Dict(
    :Richness => DummyCoding(; base ="medium"),
    :Travel => DummyCoding(; base ="short"),
    :Rewarded => DummyCoding(; base = false),
    :Leave => DummyCoding(; base = false),

    :Time => Center(1),
    :Duration => Center(median(an_pokes.Duration)),
    :SummedForage => Center(median(an_pokes.SummedForage)),
    :ElapsedForage => Center(median(an_pokes.ElapsedForage)),
    :PokeInBout	=> Center(1),
    :RewardsInTrial => Center(0),
    :Trial => Center(1),

    :SubjectID => Grouping()
    )

countmap(an_pokes.Day)

form1 = @formula(Leave ~ 1 + SummedForage + ElapsedForage + PokeInBout + Rewarded + Richness + Travel + RewardsInTrial +
    (1 + SummedForage + ElapsedForage + PokeInBout + Rewarded + Richness + Travel + RewardsInTrial|SubjectID))
mdl1 = MixedModels.fit(MixedModel,form1, an_pokes, Bernoulli(); contrasts)


form2 = @formula(Leave ~ 1 + SummedForage + Richness + Travel + (1|SubjectID))
mdl2 = MixedModels.fit(MixedModel,form2, an_pokes, Bernoulli(); contrasts)

unique(an_pokes.SubjectID)
unique(an_pokes.StartDate)
unique(an_pokes.Port)
