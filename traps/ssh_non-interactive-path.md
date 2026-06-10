# ssh non-interactive セッションでの PATH 問題

## 症状
`ssh <host> 'which uv'` のように、sshに直接コマンドを渡した場合、ユーザーが対話ログインで設定した `~/.local/bin` や pyenv / cargo などのPATH拡張が読まれず、ツールが「not found」になる。

## 原因
- `ssh <host> '<cmd>'` は **non-interactive, non-login** shell で起動する
- `.bashrc` / `.zshrc` は多くの場合「interactive shell のみ」のガード付き（`[[ $- != *i* ]] && return` 等）
- PATH拡張がそこに書かれていると、non-interactive session では読まれない

## 対処法（優先度順）

### 1. ツールはフルパスで呼ぶ（推奨：冪等で副作用なし）
```bash
ssh host '/home/user/.local/bin/uv --version'
```

### 2. PATHを明示して渡す
```bash
ssh host 'PATH=$HOME/.local/bin:$PATH uv --version'
```

### 3. ログインshellとして起動（`.profile` / `.zprofile` に設定があれば効く）
```bash
ssh host 'bash -lc "uv --version"'
ssh host 'zsh -lc "uv --version"'
```
ただし `.bashrc` にしかPATHを書いていない場合は効かない。

### 4. 恒久対策（remote側で設定）
`.zshenv` / `.bash_env` （non-interactive でも読まれるファイル）にPATHを書く。
```zsh
# ~/.zshenv
export PATH="$HOME/.local/bin:$PATH"
```
⚠️ `.zshenv` は全シェル起動時に読まれるので軽量な記述に限定すること。

## 確認方法
```bash
# リモート側でinteractive shellがどう拡張しているか
ssh host 'echo $PATH'                    # non-interactive の PATH
ssh host 'bash -lc "echo \$PATH"'        # login shell の PATH
```
両者が違う → `.bashrc` / `.zshrc` の interactive ガードが原因。

## よく踏むケース
- `uv`, `pipx`, `pyenv`, `nvm`, `cargo` など `~/.local/bin` / `~/.cargo/bin` にインストールされるユーザー系ツール
- Claude Code / CI / Ansible などの非対話実行環境全般

## 関連
- `python_uv_windows.md`: uv 自体のインストール
