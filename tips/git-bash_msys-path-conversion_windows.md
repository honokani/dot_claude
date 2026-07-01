# git-bash(MSYS): `/`始まりの値がWindowsパスに化ける

## 問題
git-bash で `/` 始まりの引数・環境変数値をネイティブプログラム(node/npm/cargo 等)へ渡すと、
MSYS のパス変換が `/foo` を `C:/Program Files/Git/foo`（git 導入先ルート）に化けさせる。
**コマンド自体は成功(exit 0)する**ので気づきにくく、実行時に初めて壊れる。
→ **Bash はエラーを出さないので traps hook は発火しない**（traps は Bash 失敗時のみ）。tips 向き。

実例: `VITE_API_URL=/api npm run build` → ビルド成功だが、焼き込まれた値が
`C:/Program Files/Git/api` に。ブラウザの fetch が `file:///C:/Program Files/Git/auth/login`
へ飛び `(blocked:other)`（ローカルリソース扱いでブロック）。

## 解決
値を**ネイティブツールが直接読むファイル**に置き、シェルの env/argv を経由させない:
- 例: vite は `VITE_API_URL=/api` を `frontend/.env.production` に書く（Node がファイルを読む＝MSYS変換なし）

または変換を抑止:
- `MSYS_NO_PATHCONV=1 cmd ...`（argv のパス変換を無効化）
- `MSYS2_ARG_CONV_EXCL='*' cmd ...`（変換除外）
- 二重スラッシュ `//api`（先頭 `/` 判定を外すが値も変わるので非推奨）

## 見分け方
- 症状は「**シェルは成功、実行時（ブラウザ/ランタイム）で絶対パスやファイルURLが出る**」
- ビルド成果物を `grep -i 'Program Files/Git'` で混入検出できる
- `C:/Program Files/Git/...` や `/c/...`(MSYS形式) が想定外に出たら本件を疑う
