using Test

@testset "GardenOptim.jl" begin
    include("classification.jl")
    include("mcmc.jl")
    include("optim.jl")
end
