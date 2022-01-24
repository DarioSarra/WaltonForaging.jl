"""
    `individual_summary(df,xvar,yvar; summary = mean, err = :MOUSE)`
    computes a summary statistic (default = mean) for each individual
    (default = :MOUSE) used to later calculate the error across individual
"""

function individual_summary(df,xvar,yvar; summary = mean, err = :MOUSE)
    #evaluate if it's going over multiple grouping columns
    multiple = typeof(xvar) <: AbstractVector && sizeof(xvar) > 1
    if multiple
        gdc = groupby(df,vcat(xvar,err))
    else
        gdc = groupby(df,[xvar,err])
    end
    df1 = combine(gdc,yvar => summary => yvar)
    sort!(df1,xvar)
    if multiple
        label_df = unique(df1[:,xvar])
    else
        label_df = unique(df1[:,[xvar]])
    end
    label_df[!,:xpos] = 1:nrow(label_df)
    leftjoin(df1,label_df; on = xvar)
    try
        firstval = union(df1[:,xvar])[1]
        df1[!,:xpos] = [v == firstval ? 1 : 2  for v in df1[:,xvar]]
    catch
        println("Can't define x position")
    end
    return df1
end

"""
    `group_summary(df1,xvar,yvar; normality = true)`
    using bootstrap computes central measure plus 95% CI
    if normality is true it uses mean as central measure
    else it uses median
"""

function group_summary(df1,xvar,yvar; normality = true)
    if normality
        central = mean
    else
        central = median
    end
    df2 = combine(groupby(df1,xvar)) do dd
        # using bootstrap to calculate the central point and the 95% CI
        b = bootstrap(central, dd[:,yvar], BasicSampling(100000))
        #bootstrap confint returns a tuple containing a tuple with the statistic
        #estimates and the CI lower and uppper bounds
        m, lower, upper = confint(b,PercentileConfInt(0.95))[1]
        ci1 = m - lower
        ci2 = upper - m
        (Central = m, ERR = (ci1,ci2))
    end
    return df2
end

function survivalrate_algorythm(var; step = 0.5, xaxis = nothing)
    isnothing(xaxis) && (xaxis = range(extrema(var)..., step = step))
    survival = 1 .- ecdf(var).(xaxis)
    return (Xaxis = collect(xaxis), fy = survival)
end

function cumulative_algorythm(var; step = 0.5, xaxis = nothing)
    isnothing(xaxis) && (xaxis = range(extrema(var)..., step = step))
    cum = ecdf(var).(xaxis)
    return (Xaxis = collect(xaxis), fy = cum)
end

function hazardrate_algorythm(var; step = 0.5, xaxis = nothing)
    isnothing(xaxis) && (xaxis = range(extrema(var)..., step = step))
    survival = 1 .- ecdf(var).(xaxis)
    hazard = -pushfirst!(diff(survival),0)./survival
    return (Xaxis = collect(xaxis), fy = hazard)
end

"""
    `function_analysis(df,variable, f; grouping = nothing, step =0.05, calc = :basic,
            color = [:auto], linestyle = [:auto])`
    Apply the function f over the vaariable var per each value of grouping and
    plots the result over the variable var
"""

function function_analysis(df,var, f; grouping = nothing, step = 0.5, calc = :basic,
        xaxis = nothing,
        color = [:auto], linestyle = [:auto])
    subgroups = isnothing(grouping) ? [:MOUSE] : vcat(:MOUSE,grouping)
    isnothing(xaxis) && (xaxis = range(extrema(df[:,var])..., step = step))
    dd1 = combine(groupby(df,subgroups), var => (t-> f(t,xaxis = xaxis, step = step)) => AsTable)
    rename!(dd1, Dict(:Xaxis => var))
    sort!(dd1,[:MOUSE,var])
    if calc == :bootstrapping
        dd2 = combine(groupby(dd1,grouping)) do dd3
            group_summary(dd3,var,:fy; normality = false)
        end
        dd2[!,:low] = [x[1] for x in dd2.ERR]
        dd2[!,:up] = [x[2] for x in dd2.ERR]
    elseif calc == :quantiles
        dd2 = combine(groupby(dd1,[grouping,var]), :fy =>(t-> (Central = mean(t),
        low= abs(mean(t) - quantile(t,0.25),
        up = abs(quantile(t,0.975)-mean(t))),
        # ERR = (abs(mean(t) - quantile(t,0.25)) + abs(quantile(t,0.975)-mean(t)))/2,
        SEM = sem(t))) => AsTable)
    elseif calc == :basic
        dd2 = combine(groupby(dd1,[grouping,var]), :fy =>(t-> (Central = mean(t),up = sem(t), low = sem(t))) => AsTable)
    end
    sort!(dd2,var)

    plt = @df dd2 plot(cols(var),:Central, ribbon = (:low, :up), group = cols(grouping), linecolor = :auto, color = color, linestyle = linestyle)
    return plt, dd2
end
