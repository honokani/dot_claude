# robocopy — 集計行のラベルがコンソール出力エンコーディング既定（cp932）では日本語になり、英語「Bytes」固定の解析が外れて 0／-1 を返す

## 症状
- PowerShell から `robocopy <src> <dst> /L /S /BYTES /NJH ...` の出力を取り込み、`$_ -match '^\s*Bytes\s*:'` で合計バイトを拾う関数が、管理者権限（`Start-Process -Verb RunAs`）で起動した別プロセスでだけ全件 -1（該当行なし）になった（2026-10-23、Windows 11 25H2、PowerShell 5.1、日本語 UI）
- 権限の問題ではない。既定の `[Console]::OutputEncoding`（shift_jis）では robocopy の集計行が `ディレクトリ:` `ファイル:` `バイト:` `時刻:` と日本語で出る。`[Console]::OutputEncoding = [System.Text.Encoding]::UTF8` を先に実行したプロセスでは同じコマンドが `Dirs :` `Files :` `Bytes :` `Times :` と英語になる（同一スクリプト内で切り替えて再現）
- 非昇格側のスクリプトは冒頭で UTF8 を設定していたため英語で動き、昇格側はその行を省いたため日本語になって解析が外れた。UAC のやり直しが 2 回増えた

## 原因
- robocopy の表示言語がコンソールの出力コードページに連動する（UTF-8 のときは英語になる）。言語の切り替わりは観測事実、仕組みの説明は推測
- 英語ラベル固定の解析は、コードページ次第で例外なしに空振りする

## 対処
1. robocopy を呼ぶ PowerShell プロセスごとに、冒頭で `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8` を設定する（昇格プロセス、`powershell -Command` の別起動、サブエージェントが書くスクリプトも毎回）
2. ラベルに依存しない解析を併用する。集計行は Dirs／Files／Bytes／Times の順で固定なので、数値で始まる集計行の 3 行目を取る: `$rows = @($out | Where-Object { $_ -match '^\s*\S+\s*:\s*\d' }); $bytesRow = $rows[2]`
3. 検証: `robocopy C:\PerfLogs C:\__nonexistent__ /L /S /BYTES /NJH /NFL /NDL` を UTF8 設定の前後で実行し、集計行のラベルの言語を見る
