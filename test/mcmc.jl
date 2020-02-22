using GardenOptim
using Test

@testset "randomindex" begin
    mask = rand(Bool, 5, 5)
    @test mask[GardenOptim.randomindex(mask)]
end
@testset "swap" begin
    grid = ones(Int, 5, 5)
    grid[2] = 5
    grid[8] = -3
    GardenOptim.swap!(grid, 2, 8)
    @test grid[2] == -3
    @test grid[8] == 5
    @test grid[6] == 1
end
@testset "neighbours" begin
    grid = ones(Int, 5, 5)
    @test length(GardenOptim.neighbours(grid, 4)) == 3
    @test length(GardenOptim.neighbours(grid, 5)) == 2
    @test length(GardenOptim.neighbours(grid, 8)) == 4
    @test length(GardenOptim.neighbours(grid, 25)) == 2
    @test GardenOptim.neighbours(grid, 1) == [1, 1]
    grid[3] = 0
    @test length(GardenOptim.neighbours(grid, 4)) == 2
end
@testset "deltacost" begin
    grid = ones(Int, 5, 5)
    costs = [[1. 0. 2.]; [0. 1. -1.]; [2. -1. 1.]]
    @test GardenOptim.deltacost(grid, costs, 3, 8) == 0
    grid[3] = 2
    grid[9] = 3
    @test GardenOptim.deltacost(grid, costs, 3, 8) != 0
end
