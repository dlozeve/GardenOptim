module GardenOptim

using CSV
using Logging

export update!

function swap!(grid::Array{Int, 2}, i::Int, j::Int)
    t = grid[i]
    grid[i] = grid[j]
    grid[j] = t
    grid
end

function neighbours(grid::Array{Int, 2}, idx)
    m = size(grid, 1)
    j, i = divrem(idx - 1, m)
    i += 1
    j += 1
    neighbourindices = [(i, j-1), (i, j+1), (i-1, j), (i+1, j)]
    [grid[k, l] for (k, l) in neighbourindices if 0 < k <= m && 0 < l <= m]
end

function deltacost(grid::Array{Int, 2}, costs::Array{Float64, 2}, i::Int, j::Int)
    cost = 0
    for k in neighbours(grid, i)
        cost += costs[k, grid[j]] - costs[k, grid[i]]
    end
    for k in neighbours(grid, j)
        cost += costs[k, grid[i]] - costs[k, grid[j]]
    end
    cost
end

function update!(grid::Array{Int, 2}, costs::Array{Float64, 2}, beta::Float64 = 10.0)
    N = length(grid)
    i, j = 0, 0
    while i == j
        i, j = rand(1:N, 2)
    end
    d = deltacost(grid, costs, i, j)
    @debug "cost difference $d"
    if rand() < exp(- beta * d)
        @debug "swapping indices $i and $j"
        return swap!(grid, i, j)
    end
    grid
end

function loadcosts()
    df = CSV.read("data/costs.csv")
    df = coalesce.(df, 0)  # replace missing values by 0
    costs = convert(Matrix, df[:, 2:end])
    @debug "cost matrix of size $(size(costs))"
    # ensure the matrix is symmetric: keep the max of itself and its transpose
    costs = max.(costs, permutedims(costs))
end

end # module
