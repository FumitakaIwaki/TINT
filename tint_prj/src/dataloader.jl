using CSV
using DataFrames
using StringEncodings

function load_assoc_data(file::String)
    header = ["index", "from", "to", "weight"]
    return CSV.read(file, header=header, DataFrame, stringtype=String)
end


function load_images(file::String)
    header = ["source", "target"]

    f = open(file, "r") do f
        read(f)
    end
    f = decode(f, "shift-jis")

    return CSV.read(IOBuffer(f), header=header, DataFrame, stringtype=String)
end