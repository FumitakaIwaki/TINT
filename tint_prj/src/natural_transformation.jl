include("./config.jl")
include("./category_builder.jl")

using Graphs
using SimpleWeightedGraphs
using SimpleGraphs
using StatsBase

# 自然変換をなしているか判定する関数
function is_natural_transformation(c1::SimpleDiGraph, c2::SimpleDiGraph,
    obj_dict1::Dict, edge_dict1::Dict, obj_dict2::Dict, edge_dict2::Dict
    )::Dict
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
function full_anti_fork_rule(A_category::SimpleDiGraph, B_category::SimpleDiGraph,
    A::Int, fork_edges::Set{Tuple}, A_remain_edges::Set{Tuple}, B_remain_edges::Set{Tuple}
    )::Tuple
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

    antied_A_category = add_identity(antied_A_category)
    antied_B_category = add_identity(antied_B_category)

    return antied_A_category, antied_B_category
end

# 関手として採用する射をsoftmaxで選択する関数
function softmax(candidates::Vector, candidates_weights::Vector;
    reverse::Bool = false, β::Float64 = 1.0)::typeof(candidates[1])
    if reverse
        weights = candidates_weights .* -1
    else
        weights = candidates_weights
    end
    exp_prob = [exp(β * p) for p in weights]
    sum_exp_prob = sum(exp_prob)
    probs = [i / sum_exp_prob for i in exp_prob]
    return wsample(candidates, probs)
end

# 自然変換の候補のうち、構造が最も類似しているものを返す関数
# 対応づけられた射の連想確率の差の総和が最小
function find_similar_structure(potential_category::SimpleWeightedDiGraph,
    target_category::SimpleDiGraph, target::Int, source::Int, dom::Int, cod::Int, 
    dom_candidates::Vector{Int}, cod_candidates::Vector{Int}, config::AbstractCfg
    )::Tuple
    edge_correct_pair = Vector{Tuple{Int, Int}}()
    weight_dists = Vector{Float64}()
    for dom_candidate in dom_candidates
        for cod_candidate in cod_candidates
            # 関手が成り立つような射が間に無い場合はパス
            if !has_edge(target_category, dom_candidate, cod_candidate)
                continue
            end
            # 現状，埋め込みが起こるような部分を省いて探す
            if dom_candidate == cod_candidate
                continue
            end
            # 各射の重みを取得
            dom_edge_weight = Graphs.weights(potential_category)[source, dom]
            cod_edge_weight = Graphs.weights(potential_category)[source, cod]
            coslice_edge_weihgt = Graphs.weights(potential_category)[dom, cod]
            F_dom_edge_weight = Graphs.weights(potential_category)[target, dom_candidate]
            F_cod_edge_weight = Graphs.weights(potential_category)[target, cod_candidate]
            F_coslice_edge_weight = Graphs.weights(potential_category)[dom_candidate, cod_candidate]

            # sourceとtargetの三角構造の構成要素同士の重みを比較
            # 似た連想確率を持つ構造を移り先として適当なのではないか
            weight_dist = abs(dom_edge_weight - F_dom_edge_weight) + abs(cod_edge_weight - F_cod_edge_weight) + abs(coslice_edge_weihgt - F_coslice_edge_weight)
            push!(edge_correct_pair, (dom_candidate, cod_candidate))
            push!(weight_dists, weight_dist)
        end
    end
    if length(edge_correct_pair) == 0
        return ()
    else
        if config.search_method == "deterministic"
            return edge_correct_pair[findmin(weight_dists)[2]]
        elseif config.search_method == "softmax"
            return softmax(edge_correct_pair, weight_dists; reverse=true, β = config.β)
        else
            throw(DomainError(config.search_method, "Invalid search method is selected."))
        end
    end
end

# 自然変換を探索する関数(構造無視)
# Aがtarget, Bがsource
function search(potential_category::SimpleWeightedDiGraph,
    target::Int, source::Int, 
    target_category::SimpleDiGraph, source_category::SimpleDiGraph,
    config::ObjectCfg; cutoff::Int=1)::Tuple
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
            if config.search_method == "deterministic"
                target_object = rand(candidates[findall(candidates_weights .== maximum(candidates_weights))])
            elseif config.search_method == "softmax"
                target_object = softmax(candidates, candidates_weights; β = config.β)
            else
                throw(DomainError(config.search_method, "Invalid search method is selected."))
            end
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

# 自然変換を探索する関数（構造考慮）
function search(potential_category::SimpleWeightedDiGraph,
    target::Int, source::Int,
    target_category::SimpleDiGraph, source_category::SimpleDiGraph,
    config::TriangleCfg; cutoff::Int=1
    )::Tuple
    # sourceの対象のみ
    source_objects = [obj for obj in Graphs.neighbors(source_category, source) if obj != source]
    # targetの対象のみ
    target_objects = [obj for obj in Graphs.neighbors(target_category, target) if obj != target]
    # sourceのコスライス圏の射
    source_coslice_edges = [edge for edge in edges(source_category) if edge.src != source && edge.src != edge.dst]

    fork_edges = Set{Tuple}()
    target_remain_edges = Set{Tuple}()
    source_remain_edges = Set{Tuple}()
    BMF_objects = Dict{Int, Int}(source => target)
    F_objects = Dict{Int, Int}(source => target)

    # source -> targetの重み行列
    weight_mtx = [[potential_category.weights[s_obj, t_obj] for t_obj in  target_objects] for s_obj in source_objects]
    # 上と同じshapeの乱数行列
    rand_mtx = [rand(length(target_objects)) for i in 1:length(source_objects)]

    # コスライス圏の射ごとに対応付を行う
    # 現状，喩辞には1つの三角構造しかないため，コスライス圏の射のdom, codに対して探索している (繰り返し自体は全てのコスライス圏の射を繰り返している)
    for edge in source_coslice_edges
        dom, cod = edge.src, edge.dst
        # コスライス圏の射のdom, codのindexを取得
        dom_idx = findall(source_objects .== dom)[1]
        cod_idx = findall(source_objects .== cod)[1]
        # domから被喩辞の対象への連想を決定する乱数
        dom_rand_list = rand_mtx[dom_idx]
        # domから被喩辞の対象への連想確率
        dom_weight_list = weight_mtx[dom_idx]
        # codから被喩辞の対象への連想を決定する乱数
        cod_rand_list = rand_mtx[cod_idx]
        # codから被喩辞の対象への連想確率
        cod_weight_list = weight_mtx[cod_idx]
        # domについて自然変換の要素の候補
        dom_candidates = target_objects[dom_rand_list .< dom_weight_list]
        # codについて自然変換の要素の候補
        cod_candidates = target_objects[cod_rand_list .< cod_weight_list]

        # 候補の中で最も構造が類似しているものを自然変換の要素として選択
        # 選択する関数の中で正しく関手になっていない候補は省く
        candidate = find_similar_structure(
            potential_category, target_category, target, source,
            dom, cod, dom_candidates, cod_candidates, config
            )
        # 候補が存在しない場合はそのコスライス圏に対応づく射は無い
        if length(candidate) == 0
            continue
        end
        nt_dom, nt_cod = candidate
        
        # BMFの記録
        BMF_objects[dom] = dom
        BMF_objects[cod] = cod
        # Fの記録
        F_objects[dom] = nt_dom
        F_objects[cod] = nt_cod
        # 自然変換の要素になる射を記録
        push!(fork_edges, (dom, nt_dom))
        push!(fork_edges, (cod, nt_cod))
        # target側で残る射を記録
        push!(target_remain_edges, (target, nt_dom))
        push!(target_remain_edges, (target, nt_cod))
        push!(target_remain_edges, (nt_dom, nt_cod))
        push!(target_remain_edges, (dom, cod))
        # source側で残る射の記録
        push!(source_remain_edges, (source, dom))
        push!(source_remain_edges, (source, cod))
        push!(source_remain_edges, (dom, cod))
    end
    return fork_edges, target_remain_edges, source_remain_edges, BMF_objects, F_objects
end