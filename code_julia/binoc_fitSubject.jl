using DSP
function fit_subject(d,e;fir=false)

#e.latency = e.onsetTR
e.durationTR = e.duration./3.408


if e.task[1] == "localizer"
    formula  = @formula 0~0+condition # 0 as a dummy, we will combine wit data later
    contrasts = Dict(:condition=>StatsModels.FullDummyCoding())
else
    #continue

    # don't model no response events
    e = e[e.condition.!="no response",:]
    limit = quantile(e.duration,0.2)
    #println("Lower Eventduration Cutoff: $limit")
    e[e.duration.<limit,:condition] .= "shortEvents"
    e.duration = e.duration .-mean(e.duration)
    formula  = @formula 0~0+condition # 0 as a dummy, we will combine wit data later
    e.onsetTR = e.onsetTR .+ 3.
    #contrasts = Dict()
end
if fir
    boldbasis = unfold.firbasis([-10 32],1/3.408)
    #formula  = @formula 0~0+condition*duration # 0 as a dummy, we will combine wit data later
else
boldbasis = unfold.hrfbasis(3.408) # using default SPM parameters
#Dict(:duration=> EffectsCoding())
end

responsetype = Highpass(1/64; fs=1/3.408)
designmethod = FIRWindow(transitionwidth=0.11)
f = digitalfilter(responsetype, designmethod)



results_layer = DataFrame()
models_layer = []
for layer in 2:4
#layer = 1
    #m = unfold.fit(unfold.UnfoldLinearModel,formula,e,d[layer,:],boldbasis,eventfields=:onsetTR)
    #m = unfold.fit(unfold.UnfoldLinearModel,formula,e,d[layer,:],boldbasis,eventfields=[:onsetTR])
    m = unfold.fit(unfold.UnfoldLinearModel,formula,e,filtfilt(f,d[layer,:]),boldbasis,eventfields=[:onsetTR,:durationTR])

    m.results.layer = layer
    m.results.subject = e.subject[1]
    m.results.run = e.run[1]
    m.results.task = e.task[1]
    append!(models_layer,[m])
    append!(results_layer,m.results)
end
return results_layer,models_layer
end
