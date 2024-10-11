using Test
using DataFrames
using Graphs
using SimpleGraphs
using SimpleWeightedGraphs
using Combinatorics

include("../src/category_builder.jl")
include("sample_data.jl")
using .CategoryBuilder
using .SampleDataLoader

# add_identityのテストセット
@testset "add_identity" begin
    # 潜在圏に恒等射を追加するテスト
    graph = SimpleWeightedDiGraph(5)
    graph = CategoryBuilder.add_identity(graph)
    # 辺が５つ追加されているかのテスト
    @test length(edges(graph)) == 5
    # 追加された辺のdomとcodが等しいかのテスト
    for edge in edges(graph)
        @test edge.src == edge.dst
    end
    # 重みを引数で指定しないとき1.0になっているか
    @test weights(graph)[1, 1] == 1
    # 重みを引数で指定したときその数値になっているか
    graph = SimpleWeightedDiGraph(5)
    graph = CategoryBuilder.add_identity(graph, 0.5)
    @test weights(graph)[1, 1] == 0.5

    # コスライス圏に恒等射を追加するテスト
    graph = SimpleDiGraph(5)
    add_edge!(graph, 1, 2)
    graph = CategoryBuilder.add_identity(graph)
    rem_edge!(graph, 1, 2)
    # 射のあった対象にのみ恒等射ができているかのテスト
    @test length(edges(graph)) == 2
    # 追加された辺のdomとcodが等しいかのテスト
    for edge in edges(graph)
        @test edge.src == edge.dst
    end
end

# get_source_triangleのテストセット
# @testset "get_source_triangle" begin
#     # 完全グラフの時のテスト
#     potential_category = SimpleWeightedDiGraph(3)
#     for (dom, cod) in permutations([i for i in 1:3], 2)
#         add_edge!(potential_category, dom, cod, 0.5)
#     end
#     data = [
#         1 0.5;
#         2 0.725;
#         3 0.275;
#     ]
#     source_init_images = DataFrame(data, [:to, :weight])
#     source_init_images.to = Int64.(source_init_images.to)

#     triangle = CategoryBuilder.get_source_triangle(source_init_images, potential_category)
#     @test triangle[1] == 1
#     @test triangle[2] == 2

#     # 辺がないグラフの時のテスト
#     potential_category = SimpleWeightedDiGraph(3)
#     triangle = CategoryBuilder.get_source_triangle(source_init_images, potential_category)

#     @test triangle[1] == 0
#     @test triangle[2] == 0
# end

# buidのテストセット
@testset "build" begin
    sample = SampleDataLoader.get_sample()

    edgelist = DataFrame(sample.edgelist, [:from, :to, :weight])
    edgelist.from = Int64.(edgelist.from)
    edgelist.to = Int64.(edgelist.to)

    CategoryBuilder.NN = sample.N

    # 潜在圏構築のテスト
    expected_graph = SimpleWeightedDiGraph(sample.adjmx)
    potential_category = CategoryBuilder.build(edgelist)
    @test potential_category == expected_graph

    # コスライス圏構築のテスト (構造無視)
    expected_graph = SimpleDiGraph(sample.source_adjmx)
    source = sample.source
    source_images = sample.images[sample.images[:,1] .== source, 2]
    source_category = CategoryBuilder.build(source, source_images)
    @test source_category == expected_graph

    expected_graph = SimpleDiGraph(sample.target_adjmx)
    target = sample.target
    target_images = sample.images[sample.images[:,1] .== target, 2]
    target_category = CategoryBuilder.build(target, target_images)
    @test target_category == expected_graph

    # # 喩辞のコスライス圏構築のテスト (構造考慮)
    # expected_graph = SimpleWeightedDiGraph(sample.source_triangle_adjmx)
    # source = sample.source
    # source_images = sample.images[sample.images[:, 1] .== source, 2]
    # source_init_images = edgelist[edgelist.:from .== source, :]
    # source_init_images = source_init_images[indexin(source_init_images.:to, source_images) .!== nothing, :]
    # source_triangle_images = CategoryBuilder.get_source_triangle(source_init_images, potential_category)
    # source_category = CategoryBuilder.build(source, source_triangle_images)
    # @test source_category == expected_graph

    # # 被喩辞のコスライス圏構築のテスト (構造考慮)
    # expected_graph = SimpleWeightedDiGraph(sample.target_triangle_adjmx)
    # target = sample.target
    # target_images = sample.images[sample.images[:,1] .== target, 2]
    # target_init_images = edgelist[edgelist.:from .== target, :]
    # target_init_images = target_init_images[indexin(target_init_images.:to, target_images) .!== nothing, :]
    # target_category = CategoryBuilder.build(target, target_init_images, potential_category)
    # @test target_category == expected_graph

end