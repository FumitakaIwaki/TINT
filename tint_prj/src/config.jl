using YAML

abstract type AbstractCfg end

mutable struct ObjectCfg <: AbstractCfg
    metaphor_set::Vector{Vector{String}}
    assoc_file::String
    image_file::String
    out_dir::String
    NN::Int
    steps::Int
    search_method::String
    β::Float64
    seed::Int
    verbose::Bool
    # 直接configのdictを渡されたときの内部コンストラクタ
    function ObjectCfg(config::Dict{Any, Any})
        metaphor_set = config["metaphor_set"]
        assoc_file = config["assoc_file"]
        image_file = config["image_file"]
        out_dir = config["out_dir"]
        NN = config["NN"]
        steps = config["steps"]
        search_method = config["search_method"]
        β = config["softmax_beta"]
        seed = config["seed"]
        verbose = config["verbose"]
        new(metaphor_set, assoc_file, image_file, out_dir, NN, steps, search_method, β, seed, verbose)
    end
    # config.ymlのパスを渡されたときの内部コンストラクタ
    function ObjectCfg(path::String)
        config = YAML.load_file(path)["object"]
        return ObjectCfg(config)
    end
end

mutable struct TriangleCfg <: AbstractCfg
    metaphor_set::Vector{Vector{String}}
    assoc_file::String
    image_file::String
    out_dir::String
    NN::Int
    steps::Int
    search_method::String
    β::Float64
    seed::Int
    verbose::Bool
    # 直接configのdictを渡されたときの内部コンストラクタ
    function TriangleCfg(config::Dict{Any, Any})
        metaphor_set = config["metaphor_set"]
        assoc_file = config["assoc_file"]
        image_file = config["image_file"]
        out_dir = config["out_dir"]
        NN = config["NN"]
        steps = config["steps"]
        search_method = config["search_method"]
        β = config["softmax_beta"]
        seed = config["seed"]
        verbose = config["verbose"]
        new(metaphor_set, assoc_file, image_file, out_dir, NN, steps, search_method, β, seed, verbose)
    end
    # config.ymlのパスを渡されたときの内部コンストラクタ
    function TriangleCfg(path::String)
        config = YAML.load_file(path)["triangle"]
        return TriangleCfg(config)
    end
end

mutable struct WholeStructureCfg <: AbstractCfg
    metaphor_set::Vector{Vector{String}}
    assoc_file::String
    image_file::String
    out_dir::String
    NN::Int
    steps::Int
    search_method::String
    β::Float64
    seed::Int
    verbose::Bool
    # 直接configのdictを渡されたときの内部コンストラクタ
    function WholeStructureCfg(config::Dict{Any, Any})
        metaphor_set = config["metaphor_set"]
        assoc_file = config["assoc_file"]
        image_file = config["image_file"]
        out_dir = config["out_dir"]
        NN = config["NN"]
        steps = config["steps"]
        search_method = config["search_method"]
        β = config["softmax_beta"]
        seed = config["seed"]
        verbose = config["verbose"]
        new(metaphor_set, assoc_file, image_file, out_dir, NN, steps, search_method, β, seed, verbose)
    end
    # config.ymlのパスを渡されたときの内部コンストラクタ
    function WholeStructureCfg(path::String)
        config = YAML.load_file(path)["whole_structure"]
        return WholeStructureCfg(config)
    end
end