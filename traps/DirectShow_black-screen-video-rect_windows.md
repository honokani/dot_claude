# DirectShow で映像が真っ黒（音は出る・再生位置は進む）

## 症状

グラフは組めて再生位置も進むのに、ウィンドウが真っ黒で何も映らない。
エラーは一切出ない。`IBasicVideo::GetCurrentImage` は正しい色を返すので、
「デコードは出来ている」と分かるぶん余計に迷う。

## 原因

レンダラの**映像矩形（destination rect）が空**。

ウィンドウ矩形（`IVideoWindow::SetWindowPosition`）だけ設定して、
映像矩形（`IBasicVideo::SetDestinationPosition`）を設定していない。

レンダラは描画範囲を `videoRect ∩ windowRect` で決めるので、
videoRect が空だと交差も空になり、**正しいサイズのまま真っ黒**な面が提示される。

多くのレンダラは `SetDefaultDestinationPosition` で自動計算してくれるが、
実装していない（E_NOTIMPL の）レンダラがある。MPC Video Renderer がそれ。

## 解決

両方を設定する。

```rust
video_window.SetWindowPosition(x, y, w, h)?;          // IVideoWindow
basic_video.SetDestinationPosition(vx, vy, vw, vh)?;  // IBasicVideo ← これを忘れる
```

ウィンドウサイズ変更時も両方を呼び直すこと。

## 切り分け方が重要

**`GetCurrentImage` ではこの不具合を検出できない。** レンダラ内部の処理結果を返すためで、
画面が真っ黒でも正しい色が返る。

画面に本当に出ているかは**スワップチェーンのバックバッファ**を見る。
MPC Video Renderer なら `IExFilterConfig::Flt_GetBin("displayedImage")`。

GDI での画面取り込みは使えない。デスクトップ DC からの `BitBlt` も
`PrintWindow` + `PW_RENDERFULLCONTENT` も、DXGI スワップチェーンの内容には届かず
黒しか返さない。これを「映っていない証拠」と解釈すると誤診する。

## 関連（MPC Video Renderer 固有）

- `put_Owner` は内部で `Init(true)` を呼び、描画用の子ウィンドウを `CW_USEDEFAULT` で
  作った直後に D3D を初期化する。子ウィンドウへの `CW_USEDEFAULT` はサイズ 0 相当なので、
  **`SetWindowPosition` を `put_Owner` より先に**呼んで位置を確定させておく
- `put_WindowStyle` と `put_Visible` は E_NOTIMPL。スタイルはレンダラ自身が管理する
- 映像をホストする親ウィンドウには `WS_CLIPCHILDREN` を付ける
