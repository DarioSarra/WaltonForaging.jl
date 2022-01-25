#=
Data for modelling: Structured in Trials (pokes are concatenated to remove gaps)
    - arrival_times = vec : arrival time in the foraging port
    - departure_times = vec : leaving time in the foraging port (moment they start travel poke)
    - average_reward_rate = float64 : average reward rate fixed value
    - block_transitions = vec : block transition from long to short travel or viceversa
    - firts_block = string : travel block state at the session start
    - n_bins = int : total number of 100ms time n_bins
    - n_rewards = int : total number of rewards
    - reward_times = vec : when the reward are given (defined as when the reward available state occurs)
    - time_bin = float : size of the time bin
=#

#= Models Return
return bin by bin vector of
    rewrate(rho)_env
    rewrate_patch
    rew_prediction_error_env
    rew_prediction_error_patch
    p_staying
    p_leaving
=#

#= Reward rate comparison modelling
 5 parameters float randomly initialized 10 times or 20 if didn't stabilise
 alpha_environment = [0,0.1] learning rate of environment
 alpha_patch = [0, 0.2] learning rate of the patch
 beta = [2, 10] noise parameter or inverse temperature
 reset = [0, 0.5] patch env rew rate at the entrance of a trials, because it has decayed in the last trial
 bias = [2, 10] bias towards staying in the softmax

initialization
environment_reward_rate set to the whole session reward rate
patch_reward_rate set to the reset value

bin by bin
    check reward status 1||0 (has a reward)

    compute Env reward prediction error 0||1 - environment reward rate (evolves during travel)
    follow update with relative alpha

    Are we travelling?
        No
            compute Patch reward prediction error 0||1 - patch reward rate (reset after travel, substitute patch_rew_rate with rest param)
            follow update with relative alpha
            calculate probability of staying
            p_staying likelihood = exp(bias + beta*patch_rew_rate)/exp(bias + beta*patch_rew_rate) + exp(beta*env_rew_rate)
            p_leaving = 1 - p_staying
        Yes

        is it the first time bin?
            Yes
            compute Patch reward prediction error 0||1 - patch reward rate (reset after travel, substitute patch_rew_rate with rest param)
            follow update with relative alpha
            calculate probability of leaving
            p_leaving = exp(beta*env)/(exp(beta*env) + exp(bias + beta*patch))
            OR as before 1 - staying
            p_staying likelihood = exp(bias + beta*patch_rew_rate)/exp(bias + beta*patch_rew_rate) + exp(beta*env_rew_rate)
            p_leaving = 1 - p_staying
            1 - p_staying = exp(beta*env)/(exp(beta*env) + exp(bias + beta*patch))
            NO
            reset the patch value to RESET parameter
=#

#= Fixed Treshold
    threshold replacing the environmen_rew_rate with a fixed fitted value
    p_staying = exp(bias+ beta*patch_rew_rate)/(exp(bias+ beta*patch_rew_rate) + exp(beta*threshold)

    Alternatively 2 threshold depending on the travel block
    which is why we have a block transition vector
=#

#= Semiconstant environment / Staggered model: update environment reward rate only at end of a trial
Equivalent to Reward rate comparison model but
    - Store the env_rew_rate at the start of a trial and use as reference throught the trial
    - Keep updating env_rew_rate underhood as before
    if arrival to a new patch is true update the env_rew_rate
    CAREFUL THAT IF YOU UPDATE AT LEAVING FIRST CHECK P_LEAVING THEN CHANGE ENV_RERATE
=#
