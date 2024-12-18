module TINT
using Random
using DataFrames
using Graphs
using SimpleWeightedGraphs
using SimpleGraphs
using Combinatorics: permutations
using ProgressBars

include("./config.jl")
include("./dataloader.jl")
include("./category_builder.jl")
include("./natural_transformation.jl")
include("./recorder.jl")

# シミュレーション実行関数
function simulate(potential_category::SimpleWeightedDiGraph,
    A::Int, B::Int, A_category::SimpleDiGraph, B_category::SimpleDiGraph,
    config::AbstractCfg
    )::Tuple{Dict{Int, Set{Graphs.SimpleGraphs.SimpleEdge{Int}}}, Dict{Tuple{Int, Int}, Tuple{Int, Int}}}
    is_BMF_functor = false
    is_F_functor = false
    # 獲得された比喩)
    metaphor = Dict{Int, Set{Graphs.SimpleGraphs.SimpleEdge{Int}}}()
    # 探索された関手
    F = Dict{Tuple{Int, Int}, Tuple{Int, Int}}()

    # A_categoryとB_categoryの対応付を探索
    fork_edges, A_remain_edges, B_remain_edges, BMF_objects, F_objects = search(potential_category, A, B, A_category, B_category, config)

    # 対応を取るときはAがBにfでつながった形にしなければいけない
    # それでは元に戻せないので現状の圏を保管しておく
    tmp_B_category = copy(B_category)
    tmp_fork_edges = copy(fork_edges)
    tmp_A_remain_edges = copy(A_remain_edges)
    tmp_B_remain_edges = copy(B_remain_edges)

    # anti-fork ruleで対応がつかなかった部分を削除
    A_category, B_category = full_anti_fork_rule(A_category, B_category, A, fork_edges, A_remain_edges, B_remain_edges)
    # 全てのノードが無くなった場合は飛ばす
    if nv(A_category) == 0 || nv(B_category) == 0
        println("All nodes were removed in anti-fork rules.")
        return metaphor, F
    end

    # BMFが関手かどうか
    is_BMF_correspondence, BMF_edges = edge_correspondence(B_category, A_category, BMF_objects)
    if is_BMF_correspondence
        is_BMF_functor = is_functor(B_category, BMF_objects, BMF_edges)
    end
    # Fが関手かどうか
    is_F_correspondence, F_edges = edge_correspondence(B_category, A_category, F_objects)
    if is_F_correspondence
        is_F_functor = is_functor(B_category, F_objects, F_edges)
    end
    # どちらも関手でなかった場合
    if !is_BMF_functor || !is_F_functor
        println("The morphisms weren't functors.")
        return metaphor, F
    end

    # 自然変換をなしているかどうか
    metaphor = is_natural_transformation(B_category, A_category, BMF_objects, BMF_edges, F_objects, F_edges)
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
    config::ObjectCfg)::ObjectRecorde
    metaphor = Dict{Int, Set{Graphs.SimpleGraphs.SimpleEdge{Int}}}()
    F = Dict{NTuple{2, Int}, NTuple{2, Int}}()
    # 被喩辞のコスライス圏
    A_category = build(A, A_images, config)
    # 喩辞のコスライス圏
    B_category = build(B, B_images, config)
    # シミュレーション
    metaphor, F = simulate(potential_category, A, B, A_category, B_category, config)
    # 結果の格納
    recordes = ObjectRecorde(F)

    return recordes
end

# 構造考慮の実行関数
function run(potential_category::SimpleWeightedDiGraph,
    A::Int, B::Int, A_images::Vector{Int}, B_images::Vector{Int},
    config::TriangleCfg)::Vector{TriangleRecorde}
    metaphor = Dict{Int, Set{Graphs.SimpleGraphs.SimpleEdge{Int}}}()
    F = Dict{NTuple{2, Int}, NTuple{2, Int}}()
    recordes = Vector{TriangleRecorde}()
    sizehint!(recordes, length(permutations(B_images, 2)))

    # 被喩辞のコスライス圏
    A_category = build(A, A_images, config)
    for (B_dom, B_cod) in permutations(B_images, 2)
        if B == B_dom || B == B_cod || B_dom == B_cod
            continue
        end
        # 喩辞のコスライス圏
        B_category = build(B, B_dom, B_cod, config)
        # シミュレーション
        metaphor, F = simulate(potential_category, A, B, A_category, B_category, config)
        # 結果の格納
        push!(recordes, TriangleRecorde(B_dom, B_cod, F))
    end
    return recordes
end

# main関数
function main(config::AbstractCfg)
    Random.seed!(config.seed) # シード値の設定
    # データの読み込み
    assoc_df = load_assoc_data(config.assoc_file)
    image_df = load_images(config.image_file)
    # indexとstrの辞書
    idx2img = unique(vcat((image_df[:, ["source", "target"]] |> Array)...))
    img2idx = Dict((idx2img[i], i) for i in eachindex(idx2img))
    # 総イメージ数の設定
    config.NN = length(idx2img)
    # strをindexに変換したdf
    encoded_assoc_df = get.(Ref(img2idx), assoc_df[:, ["from", "to", "weight"]], assoc_df[:, "weight"])
    encoded_image_df = get.(Ref(img2idx), image_df[:, ["source", "target"]], missing)
    # プログレスバーを表示するか否か
    if config.verbose
        step_iter = ProgressBar(1:config.steps)
    else
        step_iter = 1:config.steps
    end
    # 　全ての比喩セットに対して実行
    for (topic, vehicle) in config.metaphor_set
        if config.verbose
            mode = split(string(typeof(config)), ".")[3][1:end-3]
            println(mode, " simulation for ", topic, " -> ", vehicle)
        end
        # 潜在圏
        potential_category = build(encoded_assoc_df, config)
        # 被喩辞
        A = img2idx[topic]
        # 被喩辞の初期イメージ
        A_images = encoded_image_df[encoded_image_df.:source .== A, :target]
        # 喩辞
        B = img2idx[vehicle]
        # 喩辞の初期イメージ
        B_images = encoded_image_df[encoded_image_df.:source .== B, :target]

        # 結果格納用
        result = Result(A, B, config)
        # TINTの実行
        for step in step_iter
            recordes = run(potential_category, A, B, A_images, B_images, config)
            update_result!(result, recordes)
        end
        save_result(result, config, idx2img)
    end
end # main

end # module TINT
