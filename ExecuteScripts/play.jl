genericf(x,a,b,c) = a*x^2 + b*x + c

plot(vals,genericf.(vals,-1,5,2), xticks = :auto)

generic_pol(x::Real,c::AbstractVector{:Real}) = c[1]*x^4 + c[2]*x^3 + c[3]*x^2 + c[4]*x + c[5]
generic_pol(x::AbstractRange,c) = [generic_pol(v,c) for v in x]

##
vals = 0:0.1:6
opts = [1,5,10]
f = plot()
for o in opts
    plot!(f,vals,generic_pol(vals,[-1,3,o,100,1]), xticks = :auto, legend = false)
end
f

n = 10
attempt = @animate for i ∈ 1:n
    plot(vals,generic_pol(vals,[-1,3,i,100,1]), xticks = 0:1:6, ylims = (0,520), legend = false)
end every 1

gif(attempt, "/Users/dariosarra/Documents/Lab/Oxford/Walton/Presentations/Lab_meeting/Lab_meeting20230222/testgif.gif",fps =3)
##

ys = [0.0, 1.5, 2.9, 4.2, 5.4, 6.1, 7.1, 8.0, 8.8, 9.5, 
    10.1, 10.7, 11.2, 11.7, 12.3, 12.7, 13.0, 13.4, 13.7, 14.0,
    14.2, 14.4, 14.8, 15.2, 15.7, 16, 16.2, 16.4, 16.6, 16.5,
    16.3, 16.0, 15.0, 14.0, 12.0, 9.0, 6.0, 0.0]
plot(ys, xticks = 0:2:40, aspect_ratio = 1.0)

ys2 = [0,1,1.8,2.4,2.8,3.0,2.9,2.8,2.6,2.4,2.1,1.8,1.4,1.0,0.4,0.0]
plot(ys2, xticks = 0:2:40, aspect_ratio = 1.0)
