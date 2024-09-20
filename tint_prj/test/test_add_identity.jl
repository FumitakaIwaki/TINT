using Test
using DataFrames
using Graphs
using SimpleWeightedGraphs
using Combinatorics

include("../src/category_builder.jl")
using .CategoryBuilder: build, add_identity, get_source_triangle

# add_identity関数のテストセット
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

# get_source_triangleのテストセット
@testset "get_source_triangle" begin
    # 完全グラフの時のテスト
    potential_category = SimpleWeightedDiGraph(3)
    for (dom, cod) in permutations([i for i in 1:3], 2)
        add_edge!(potential_category, dom, cod, 0.5)
    end
    data = [
        1 0.5;
        2 0.725;
        3 0.275;
    ]
    source_init_images = DataFrame(data, [:to, :weight])
    source_init_images.to = Int64.(source_init_images.to)

    triangle = get_source_triangle(source_init_images, potential_category)
    @test triangle[1] == 1
    @test triangle[2] == 2

    # 辺がないグラフの時のテスト
    potential_category = SimpleWeightedDiGraph(3)
    triangle = get_source_triangle(source_init_images, potential_category)

    @test triangle[1] == 0
    @test triangle[2] == 0
end