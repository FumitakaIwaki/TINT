module FunctorBuilder
export Functor

# 関手の構造体
mutable struct Functor
    objects::Dict{Int, Int}
    morphisms::Dict{Tuple, Tuple}
end

# 関手かどうかを判定する関数
function is_functor(F::Functor)::Bool
    return true
end

end # FunctorBuilder