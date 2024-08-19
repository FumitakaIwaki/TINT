module NaturalTransformer
include("functor.jl")

using Graphs
using SimpleWeightedGraphs
using Combinatorics
using StatsBase
using .FunctorBuilder

# 関手として採用する射をsoftmaxで選択する関数
function softmax(candidates::Vector{Tuple})::Tuple
    exp_prob = [exp(p[3]) for p in candidates]
    sum_exp_prob = sum(exp_prob)
    probs = [i / sum_exp_prob for i in exp_prob]
    return wsample(candidates, probs)
end

# 自然変換を探索する関数（構造無視）
function search(source::Int, target::Int,
    source_category::SimpleWeightedDiGraph, target_category::SimpleWeightedDiGraph, potential_category::SimpleWeightedDiGraph
    )::Functor

    objects = Dict{Int, Int}()
    morphisms = Dict{Tuple, Tuple}()

    for source_image in vertices(source_category)
        candidates = Vector{Tuple}()
        sizehint!(candidates, nv(potential_category))
        for target_image in vertices(target_category)
            assoc_prob = Graphs.weights(potential_category)[source_image, target_image]
            if assoc_prob >= rand()
                push!(candidates, (source_image, target_image, assoc_prob))
            end
        end
        if length(candidates) != 0
            # 連想確率の最大値で選択
            # dom, cod, prob = candidates[findmax(x->x[3], candidates)[2]]
            # softmaxで選択
            dom, cod, prob = softmax(candidates)

            objects[dom] = cod
            morphisms[(source, dom)] = (target, cod)
        end
    end

    return Functor(objects, morphisms)
end

# 自然変換を探索する関数（構造考慮）
function search(source::Int, target::Int,
    source_category::SimpleWeightedDiGraph, target_category::SimpleWeightedDiGraph, potential_category::SimpleWeightedDiGraph,
    source_triangle_images::Vector{Int})::Functor

    objects = Dict{Int, Int}()
    morphisms = Dict{Tuple, Tuple}()
    triangle_dom, triangle_cod = source_triangle_images
    dom_assoc_images = Vector{}()
    cod_assoc_images = Vector{}()
    candidates = Vector{Tuple}()

    for target_node in vertices(target_category)
        if potential_category.weights[triangle_dom, target_node] >= rand()
            push!(dom_assoc_images, target_node)
        end
        if potential_category.weights[triangle_cod, target_node] >= rand()
            push!(cod_assoc_images, target_node)
        end
    end
    if length(dom_assoc_images) == 0
        return nothing
    end
    if length(cod_assoc_images) == 0
        return nothing
    end
    triangle_dom_prob = potential_category.weights[source, triangle_dom]
    triangle_cod_prob = potential_category.weights[source, triangle_cod]
    triangle_edge_prob = potential_category.weights[triangle_dom, triangle_cod]
    for (dom, cod) in Iterators.product(dom_assoc_images, cod_assoc_images)
        if has_edge(potential_category, dom, cod) && dom != cod
            F_triangle_dom_prob = potential_category.weights[target, dom]
            F_triangle_cod_prob = potential_category.weights[target, cod]
            F_triangle_edge_prob = potential_category.weights[dom, cod]
            dom_prob_dist = abs(triangle_dom_prob - F_triangle_dom_prob)
            cod_prob_dist = abs(triangle_cod_prob - F_triangle_cod_prob)
            edge_prob_dist = abs(triangle_edge_prob - F_triangle_edge_prob)
            dist_sum = dom_prob_dist + cod_prob_dist + edge_prob_dist
            push!(candidates, (dom, cod, dist_sum))
        end 
    end
    # 連想確率の最大値で選択
    # dom, cod, prob = candidates[findmin(x->x[3], candidates)[2]]
    # softmaxで選択
    dom, cod, prob = softmax(candidates)

    morphisms[(source, triangle_dom)] = (target, dom)
    morphisms[(source, triangle_cod)] = (target, cod)
    morphisms[(triangle_dom, triangle_cod)] = (dom, cod)

    return Functor(objects, morphisms)
end

end # NaturalTransformer