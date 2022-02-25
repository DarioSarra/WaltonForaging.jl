function AICtest(m0,m1)
    exp((aic(m0) − aic(m1))/2)
end
