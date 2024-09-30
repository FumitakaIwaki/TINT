module BMFBuilder
include("functor.jl")

using Graphs
using SimpleWeightedGraphs
using .FunctorBuilder


# BMFを構築する関数（構造無視）
function build(source::Int, target::Int,
    source_category::SimpleWeightedDiGraph, target_category::SimpleWeightedDiGraph
    )#::(SimpleWeightedDiGraph, Functor)
    _target_category = copy(target_category)

    objects = Dict{Int, Int}()
    morphisms = Dict{Tuple, Tuple}()
    objects[source] = target

    for source_image in vertices(source_category)
        add_edge!(_target_category, target, source_image, 1.0)
        morphisms[(source, source_image)] = (target, source_image)
    end

    return (_target_category, Functor(objects, morphisms))
end

# BMFを構築する関数（構造考慮）
function build(source::Int, target::Int,
    source_triangle_images::Vector{Int}, target_category::SimpleWeightedDiGraph
    )#::(SimpleWeightedDiGraph, Functor)
    _target_category = copy(target_category)

    objects = Dict{Int, Int}()
    morphisms = Dict{Tuple, Tuple}()
    objects[source] = target
    triangle_dom, triangle_cod = source_triangle_images
    add_edge!(_target_category, target, triangle_dom)
    add_edge!(_target_category, target, triangle_cod)
    add_edge!(_target_category, triangle_dom, triangle_cod)
    morphisms[(source, triangle_dom)] = (target, triangle_dom)
    morphisms[(source, triangle_cod)] = (target, triangle_cod)
    morphisms[(triangle_dom, triangle_cod)] = (triangle_dom, triangle_cod)
    
    return (_target_category, Functor(objects, morphisms))
end

end # BMFBuilder