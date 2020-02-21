module GardenOptim

using Logging
using Unicode

using DataFrames
using DocStringExtensions
using CSV
using JSON
using Tables

export loadclassification, loadplants, loadgarden, loadcosts
export update!, randomgardenevolution!, outputgarden

@template (FUNCTIONS, METHODS, MACROS) =
    """
    $(TYPEDSIGNATURES)
    $(DOCSTRING)
    """

mutable struct Classification
    type::Symbol
    name::Symbol
    bio::String
    children::Vector{Classification}
    parent::Classification

    function Classification(classif::Dict{String, Any})
        children = [Classification(d) for d in get(classif, "children", [])]
        type = Symbol(Unicode.normalize(classif["type"], casefold=true, stripmark=true))
        name = Symbol(Unicode.normalize(classif["name"], casefold=true, stripmark=true))
        classif = new(type, name, get(classif, "bio", ""), children)
        for child in children
            child.parent = classif
        end
        classif
    end
end

function loadclassification()
    clf = JSON.parsefile("data/classification.json")
    clf = Classification(clf)
    @debug "loaded classification of type $(clf.type)"
    clf
end

function loadplants()::DataFrame
    plants = CSV.read("data/plants.csv")
    @info "loaded $(size(plants, 1)) plants"
    plants.name = Symbol.(plants.name)
    plants
end

function loadgarden(plants::Vector{String})::Tuple{Matrix{Int}, Matrix{Bool}}
    garden = CSV.read("data/garden.csv")
    garden = coalesce.(garden, "")
    mask = convert(Matrix, garden .== "empty")
    garden = indexin(convert(Matrix, garden), plants)
    garden = replace(garden, nothing=>0)
    @assert size(garden) == size(mask)
    @info "loaded garden of size $(size(garden))"
    garden, mask
end

function loadcosts()::DataFrame
    df = CSV.read("data/associations.csv", copycols=true)
    colnames = String.(names(df))
    colnames = Symbol.(Unicode.normalize.(colnames, casefold=true, stripmark=true))
    rename!(df, colnames)
    df.name = colnames[2:end]
    # df = coalesce.(df, 0.0)
    @info "loaded cost matrix for $(size(df, 1)) plants"
    df
end

# function loadcosts()::Matrix{Float64}
#     df = CSV.read("data/costs.csv")
#     df = coalesce.(df, 0)  # replace missing values by 0
#     costs = convert(Matrix, df[:, 2:end])
#     @info "loaded cost matrix of size $(size(costs))"
#     # ensure the matrix is symmetric: keep the max of itself and its transpose
#     costs = Float64.(max.(costs, permutedims(costs)))
# end

function getparent(name::Symbol, classification::Classification)
    if classification.name == name
        return classification.parent
    else
        for child in classification.children
            parent = getparent(name, child)
            if !isnothing(parent)
                return parent
            end
        end
    end
end

function computecost(costs::DataFrame, plant1::Symbol, plant2::Symbol, classification::Classification)::Float64
    @debug "$plant1 and $plant2"
    if plant1 in names(costs) && plant2 in names(costs)
        cost = costs[costs.name .== plant1, plant2][1]
    else
        @debug "$plant1 and $plant2 not in costs"
        cost = missing
    end

    if !ismissing(cost)
        return cost
    end

    @debug "missing"
    try
        parent1 = getparent(plant1, classification).name
        computecost(costs, parent1, plant2, classification)
    catch UndefRefError
        return missing
    end

    try
        parent2 = getparent(plant2, classification).name
        computecost(costs, plant1, parent2, classification)
    catch UndefRefError
        return missing
    end

end

"Return a random index to be filled from the garden mask."
function randomindex(mask::Matrix{Bool})::Int
    while true
        i = rand(1:length(mask))
        if mask[i]
            return i
        end
    end
end

"Swap to the elements corresponding to the two provided indices."
function swap!(garden::Matrix{Int}, i::Int, j::Int)
    t = garden[i]
    garden[i] = garden[j]
    garden[j] = t
    garden
end

"Return the neighbours to be filled of the cell at the given index."
function neighbours(garden::Matrix{Int}, idx::Int)::Vector{Int}
    m, n = size(garden)
    j, i = divrem(idx - 1, m)
    i += 1
    j += 1
    neighbourindices = [(i, j-1), (i, j+1), (i-1, j), (i+1, j)]
    # cells filled with 0 are not part of the garden
    [
        garden[k, l] for (k, l) in neighbourindices
        if 0 < k <= m && 0 < l <= n && garden[k, l] != 0
    ]
end

"Compute the cost difference when swapping the two provided indices."
function deltacost(garden::Matrix{Int}, costs::Matrix{Float64}, i::Int, j::Int)::Float64
    cost = 0
    for k in neighbours(garden, i)
        cost += costs[k, garden[j]] - costs[k, garden[i]]
    end
    for k in neighbours(garden, j)
        cost += costs[k, garden[i]] - costs[k, garden[j]]
    end
    cost
end

"Update the garden using Metropolis-Hastings, using the inverse temperature beta."
function update!(
    garden::Matrix{Int},
    mask::Matrix{Bool},
    costs::Matrix{Float64},
    beta::Float64 = 10.0
)
    N = length(garden)
    i = randomindex(mask)
    j = randomindex(mask)
    while i == j
        j = randomindex(mask)
    end
    d = deltacost(garden, costs, i, j)
    @debug "cost difference $d"
    if rand() < exp(- beta * d)
        @debug "swapping indices $i and $j"
        return swap!(garden, i, j)
    end
    garden
end

"Fill the garden randomly with a predefined number of plants."
function randomfillgarden!(garden::Matrix{Int}, mask::Matrix{Bool}, plantcount::Int)
    garden[mask] = rand(1:plantcount, sum(mask))
    garden
end

"Update the garden for a given number of steps, starting from a random initialisation."
function randomgardenevolution!(
    garden::Matrix{Int},
    mask::Matrix{Bool},
    costs::Matrix{Float64};
    steps::Int = 10000
)
    m = size(costs, 1)
    garden = randomfillgarden!(garden, mask, m)
    for i = 1:steps
        update!(garden, mask, costs, 10.0)
    end
    garden
end

"Save the garden to a CSV file."
function outputgarden(garden::Matrix{Int}, plants::Vector{String})
    output = vcat([""], plants)[garden .+ 1]
    CSV.write("output.csv", Tables.table(output), writeheader=false)
end

end # module
