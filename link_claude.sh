#!/bin/bash
# dot_claude → ~/.claude/ シンボリックリンク設置
# dotfiles の link_dotfiles.sh と同系統

# Windows環境でのシンボリックリンク設定
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    export MSYS="${MSYS:+$MSYS:}winsymlinks:nativestrict"
    echo "INFO: Set MSYS=winsymlinks:nativestrict for proper symlink support"
fi

: "SET_BASE_PATH" && {
    PTH_D_BASE=$(cd "$(dirname "$0")" && pwd)
}

# 安全にシンボリックリンクを張る（dotfilesのlink_dotfile関数と同ロジック）
link_dotfile() {
    local target_path="$1"
    local source_path="$2"

    if [ -L "$target_path" ]; then
        rm "$target_path"
    elif [ -e "$target_path" ]; then
        echo "WARN: real $target_path exists already. backuped."
        mv "$target_path" "${target_path}_bk"
    fi

    ln -s "$source_path" "$target_path"

    if [[ -L "$target_path" ]]; then
        echo "INFO: Created symlink: $target_path -> $source_path"
    else
        echo "WARN: Symlink creation may have failed for: $target_path"
    fi
}

: "LINK_DOT_CLAUDE" && {
    # ~/.claude/ は Claude Code ランタイム領域（history.jsonl等が実ファイルで書かれる）
    mkdir -p "$HOME/.claude"

    # dot_claude 配下のトップレベル項目を個別リンク
    # ドットファイル（.git, .gitignore, .gitattributes）は glob で自動除外
    for item in "$PTH_D_BASE"/*; do
        [ -e "$item" ] || continue
        name=$(basename "$item")
        case "$name" in
            link_claude.sh|README.md)
                continue
                ;;
        esac
        link_dotfile "$HOME/.claude/$name" "$item"
    done
}
