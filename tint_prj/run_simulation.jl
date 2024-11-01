include("./src/tint.jl")
using .TINT

using Random

function simulation(;
    assoc_file::String = "tint_prj/data/three_metaphor_assoc_data.csv",
    image_file::String = "tint_prj/data/three_metaphor_images.csv",
    outdir::String = "tint_prj/out",
    )
    # 比喩のセット
    metaphor_set = Set([("蝶", "踊り子"), ("笑顔", "花"), ("粉雪", "羽毛")])

    TINT.mode = "object"
    TINT.seed = 1234

    F = TINT.main(metaphor_set, assoc_file, image_file, outdir)

    return F
end