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
6. キーボードから`]`を入力しパッケージモードにする
7. `% activate tint_prj`でプロジェクトを起動
8. `% instantiate`で必要なライブラリをインストール

#### シミュレーション設定
- シミュレーションの設定は`tint_prj/tint_config.yml`で管理
```yaml  tint_config.yml
object: # 構造無視の設定
  metaphor_set: [["蝶", "踊り子"]] # ベースとなる比喩のペア
  assoc_file: "tint_prj/data/three_metaphor_assoc_data.csv" # 連想確率データ
  image_file: "tint_prj/data/three_metaphor_images.csv" # 初期イメージのデータ
  out_dir: "tint_prj/out/" # 出力先ディレクトリ
  NN: 0 # 総イメージ数 (自動で変更されるので0でok)
  steps: 10000 # シミュレーション数
  search_method: "softmax" # 対応づけの手法 "deterministic": 決定論的 or "softmax": 確率論的
  softmax_beta: 1.0 # softmaxの逆温度パラメータ
  seed: 1234 # シード値
  verbose: true # プログレスバーを表示するか否か

triangle: # 三角構造考慮の設定
  metaphor_set: [["蝶", "踊り子"]]
  assoc_file: "tint_prj/data/three_metaphor_assoc_data.csv"
  image_file: "tint_prj/data/three_metaphor_images.csv"
  out_dir: "tint_prj/out/"
  NN: 0
  steps: 10000
  search_method: "softmax"
  softmax_beta: 1.0
  seed: 1234
  verbose: true
```

#### シミュレーション
1. VS Codeで`tint_prj/run_simulation.jl`を開く (ワークスペースは`TINT`)
2. 右上の▶︎をクリック
3. juliaのREPLが起動しコンパイルされる
4. シミュレーション実行
    - `% main()`: 構造無視，三角構造考慮両方のシミュレーションを実施
    - `% main(mode="object")`: 構造無視のシミュレーションを実施
    - `% main(mode="triangle")`: 三角構造考慮のシミュレーションを実施
    - `% main(config_file="path_to_my_config.yml")`: `tint_prj/tint_config.yml`とは別にconfigファイルを作成した場合，`TINT/`からの相対パスを入力することで適用できる

## 計算機での実行
to do

### 参考サイト  
> [AnacondaとJuliaをインストールしたDockerのコンテナを作るDockerfile](https://eqseqs.hatenablog.com/entry/2020/07/26/180318)
