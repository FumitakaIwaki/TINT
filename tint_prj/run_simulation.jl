include("./src/tint.jl")
using .TINT

function run_object(config_file::String)
    config = TINT.ObjectCfg(config_file)
    TINT.main(config)
end

function run_triangle(config_file::String)
    config = TINT.TriangleCfg(config_file)
    TINT.main(config)
end

function run_whole_structure(config_file::String)
    config = TINT.WholeStructureCfg(config_file)
    TINT.main(config)
end

function main(;mode::String = "all", config_file::String = "tint_prj/tint_config.yml")
    if mode == "object"
        run_object(config_file)
    elseif mode == "triangle"
        run_triangle(config_file)
    elseif mode == "whole"
        run_whole_structure(config_file)
    elseif mode == "all"
        run_object(config_file)
        run_triangle(config_file)
        run_whole_structure(config_file)
    else
        throw(DomainError(mode, "Invalid mode selected."))
    end
    println("Completed.")
end