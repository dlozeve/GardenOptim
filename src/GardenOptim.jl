module GardenOptim

using Logging

using DocStringExtensions
using Tables

export loadplants, loadgarden, loadclassification, loadcosts
export update!, fillgardenrandomly!, gardenevolution!, outputgarden

@template (FUNCTIONS, METHODS, MACROS) =
    """
    $(TYPEDSIGNATURES)
    $(DOCSTRING)
    """

include("classification.jl")
include("loaddata.jl")
include("mcmc.jl")
include("optim.jl")

"Save the garden to a CSV file."
function outputgarden(garden::Matrix{Int}, plants::Vector{Symbol})
    output = vcat([""], String.(plants))[garden .+ 1]
    CSV.write("out/output.csv", Tables.table(output), writeheader=false)
end

end # module
