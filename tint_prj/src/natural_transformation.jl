module NaturalTransformer
include("functor.jl")

using Graphs
using SimpleWeightedGraphs
using SimpleGraphs
using Combinatorics
using StatsBase
using .FunctorBuilder

# "softmax" or "deterministic"
search_method::String = "softmax"

# 関手として採用する射をsoftmaxで選択する関数
function softmax(candidates::Vector{Tuple})::Tuple
    exp_prob = [exp(p[3]) for p in candidates]
    sum_exp_prob = sum(exp_prob)
    probs = [i / sum_exp_prob for i in exp_prob]
    return wsample(candidates, probs)
end

# 自然変換を探索する関数(構造無視)
# Aがtarget, Bがsource
function search(potential_category::SimpleWeightedDiGraph,
    target::Int, source::Int, 
    target_category::SimpleDiGraph, source_category::SimpleDiGraph,
    cutoff::Int=1)::Tuple
    # Bの対象のみ
    source_objects = [obj for obj in Graphs.neighbors(source_category, source) if obj != source]
    # Aの対象のみ
    target_objects = [obj for obj in Graphs.neighbors(target_category, target) if obj != target]

    fork_edges = Set{Tuple}()
    target_remain_edges = Set{Tuple}()
    source_remain_edges = Set{Tuple}()
    BMF_objects = Dict{Int, Int}(source => target)
    F_objects = Dict{Int, Int}(source => target)

    # source -> targetの重み行列
    weight_mtx = [[potential_category.weights[s_obj, t_obj] for t_obj in  target_objects] for s_obj in source_objects]
    # 上と同じshapeの乱数行列
    rand_mtx = [rand(length(target_objects)) for i in 1:length(source_objects)]

    for (i, (rand_list, weight_list)) in enumerate(zip(rand_mtx, weight_mtx))
        # 自然変換の候補: 乱数 < 重みの対象
        candidates = target_objects[rand_list .< weight_list]
        if length(candidates) != 0
            # 候補の重み
            candidates_weights = weight_list[rand_list .< weight_list]
            # 変換先の決定: 重み最大 (複数の場合ランダム)
            target_object = rand(candidates[findall(candidates_weights .== maximum(candidates_weights))])
            # 変換元の対象
            source_object = source_objects[i]
            
            # BMFの記録
            BMF_objects[source_object] = source_object
            # Fの記録
            F_objects[source_object] = target_object
            # 自然変換の要素を記録
            push!(fork_edges, (source_object, target_object))
            # Fで移される射を記録
            push!(target_remain_edges, (target, target_object))
            # BMF, Fの移り元となる射を記録
            push!(source_remain_edges, (source, source_object))
        end
    end
    return fork_edges, target_remain_edges, source_remain_edges, BMF_objects, F_objects
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
            if search_method == "softmax"
                # softmaxで選択
                dom, cod, prob = softmax(candidates)
            elseif search_method == "deterministic"
                # 連想確率の最大値で選択
                dom, cod, prob = candidates[findmax(x->x[3], candidates)[2]]
            else
                return "Error: invalid method selected"
            end

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