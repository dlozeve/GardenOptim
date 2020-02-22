using GardenOptim
using Test

@testset "classification" begin
    clf = GardenOptim.Classification(
        Dict(
            "type"=>"Life",
            "name"=>"God",
            "children"=>[
                Dict(
                    "type"=>"Family",
                    "name"=>"Homo",
                    "children"=>[
                        Dict(
                            "type"=>"Species",
                            "name"=>"Human",
                            "bio"=>"Homo sapiens",
                            "children"=>[]
                        )
                    ]
                )
            ]
        )
    )
    @testset "constructor" begin
        @test_throws UndefRefError clf.parent
        @test clf.children[1].parent === clf
        @test length(clf.children) == 1
        @test clf.children[1].type == :family
        @test clf.children[1].children[1].bio == "Homo sapiens"
        @test clf.children[1].children[1].name == :human
        @test clf.children[1].children[1].children == []
    end
    @testset "getfirstparent" begin
        @test GardenOptim.getfirstparent(:human, clf) === clf.children[1]
        @test GardenOptim.getfirstparent(:homo, clf) === clf.children[1]
        @test_throws UndefRefError GardenOptim.getfirstparent(:god, clf)
    end
end
