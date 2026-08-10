# LoadLibrary が 0x800736B1（サイド バイ サイド構成が正しくない）で失敗する

## 症状

`LoadLibrary` / `LoadLibraryEx` / COM の `CoCreateInstance` が次で失敗する。

```
HRESULT(0x800736B1) ERROR_SXS_CANT_GEN_ACTCTX
「このアプリケーションのサイド バイ サイド構成が正しくないため、アプリケーションを開始できませんでした」
```

## 原因

VC++ ランタイム不足と間違えやすいが、別物。DLL の**埋め込みマニフェスト**が
プライベート side-by-side アセンブリへの依存を宣言していて、それが見つかっていない。

## 診断（推測せず実物を見る）

埋め込みマニフェストはバイナリ内に平文 XML で入っているので直接読める。

```bash
grep -a -o '<assembly[^>]*>.\{0,600\}' TARGET.dll | head -c 1500
```

```xml
<dependency><dependentAssembly>
  <assemblyIdentity type="win32" name="Foo.Dependencies" version="1.0.0.0"/>
</dependentAssembly></dependency>
```

この `name` が要求されているアセンブリ名。

## 解決

`<name>.manifest` と、その中で列挙される DLL 群を揃える。Windows の探索順は

- `<dir>\<name>.manifest`（フラット配置）
- `<dir>\<name>\<name>.manifest`（サブフォルダ配置）

の**両方**を見るので、どちらでもよい。配布物からファイルを拾うときに
`.manifest` を取りこぼすのが典型的な事故。DLL だけ集めても動かない。

## 実例

LAV Filters を regsvr32 せず `LoadLibraryEx` で直接ロードする構成で発生。
`LAVSplitter.ax` が `LAVFilters.Dependencies` を要求しており、
`LAVFilters.Dependencies.manifest` と `av*-lav-*.dll` 一式が必要だった。

## 関連

- 依存 DLL が同一フォルダにある場合、`LoadLibraryEx` には
  `LOAD_WITH_ALTERED_SEARCH_PATH` が必須（無いと依存 DLL を解決できない）
