@doc doc"""
This file provides a mechanism for building data workflows for
machine learning and data analysis applications by building a list of
Transforms.

NOTE: we might be able to merge the arbiter wrapper API with the workflow stuff
more smoothly in the future, but for now I'd like to keep the two pretty separate till
PyCall gets fixed up a bit and the interactions are less ugly.
"""
using Logging
using Graphs
import Base.Transform

@doc doc"""
    Transforms are wrappers around arbitrary functions that
    manipulate data and are the fundamental components for building
    data workflows.

    Arg:
        name (Symbol): the name of the Transform
        func (Function): the function to run
        input (Array): array of input node names
        args (Tuple): the args to pass to func before the outp
        output (Any): stores the output of the function.
            including
            * a channel to write
            * a simple array
            * a distribution
            * etc
""" ->
type Transform
    name::Symbol
    func::Function
    input::Array{Symbol, 1}
    args::Tuple
    kwargs::Array{Any, 1}
    spawn::Bool
    output

    function Transform(name::Symbol, func::Function, args...; input=Array{Symbol, 1}(), spawn=false, kwargs...)
        new(name, func, input, args, kwargs, spawn, None)
    end
end


is_source(transform::Transform) = length(transform.input) == 0


@doc doc"""
    A Flow defines a data workflow and manages organizing and
    running a set of transforms.
""" ->
type Flow
    transforms::Array{Transform, 1}

    function Flow(transforms::Array{Transform, 1})
        names = []

        for t in transforms
            if t.name in names
                throw(ErrorException("More than 1 transform provided has the name $t.name"))
            end
        end
        new(transforms)
    end
end


@doc doc"""
    A closure that returns a wrapped function for a node
    that handles transfer of data to and from the node method
    function.

    NOTE: if we wanted to support parallelism we could just
    change execute to remotecall transform.func and update
    get_data to call fetch on the input transform output.
""" ->
function execute(transform::Transform, flow::Flow)
    Logging.debug("Running transform $(transform.name) ...")
    passed = false

    try
        data = []
        if !is_source(transform)
            data = get_data(flow, transform.input)
        end

        if transform.spawn
            transform.output = @spawn transform.func(data..., transform.args...; transform.kwargs...)
        else
            transform.output = transform.func(data..., transform.args...; transform.kwargs...)
        end

        passed = true
    catch exc
        #Try and log the error
        if isa(exc, ErrorException)
           Logging.err(exc.msg)
        else
           Logging.err(string(exc))
        end
        rethrow(exc)
    end
    return passed
end


@doc doc"""
    Converts the transforms to Transforms that arbiter can run
    and then calls run_transforms.
""" ->
function execute(flow::Flow)
    g = simple_graph(length(flow.transforms))
    tnames = Array{Symbol, 1}(length(flow.transforms))

    for i in 1:length(flow.transforms)
        tnames[i] = flow.transforms[i].name
    end

    for transform in flow.transforms
        for dep in transform.input
            name_idx = findin(tnames, [transform.name])[1]
            dep_idx = findin(tnames, [dep])[1]
            add_edge!(g, dep_idx, name_idx)
        end
    end

    ordered = topological_sort_by_dfs(g)
    Logging.debug("Transform names: $tnames")
    Logging.debug("Transform indices: $(collect(1:length(tnames)))")
    Logging.debug("Transform index order: $ordered")

    # iterate over the ordered transforms and
    # run the transform function with their args.
    for i in ordered
        execute(flow.transforms[i], flow)
    end
end


@doc doc"""
    Returns the transform with a name that matches the
    key or throws a KeyError.
 """ ->
function getindex(flow::Flow, key::Symbol)
    for n in flow.transforms
        if n.name == key
            return n
        end
    end
    throw(KeyError(key))
end


@doc doc"""
    Gets the output data from a given transform with the provided key.
""" ->
function get_data(flow::Flow, keys::Array{Symbol, 1})
    data = []

    for key in keys
        output = flow[key].output

        # If the output for the transform is a
        # remote ref then fetch it.
        if isa(output, RemoteRef)
            push!(data, fetch(output))
        else
            push!(data, output)
        end
    end

    return data
end

