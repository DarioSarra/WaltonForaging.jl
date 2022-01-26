"""
    `get_rew_rate(rewards, alpha, initialvalue)`

Use accumulate to update reward rate according to
a starting point 'initialvalue'
a sequence of outcomes 'rewards'
and a learning rate 'alpha'
"""

function get_rew_rate(rewards, alpha, initialvalue)
   return accumulate(rewards; init=initialvalue) do value, reward
       #=(1 - alpha) * value + alpha*reward=#
       value + alpha*(reward - value)
   end
end

"""
    `get_consecutive_omissions_rate(n, alpha, initialvalue)`

Calculate rew_rate update for n consecutive no rewards
"""
function get_consecutive_omissions_rate(n, alpha, initialvalue)
    initialvalue*(1-alpha)^n
end


"""
    `get_consecutive_rewards_rate(n, alpha, initialvalue)`

Calculate rew_rate update for n consecutive no rewards
"""


function get_consecutive_rewards_rate(n, alpha, initialvalue)
    initialvalue*((1-alpha)^n) + alpha*(ploynomial_alpha(1-alpha,n))
end

"""
    `ploynomial_alpha(n, alpha, initialvalue)`

    Helper function to calculate the value of the polynomial necessary to calculate consecutive rewards rate
"""
function ploynomial_alpha(oneminusalpha,n)
    n<1 && error("minimum one outcome to consider")
    sum(oneminusalpha.^(0:n-1))
end
"""
    `get_1bin_reward_rate(n, alpha, initialvalue)`
"""
function get_1bin_reward_rate(n, alpha, initialvalue)
    pre_rew_rate = initialvalue*(1-alpha)^(n-1) #omission until the last bin
    pre_rew_rate + alpha*(1-pre_rew_rate)
end


function get_rew_rate(rewards::AbstractVector,n::AbstractVector, initialvalue::Float64, alpha::Float64)
    x = collect(zip(rewards,n))
    return accumulate(x; init=initialvalue) do value, x
        #= x is a tuple containing
        the outcome val (1 = rew, 0 = omission): x[1]
        and the number of bins in that poke: x[2]
        =#
        # Bool(x[1]) ? get_consecutive_rewards_rate(x[2], alpha, value) : get_consecutive_omissions_rate(x[2], alpha, value)
        Bool(x[1]) ? get_1bin_reward_rate(x[2], alpha, value) : get_consecutive_omissions_rate(x[2], alpha, value)
    end
end

function env_get_rew_rate(rewards::AbstractVector,n::AbstractVector, initialvalue::AbstractVector, reset::AbstractVector, alpha)
    x = collect(zip(reset, initialvalue,rewards,n))
    #= x is a tuple containing
    x[1]: whether the reward rate has to be reset i.e. first poke in a new session for env_rew
    x[2]: the initial env_reward rate value (precomputed per session)
    x[3]: the outcome val (1 = rew, 0 = omission)
    x[4]: and the number of bins in that poke
    =#
    return accumulate(x; init=x[2]) do value, x
        if Bool(x[1])
            # reset env_rew or patch_rew if a new session or trial starts respectively
            return Bool(x[3]) ? get_1bin_reward_rate(x[4], alpha, x[2]) : get_consecutive_omissions_rate(x[4], alpha, x[2])
        else
            return Bool(x[3]) ? get_1bin_reward_rate(x[4], alpha, value) : get_consecutive_omissions_rate(x[4], alpha, value)
        end
    end
end

function patch_get_rew_rate(rewards::AbstractVector,n::AbstractVector, resetvalue::Float64, resetcases::AbstractVector, alpha::Float64)
    x = collect(zip(resetcases,rewards,n))
    #= x is a tuple containing
    x[1]: whether the reward rate has to be reset i.e. first poke in a new trial for patch_rew
    x[2]: the outcome val (1 = rew, 0 = omission)
    x[3]: and the number of bins in that poke
    =#
    return accumulate(x; init=resetvalue) do value, x
        if Bool(x[1])
            # reset env_rew or patch_rew if a new session or trial starts respectively
            return Bool(x[2]) ? get_1bin_reward_rate(x[3], alpha, resetvalue) : get_consecutive_omissions_rate(x[3], alpha, resetvalue)
        else
            return Bool(x[2]) ? get_1bin_reward_rate(x[3], alpha, value) : get_consecutive_omissions_rate(x[3], alpha, value)
        end
    end
end


# rew = [0,0,1,1,0,0,0,1,1,1]
# alpha_val = 0.1
# initialvalue = 0.5
# get_rew_rate(rew, alpha_val, initialvalue)
# get_rew_rate([0,1,0,1],[2,2,3,3],alpha_val,initialvalue)
