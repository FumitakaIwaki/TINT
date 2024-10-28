module TINT

include("dataloader.jl")
include("category_builder.jl")
include("functor.jl")
include("bmf_builder.jl")
include("natural_transformation.jl")

using .DataLoader
using .CategoryBuilder
using .FunctorBuilder
using .BMFBuilder
using .NaturalTransformer

using DataFrames
using Graphs
using SimpleWeightedGraphs
using SimpleGraphs

# 総イメージ数
NN::Int = 0
# シミュレーションのタイプ ("object", "triangle")
mode::String = "object"


# シミュレーション実行関数（構造無視）
function simulate(potential_category::SimpleWeightedDiGraph,
    A::Int, B::Int, A_category::SimpleDiGraph, B_category::SimpleDiGraph
    )::Tuple
    is_BMF_functor = false
    is_F_functor = false
    # 探索された関手
    F = Dict()
    # 獲得された比喩
    metaphor = Dict()

    # A_categoryとB_categoryの対応付を探索
    fork_edges, A_remain_edges, B_remain_edges, BMF_objects, F_objects = NaturalTransformer.search(potential_category, A, B, A_category, B_category)

    # 対応を取るときはAがBにfでつながった形にしなければいけない
    # それでは元に戻せないので現状の圏を保管しておく
    tmp_B_category = copy(B_category)
    tmp_fork_edges = copy(fork_edges)
    tmp_A_remain_edges = copy(A_remain_edges)
    tmp_B_remain_edges = copy(B_remain_edges)

    # anti-fork ruleで対応がつかなかった部分を削除
    A_category, B_category = NaturalTransformer.full_anti_fork_rule(A_category, B_category, A, fork_edges, A_remain_edges, B_remain_edges)
    # 全てのノードが無くなった場合は飛ばす
    if nv(A_category) == 0 || nv(B_category) == 0
        println("All nodes were removed in anti-fork rules.")
        return metaphor, F
    end

    # BMFが関手かどうか
    is_BMF_correspondence, BMF_edges = NaturalTransformer.edge_correspondence(B_category, A_category, BMF_objects)
    if is_BMF_correspondence
        is_BMF_functor = NaturalTransformer.is_functor(B_category, BMF_objects, BMF_edges)
    end
    # Fが関手かどうか
    is_F_correspondence, F_edges = NaturalTransformer.edge_correspondence(B_category, A_category, F_objects)
    if is_F_correspondence
        is_F_functor = NaturalTransformer.is_functor(B_category, F_objects, F_edges)
    end
    # どちらも関手でなかった場合
    if !is_BMF_functor || !is_F_functor
        println("The morphisms weren't functors.")
        return metaphor, F
    end

    # 自然変換をなしているかどうか
    metaphor = NaturalTransformer.is_natural_transformation(B_category, A_category, BMF_objects, BMF_edges, F_objects, F_edges)
    if isnothing(metaphor)
        println("The functors didn't construct a natural transformation.")
        return metaphor, F
    end

    F = F_edges
    return metaphor, F
end

# function simulate(source::Int, target::Int,
#     source_init_images::DataFrame, target_init_images::DataFrame, potential_category::SimpleWeightedDiGraph
#     )::NaturalTransformer.FunctorBuilder.Functor

#     source_category = CategoryBuilder.build(source, source_init_images)
#     target_category = CategoryBuilder.build(target, target_init_images)
#     _target_category, BMF = BMFBuilder.build(source, target, source_category, target_category)
#     F = NaturalTransformer.search(source, target, source_category, target_category, potential_category)

#     return F
# end

# シミュレーション実行関数（構造考慮）
# function simulate(source::Int, target::Int,
#     source_triangle_images::Vector{Int}, target_init_images::DataFrame, potential_category::SimpleWeightedDiGraph,
#     )::NaturalTransformer.FunctorBuilder.Functor

#     source_category = CategoryBuilder.build(source, source_triangle_images, potential_category)
#     target_category = CategoryBuilder.build(target, target_init_images, potential_category)
#     _target_category, BMF = BMFBuilder.build(source, target, source_triangle_images, target_category)
#     F = NaturalTransformer.search(source, target, source_category, target_category, potential_category, source_triangle_images)

#     return F
# end


function main(;file::String="tint_prj/data/three_metaphor_assoc_data.csv", outdir::String="tint_prj/out")
    df = DataLoader.load_assoc_data(file)

    # indexとstrの辞書
    idx2img = unique(vcat((df[:, ["from", "to"]] |> Array)...))
    img2idx = Dict((idx2img[i], i) for i in eachindex(idx2img))

    # 総イメージ数の設定
    TINT.NN = length(idx2img)
    CategoryBuilder.NN = length(idx2img)

    A = img2idx["蝶"] # 被喩辞
    B = img2idx["踊り子"] # 喩辞

    # strをindexに変換したdf
    encoded_df = copy(df[:, ["weight"]])
    encoded_df = hcat(get.(Ref(img2idx), df[:, ["from", "to"]], missing), encoded_df)

    # 被喩辞の初期イメージ
    A_init_images = encoded_df[encoded_df.:from .== A, ["to", "weight"]]
    # 瑜辞の初期イメージ
    B_init_images = encoded_df[encoded_df.:from .== B, ["to", "weight"]]

    # 潜在圏
    potential_category = CategoryBuilder.build(encoded_df[:, ["from", "to", "weight"]])
    potential_category = CategoryBuilder.add_identity(potential_category)

    if TINT.mode == "object"
        F = simulate(source, B, A_init_images, B_init_images, potential_category)
        return F
    elseif TINT.mode == "triangle"
        # 喩辞の三角構造を一つ取得
        A_triangle_images = CategoryBuilder.get_source_triangle(A_init_images, potential_category)
        F = simulate(A, B, A_triangle_images, B_init_images, potential_category)
        return F
    else
        return "ERROR: Invalid mode selection!!"
    end

    return F
end

end # module TINT
