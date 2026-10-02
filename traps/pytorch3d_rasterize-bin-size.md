# pytorch3d の rasterize_meshes が `bin_size too small, number of faces per bin must be less than 22` で止まる

## 症状

大きな画像（例: UV のアトラス 4096²）を `bin_size` を小さく指定してラスタライズすると:

```
ValueError: bin_size too small, number of faces per bin must be less than 22; got 64
```

（文言は「面の数」だが、実際は 1 辺の区画（bin）の数 = image_size / bin_size が 22 未満でないといけない、という意味）

また、区画に入りきらないと `Bin size was too small in the coarse rasterization phase. This caused an overflow` の警告が出て、面が欠ける。

## 原因

pytorch3d の粗いラスタライズは、画像を bin_size 四方の区画に分け、1 辺の区画の数に上限（22 未満）がある。
区画ごとに持てる面の数は `max_faces_per_bin`（既定は推定値）で、細かい面が密集すると溢れる。

## 解決策

```python
import numpy as np
bin_size = int(2 ** np.ceil(np.log2(max(image_size / 21, 1))))   # 4096 -> 256、2048 -> 128、512 -> 32
p2f, zbuf, bary, dists = rasterize_meshes(meshes, image_size=image_size, blur_radius=0.0, faces_per_pixel=2,
                                          bin_size=bin_size, max_faces_per_bin=num_faces,   # 溢れない（メモリは 区画数 × 面数 × 4B）
                                          perspective_correct=False, cull_backfaces=False)
```

- `bin_size=0` は区画を使わない素朴な方法（溢れないが、面が多いと非常に遅い）
- 4096²・面 100 万で `max_faces_per_bin=面数` にすると区画 16×16 → 約 1GB（GPU）

## 備考: faces_per_pixel ≥ 2 で重なりを調べると、辺の上の画素が両側に数えられる

隣り合う 2 つの三角形の共有する辺にちょうど画素の中心が乗ると、両方の三角形に数えられることがある（重なっていないのに「2 枚が覆う」）。
重なりを数えるときは、どちらかの三角形で重心座標の最小がほぼ 0 の画素を除く:

```python
inside_both = (p2f[0, ..., 0] >= 0) & (p2f[0, ..., 1] >= 0) \
    & (bary[0, ..., 0, :].min(-1).values > 1e-5) & (bary[0, ..., 1, :].min(-1).values > 1e-5)
```
