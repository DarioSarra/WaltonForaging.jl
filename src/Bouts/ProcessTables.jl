function process_foraging(main_path,Exp)
    AllBouts = DataFrame()
    AllPokes = DataFrame()
    FileList = readdir(joinpath(main_path,Exp,"RawData"))
    filter!(r -> ismatch(r".txt",r), FileList)
    for file in FileList[1:end]
        println(file)
        session = joinpath(main_path,Exp,"RawData",file)
        pokes = process_raw_session(session; observe = false)
        bouts = process_bouts(pokes; observe = false)
        # path = joinpath(main_path,Exp,"Processed",replace(file,"txt"=>"csv"))
        # CSV.write(path, bouts)
        if isempty(AllBouts)
            AllPokes = allowmissing(pokes)
            AllBouts = bouts
            allowmissing!(AllBouts)
        else
            append!(AllPokes,pokes)
            append!(AllBouts,bouts)
        end
    end
    return AllPokes, AllBouts
end
