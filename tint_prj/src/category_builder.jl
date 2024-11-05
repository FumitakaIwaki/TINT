module CategoryBuilder

using Graphs
using SimpleWeightedGraphs
using SimpleGraphs
using DataFrames
using Combinatorics: permutations

NN::Int = 0


# 潜在圏を構築する関数
function build(edgelist::DataFrame)::SimpleWeightedDiGraph
    graph = SimpleWeightedDiGraph(NN)
    for edge in eachrow(edgelist)
        add_edge!(graph, edge.from, edge.to, edge.weight)
    end
    graph = add_identity(graph)
    return graph
end

# コスライス圏を構築する関数 (構造無視)
function build(center_image::Int, init_images::Vector{Int})::SimpleDiGraph
    graph = SimpleDiGraph(NN)
    for image in init_images
        add_edge!(graph, center_image, image)
    end
    graph = add_identity(graph)
    return graph
end

# 被喩辞のコスライス圏を構築する関数 （構造考慮）
function build(center_image::Int, init_images::Vector{Int}; triangle::Bool=true)::SimpleDiGraph
    graph = SimpleDiGraph(NN)
    for image in init_images
        add_edge!(graph, center_image, image)
    end
    for (dom, cod) in permutations(init_images, 2)
        add_edge!(graph, dom, cod)
    end
    graph = add_identity(graph)
    return graph
end

# 喩辞のコスライス圏を構築する関数 (構造考慮)
function build(center_image::Int, dom::Int, cod::Int)::SimpleDiGraph
    graph = SimpleDiGraph(NN)
    add_edge!(graph, center_image, dom)
    add_edge!(graph, center_image, cod)
    add_edge!(graph, dom, cod)
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

# 喩辞と初期イメージの三角構造の組を一つ取得する関数
function get_source_triangle(source_init_images::DataFrame, potential_category::SimpleWeightedDiGraph)::Vector{Int}
    for dom in source_init_images.to
        for cod in source_init_images.to
            if dom!=cod && has_edge(potential_category, dom, cod)
                return Vector([dom, cod])
            end
        end
    end
    return zeros(2)
end

end # CategoryBuilder