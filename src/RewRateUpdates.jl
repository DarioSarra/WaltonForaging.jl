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

function get_rew_rate(rewards,n, alpha, initialvalue)
    x = collect(zip(rewards,n))
    return accumulate(x; init=initialvalue) do value, x
        #= x is a tuple containing
        the outcome val (1 = rew, 0 = omission): x[1]
        and the number of bins in that poke: x[2]
        =#
        Bool(x[1]) ? get_consecutive_rewards_rate(x[2], alpha, value) : get_consecutive_omissions_rate(x[2], alpha, value)
    end
end

function get_rew_rate(rewards,n, alpha, initialvalue, firsttrial)
    x = collect(zip(rewards,n))
    #= x is a tuple containing
    the outcome val (1 = rew, 0 = omission): x[1]
    and the number of bins in that poke: x[2]
    =#
    return accumulate(x; init=initialvalue) do value, x
        if Bool(firsttrial)
            # firsttrial tells if a new session starts here so it needs a new initial value
            return initialvalue
        else
            return Bool(x[1]) ? get_consecutive_rewards_rate(x[2], alpha, value) : get_consecutive_omissions_rate(x[2], alpha, value)
        end
    end
end

# rew = [0,0,1,1,0,0,0,1,1,1]
# alpha_val = 0.1
# initialvalue = 0.5
# get_rew_rate(rew, alpha_val, initialvalue)
# get_rew_rate([0,1,0,1],[2,2,3,3],alpha_val,initialvalue)
