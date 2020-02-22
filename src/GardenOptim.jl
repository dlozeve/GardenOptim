module GardenOptim

using Logging

using DocStringExtensions

export loadplants, loadgarden, loadclassification, loadcosts
export update!, randomgardenevolution!, outputgarden

@template (FUNCTIONS, METHODS, MACROS) =
    """
    $(TYPEDSIGNATURES)
    $(DOCSTRING)
    """

include("classification.jl")
include("loaddata.jl")
include("mcmc.jl")

"Save the garden to a CSV file."
function outputgarden(garden::Matrix{Int}, plants::Vector{String})
    output = vcat([""], plants)[garden .+ 1]
    CSV.write("output.csv", Tables.table(output), writeheader=false)
end

end # module
