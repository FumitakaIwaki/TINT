include("./config.jl")

using Graphs
using SimpleWeightedGraphs
using SimpleGraphs
using DataFrames
using Combinatorics: permutations

# 潜在圏を構築する関数
function build(edgelist::DataFrame, config::AbstractCfg)::SimpleWeightedDiGraph
    graph = SimpleWeightedDiGraph(config.NN)
    for edge in eachrow(edgelist)
        add_edge!(graph, edge.from, edge.to, edge.weight)
    end
    graph = add_identity(graph)
    return graph
end

# コスライス圏を構築する関数 (構造無視)
function build(center_image::Int, init_images::Vector{Int}, config::ObjectCfg)::SimpleDiGraph
    graph = SimpleDiGraph(config.NN)
    for image in init_images
        add_edge!(graph, center_image, image)
    end
    graph = add_identity(graph)
    return graph
end

# 被喩辞のコスライス圏を構築する関数 （三角構造考慮）
function build(center_image::Int, init_images::Vector{Int}, config::TriangleCfg)::SimpleDiGraph
    graph = SimpleDiGraph(config.NN)
    for image in init_images
        add_edge!(graph, center_image, image)
    end
    for (dom, cod) in permutations(init_images, 2)
        add_edge!(graph, dom, cod)
    end
    graph = add_identity(graph)
    return graph
end

# 喩辞のコスライス圏を構築する関数 (三角構造考慮)
function build(center_image::Int, dom::Int, cod::Int, config::TriangleCfg)::SimpleDiGraph
    graph = SimpleDiGraph(config.NN)
    add_edge!(graph, center_image, dom)
    add_edge!(graph, center_image, cod)
    add_edge!(graph, dom, cod)
    graph = add_identity(graph)
    return graph
end

# コスライス圏を構築する関数 (全構造考慮)
function build(center_image::Int, init_images::Vector{Int}, config::WholeStructureCfg)::SimpleDiGraph
    graph = SimpleDiGraph(config.NN)
    for image in init_images
        add_edge!(graph, center_image, image)
    end
    for (dom, cod) in permutations(init_images, 2)
        add_edge!(graph, dom, cod)
    end
    graph = add_identity(graph)
    return graph
end

# 潜在圏に恒等射を追加する関数
function add_identity(graph::SimpleWeightedDiGraph, weight::Float64=1.0)::SimpleWeightedDiGraph
    for node in vertices(graph)
        add_edge!(graph, node, node, weight)
    end
    return graph
end

# コスライス圏に恒等射を追加する関数
function add_identity(graph::SimpleDiGraph)::SimpleDiGraph
    degrees = degree(graph)
    for node in vertices(graph)
        if degrees[node] != 0
            add_edge!(graph, node, node)
        end
    end
    return graph
end