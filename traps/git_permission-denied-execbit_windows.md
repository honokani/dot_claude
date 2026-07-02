# Windows で commit した .sh が Linux で permission denied (126)

## 症状

Windows で作成・commit したシェルスクリプトを Linux 側で clone/pull して実行すると:

```
zsh:1: permission denied: ./build.sh
（exit code 126）
```

## 原因

Windows のファイルシステムに実行ビットが無いため、git の index に **100644（非実行）** で記録される。
Linux checkout はそのモードを再現するので `./xxx.sh` が実行不可になる。
`bash xxx.sh` なら動くため、動作確認をそれで済ませていると気づかない。

## 解決

Windows 側で index のモードを直接変更して commit する（作業ツリーに触らない）:

```bash
git update-index --chmod=+x build.sh daemonctl.sh   # 対象の .sh を列挙
git ls-files -s -- '*.sh'                           # 100755 になったことを確認
git commit -m "chore(git): .sh に実行ビットを付与"
```

- 確認: `git ls-files -s -- '*.sh'` が `100755` を示せば OK（`ls -l` では Windows 上で判別できない）
- 新規 .sh を作るたびに再発するので、Linux で実行するスクリプトを追加したら commit 前に `git ls-files -s` を見る癖をつける

## 関連

- 改行コード（CRLF）も同種の Windows→Linux 罠。`.gitattributes` に `*.sh text eol=lf` を置いて防ぐ
