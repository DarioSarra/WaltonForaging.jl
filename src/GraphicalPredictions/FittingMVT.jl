function fit_cumulative(cum,time)
    model(x,p) = @. (1 - exp(-p[1]*x)) * p[2]
    p0 = [0.5,1]
    fitting = curve_fit(model, cum, time, p0)
    # return DataFrame(Coef = fitting.param[1], Scale = fitting.param[2])
    # return (fitting.param...,)
    return fitting.param
end

ParetoModel(x,p) = @. (1 - ((p[1]/x)^p[2])) * p[3]
function fit_pareto(x,y)
    p0 = [0.5,0.5,0.5]
    fitting = curve_fit(ParetoModel, x, y, p0)
    return fitting.param
end

ExpoModel(x,p) = @. ((1 - exp(-p[1]*x)) * p[2]) + p[3]
function fit_ExpoModel(x,y)
    p0 = [0.5,0.5,0.5]
    fitting = curve_fit(ExpoModel, x, y, p0)
    return fitting.param
end

function MVTtangent(coef, P)
    # P is the point where the line pass through
    # cumulative to be tangential to
    c(x) = @. (1 - exp(-coef[1]*x))*coef[2]
    #derivative of the cum, equal to the slope
    d(x) = @. coef[1] * exp(-coef[1]*x) *coef[2]
    #solve using slope-intercept form of the line
    # y-y0 = m(x-x0)
    # x0 has to be a point on the curve so express it in this way
    # y-c(x0) = d(x0)(x-x0)
    # solve passing for the point P
    # yp -c(x0) = d(x0)(xp-x0)
    # yp -c(x0) - d(x0)(xp-x0) = 0
    # f(x) = P[2] - (1 - exp(-coef[1]*x))*coef[2] - (coef[1] * exp(-coef[1]*x))*coef[2]*(P[1]-x)
    f(x) = P[2] - c(x) - d(x)*(P[1]-x)
    x0 = Roots.find_zero(f,0) # search x0 in a reasonable range of trial time
    #find inercept using P and m = d(x0)
    # y = mx +q
    # P[2] = d(x0)*P[1] + q
    # q = -d(x0)*P[1] - P[2]
    q = -d(x0)*P[1] - P[2]
    # sol(x) = @. x * d(x0) + q
    # return DataFrame(OptLeave = x0, Slope = d(x0), Intercept = q)
    return (x0,d(x0),q)
end

GainModel(x,p) = @. (1 - exp(-p[1]*x)) *p[2]

# control = filter(r->r.Treatment == "Control", timedf)
# coef = fit_cumulative(control.Time, control.CumRew)
# control2 = filter(r->r.Treatment == "Control", timedf2)
# coef2 = fit_cumulative(control2.Time, control2.CumRew)
#
# xaxis = 0:0.5:35
# plot(xaxis,GainModel(xaxis,coef), label = "TrialTime", legend = :bottomright)
# plot!(xaxis,GainModel(xaxis,coef2), label = "ForagingTime", linecolor = :purple)
