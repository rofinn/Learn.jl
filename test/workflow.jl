using Base.Test

data1(n) = rand(n)
data2(n) = 100 * rand(n)
fit1(x::Array{Float64, 1}, n) = sort(x)[1:n]
transform(model::Array{Float64, 1}, x::Array{Float64, 1}; C=1) = C * (model * x')

transforms = [
    Transform(:data1, data1, 100),
    Transform(:data2, data2, 10),
    Transform(:fit_data1, fit1, 10; input=[:data1]),
    Transform(:tranform, transform; input=[:fit_data1, :data2], C=8)
]

flow = Flow(transforms)
execute(flow)

@test size(flow.transforms[4].output) == (10,10)
