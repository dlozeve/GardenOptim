using Logging
using Random

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

"Fill the garden randomly with a predefined number for each plant."
function fillgardenrandomly!(garden::Matrix{Int}, mask::Matrix{Bool}, plants::DataFrame)
    cells = vcat([repeat([plant], count) for (plant, count) in eachrow(plants)]...)
    # fill the remaining slots with random plants
    diffcount = sum(mask) - length(cells)
    cells = vcat(cells, rand(cells, diffcount))
    garden[mask] = shuffle!(indexin(cells, plants.name))
    garden
end

"Update the garden for a given number of steps."
function gardenevolution!(garden::Matrix{Int}, mask::Matrix{Bool}, costs::Matrix{Float64}; steps::Int = 10000)
    for i = 1:steps
        update!(garden, mask, costs, 10.0)
    end
    garden
end
