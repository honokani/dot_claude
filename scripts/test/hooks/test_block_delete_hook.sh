#!/bin/bash
# Test: pre-tool-block-delete.sh — 削除系コマンドを exit 2 で止め、ほかは通す（issue #20）
# Usage: bash ~/.claude/scripts/test/hooks/test_block_delete_hook.sh
# PreToolUse で止まるのは exit 2 だけ（exit 1 は止めない）なので、終了コードそのものを確かめる

set -uo pipefail

HOOK="$HOME/.claude/scripts/hooks/pre-tool-block-delete.sh"
PASS=0
FAIL=0

check() {  # check <expected exit> <label> <tool_name> <command>
  local json got
  json=$(jq -cn --arg t "$3" --arg c "$4" '{tool_name: $t, tool_input: {command: $c}}')
  printf '%s' "$json" | bash "$HOOK" >/dev/null 2>&1
  got=$?
  if [ "$got" = "$1" ]; then
    PASS=$((PASS + 1))
    echo "  PASS: $2"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL: $2 (expected $1, got $got)"
  fi
}

echo "=== 止めるもの（exit 2）"
check 2 "rm"                                   Bash 'rm foo.txt'
check 2 "rm after &&"                          Bash 'cd build && rm -rf out'
check 2 "rm in a subshell"                     Bash '(rm foo.txt)'
check 2 "PowerShell Remove-Item in quotes"     Bash 'powershell -Command "Remove-Item foo.txt"'
check 2 "pwsh del in single quotes"            Bash "pwsh -c 'del foo.txt'"
check 2 "cmd del"                              Bash 'cmd /c del foo.txt'
check 2 "rd at the end"                        Bash 'echo rd'
check 2 "find -delete"                         Bash 'find . -name "*.tmp" -delete'
check 2 "xargs rm"                             Bash 'ls | xargs rm'
check 2 "xargs -0 rm -f"                       Bash 'find . -name "*.tmp" -print0 | xargs -0 rm -f'
check 2 "xargs -I{} rm"                        Bash 'ls | xargs -I{} rm {}'
check 2 "xargs -n 1 rm (flag with a value)"    Bash 'ls | xargs -n 1 rm'
check 2 "xargs rmdir"                          Bash 'ls -d */ | xargs rmdir'
check 2 "xargs sh -c rm (direct rule)"         Bash "ls | xargs -I{} sh -c 'rm {}'"
check 2 "find -delete followed by ;"           Bash 'find . -name "*.tmp" -delete; echo done'
check 2 "PowerShell tool Remove-Item"          PowerShell 'Remove-Item foo.txt'
check 2 "PowerShell tool alias ri"             PowerShell 'ri foo.txt'

echo "=== 通すもの（exit 0）"
check 0 "git status"                           Bash 'git status'
check 0 "grep for the word del"                Bash 'grep -n "del" notes.txt'
check 0 "rm inside words"                      Bash 'npm run format && echo firmware riddle'
check 0 "mv to _gomi"                          Bash 'mv a.txt _gomi/'
check 0 "xargs stat --format"                  Bash 'ls *.log | xargs stat --format="%s %n"'
check 0 "xargs grep permission"                Bash 'git ls-files | xargs grep -l "permission denied"'
check 0 "xargs -n 1 stat --format"             Bash 'ls | xargs -n 1 stat --format=%s'
check 0 "rmeta in a comment after xargs"       Bash 'find . -name "*.rlib" | xargs du -ch   # rmeta is elsewhere'
check 0 "find pattern containing -delete"      Bash 'find /var/log -name "*-deleted*" -print'
check 0 "docker run --rm"                      Bash 'docker run --rm -it python:3.12 python -V'

echo "passed $PASS, failed $FAIL"
[ "$FAIL" = 0 ]
