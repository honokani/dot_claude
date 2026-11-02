# 時間切れで裏に回したコマンドを止めても、パイプの中の grep.exe が残って CPU を使い続ける — Bash ツール（Windows / git bash）

## 症状

- Bash ツールのコマンドが時間内（既定 120 秒）に終わらないと、止まらずに裏へ回される: `Command did not complete within its 120s timeout and was moved to the background (ID: …)`
- そのあと裏の仕事が止められても（task-notification の `<status>killed</status>`）、パイプの先頭の grep.exe が残って動き続けた。エラーは出ない
- 気づかないと、何時間も CPU のコアを1つ使い続ける。その間に測った時間はのびる

## 観測（2026-11-02〜03, pj_traincolor, GNU grep 3.0, Git for Windows の bash）

| 時刻（UTC） | 起きたこと |
|---|---|
| 11-02 06:31:55 | この会話の記録ファイル（.jsonl、536MB・約3.6万行）に `grep -o "[^\"]\{0,300\}<日本語のフォルダ名>/[^\"]\{0,200\}" f \| grep -v … \| grep … \| tail -6 \| cut -c1-600` を出した |
| 06:33:57 | 120 秒で終わらず、裏へ回された（TaskStop はしなかった） |
| 11:51:14 | メモリ不足で Claude Code が裏の仕事を止めた（`killed`） |
| 18:21:43 | CPU 使用率 32%。grep.exe（PID 3968、作られたのは 06:31:56）の CPU 時間が 36,568 秒。コマンドラインは上の grep。親の PID 29720 を引いても何も出なかった |
| 18:22:18 | `taskkill //PID 3968 //F` は auto mode の判定で断られた（`[Interfere With Workloads]`） |
| 11-02 19:3x | もう無かった |

## 原因

1. Bash ツールの時間切れは、コマンドを止めずに裏へ回す（メッセージのとおり）
2. 裏の仕事を止めても、パイプの中の grep.exe までは止まらなかった（観測）。親の bash が先に消えて、子だけが残ったと見ている（推測）
3. grep が終わらなかったのは、先頭が `[^"]\{0,300\}` の `-o` に日本語を混ぜて、長い行が並ぶ大きいファイルにかけたため（推測。11 時間 50 分たっても終わっていなかった）

## 回避策

1. **長くかかりそうなコマンドは `timeout N` で包む**。`timeout 2 yes | wc -l` は 2〜3 秒で止まり、yes.exe は残らなかった（2026-11-03）。ただし、同じパイプの後ろの `wc` も `Terminated` になり、何も出力しなかった。途中までの結果が要るなら、ファイルに書かせる
2. **この会話の記録（`~/.claude/projects/**/*.jsonl`）のような大きいファイルを grep で探さない**。Grep の道具（ripgrep）か、Python で1行ずつ読む（`json.loads` して tool_use・tool_result だけを見る）。この bash には `rg` が無い（`timeout: failed to run command 'rg': No such file or directory`）
3. 「moved to the background」が出て、もう要らないなら、すぐ TaskStop する。止めたあと、子が残っていないかを見る（TaskStop で子まで止まるかは確かめていない）:

   ```bash
   powershell -NoProfile -Command 'Get-Process | Sort-Object CPU -Descending | Select-Object -First 8 Name, Id, @{n="CPU_s"; e={[int]$_.CPU}}'
   powershell -NoProfile -Command 'Get-CimInstance Win32_Process -Filter "ProcessId=<PID>" | Select-Object ParentProcessId, CreationDate, CommandLine | Format-List'
   ```

4. 自分の置き去りのプロセスを止めようとして断られたら、その場でユーザーに伝える（作業の終わりまで待たない）。打ってもらうのは `! powershell -NoProfile -Command "Stop-Process -Id <PID> -Force"`（bash でも PowerShell でも同じ書き方で通るはず。試していない）か、タスクマネージャー
