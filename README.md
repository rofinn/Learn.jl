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

### Abstract Types ###
NOTE: would be interfaces or mixins if julialang support them.

    LearningModel:
    fit(model, data...)
    fit!(model, data...)
    transform(model, data...)


    SupervisedModel <: LearningModel
    fit(model, data, labels)
    tranform(model, data)
    tranform!(model, data, output)
    predict(model, data) [usually just an alias to transform for readability]
    predict!(model, data, output)


    UnsupervisedModel <: LearningModel
    fit(model, data)
    fit!(model, data)
    tranform(model, data)
    tranform!(model, data, output)


    Classifier <: SupervisedModel
    Regressor <: SupervisedModel
    Cluster <: Unsupervised


### Implementations ###
I think it makes more sense for maintainability if most of the ML algorithm implementations are in their own repos and just use Learn.jl if they support the required methods.


### Utilities ###
Pipelines:
    allow pipelining multiple models so long as all models are valid LearningModels with a transform method. SupervisedPipeline could be a special case that requires the output model to be a supervised model.

Multiclass:
    Utility classifier for converting binary classifiers into multiclassifiers (supporting both one-to-one and one-to-rest methods)

Evaluation:
    A test harness framework consisting of set of common steps (ie: performance measures, test/train dataset initialization, etc) for evaluating a learning method.

HyperOpt (could maybe be its own repo):
    Hyperparameter optimization framework with maybe a few common implementations like gridsearch and bayesian optimization.

