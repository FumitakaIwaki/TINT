using DataFrames
using Combinatorics

struct SampleData
    N::Int64
    adjmx::Matrix{Float64}
    edgelist::DataFrame
    images::Matrix{Int64}
    A::Int64
    B::Int64
    A_adjmx::Matrix{Float64}
    B_adjmx::Matrix{Float64}
    A_triangle_adjmx::Matrix{Float64}
    B_triangle_adjmx::Matrix{Float64}
    function SampleData()
        N = 8
        A = 1
        B = 2
        # 潜在圏の隣接行列
        adjmx = [
            1.0 0.5 0.5 0.5 0.5 0.5 0.5 0.5;
            0.5 1.0 0.5 0.5 0.5 0.5 0.5 0.5;
            0.5 0.5 1.0 0.5 0.5 0.9 0.5 0.5;
            0.5 0.5 0.5 1.0 0.5 0.5 0.9 0.5;
            0.5 0.5 0.5 0.5 1.0 0.5 0.5 0.9;
            0.5 0.5 0.5 0.5 0.5 1.0 0.5 0.5;
            0.5 0.5 0.5 0.5 0.5 0.5 1.0 0.5;
            0.5 0.5 0.5 0.5 0.5 0.5 0.5 1.0;
        ]
        # 潜在圏の辺リスト
        edgelist = zeros(N*(N-1), 3)
        for (i, (dom, cod)) in enumerate(permutations([i for i in 1:N], 2))
            edgelist[i, 1] = dom
            edgelist[i, 2] = cod
            edgelist[i, 3] = adjmx[dom, cod]
        end
        edgelist = DataFrame(edgelist, [:from, :to, :weight])
        edgelist.from = Int64.(edgelist.from)
        edgelist.to = Int64.(edgelist.to)
        # 初期イメージ
        images = [
            1 3;
            1 4;
            1 5;
            2 6;
            2 7;
            2 8;
        ]
        # 喩辞の初期イメージ (構造無視)
        A_adjmx = [
            1 0 1 1 1 0 0 0;
            0 0 0 0 0 0 0 0;
            0 0 1 0 0 0 0 0;
            0 0 0 1 0 0 0 0;
            0 0 0 0 1 0 0 0;
            0 0 0 0 0 0 0 0;
            0 0 0 0 0 0 0 0;
            0 0 0 0 0 0 0 0;
        ]
        # 被喩辞の初期イメージ (構造無視)
        B_adjmx = [
            0 0 0 0 0 0 0 0;
            0 1 0 0 0 1 1 1;
            0 0 0 0 0 0 0 0;
            0 0 0 0 0 0 0 0;
            0 0 0 0 0 0 0 0;
            0 0 0 0 0 1 0 0;
            0 0 0 0 0 0 1 0;
            0 0 0 0 0 0 0 1;
        ]
        # 喩辞の初期イメージ (構造考慮)
        A_triangle_adjmx = [
            1 0 1 1 0 0 0 0;
            0 1 0 0 0 0 0 0;
            0 0 1 1 0 0 0 0;
            0 0 0 1 0 0 0 0;
            0 0 0 0 1 0 0 0;
            0 0 0 0 0 1 0 0;
            0 0 0 0 0 0 1 0;
            0 0 0 0 0 0 0 1;
        ]
        # 被喩辞の初期イメージ (構造考慮)
        B_triangle_adjmx = [
            1 0 0 0 0 0 0 0;
            0 1 0 0 0 1 1 1;
            0 0 1 0 0 0 0 0;
            0 0 0 1 0 0 0 0;
            0 0 0 0 1 0 0 0;
            0 0 0 0 0 1 1 1;
            0 0 0 0 0 1 1 1;
            0 0 0 0 0 1 1 1;
        ]
        new(
            N, adjmx, edgelist, images,
            A, B,
            A_adjmx, B_adjmx,
            A_triangle_adjmx, B_triangle_adjmx
        )
    end
end