# 不定自然変換理論 (Theory of Indeterminate Natural Transformation: TINT)
不定自然変換理論 (TINT) のシミュレーションプログラム

## TINTについて
to do: 論文の引用と軽い説明

## 実行方法
### 環境
- Julia 1.10.4
- Visual Studio Code 1.91.1 (Universal)
### 手順
#### 環境構築
1. JuliaとVisual Studio Codeのインストール
2. VS CodeでJuliaの設定
3. このリポジトリをcloneしディレクトリに移動
5. `% julia`でJuliaを起動
6. キーボードで`]`を入力しパッケージモードにする
7. `% activate tint_prj`でプロジェクトを起動
8. `% instantiate`で必要なライブラリをインストール
#### シミュレーション
1. VS Codeで`tint_prj/src/run.jl`を開く (VS Codeで開くディレクトリは`TINT`)
2. 右上の▶︎をクリック
3. juliaのREPLが起動しシミュレーションが実行される

## 計算機での実行
### 参考サイト  
> [AnacondaとJuliaをインストールしたDockerのコンテナを作るDockerfile](https://eqseqs.hatenablog.com/entry/2020/07/26/180318)