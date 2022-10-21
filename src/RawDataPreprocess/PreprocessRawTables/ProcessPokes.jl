function process_rawtable(rawt)
        renamerawtable!(rawt)
        df = parallelise_states(rawt)
        df2 = parallelise_prints(df,rawt)
        df2[!, :globalstate] = readstate.(df.state)
        findtravel!(df2)
        correct_travelstart!(df2)
        findrichness!(df2)
        rename!(df2, :name => :Port, :B_n => :Block, :R_n => :Rew, :P_n => :Patch,
                :RP_n => :RewInPatch, :RB_n => :RewInBlock, :PB_n => :PatchInBlock,
                :time => :Time, :duration => :Duration, :globalstate => :Status, :Column1 => :OriginalIndex)
        return select(df2,[:SubjectID, :StartDate, :Time, :Duration,:Port, :Rew,:Patch,
                :Status,:Travel, :Richness,
                :RewInPatch,:RewInBlock, :PatchInBlock, :Block,
                :P, :T, :AFT, :IFT, :TT,
                :ExperimentName, :TaskName, :TaskFileHash, :SetupID, :OriginalIndex, :type])
end
