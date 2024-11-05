abstract type AbstractCfg end

mutable struct ObjectCfg <: AbstractCfg
    metaphor_set::Set{Tuple{String, String}}
    assoc_file::String
    image_file::String
    out_dir::String
    NN::Int
    steps::Int
    search_method::String
    seed::Int
    verbose::Bool
    function ObjectCfg(config::Dict{String, Any})
        metaphor_set = config["metaphor_set"]
        assoc_file = config["assoc_file"]
        image_file = config["image_file"]
        out_dir = config["out_dir"]
        NN = config["NN"]
        steps = config["steps"]
        search_method = config["search_method"]
        seed = config["seed"]
        verbose = config["verbose"]
        new(metaphor_set, assoc_file, image_file, out_dir, NN, steps, search_method, seed, verbose)
    end
end

mutable struct TriangleCfg <: AbstractCfg
    metaphor_set::Set{Tuple{String, String}}
    assoc_file::String
    image_file::String
    out_dir::String
    NN::Int
    steps::Int
    search_method::String
    seed::Int
    verbose::Bool
    function TriangleCfg(config::Dict{String, Any})
        metaphor_set = config["metaphor_set"]
        assoc_file = config["assoc_file"]
        image_file = config["image_file"]
        out_dir = config["out_dir"]
        NN = config["NN"]
        steps = config["steps"]
        search_method = config["search_method"]
        seed = config["seed"]
        verbose = config["verbose"]
        new(metaphor_set, assoc_file, image_file, out_dir, NN, steps, search_method, seed, verbose)
    end
end