# insteadOf の接頭辞置換で org 名が消えて Repository not found

## 症状

SSH 認証は成功する（`ssh -T git@<alias>` → `Hi <user>!`）のに、clone/ls-remote が:

```
ERROR: Repository not found.
fatal: Could not read from remote repository.
```

## 原因

`url.<base>.insteadOf` は**接頭辞の文字列置換**。置換先に org/パス部分を含めないと、マッチした接頭辞ごと消える。

```ini
# NG: git@github.com:myorg/repo.git → github-work:repo.git（myorg/ が消える）
[url "github-work:"]
	insteadOf = git@github.com:myorg/
```

`GIT_TRACE=1 git ls-remote <URL>` で実際に実行される `git-upload-pack '<path>'` を見ると、パスから org が落ちているのが観測できる。

## 解決

置換先にも org を含める（マッチ接頭辞と置換先を1対1対応させる）:

```ini
# OK: git@github.com:myorg/repo.git → github-work:myorg/repo.git
[url "github-work:myorg/"]
	insteadOf = git@github.com:myorg/
	insteadOf = ssh://git@github.com/myorg/
```

回避策（config を直さない場合）: remote URL を書き換え対象にならない直接エイリアス形式
`github-work:myorg/repo.git` で登録する。

## 診断手順

1. `ssh -T git@<alias>` — 鍵・認証の問題かを切り分け（Hi が出れば認証は OK）
2. `GIT_TRACE=1 git ls-remote <URL> 2>&1 | grep upload-pack` — git が実際に投げるパスを確認
3. パスに org が無ければ insteadOf の接頭辞飲み込み
