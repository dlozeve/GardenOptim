using GardenOptim
using LinearAlgebra
using Test

@testset "optim" begin
    mask = zeros(Bool, 5, 7)
    mask[[1, 2, 6, 7]] .= 1
    @test GardenOptim.neighbourindices(mask, 1) == [6, 2]
    @test GardenOptim.neighbourindices(mask, 2) == [7, 1]
    @test GardenOptim.neighbourindices(mask, 3) == []
    neighbourcount = sum([length(GardenOptim.neighbourindices(mask, i)) for i = 1:length(mask)])
    @test sum(GardenOptim.neighbourmatrix(mask)) == neighbourcount
    @test issymmetric(GardenOptim.neighbourmatrix(mask))
end

