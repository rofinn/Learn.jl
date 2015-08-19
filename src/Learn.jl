module Learn

VERSION < v"0.4-" && using Docile
using Compat

export Transform, Flow, execute

include("workflow.jl")

end
