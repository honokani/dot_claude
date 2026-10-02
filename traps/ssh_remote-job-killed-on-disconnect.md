# ssh で起動した長いジョブが、接続が切れると一緒に止まる（`client_loop: send disconnect: Connection reset by peer`、exit 255）

## 症状

```sh
ssh host 'cd ~/proj && python long_job.py 2>&1 | grep -v Warning'      # 数十分かかる
```

途中で回線が切れる・ノートPCが眠ると、手元に

```
client_loop: send disconnect: Connection reset by peer
```

が出て exit 255。リモートの `ps` を見ると `long_job.py` も消えている（途中までの結果も失われる）。

## 原因

`ssh host '<cmd>'` で起動したプロセスは ssh セッションに属する。接続が切れるとセッションが閉じ、
子プロセスに SIGHUP が届いて終了する。`run_in_background` で手元側を背景にしても、リモート側は守られない。

## 解決策

リモート側でセッションから切り離して起動し、ログをファイルに書く。結果は後から読む。

```sh
ssh host 'cd ~/proj && setsid nohup python long_job.py > job.log 2>&1 < /dev/null & sleep 1; pgrep -f "[l]ong_job.py"'
ssh host 'tail -5 ~/proj/job.log'          # 進み具合（何度でも）
```

- `setsid`: 新しいセッションにして SIGHUP を受けない。`nohup` と `< /dev/null` で端末から完全に切り離す
- grep などで出力を絞るときは、リモートのログに全部書いてから読む側で絞る（パイプの途中はバッファされ、切断で消える）

## 備考: 待ち合わせの `pgrep -f` は自分自身に当たる

```sh
until ssh host '! pgrep -f long_job.py'; do sleep 20; done     # 終わらない
```

`ssh host '<cmd>'` はリモートで `zsh -c '<cmd>'`（または bash）を起動し、その引数に `long_job.py` が含まれるため、
`pgrep -f long_job.py` は待ち合わせの shell 自身に必ず当たる。文字クラスで自分を外す:

```sh
until ssh host '! pgrep -f "[l]ong_job.py"'; do sleep 20; done
```

（正規表現 `[l]ong_job.py` は `long_job.py` に当たるが、自分のコマンド行の文字列 `[l]ong_job.py` には当たらない）
