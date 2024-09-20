using Test
using Graphs
using SimpleWeightedGraphs

include("../src/category_builder.jl")
using .CategoryBuilder: add_identity

@testset "add_identity" begin
    graph = SimpleWeightedDiGraph(5)
    graph = add_identity(graph)

    # 辺が５つ追加されているかのテスト
    @test length(edges(graph)) == 5

    # 追加された辺のdomとcodが等しいかのテスト
    for edge in edges(graph)
        @test edge.src == edge.dst
    end
end