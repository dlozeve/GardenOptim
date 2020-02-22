using Logging
using Unicode

using DataFrames
using CSV
using JSON

function loadplants()::DataFrame
    plants = CSV.read("data/plants.csv")
    @info "loaded $(size(plants, 1)) plants"
    plants.name = Symbol.(plants.name)
    plants
end

function loadgarden(plants::Vector{Symbol})::Tuple{Matrix{Int}, Matrix{Bool}}
    garden = CSV.read("data/garden.csv")
    garden = coalesce.(garden, "")
    mask = convert(Matrix, garden .== "empty")
    garden = Unicode.normalize.(garden, casefold=true, stripmark=true)
    garden = indexin(convert(Matrix, garden), String.(plants))
    garden = replace(garden, nothing=>0)
    @assert size(garden) == size(mask)
    @info "loaded garden of size $(size(garden))"
    garden, mask
end

function loadclassification()::Classification
    clf = JSON.parsefile("data/classification.json")
    clf = Classification(clf)
    @debug "loaded classification of type $(clf.type)"
    clf
end

function loadcostsdf()::DataFrame
    df = CSV.read("data/associations.csv", copycols=true)
    colnames = String.(names(df))
    colnames = Symbol.(Unicode.normalize.(colnames, casefold=true, stripmark=true))
    rename!(df, colnames)
    df.name = colnames[2:end]
    # df = coalesce.(df, 0.0)
    @info "loaded cost matrix for $(size(df, 1)) plants"
    df
end

function computecost(plant1::Symbol, plant2::Symbol, costs_df::DataFrame, classification::Classification)::Float64
    @debug "computecost($plant1, $plant2)"
    if plant1 in names(costs_df) && plant2 in names(costs_df)
        cost = costs_df[costs_df.name .== plant1, plant2][1]
    else
        cost = missing
    end

    if !ismissing(cost)
        return cost
    end

    parent1 = getfirstparent(plant1, classification)
    parent2 = getfirstparent(plant2, classification)
    if isnothing(parent1) || isnothing(parent2)
        return 0.0
    end
    @debug "computecost($(parent1.name), $(parent2.name))"
    if parent1.name in names(costs_df) && parent2.name in names(costs_df)
        cost = costs_df[costs_df.name .== parent1.name, parent2.name][1]
    end

    if !ismissing(cost)
        return cost
    end

    return 0.0
end

function costsmatrix(plants::Vector{Symbol}, costs_df::DataFrame, classification::Classification)::Matrix{Float64}
    [computecost(plant1, plant2, costs_df, classification) for plant1 in plants, plant2 in plants]
end

function loadcosts()
    plants = loadplants()
    clf = loadclassification()
    costs_df = loadcostsdf()
    costs = costsmatrix(plants.name, costs_df, clf)
end
