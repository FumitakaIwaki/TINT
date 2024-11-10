using CSV
using DataFrames

# 自然変換の探索により得られた関手の記録媒体
abstract type AbstractRecorde end
# 構造無視
mutable struct ObjectRecorde <: AbstractRecorde
    counts::Dict{NTuple{4, Int}, Int}
    function ObjectRecorde(F::Dict{NTuple{2, Int}, NTuple{2, Int}})
        counts = Dict{NTuple{4, Int}, Int}()
        for ((B_dom, B_cod), (A_dom, A_cod)) in pairs(F)
            if B_dom != B_cod || A_dom != A_cod
                counts[(B_dom, B_cod, A_dom, A_cod)] = 1
            end
        end
        new(counts)
    end
end
# 構造考慮
mutable struct TriangleRecorde <: AbstractRecorde
    B_pair::NTuple{2, Int}
    counts::Dict{NTuple{4, Int}, Int}
    function TriangleRecorde(B_dom::Int, B_cod::Int, F::Dict{NTuple{2, Int}, NTuple{2, Int}})
        counts = Dict{NTuple{4, Int}, Int}()
        for ((B_dom, B_cod), (A_dom, A_cod)) in pairs(F)
            if B_dom != B_cod || A_dom != A_cod
                counts[(B_dom, B_cod, A_dom, A_cod)] = 1
            end
        end
        new((B_dom, B_cod), counts)
    end
end

# シミュレーション結果の記録媒体
# Recordeの総体
abstract type AbstractResult end
# 構造無視
mutable struct ObjectResult <: AbstractResult
    A::Int
    B::Int
    recorde::ObjectRecorde
end
# 構造無視の外部コンストラクタ
function Result(A::Int, B::Int, config::ObjectCfg)
    recordes = ObjectRecorde(Dict{NTuple{2, Int}, NTuple{2, Int}}())
    return ObjectResult(A, B, recordes)
end
# 構造考慮
mutable struct TriangleResult <: AbstractResult
    A::Int
    B::Int
    recordes::Dict{NTuple{2, Int}, TriangleRecorde}
end
# 構造考慮の外部コンストラクタ
function Result(A::Int, B::Int, config::TriangleCfg)
    recordes = Dict{NTuple{2, Int}, TriangleRecorde}()
    sizehint!(recordes, config.steps)
    return TriangleResult(A, B, recordes)
end

# Resultの更新をする関数
# 構造無視
function update_result!(result::ObjectResult, new_recorde::ObjectRecorde)
    for (correspondence, count) in pairs(new_recorde.counts)
        if haskey(result.recorde.counts, correspondence)
            result.recorde.counts[correspondence] += count
        else
            result.recorde.counts[correspondence] = count
        end
    end
end
# 構造考慮
function update_result!(result::TriangleResult, new_recordes::Vector{TriangleRecorde})
    for new_recorde in new_recordes
        B_pair = new_recorde.B_pair
        if haskey(result.recordes, B_pair)
            for (correspondence, count) in pairs(new_recorde.counts)
                if haskey(result.recordes[B_pair].counts, correspondence)
                    result.recordes[B_pair].counts[correspondence] += count
                else
                    result.recordes[B_pair].counts[correspondence] = count
                end
            end
        else
            result.recordes[B_pair] = new_recorde
        end
    end
end

# Resultを保存する関数
# 構造無視
function save_result(result::ObjectResult, config::ObjectCfg, idx2img::Vector{String})
    dir = string(config.out_dir, "object/")
    if !isdir(dir)
        mkdir(dir)
    end
    A = idx2img[result.A]
    B = idx2img[result.B]
    recorde = result.recorde
    file = string("object_", A, "_", B, ".csv")
    df = DataFrame(
        B_dom = [idx2img[x[1]] for x in keys(recorde.counts)],
        B_cod = [idx2img[x[2]] for x in keys(recorde.counts)],
        A_dom = [idx2img[x[3]] for x in keys(recorde.counts)],
        A_cod = [idx2img[x[4]] for x in keys(recorde.counts)],
        count = [x for x in values(recorde.counts)],
        probability = values(recorde.counts) ./ config.steps,
        )
    sort!(df, [:B_dom, :B_cod, :A_dom, :A_cod])
    path = string(dir, file)
    CSV.write(path, df, header=true)
end
# 構造考慮
function save_result(result::TriangleResult, config::TriangleCfg, idx2img::Vector{String})
    dir = string(config.out_dir, "triangle/")
    if !isdir(dir)
        mkdir(dir)
    end
    A = idx2img[result.A]
    B = idx2img[result.B]
    for (B_pair, recorde) in pairs(result.recordes)
        B_dom = idx2img[B_pair[1]]
        B_cod = idx2img[B_pair[2]]
        file = string("triangle_", A, "_", B, "_", B_dom, "_", B_cod, ".csv")
        df = DataFrame(
            B_dom = [idx2img[x[1]] for x in keys(recorde.counts)],
            B_cod = [idx2img[x[2]] for x in keys(recorde.counts)],
            A_dom = [idx2img[x[3]] for x in keys(recorde.counts)],
            A_cod = [idx2img[x[4]] for x in keys(recorde.counts)],
            count = [x for x in values(recorde.counts)],
            probability = values(recorde.counts) ./ config.steps,
            )
        sort!(df, [:B_dom, :B_cod, :A_dom, :A_cod])
        path = string(dir, file)
        CSV.write(path, df, header=true)
    end
end