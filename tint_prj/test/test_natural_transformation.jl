using Test
using Random
using DataFrames

include("sample_data.jl")
include("../src/category_builder.jl")
include("../src/natural_transformation.jl")
include("../src/functor.jl")
using .SampleDataLoader
using .CategoryBuilder
using .NaturalTransformer
using .FunctorBuilder: Functor

# softmax関数のテスト
@testset "softmax" begin
    Random.seed!(1234) # (2, 3, 0.8) が選ばれるseed値
    candidates = Vector{Tuple}()
    push!(candidates, (2, 3, 0.8))
    push!(candidates, (2, 4, 0.5))
    push!(candidates, (2, 5, 0.2))

    result = NaturalTransformer.softmax(candidates)
    expected = (2, 3, 0.8)
    @test result == expected
end

# 自然変換の探索のテスト
@testset "search" begin
    sample = SampleDataLoader.get_sample()

    edgelist = DataFrame(sample.edgelist, [:from, :to, :weight])
    edgelist.from = Int64.(edgelist.from)
    edgelist.to = Int64.(edgelist.to)

    CategoryBuilder.NN = sample.N
    potential_category = CategoryBuilder.build(edgelist)

    # 構造無視
    A = sample.A
    A_images = sample.images[sample.images[:,1] .== A, 2]
    A_category = CategoryBuilder.build(A, A_images)
    B = sample.B
    B_images = sample.images[sample.images[:,1] .== B, 2]
    B_category = CategoryBuilder.build(B, B_images)

    Random.seed!(1234)
    fork_edges, target_remain_edges, source_remain_edges, BMF_objects, F_objects = NaturalTransformer.search(potential_category, A, B, A_category, B_category)

    expected_fork_edges = Set(Tuple([(7, 4), (6, 3), (8, 5)]))
    @test fork_edges == expected_fork_edges
    expected_target_remain_edges = Set(Tuple([(1, 3), (1, 4), (1, 5)]))
    @test target_remain_edges == expected_target_remain_edges
    expected_source_remain_edges = Set(Tuple([(2, 8), (2, 7), (2, 6)]))
    @test source_remain_edges == expected_source_remain_edges
    expected_BMF_objects = Dict(6 => 6, 7 => 7, 2 => 1, 8 => 8)
    @test BMF_objects == expected_BMF_objects
    expected_F_objects = Dict(6 => 3, 7 => 4, 2 => 1, 8 => 5)
    @test F_objects == expected_F_objects
end