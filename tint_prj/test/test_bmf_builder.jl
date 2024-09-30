using Test
using DataFrames
using Graphs
using SimpleWeightedGraphs
using Combinatorics

include("../src/category_builder.jl")
include("../src/functor.jl")
include("../src/bmf_builder.jl")
include("sample_data.jl")
using .CategoryBuilder
using .FunctorBuilder: Functor
using .BMFBuilder
using .SampleDataLoader

# buildのテスト
@testset "build" begin
    sample = SampleDataLoader.get_sample()

    edgelist = DataFrame(sample.edgelist, [:from, :to, :weight])
    edgelist.from = Int64.(edgelist.from)
    edgelist.to = Int64.(edgelist.to)

    CategoryBuilder.NN = sample.N

    # BMF構築 (構造無視) のテスト
    source = sample.source
    source_images = sample.images[sample.images[:,1] .== source, 2]
    source_init_images = edgelist[edgelist.:from .== source, :]
    source_init_images = source_init_images[indexin(source_init_images.:to, source_images) .!== nothing, :]
    source_category = CategoryBuilder.build(source, source_init_images)

    target = sample.target
    target_images = sample.images[sample.images[:,1] .== target, 2]
    target_init_images = edgelist[edgelist.:from .== target, :]
    target_init_images = target_init_images[indexin(target_init_images.:to, target_images) .!== nothing, :]
    target_category = CategoryBuilder.build(target, target_init_images)

    objects = Dict{Int, Int}()
    objects[source] = target
    morphisms = Dict{Tuple, Tuple}()
    for i in 1:sample.N
        morphisms[(source, i)] = (target, i)
    end
    expected_BMF = Functor(objects, morphisms)
    _target_category, BMF = BMFBuilder.build(source, target, source_category, target_category)
    # 対象の関手のテスト
    @test BMF.objects == expected_BMF.objects
    # 射の関手のテスト
    @test BMF.morphisms == expected_BMF.morphisms

    # BMF構築 (構造考慮) のテスト
    potential_category = CategoryBuilder.build(edgelist)

    source = sample.source
    source_images = sample.images[sample.images[:, 1] .== source, 2]
    source_init_images = edgelist[edgelist.:from .== source, :]
    source_init_images = source_init_images[indexin(source_init_images.:to, source_images) .!== nothing, :]
    source_triangle_images = CategoryBuilder.get_source_triangle(source_init_images, potential_category)
    source_category = CategoryBuilder.build(source, source_triangle_images, potential_category)

    target = sample.target
    target_images = sample.images[sample.images[:,1] .== target, 2]
    target_init_images = edgelist[edgelist.:from .== target, :]
    target_init_images = target_init_images[indexin(target_init_images.:to, target_images) .!== nothing, :]
    target_category = CategoryBuilder.build(target, target_init_images, potential_category)

    objects = Dict{Int, Int}()
    objects[source] = target
    morphisms = Dict{Tuple, Tuple}()
    morphisms[(1, 3)] = (2, 3)
    morphisms[(3, 4)] = (3, 4)
    morphisms[(1, 4)] = (2, 4)
    expected_BMF = Functor(objects, morphisms)

    _target_category, BMF = BMFBuilder.build(source, target, source_triangle_images, target_category)
    # 対象の関手のテスト
    @test BMF.objects == expected_BMF.objects
    # 射の関手のテスト
    @test BMF.morphisms == expected_BMF.morphisms

end