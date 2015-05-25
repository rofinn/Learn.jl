Learn.jl
==========

[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/Rory-Finnegan/Learn.jl?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

Base framework library for machine learning packages. Attempting to consolidate MLBase.jl and MachineLearning.jl into one common package.


Installation
--------------
    Pkg.add("Learn")

installing latest development version:

    Pkg.clone("https://github.com/Rory-Finnegan/Learn.jl")


Concept Overview / Bikeshedding
------------

### Interfaces ###
I think the cleaner approach rather than an abstract type hierarchy which
doesn't entirely fit all the different types of learners and how they relate
to each other is to use something like Interfaces.jl or Traits.jl.

    """
    Requires Interfaces.jl
    """
    
    @interface Learner begin
        fit(model::Learner, data...)
        fit!(model::Learner, data...)
        transform(model::Learner, data...)
    end
    
    @interface Supervised begin
        fit(model::Supervised, data, labels)
        tranform(model::Supervised, data)
        tranform!(model::Supervised, data, output)
        predict(model::Supervised, data) [usually just an alias to transform for readability]
        predict!(model::Supervised, data, output)
    end

    @interface Unsupervised begin
        fit(model::Unsupervised, data)
        fit!(model::Unsupervised, data)
        tranform(model::Unsupervised, data)
        tranform!(model::Unsupervised, data, output)
    end
    
    """
    Could continue for even more specific interfaces,
    but I'm not sure that is necessary right away.
    Classifier
    Regressor
    Cluster
    """
    
    # Usage
    using Learn
    import MyLib: MyMethod
    
    mymethod = MyMethod()
    unsupervised = Unsupervised(mymethod)
    
    # If MyMethod supports the Unsupervised api, we return a wrapper and
    # proceed to use the unsupervised type in various common libraries. Otherwise
    # an exception will be thrown. 
    ...

This decouples the implementation like `MyMethod` from the Learn.jl API, since an implementation could be 
supported by Learn.jl without having to actively use it. Similarly, in order to get libraries 
to comply with our API we won't need to restructure any of their internal type hierarchy (if they have one),
instead most of the time we'll just need to add a method or an alias to an existing method.

### Implementations ###
I think it makes more sense for maintainability if most of the ML algorithm implementations are in their own repos and just use Learn.jl if they support the required methods. Down the road we could choose to register implementations
into a meta packages.


### Utilities ###
Pipelines:
    allow pipelining multiple models so long as all models are valid LearningModels with a transform method. SupervisedPipeline could be a special case that requires the output model to be a supervised model. [Update: this should be handled by Orchestra.jl]

Multiclass:
    Utility classifier for converting binary classifiers into multiclassifiers (supporting both one-to-one and one-to-rest methods)

Evaluation:
    A test harness framework consisting of set of common steps (ie: performance measures, test/train dataset initialization, etc) for evaluating a learning method.

HyperOpt (could maybe be its own repo):
    Hyperparameter optimization framework with maybe a few common implementations like gridsearch and bayesian optimization.

