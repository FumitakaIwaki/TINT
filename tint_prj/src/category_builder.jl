module CategoryBuilder

using Graphs
using SimpleWeightedGraphs
using DataFrames
using Combinatorics

NN::Int = 0


# 潜在圏を構築する関数
function build(edgelist::DataFrame)::SimpleWeightedDiGraph
    graph = SimpleWeightedDiGraph(NN)
    for edge in eachrow(edgelist)
        add_edge!(graph, edge.from, edge.to, edge.weight)
    end
    graph = add_identity(graph, 0.5)
    return graph
end

# コスライス圏を構築する関数 (構造無視)
function build(center_image::Int, init_images::DataFrame)::SimpleWeightedDiGraph
    graph = SimpleWeightedDiGraph(NN)
    for image in eachrow(init_images)
        add_edge!(graph, center_image, image.to, 1.0)
    end
    graph = add_identity(graph)
    return graph
end

# 喩辞コスライス圏を構築する関数 (構造考慮)
function build(center_image::Int, init_images::Vector{Int})::SimpleWeightedDiGraph
    graph = SimpleWeightedDiGraph(NN)
    triangle_dom, triangle_cod = init_images
    add_edge!(graph, center_image, triangle_dom, 1.0)
    add_edge!(graph, center_image, triangle_cod, 1.0)
    add_edge!(graph, triangle_dom, triangle_cod, 1.0)
    graph = add_identity(graph)
    return graph
end

# 被喩辞のコスライス圏を構築する関数 （構造考慮）
function build(center_image::Int, init_images::DataFrame, potential_category::SimpleWeightedDiGraph)::SimpleWeightedDiGraph
    graph = SimpleWeightedDiGraph(NN)
    for image in eachrow(init_images)
        add_edge!(graph, center_image, image.to, 1.0)
    end
    for (dom, cod) in permutations(init_images.to, 2)
        add_edge!(graph, dom, cod, 1.0)
    end
    graph = add_identity(graph)
    return graph
end

# 恒等射を追加する関数
function add_identity(category::SimpleWeightedDiGraph, weight::Float64=1.0)::SimpleWeightedDiGraph
    for node in vertices(category)
        add_edge!(category, node, node, weight)
    end
    return category
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