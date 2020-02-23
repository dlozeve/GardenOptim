using JuMP
using MosekTools

function neighbourindices(mask::Matrix, idx::Int)::Vector{Int}
    if mask[idx] == 0
        return []
    end

    m, n = size(mask)
    i, j = Tuple(CartesianIndices(mask)[idx])
    indices = [(i, j-1), (i, j+1), (i-1, j), (i+1, j)]
    # cells filled with 0 are not part of the garden
    cartesianindices = [
        CartesianIndex(k, l) for (k, l) in indices
        if 0 < k <= m && 0 < l <= n && mask[k, l] != 0
    ]
    # convert to linear indices
    LinearIndices(mask)[cartesianindices]
end

function neighbourmatrix(mask::Matrix)::Matrix{Bool}
    N = length(mask)
    d = zeros(N, N)
    for i in 1:N
        for j in neighbourindices(mask, i)
            d[i, j] = 1
        end
    end
    d
end

function definemodel(plantcounts::Vector, garden::Matrix, mask::Matrix, costs::Matrix)
    N = length(mask)
    Q = size(costs, 1)

    optimizer = Mosek.Optimizer
    model = Model(optimizer_with_attributes(optimizer, "QUIET" => false))

    @variable(model, x[1:N, 1:Q], Bin)

    @objective(
        model,
        Min,
        sum(
            costs[q, r] * x[i, q] * x[j, r]
            for i = 1:N, q = 1:Q, r = 1:Q for j = neighbourindices(mask, i)
        )
    )

    for i = 1:N
        @constraint(model, sum(x[i, q] for q = 1:Q) <= 1)
        if mask[i] == 0
            for q = 1:Q
                @constraint(model, x[i, q] == 0)
            end
        end
        if garden[i] != 0
            @constraint(model, x[i, garden[i]] == 1)
        end
    end

    for q = 1:Q
        @constraint(model, sum(x[i, q] for i = 1:N) >= plantcounts[q])
    end
    model
end
