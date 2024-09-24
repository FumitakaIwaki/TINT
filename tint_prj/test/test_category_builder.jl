using Test
using DataFrames
using Graphs
using SimpleWeightedGraphs
using Combinatorics

include("../src/category_builder.jl")
using .CategoryBuilder

# add_identityのテストセット
@testset "add_identity" begin
    graph = SimpleWeightedDiGraph(5)
    graph = CategoryBuilder.add_identity(graph)

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

    triangle = CategoryBuilder.get_source_triangle(source_init_images, potential_category)
    @test triangle[1] == 1
    @test triangle[2] == 2

    # 辺がないグラフの時のテスト
    potential_category = SimpleWeightedDiGraph(3)
    triangle = CategoryBuilder.get_source_triangle(source_init_images, potential_category)

    @test triangle[1] == 0
    @test triangle[2] == 0
end

# buidのテストセット
@testset "build" begin
    # サンプル辺リスト
    data = [
        1 3 0.8;
        1 4 0.5;
        1 5 0.2;
        2 6 0.8;
        2 7 0.5;
        2 8 0.2;
        4 3 0.3;
        4 5 0.3;
        7 6 0.3;
        7 8 0.3;
    ]
    # data = [
    #     3 1 0.8;
    #     4 1 0.5;
    #     5 1 0.2;
    #     6 2 0.8;
    #     7 2 0.5;
    #     8 2 0.2;
    #     3 4 0.3;
    #     5 4 0.3;
    #     6 7 0.3;
    #     8 7 0.3;
    # ]
    edgelist = DataFrame(data, [:from, :to, :weight])
    edgelist.from = Int64.(edgelist.from)
    edgelist.to = Int64.(edgelist.to)

    CategoryBuilder.NN = 8

    # 潜在圏構築のテスト
    adjmx = [
        0.5 0.0 0.8 0.5 0.2 0.0 0.0 0.0;
        0.0 0.5 0.0 0.0 0.0 0.8 0.5 0.2;
        0.0 0.0 0.5 0.0 0.0 0.0 0.0 0.0;
        0.0 0.0 0.3 0.5 0.3 0.0 0.0 0.0;
        0.0 0.0 0.0 0.0 0.5 0.0 0.0 0.0;
        0.0 0.0 0.0 0.0 0.0 0.5 0.0 0.0;
        0.0 0.0 0.0 0.0 0.0 0.3 0.5 0.3;
        0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.5;
    ]
    expected_graph = SimpleWeightedDiGraph(adjmx)
    potential_category = CategoryBuilder.build(edgelist)
    @test potential_category == expected_graph

    # コスライス圏構築のテスト (構造無視)
    adjmx = [
        0.5 0.0 0.8 0.5 0.2 0.0 0.0 0.0;
        0.0 0.5 0.0 0.0 0.0 0.0 0.0 0.0;
        0.0 0.0 0.5 0.0 0.0 0.0 0.0 0.0;
        0.0 0.0 0.0 0.5 0.0 0.0 0.0 0.0;
        0.0 0.0 0.0 0.0 0.5 0.0 0.0 0.0;
        0.0 0.0 0.0 0.0 0.0 0.5 0.0 0.0;
        0.0 0.0 0.0 0.0 0.0 0.0 0.5 0.0;
        0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.5;
    ]
    expected_graph = SimpleWeightedDiGraph(adjmx)
    source = 1
    source_init_images = edgelist[edgelist.:from .== source, ["to", "weight"]]
    source_category = CategoryBuilder.build(source, source_init_images)
    @test source_category == expected_graph

    adjmx = [
        0.5 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
        0.0 0.5 0.0 0.0 0.0 0.8 0.5 0.2;
        0.0 0.0 0.5 0.0 0.0 0.0 0.0 0.0;
        0.0 0.0 0.0 0.5 0.0 0.0 0.0 0.0;
        0.0 0.0 0.0 0.0 0.5 0.0 0.0 0.0;
        0.0 0.0 0.0 0.0 0.0 0.5 0.0 0.0;
        0.0 0.0 0.0 0.0 0.0 0.0 0.5 0.0;
        0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.5;
    ]
    expected_graph = SimpleWeightedDiGraph(adjmx)
    target = 2
    target_init_images = edgelist[edgelist.:from .== target, ["to", "weight"]]
    target_category = CategoryBuilder.build(target, target_init_images)
    @test target_category == expected_graph

    # 喩辞のコスライス圏構築のテスト (構造考慮)
    adjmx = [
        0.5 0.0 0.8 0.5 0.0 0.0 0.0 0.0;
        0.0 0.5 0.0 0.0 0.0 0.0 0.0 0.0;
        0.0 0.0 0.5 0.0 0.0 0.0 0.0 0.0;
        0.0 0.0 0.3 0.5 0.0 0.0 0.0 0.0;
        0.0 0.0 0.0 0.0 0.5 0.0 0.0 0.0;
        0.0 0.0 0.0 0.0 0.0 0.5 0.0 0.0;
        0.0 0.0 0.0 0.0 0.0 0.0 0.5 0.0;
        0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.5;
    ]
    expected_graph = SimpleWeightedDiGraph(adjmx)
    source = 1
    source_init_images = edgelist[edgelist.:from .== source, ["to", "weight"]]
    source_triangle_images = CategoryBuilder.get_source_triangle(source_init_images, potential_category)
    source_category = CategoryBuilder.build(source, source_triangle_images, potential_category)
    @test source_category == expected_graph

    # 被喩辞のコスライス圏構築のテスト (構造考慮)
    adjmx = [
        0.5 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
        0.0 0.5 0.0 0.0 0.0 0.8 0.5 0.2;
        0.0 0.0 0.5 0.0 0.0 0.0 0.0 0.0;
        0.0 0.0 0.0 0.5 0.0 0.0 0.0 0.0;
        0.0 0.0 0.0 0.0 0.5 0.0 0.0 0.0;
        0.0 0.0 0.0 0.0 0.0 0.5 0.0 0.0;
        0.0 0.0 0.0 0.0 0.0 0.3 0.5 0.3;
        0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.5;
    ]
    expected_graph = SimpleWeightedDiGraph(adjmx)
    target = 2
    target_init_images = edgelist[edgelist.:from .== target, ["to", "weight"]]
    target_category = CategoryBuilder.build(target, target_init_images, potential_category)
    @test target_category == expected_graph

end