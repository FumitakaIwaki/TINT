module TINT

include("./dataloader.jl")
include("./category_builder.jl")
include("./natural_transformation.jl")

using .DataLoader
using .CategoryBuilder
using .NaturalTransformer

using Random
using DataFrames
using Graphs
using SimpleWeightedGraphs
using SimpleGraphs
using Combinatorics: permutations

# シミュレーションのタイプ
# "object": 構造無視
# "triangle": 構造考慮
mode::String = "object"
# シード値
seed::Int = 1234

# 得られた関手を可視化する関数
function view_functor(idx2img::Vector, F::Dict)
    for (dom, cod) in F
        if dom[1] != dom[2]
            println(idx2img[dom[1]], " -> ", idx2img[dom[2]], " \t=> ", idx2img[cod[1]], " -> ", idx2img[cod[2]])
        end
    end
end

# シミュレーション実行関数
function simulate(potential_category::SimpleWeightedDiGraph,
    A::Int, B::Int, A_category::SimpleDiGraph, B_category::SimpleDiGraph,
    triangle::Val
    )::Tuple
    is_BMF_functor = false
    is_F_functor = false
    # 探索された関手
    F = Dict()
    # 獲得された比喩
    metaphor = Dict()

    # A_categoryとB_categoryの対応付を探索
    fork_edges, A_remain_edges, B_remain_edges, BMF_objects, F_objects = NaturalTransformer.search(potential_category, A, B, A_category, B_category, triangle)

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

# 構造無視の実行関数
function run(potential_category::SimpleWeightedDiGraph,
    A::Int, B::Int, A_images::Vector{Int}, B_images::Vector{Int},
    triangle::Val{false})::Dict{Tuple, Tuple}
    # 被喩辞のコスライス圏
    A_category = CategoryBuilder.build(A, A_images)
    # 喩辞のコスライス圏
    B_category = CategoryBuilder.build(B, B_images)
    # シミュレーション
    metaphor, F = simulate(potential_category, A, B, A_category, B_category, triangle)

    return F
end

# 構造考慮の実行関数
function run(potential_category::SimpleWeightedDiGraph,
    A::Int, B::Int, A_images::Vector{Int}, B_images::Vector{Int},
    triangle::Val{true})::Dict{Tuple, Tuple}
    F = Dict{Tuple, Tuple}()
    # 被喩辞のコスライス圏
    A_category = CategoryBuilder.build(A, A_images, triangle=true)
    for (B_dom, B_cod) in permutations(B_images, 2)
        if B == B_dom || B == B_cod || B_dom == B_cod
            continue
        end
        # 喩辞のコスライス圏
        B_category = CategoryBuilder.build(B, B_dom, B_cod)
        # シミュレーション
        metaphor, _F = simulate(potential_category, A, B, A_category, B_category, triangle)
        merge!(F, _F)
    end
    return F
end

# main関数
function main(;metaphor_set::Set = Set([("蝶", "踊り子")]),
    assoc_file::String = "tint_prj/data/three_metaphor_assoc_data.csv",
    image_file::String = "tint_prj/data/three_metaphor_images.csv",
    outdir::String = "tint_prj/out",
    verbose::Bool = true
    )
    Random.seed!(TINT.seed) # シード値の設定
    # モードの選択
    if TINT.mode == "object"
        triangle = Val(false)
    elseif TINT.mode == "triangle"
        triangle = Val(true)
    else
        throw(DomainError(TINT.mode, "Invalid mode selected!! Selecting from 'object' or 'triangle'."))
        return
    end
    # データの読み込み
    assoc_df = DataLoader.load_assoc_data(assoc_file)
    image_df = DataLoader.load_images(image_file)

    # indexとstrの辞書
    idx2img = unique(vcat((image_df[:, ["source", "target"]] |> Array)...))
    img2idx = Dict((idx2img[i], i) for i in eachindex(idx2img))

    # 総イメージ数の設定
    CategoryBuilder.NN = length(idx2img)

    # strをindexに変換したdf
    encoded_assoc_df = get.(Ref(img2idx), assoc_df[:, ["from", "to", "weight"]], assoc_df[:, "weight"])
    encoded_image_df = get.(Ref(img2idx), image_df[:, ["source", "target"]], missing)

    for (topic, vehicle) in metaphor_set
        if verbose
            println("\n", repeat("-", 30))
            println(topic, " -> ", vehicle)
            println(repeat("-", 30))
        end
        # 潜在圏
        potential_category = CategoryBuilder.build(encoded_assoc_df)
        # 被喩辞
        A = img2idx[topic]
        # 被喩辞の初期イメージ
        A_images = encoded_image_df[encoded_image_df.:source .== A, :target]
        # 喩辞
        B = img2idx[vehicle]
        # 喩辞の初期イメージ
        B_images = encoded_image_df[encoded_image_df.:source .== B, :target]

        # TINTの実行
        F = run(potential_category, A, B, A_images, B_images, triangle)
        if verbose
            view_functor(idx2img, F)
        end

        # TINTの実行
        # if TINT.mode == "object" # 構造無視
        #     # 被喩辞のコスライス圏
        #     A_category = CategoryBuilder.build(A, A_images)
        #     # 喩辞のコスライス圏
        #     B_category = CategoryBuilder.build(B, B_images)
        #     # シミュレーション
        #     metaphor, F = simulate(potential_category, A, B, A_category, B_category, triangle)
        #     if verbose
        #         view_functor(idx2img, F)
        #     end
        # elseif TINT.mode == "triangle" # 構造考慮
        #     # 被喩辞のコスライス圏
        #     A_category = CategoryBuilder.build(A, A_images, triangle=true)
        #     for (B_dom, B_cod) in permutations(B_images, 2)
        #         if B == B_dom || B == B_cod || B_dom == B_cod
        #             continue
        #         end
        #         # 喩辞のコスライス圏
        #         B_category = CategoryBuilder.build(B, B_dom, B_cod)
        #         # シミュレーション
        #         metaphor, F = simulate(A, B, A_triangle_images, B_init_images, potential_category, triangle)
        #         if verbose
        #             view_functor(idx2img, F)
        #         end
        #     end
        # else
        #     throw(DomainError(TINT.mode, "Invalid mode selected!! Selecting from 'object' or 'triangle'."))
        #     return
        # end
    end
end

end # module TINT
