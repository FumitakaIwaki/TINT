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
using SimpleWeightedGraphs

# 総イメージ数
NN::Int = 47
# シミュレーションのタイプ ("object", "triangle")
mode::String = "object"


# シミュレーション実行関数（構造無視）
function simulation(source::Int, target::Int,
    source_init_images::DataFrame, target_init_images::DataFrame, potential_category::SimpleWeightedDiGraph
    )::NaturalTransformer.FunctorBuilder.Functor

    source_category = CategoryBuilder.build(source, source_init_images)
    target_category = CategoryBuilder.build(target, target_init_images)
    _target_category, BMF = BMFBuilder.build(source, target, source_category, target_category)
    F = NaturalTransformer.search(source, target, source_category, target_category, potential_category)

    return F
end

# シミュレーション実行関数（構造考慮）
function simulation(source::Int, target::Int,
    source_triangle_images::Vector{Int}, target_init_images::DataFrame, potential_category::SimpleWeightedDiGraph,
    )::NaturalTransformer.FunctorBuilder.Functor

    source_category = CategoryBuilder.build(source, source_triangle_images, potential_category)
    target_category = CategoryBuilder.build(target, target_init_images, potential_category)
    _target_category, BMF = BMFBuilder.build(source, target, source_triangle_images, target_category)
    F = NaturalTransformer.search(source, target, source_category, target_category, potential_category, source_triangle_images)

    return F
end


function main(;file::String="tint_prj/data/three_metaphor_assoc_data.csv", outdir::String="tint_prj/out")
    df = DataLoader.load_assoc_data(file)

    # indexとstrの辞書
    idx2img = unique(vcat((df[:, ["from", "to"]] |> Array)...))
    img2idx = Dict((idx2img[i], i) for i in eachindex(idx2img))

    source = img2idx["蝶"] # 被喩辞
    target = img2idx["踊り子"] # 喩辞

    # strをindexに変換したdf
    encoded_df = copy(df[:, ["weight"]])
    encoded_df = hcat(get.(Ref(img2idx), df[:, ["from", "to"]], missing), encoded_df)

    # 被喩辞の初期イメージ
    source_init_images = encoded_df[encoded_df.:from .== source, ["to", "weight"]]
    # 瑜辞の初期イメージ
    target_init_images = encoded_df[encoded_df.:from .== target, ["to", "weight"]]

    # 総イメージ数の設定
    CategoryBuilder.NN = TINT.NN

    # 潜在圏
    potential_category = CategoryBuilder.build(encoded_df[:, ["from", "to", "weight"]])
    potential_category = CategoryBuilder.add_identity(potential_category)

    if TINT.mode == "object"
        F = simulation(source, target, source_init_images, target_init_images, potential_category)
        return F
    elseif TINT.mode == "triangle"
        # 喩辞の三角構造を一つ取得
        source_triangle_images = CategoryBuilder.get_source_triangle(source_init_images, potential_category)
        F = simulation(source, target, source_triangle_images, target_init_images, potential_category)
        return F
    else
        return "ERROR: Invalid mode selection!!"
    end

    return F
end

end # module TINT
