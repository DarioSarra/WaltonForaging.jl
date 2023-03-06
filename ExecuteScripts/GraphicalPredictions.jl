using Revise, WaltonForaging
##
init_forage_time = [1,0.5,0.227]
reward = 10
θ = 5
e1 = Exponential(θ)
mean(e1)
rand(e1)
quantile(e1,0.025)
quantile(e1,0.925)

function update_time(rew_num, initial)
    M = initial*(1.3^(rew_num-1))
    EXP = Exponential(M)
    CIlow = quantile(EXP,0.025)
    CIhigh =  quantile(EXP,0.925)
    return M, CIlow, CIhigh
end

function update_time(initial; n_rewards = 15)
    df = DataFrame(Mean = Float64[],CI_L = Float64[], CI_H = Float64[], Rew = Float64[])
    prev = 0
    for i in 1:n_rewards
        m, cil, cih = update_time(i,initial)
        push!(df,(Mean = m+prev,CI_L = cil+prev, CI_H = cih+prev, Rew = i))
        prev +=m
    end
    return df
end
##
poor = update_time(1)
medium = update_time(0.5)
rich = update_time(0.227)

@df poor plot(:Rew,:Mean, ribbon = (:Mean - :CI_L,:CI_H - :Mean), fillalpha = 0.2, label = "poor")
@df medium plot!(:Rew,:Mean, ribbon = (:Mean - :CI_L,:CI_H - :Mean), fillalpha = 0.2, label = "medium")
@df rich plot!(:Rew,:Mean, ribbon = (:Mean - :CI_L,:CI_H - :Mean), fillalpha = 0.2, label = "high", legend = :topleft)
##
@df poor plot(:Mean, :Rew, ribbon = (:CI_L,:CI_H), fillalpha = 0.2,label = "poor")
@df medium plot!(:Mean, :Rew, ribbon = (:CI_L,:CI_H), fillalpha = 0.2, label = "medium")
@df rich plot!(:Mean, :Rew, ribbon = (:CI_L,:CI_H), fillalpha = 0.2, label = "high",
     legend = :topleft, xlims = (0,15), ylims=(0,18),xticks = 0:1:15,yticks = 0:1:18)
##
xaxis = 0:20
low = [0.075,32.5]
high = [0.075,57.5]
plot(xaxis,basic(xaxis,low),label = "low", color = :grey)
plot!(xaxis,basic(xaxis,high),label = "high", color = :black)
low2 = [0.075*1.1,32.5]
high2 = [0.075*1.1,57.5]
plot!(xaxis,basic(xaxis,low2),label = "low2", color = :grey, linestyle = :dash)
plot!(xaxis,basic(xaxis,high2),label = "high2", color = :black, linestyle = :dash)
##
inverse(20,low2) - inverse(20,low)
inverse(20,high2) - inverse(20,high)
vline!([inverse(20,high)], color = :red)
vline!([inverse(20,high2)], color = :red, linestyle = :dash)
vline!([inverse(20,low)], color = :green)
vline!([inverse(20,low2)], color = :green, linestyle = :dash)
hline!([20], color = :blue)
##
xaxis = 0:20
low = [0.075,32.5]
high = [0.075,57.5]
plot(xaxis,basic(xaxis,low),label = "low", color = :grey, legend = :topleft)
plot!(xaxis,basic(xaxis,high),label = "high", color = :black)
hline!([20], color = :blue, label = "threshold")
scaling_factor = 1.1
low2 = [0.075*scaling_factor,32.5]
high2 = [0.075*scaling_factor,57.5]
plot!(xaxis,basic(xaxis,low2),label = "scaled_low", color = :grey, linestyle = :dash)
plot!(xaxis,basic(xaxis,high2),label = "scaled_high", color = :black, linestyle = :dash)
vline!([inverse(20,high)], color = :red, label = "")
vline!([inverse(20,high2)], color = :red, linestyle = :dash, label = "")
vline!([inverse(20,low)], color = :green, label = "")
vline!([inverse(20,low2)], color = :green, linestyle = :dash, label = "")
##
inverse(20,low2) - inverse(20,low)
inverse(20,high2) - inverse(20,high)
##
xaxis = 0:20
low = [0.075,32.5]
high = [0.075,57.5]
plot(xaxis,basic(xaxis,low),label = "low", color = :grey, legend = :topleft)
plot!(xaxis,basic(xaxis,high),label = "high", color = :black)
hline!([20], color = :blue, label = "threshold")
scaling_factor = 1.1
hline!([20*scaling_factor], color = :blue, linestyle = :dash, label = "scaled_treshold")
vline!([inverse(20,high)], color = :red, label = "")
vline!([inverse(20*scaling_factor,high)], color = :red, linestyle = :dash, label = "")
vline!([inverse(20,low)], color = :green, label = "")
vline!([inverse(20*scaling_factor,low)], color = :green, linestyle = :dash, label = "")
##
inverse(20*scaling_factor,low) - inverse(20,low)
inverse(20*scaling_factor,high) - inverse(20,high)
