include("./src/tint.jl")
using .TINT

using Random

function simulation()
    config = Dict{String, Any}(
    "metaphor_set" => Set([("蝶", "踊り子"), ("笑顔", "花"), ("粉雪", "羽毛")]),
    "assoc_file" => "data/three_metaphor_assoc_data.csv",
    "image_file" => "data/three_metaphor_images.csv",
    "out_dir" => "tint_prj/out",
    "NN" => 0,
    "steps" => 1,
    "search_method" => "deterministic",
    "seed" => 1234,
    "verbose" => false,
    )
    # config = TINT.ObjectCfg(config)
    config = TINT.TriangleCfg(config)

    metaphor_history, F_history = TINT.main(config)

    return metaphor_history, F_history
end