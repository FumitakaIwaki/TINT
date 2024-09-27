module SampleDataLoader
export SampleData

using Combinatorics

struct SampleData
    N::Int64
    adjmx::Matrix{Float64}
    edgelist::Matrix{Float64}
    images::Matrix{Int64}
    source::Int64
    target::Int64
    source_adjmx::Matrix{Float64}
    target_adjmx::Matrix{Float64}
end

function get_sample()
    N = 8
    source = 1
    target = 2
    # 潜在圏の隣接行列
    adjmx = [
        0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5;
        0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5;
        0.5 0.8 0.5 0.5 0.5 0.5 0.5 0.5;
        0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5;
        0.5 0.2 0.5 0.5 0.5 0.5 0.5 0.5;
        0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5;
        0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5;
        0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5;
    ]
    # 潜在圏の辺リスト
    edgelist = zeros(N*(N-1), 3)
    for (i, (dom, cod)) in enumerate(permutations([i for i in 1:N], 2))
        edgelist[i, 1] = dom
        edgelist[i, 2] = cod
        edgelist[i, 3] = adjmx[dom, cod]
    end
    # 初期イメージ
    images = [
        1 3;
        1 4;
        1 5;
        2 6;
        2 7;
        2 8;
    ]
    # 喩辞の初期イメージ
    source_adjmx = [
        0.5 0.0 0.5 0.5 0.5 0.0 0.0 0.0;
        0.0 0.5 0.0 0.0 0.0 0.0 0.0 0.0;
        0.0 0.0 0.5 0.0 0.0 0.0 0.0 0.0;
        0.0 0.0 0.0 0.5 0.0 0.0 0.0 0.0;
        0.0 0.0 0.0 0.0 0.5 0.0 0.0 0.0;
        0.0 0.0 0.0 0.0 0.0 0.5 0.0 0.0;
        0.0 0.0 0.0 0.0 0.0 0.0 0.5 0.0;
        0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.5;
    ]
    # 被喩辞の初期イメージ
    target_adjmx = [
        0.5 0.0 0.0 0.0 0.0 0.0 0.0 0.0;
        0.0 0.5 0.0 0.0 0.0 0.5 0.5 0.5;
        0.0 0.0 0.5 0.0 0.0 0.0 0.0 0.0;
        0.0 0.0 0.0 0.5 0.0 0.0 0.0 0.0;
        0.0 0.0 0.0 0.0 0.5 0.0 0.0 0.0;
        0.0 0.0 0.0 0.0 0.0 0.5 0.0 0.0;
        0.0 0.0 0.0 0.0 0.0 0.0 0.5 0.0;
        0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.5;
    ]
    return SampleData(N, adjmx, edgelist, images, source, target, source_adjmx, target_adjmx)
end

end