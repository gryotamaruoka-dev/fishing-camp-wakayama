# プロジェクト内 CLAUDE.md（Direct-Build mode）

> このプロジェクトは **Claude Code Secure Sandbox**（ホストから隔離・送信先 allowlist 済みの
> Docker コンテナ）の中で動いています。`acceptEdits` モードでファイル編集はノンストップで進みます。

## 大原則：メインの Claude が直接書く

旧 Agent Quartet Harness（generator → designer → security-auditor → evaluator 連鎖）は
**廃止**しました。1案件 60分かかっていた根本原因が Agent 切替の context 構築コストだったため、
動画 (tckOndDPhm8 / Shin Coding Tutorial) の手法を導入：

- **メインの Claude が `index.html` / CSS / JS を直接書く**
- Agent は明確な副作用がある特殊用途のみ：
  - `image-curator` — 外部 API 連打が必要なとき
  - `smoke-evaluator` — smoke.sh の結果解釈支援
  - `planner` — typology 不一致の複雑案件のみ
  - `security-auditor` — `security_level: strict` の最終ゲートのみ
- Playwright MCP / `evaluator` Agent / `builder` Agent / `designer` Agent / `generator` Agent
  は **全て削除済み**

## 標準ワークフロー（10〜20分で完成）

```
1. @quick-spec        ← docs/spec.md と docs/spec.json を生成（10秒）
2. design-tokens 配置 ← cp .claude/skills/design-tokens/presets/<preset>.md docs/design-tokens.md
3. @image-curator     ← 旅行/レシピ等の固有名詞写真が必要な場合のみ
4. メイン Claude が実装  ← index.html / style.css / script.js を直接 Write
5. !python3 -m http.server 8080  ← Claude 内 bash で dev サーバー起動
6. bash scripts/smoke.sh http://localhost:8080  ← exit code で合否判定
7. 完了報告           ← URL / screenshots / 画像クレジット
```

途中でユーザー確認は出さない。**1案件 = 1完了報告**。

## 自動進行ルール

**ユーザーは最初の依頼を一度投げるだけ**。以後の全フェーズはメインの Claude が
自動で連続実行する。途中でユーザー確認を求めて停止してはならない。

例外（これ以外では止まらない）：
1. 全実装が smoke.sh で PASS → **最終完了報告**
2. 同一フェーズで修正ループが **3回連続で不合格** → 自動修正の限界として報告
3. 物理的に進めない情報不足
4. firewall が必要な通信をブロックしており allowlist 緩和判断が必要

## ファイル構成

```
SECURITY-BASELINE.md           # セキュア・バイ・デフォルト恒久ルール
scripts/
└── smoke.sh                   # 軽量評価スクリプト（15〜30秒）
docs/
├── spec.md                    # 製品仕様書（quick-spec が生成）
├── spec.json                  # smoke.sh の must_contain_text 等
├── design-tokens.md           # デザイントークン（design-tokens skill or 手書き）
├── design-references/         # 参考画像（任意）
├── images.json                # image-curator が生成（画像必要時のみ）
├── image-credits.md           # 画像クレジット集約
└── transcripts/               # YouTube文字起こし（youtube-transcript skill）
    └── <video_id>.md
```

`docs/sprints/` は **不使用**（Quartet Harness 廃止に伴い削除予定）。

## Slash コマンドの使いどころ

| コマンド | タイミング |
|---|---|
| `/rewind` | 失敗ループから抜けたい時、方向性を間違えた時 |
| `/batch` | N 個のコンポーネントに同じ変更、N ページ一括修正 |
| `/fewer-permission-prompts` | 許可ダイアログが頻発したら過去履歴から allowlist 拡張 |
| `/insights` | 月1で使い方分析 |

## ジャンル別の既定方針

### 旅行プラン / しおり系プロジェクト

ユーザー要件に「旅行」「しおり」「観光プラン」「○泊○日」等が含まれる場合、メイン
Claude は spec 段階で以下を Acceptance Criteria に織り込む（後付け修正禁止）:

1. **航空券は実勢価格** — WebSearch / WebFetch で運賃を確認。便名・運航日・JPYレンジ・
   出典URL・確認日を `docs/flight-research.md` に記録。「相場感」は禁止
2. **日程表はタイムラインカード** — `<ol class="itinerary-timeline">` + `<li class="timeline-card">`
3. **行動別の実写写真** — 固有名詞を含む行動には Wikimedia Commons の本物の写真。
   仮画像・抽象アイコンの代用は禁止。各プラン15個以上の画像付きカード
4. **持ち物・地図・実用情報** — パスポート/両替/電源/治安/通貨/為替/ベストシーズン +
   Google Maps 公式URL（`rel="noopener noreferrer" target="_blank"`）
5. **印刷向け A4 レイアウト** — `@media print` で写真非表示、A4 1〜2 ページ収納

### ダッシュボード系

- `linear.md` プリセット（ダーク基調・密度高め）が既定
- グラフは Chart.js (CDN) を使う。SVG 手書きは避ける
- カードは `--color-bg-subtle` の地色 + 1px border、shadow なし

### LP

- `resend.md` プリセット（白基調・余白多め）が既定
- ヒーロー → 機能3つ → 価格 → CTA の動線
- フォームは1つだけ（メアド or 名前+メアド）

## セキュリティ最優先

- 「Mock だから」「POC だから」を脆弱性を残す言い訳にしない
- 実装の判断基準はすべて `SECURITY-BASELINE.md` に従う
- 秘密情報をコードに**絶対に書かない**。`.env` を使い `.env.example` のみコミット
- 外部送信はサンドボックスの firewall で allowlist 制限。許可外ドメインへの通信が
  必要になったら、勝手に回避せずユーザーに報告する

## security_level の早見表

spec.md frontmatter で指定：

| 値 | 想定 | auditor |
|---|---|---|
| `light`（既定） | 旅行/レシピ/家庭用ページ/ノート（入力/認証/PII無し） | スキップ |
| `standard` | 顧客向けPOC・軽い入力フォームあり | 完了直前に @security-auditor を1回呼ぶ |
| `strict` | 認証/PII/本番公開 | @security-auditor 必須、不合格は再実装 |
