# pytorch3d の join_meshes_as_scene が `All meshes in the batch must have the same type of texture.` / `All textures must have the same sampling_mode.` で止まる

## 症状

部品ごとに色の付け方を変えて 1 つの場面にまとめようとすると:

```python
scene = join_meshes_as_scene([mesh_with_TexturesUV, mesh_with_TexturesVertex])
```

```
ValueError: All meshes in the batch must have the same type of texture.
```

TexturesUV どうしでも、`sampling_mode` が違うと（片方だけ `"nearest"`）:

```
ValueError: All textures must have the same sampling_mode.
```

## 原因

join は同じ種類のテクスチャしか結合できない（TexturesUV は 1 枚のアトラスへ詰め直して結合するので、種類と取り方をそろえる必要がある）。
大きさの違うテクスチャ（2048 と 4096 など）は TexturesUV どうしなら結合できる。

## 解決策

種類と取り方をそろえる。単色にしたい部品は、TexturesVertex ではなく単色の小さな TexturesUV にする:

```python
tex = torch.full((1, 8, 8, 3), 0.55, device=dev)                       # 灰色 1 色
uv = torch.full((len(verts), 2), 0.5, device=dev)
gray = Meshes(verts=[v], faces=[f], textures=TexturesUV(maps=tex, faces_uvs=[f], verts_uvs=[uv], align_corners=False))
```

最近傍で取りたいときは、結合するすべての TexturesUV に同じ `sampling_mode="nearest"` を渡す。
