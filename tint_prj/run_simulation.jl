include("./src/tint.jl")
using .TINT

using Random

function run_object()
    config = Dict{String, Any}(
        "metaphor_set" => Set([("蝶", "踊り子")]),
        "assoc_file" => "tint_prj/data/three_metaphor_assoc_data.csv",
        "image_file" => "tint_prj/data/three_metaphor_images.csv",
        "out_dir" => "tint_prj/out/",
        "NN" => 0,
        "steps" => 10,
        "search_method" => "deterministic",
        "seed" => 1234,
        "verbose" => true,
    )
    config = TINT.ObjectCfg(config)
    TINT.main(config)
end

function run_triangle()
    config = Dict{String, Any}(
        "metaphor_set" => Set([("蝶", "踊り子")]),
        "assoc_file" => "tint_prj/data/three_metaphor_assoc_data.csv",
        "image_file" => "tint_prj/data/three_metaphor_images.csv",
        "out_dir" => "tint_prj/out/",
        "NN" => 0,
        "steps" => 10,
        "search_method" => "deterministic",
        "seed" => 1234,
        "verbose" => true,
    )
    config = TINT.TriangleCfg(config)
    TINT.main(config)
end

function main(;mode::String = "object")
    if mode == "object"
        run_object()
    elseif mode == "triangle"
        run_triangle()
    elseif mode == "all"
        run_object()
        run_triangle()
    else
        throw(DomainError(mode, "Invalid mode selected."))
    end
    println("Completed.")
end