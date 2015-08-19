include("../src/Learn.jl")
using Learn

tests = [
    "workflow",
]


println("Running tests:")

for t in tests
    tfile = string(t, ".jl")
    println(" * $(tfile) ...")
    include(tfile)
end
