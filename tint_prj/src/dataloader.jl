module DataLoader

using CSV
using DataFrames
using StringEncodings

function load_assoc_data(file::String)
    header = ["index", "from", "to", "weight"]
    return CSV.read(file, header=header, DataFrame)
end


function load_images(file::String, L::Int)
    source = Array{String}(undef, L)
    target = Array{String}(undef, L)

    open(file, "r") do f
        lines = readlines(f, enc"shift-jis")
        for i in 1:length(lines)
            source[i], target[i] = split(lines[i], ",")
        end
    end

    return source, target
end

end # DataLoader