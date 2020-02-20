module GardenOptim

using Logging
using CSV
using Tables

export loadplants, loadgarden, loadcosts, update!, randomgardenevolution!, outputgarden

function loadplants()::Vector{String}
    plants = readlines("data/plants.txt")
    @info "loaded $(length(plants)) plants"
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

function loadcosts()::Matrix{Float64}
    df = CSV.read("data/costs.csv")
    df = coalesce.(df, 0)  # replace missing values by 0
    costs = convert(Matrix, df[:, 2:end])
    @info "loaded cost matrix of size $(size(costs))"
    # ensure the matrix is symmetric: keep the max of itself and its transpose
    costs = Float64.(max.(costs, permutedims(costs)))
end

function randomindex(mask::Matrix{Bool})::Int
    while true
        i = rand(1:length(mask))
        if mask[i]
            return i
        end
    end
end

function swap!(garden::Matrix{Int}, i::Int, j::Int)
    t = garden[i]
    garden[i] = garden[j]
    garden[j] = t
    garden
end

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

function randomfillgarden!(garden::Matrix{Int}, mask::Matrix{Bool}, plantcount::Int)
    garden[mask] = rand(1:plantcount, sum(mask))
    garden
end

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

function outputgarden(garden::Matrix{Int}, plants::Vector{String})
    output = vcat([""], plants)[garden .+ 1]
    CSV.write("output.csv", Tables.table(output), writeheader=false)
end

end # module
