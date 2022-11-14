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
transform!(pokes, :SubjectID => ByRow(x -> (ismatch(r"RP\d$",x) ? "RP0"*x[end] : x)) => :SubjectID)
CSV.write(joinpath(main_path,"data",Exp,"Processed","PokesTable.csv"),pokes)
pokes = CSV.read(joinpath(main_path,"data",Exp,"Processed","PokesTable.csv"), DataFrame)
##
bouts = process_bouts(pokes)
open_html_table(df[1:5000,:])
open_html_table(pokes[1:500,:])
open_html_table(bouts[1:500,:])
##
unique(pokes[:, :SubjectID])
transform!(pokes, :SubjectID => ByRow(x -> (ismatch(r"RP\d$",x) ? "RP0"*x[end] : x)) => :SubjectID)
transform!(bouts, :SubjectID => ByRow(x -> (ismatch(r"RP\d$",x) ? "RP0"*x[end] : x)) => :SubjectID)
unique(pokes[:, :SubjectID])
unique(bouts[:, :SubjectID])
##
r = findall(ismatch.(r"reward",df.state))
t = findall(ismatch.(r"Trav",df.Port))
res = [trav - r[findfirst(r.> trav) - 1] for trav in t]
idx = findall(res.<=2)
i = t[idx[2]]
    open_html_table(df[i-10:i+10,:])
##
patch = 43
mouse = "RP01"
date = "2021/02/05 13:35:04"
open_html_table(filter(r-> r.SubjectID == mouse &&
    r.StartDate == date &&
    (patch <= r.Patch <= patch +1),
    df))
open_html_table(filter(r-> r.SubjectID == mouse &&
    r.StartDate == date &&
    (patch <= r.Trial <= patch +1),
    pokes))
##
length(findall(Bool.(pokes.Rewarded) .&& Bool.(pokes.Leave))) / length(findall(Bool.(pokes.Leave)))
##
RaquelPharmaCalendar!(pokes)
open_html_table(pokes[1:500,:])
countmap(pokes.Treatment)
##
contrasts = Dict(
    :Richness => DummyCoding(; base ="medium"),
    :Travel => DummyCoding(; base ="short"),
    :Rewarded => DummyCoding(; base = false),
    :Leave => DummyCoding(; base = false),

    :Time => Center(1),
    :Duration => Center(1),
    :SummedForage => Center(1),
    :ElapsedForage => Center(1),
    :PokeInBout	=> Center(1),
    :RewardsInTrial => Center(0),
    :Trial => Center(1),

    :SubjectID => Grouping()
    )
##
an_pokes = filter(r-> r.Status == "forage" &&
    !ismissing(r.Bout) &&
    !ismissing(r.Travel) &&
    r.Treatment == "Baseline",
    pokes)
unique(an_pokes.Phase)
open_html_table(an_pokes[1:500,:[:SubjectID, :Day, :Port,:Leave,:Rewarded,:Richness,:Travel,
    :PokeInBout, :SummedForage, :ElapsedForage]])

p_form1 = @formula(Leave ~ 1 + SummedForage + ElapsedForage + PokeInBout + Rewarded + Richness + Travel + RewardsInTrial +
    (1 + SummedForage + ElapsedForage + PokeInBout + Rewarded + Richness + Travel + RewardsInTrial|SubjectID))
p_mdl1 = MixedModels.fit(MixedModel,p_form1, an_pokes, Bernoulli(); contrasts)

form2 = @formula(Leave ~ 1 + SummedForage + Richness + Travel + (1|SubjectID))
mdl2 = MixedModels.fit(MixedModel,form2, an_pokes, Bernoulli(); contrasts)

unique(an_pokes.SubjectID)
unique(an_pokes.StartDate)
unique(an_pokes.Port)
##
form1 = @formula(Leave ~ 1 + SummedForage + ElapsedForage  + Rewarded + Richness + Travel + RewardsInTrial +
    (1 + SummedForage + ElapsedForage  + Rewarded + Richness + Travel + RewardsInTrial|SubjectID))
mdl1 = MixedModels.fit(MixedModel,form1, bouts, Bernoulli(); contrasts)

form2 = @formula(Leave ~ 1 + SummedForage + Richness + Travel + (1|SubjectID))
mdl2 = MixedModels.fit(MixedModel,form2, bouts, Bernoulli(); contrasts)
##
check = combine(groupby(bouts, :SubjectID), [:Rewarded, :Travel,:Leave] .=> x -> [countmap(x)])
open_html_table(check)
findall(bouts.Travel .== 0)
fdf = filter(r-> !ismissing(r.Travel) && r.Travel == 0, bouts)
open_html_table(fdf)
countmap(pokes.Bout)
##
fdf = filter(r-> !ismissing(r.Travel) && r.Travel == 0, pokes)
countmap(pokes.Travel)
##
c2 = combine(groupby(pokes,[:SubjectID,:StartDate,:Bout]),
    :Status => (x -> sum(ismatch.(r"forage",x))) => :ForagePokes,
    :Status => (x -> sum(ismatch.(r"travel",x))) => :TravelPokes)
c3 = filter(r -> r.ForagePokes == 0, c2)
c4 = filter(r -> ismissing(r.Bout), pokes)
findall(ismissing.(pokes.Bout))
open_html_table(pokes[2680:2800,:])
