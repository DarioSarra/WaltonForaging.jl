using WaltonForaging
using Documenter

makedocs(;
    modules=[WaltonForaging],
    authors="Dario Sarra",
    repo="https://github.com/DarioSarra/WaltonForaging.jl/blob/{commit}{path}#L{line}",
    sitename="WaltonForaging.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://DarioSarra.github.io/WaltonForaging.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/DarioSarra/WaltonForaging.jl",
)
