module NaturalTransformer
include("category_builder.jl")
include("functor.jl")

using Graphs
using SimpleWeightedGraphs
using SimpleGraphs
using Combinatorics
using StatsBase
using .FunctorBuilder
using .CategoryBuilder

# "softmax" or "deterministic"
search_method::String = "softmax"

# 自然変換をなしているか判定する関数
function is_natural_transformation(c1, c2, obj_dict1, edge_dict1, obj_dict2, edge_dict2)
    edges1 = collect(keys(edge_dict1))
    edges2 = collect(keys(edge_dict2))
    origin_edges = collect(edges(c2))
    origin_edges_pairs = vcat(collect(Iterators.product(origin_edges, origin_edges))...)
    natural_transformations = Dict()

    # 関手によって移された射を可換にするような自然変換の射を探す
    for (edge1, edge2) in zip(edges1, edges2)
        dom1, cod1 = edge1
        dom2, cod2 = edge2
        # 関手Fでの対象の移り先
        F_A, F_B = obj_dict1[dom1], obj_dict1[cod1]
        # 関手Gでの対象の移り先
        G_A, G_B = obj_dict2[dom2], obj_dict2[cod2]
        # 関手F, Gでの射の移り先
        F_f, G_f = edge_dict1[edge1], edge_dict2[edge2]

        # 自然変換の記録に存在しなければ初期化
        if F_A ∉ keys(natural_transformations)
            natural_transformations[dom1] = Set()
        end
        # 自然変換の記録に存在しなければ初期化
        if F_B ∉ keys(natural_transformations)
            natural_transformations[cod1] = Set()
        end

        for origin_pair in origin_edges_pairs
            alpha1, alpha2 = origin_pair
            if alpha1.dst == G_f[1]
                G_alpha = (alpha1.src, G_f[2])
            else
                G_alpha = nothing
            end
            if F_f[2] == alpha2.src
                alpha_F = (F_f[1], alpha2.dst)
            else
                alpha_F = nothing
            end
            # 可換にできるような自然変換がある場合
            if G_alpha == alpha_F && !isnothing(G_alpha) && !isnothing(alpha_F)
                push!(natural_transformations[dom1], alpha1)
                push!(natural_transformations[cod1], alpha2)
            end
        end
        # 可換にできるような自然変換がない
        if length(natural_transformations[dom1]) == 0 && length(natural_transformations[cod1]) == 0
            # そのような射に関してはnothingを記録
            push!(natural_transformations[dom1], nothing)
            push!(natural_transformations[cod1], nothing)
        end
    end

    return natural_transformations
end

# 合成射を取得する関数
function get_composite_morphisms(g::SimpleDiGraph, edge::Tuple)::Vector{Tuple{Int, Int, Int}}
    dom, cod = edge
    composite_morphisms = Vector{Tuple{Int, Int, Int}}()
    for node in Graphs.neighbors(g, dom)
        if has_edge(g, node, cod)
            push!(composite_morphisms, (dom, node, cod))
        end
    end
    return composite_morphisms
end

# 対象の対応から射の対応付けを行う関数
function edge_correspondence(c1::SimpleDiGraph, c2::SimpleDiGraph, obj_dict::Dict)::Tuple
    edge_dict = Dict{Tuple, Tuple}()
    for edge in edges(c1)
        dom, cod = edge.src, edge.dst
        F_dom, F_cod = obj_dict[dom], obj_dict[cod]
        # 移り先に存在しない射が指定されている
        if ~has_edge(c2, F_dom, F_cod)
            return (false, Dict())
        end
        # 写像でない(同じ射が2回指定されている)
        if (dom, cod) in keys(edge_dict)
            return (false, Dict())
        end
        edge_dict[(dom, cod)] = (F_dom, F_cod)
    end
    return (true, edge_dict)
end

# 関手かどうか判定する関数
function is_functor(c1::SimpleDiGraph, obj_dict::Dict, edge_dict::Dict)::Bool
    edges_dom = collect(keys(edge_dict))
    edges_cod = collect(values(edge_dict))

    #1.恒等射の移りが、自分の対象の移りであるかF(id_A) = id_F(A)
    for edge in edges_dom
        dom, cod = edge
        # 恒等射かどうか
        if dom == cod
            F_dom = obj_dict[dom] #F(A)
            # F(id_A) = id_F(A)かどうか
            if edge_dict[(dom, dom)] != (F_dom, F_dom)
                println(false)
            end
        end
    end

    #2.F(A->B) = F(A)->F(B)の判定。移った辺が移った点2組と同じか判定
    for (i, edge) in enumerate(edges_dom)
        dom, cod = edge
        F_dom, F_cod = obj_dict[dom], obj_dict[cod]
        if (F_dom, F_cod) != edges_cod[i]
            println(false)
        end
    end

    #3.合成射がF(g・f) = F(g)・F(f)であるかどうかの判定
    for (i, edge) in enumerate(edges_dom)
        # 合成射の集合を取得
        composite_morphisms = get_composite_morphisms(c1, edge)
        if length(composite_morphisms) > 0
            F_composite = edges_cod[i]
            for (dom, node, cod) in composite_morphisms
                F_f = edge_dict[(dom, node)]
                F_g = edge_dict[(node, cod)]
                if (F_f[1], F_g[2]) != F_composite
                    return false
                end
            end
        end
    end
    
    return true
end

# full anti-fork rule
function full_anti_fork_rule(A_category, B_category, A, fork_edges, A_remain_edges, B_remain_edges)
    # 自然変換の要素を含む三角構造以外を切る
    # これだとコスライス圏は対象しか残らない
    antied_A_category = SimpleDiGraph(nv(A_category))
    antied_B_category = SimpleDiGraph(nv(B_category))

    for (dom, cod) in A_remain_edges
        add_edge!(antied_A_category, dom, cod)
    end
    for (dom, cod) in fork_edges
        add_edge!(antied_A_category, dom, cod)
        add_edge!(antied_A_category, A, dom)
    end
    for (dom, cod) in B_remain_edges
        add_edge!(antied_B_category, dom, cod)
    end

    antied_A_category = CategoryBuilder.add_identity(antied_A_category)
    antied_B_category = CategoryBuilder.add_identity(antied_B_category)

    return antied_A_category, antied_B_category
end

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
# function search(source::Int, target::Int,
#     source_category::SimpleWeightedDiGraph, target_category::SimpleWeightedDiGraph, potential_category::SimpleWeightedDiGraph
#     )::Functor

#     objects = Dict{Int, Int}()
#     morphisms = Dict{Tuple, Tuple}()

#     for source_image in vertices(source_category)
#         candidates = Vector{Tuple}()
#         sizehint!(candidates, nv(potential_category))
#         for target_image in vertices(target_category)
#             assoc_prob = Graphs.weights(potential_category)[source_image, target_image]
#             if assoc_prob >= rand()
#                 push!(candidates, (source_image, target_image, assoc_prob))
#             end
#         end
#         if length(candidates) != 0
#             if search_method == "softmax"
#                 # softmaxで選択
#                 dom, cod, prob = softmax(candidates)
#             elseif search_method == "deterministic"
#                 # 連想確率の最大値で選択
#                 dom, cod, prob = candidates[findmax(x->x[3], candidates)[2]]
#             else
#                 return "Error: invalid method selected"
#             end

#             objects[dom] = cod
#             morphisms[(source, dom)] = (target, cod)
#         end
#     end

#     return Functor(objects, morphisms)
# end

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