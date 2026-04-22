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

# 安全にシンボリックリンクを張る（冪等性対応）
link_dotfile() {
    local target_path="$1"
    local source_path="$2"

    # 既に正しいsymlinkならスキップ（冪等性）
    if [ -L "$target_path" ]; then
        local current_target
        current_target=$(readlink "$target_path")
        # パス末尾の / 差異を吸収して比較
        if [ "${current_target%/}" = "${source_path%/}" ]; then
            echo "INFO: Already linked: $target_path -> $source_path"
            return 0
        fi
        # 違う先を指しているsymlinkは削除
        rm "$target_path"
    elif [ -e "$target_path" ]; then
        # 実体がある場合、_bk に退避（既存の_bkがあれば連番）
        local bk="${target_path}_bk"
        local i=1
        while [ -e "$bk" ]; do
            bk="${target_path}_bk${i}"
            i=$((i + 1))
        done
        echo "WARN: real $target_path exists already. backup to ${bk}"
        if ! mv "$target_path" "$bk"; then
            echo "ERROR: Failed to backup $target_path (possibly locked by another process)"
            return 1
        fi
    fi

    # -n で既存ディレクトリ先への副作用リンク作成を防ぐ
    if ln -sn "$source_path" "$target_path"; then
        echo "INFO: Created symlink: $target_path -> $source_path"
    else
        echo "ERROR: Symlink creation failed for: $target_path"
        return 1
    fi
}

: "LINK_DOT_CLAUDE" && {
    # ~/.claude/ は Claude Code ランタイム領域（history.jsonl等が実ファイルで書かれる）
    mkdir -p "$HOME/.claude"

    # dot_claude 配下のトップレベル項目を個別リンク
    # ドットファイル（.git, .gitignore, .gitattributes）は glob で自動除外
    ret=0
    for item in "$PTH_D_BASE"/*; do
        [ -e "$item" ] || continue
        name=$(basename "$item")
        case "$name" in
            link_claude.sh|README.md)
                continue
                ;;
        esac
        if ! link_dotfile "$HOME/.claude/$name" "$item"; then
            ret=1
        fi
    done
    exit $ret
}
