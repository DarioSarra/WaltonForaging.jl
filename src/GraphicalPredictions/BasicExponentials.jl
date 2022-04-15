basic(x,p::AbstractVector) = @. (1-(exp(-p[1]*x)))*p[2]
inverse(y,p::AbstractVector) = @. -(log(1-(y/p[2])))/p[1]
##
function basic(xaxis,case::String)
    println(case)
    if case == "low"
        p = [0.075,32.5]
    elseif case ==  "high"
        p = [0.075,57.5]
    else
        error("case not recognized")
    end
    basic(xaxis,p)
end

function inverse(xaxis,case::String)
    if case == :low
        p = [0.075,32.5]
    elseif case ==  :high
        p = [0.075,57.5]
    end
    inverse(xaxis,p)
end
