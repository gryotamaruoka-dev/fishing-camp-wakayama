# Warm Magazine Design Tokens

旅行のしおり・レシピサイトに合う、暖色寄りの雑誌風デザイン。

## カラー

```css
:root {
  --color-bg: #fdfaf4;
  --color-bg-subtle: #f7f1e6;
  --color-bg-muted: #efe6d3;
  --color-border: #d9cdb4;
  --color-border-strong: #b8a682;

  --color-text: #2b1e10;
  --color-text-muted: #6e5b3f;
  --color-text-subtle: #9a8865;

  --color-accent: #c2410c;     /* 暖色アクセント (terra) */
  --color-accent-hover: #9a330a;
  --color-accent-fg: #fdfaf4;

  --color-secondary: #166534;   /* 深緑（リーフ） */
  --color-link: #b45309;
}
```

## タイポグラフィ

- 見出し: `'Noto Serif JP', 'Playfair Display', serif` / 700
- 本文: `'Noto Sans JP', system-ui, sans-serif` / 400 / 1.7（読みやすさ重視）
- ヒーロー見出し: 48〜64px / serif / -0.02em
- セクション見出し: 28〜36px / serif

## レイアウト

- 最大幅 800〜960px（読み物寄り）
- カラム間 padding 大きめ
- カード: 角丸 8px、subtle な shadow、写真は4:3 か 3:2 で大きめに

## 装飾

- 見出しの下に1〜2px のアクセントカラー underline
- セクション区切りは `<hr>` を `--color-border-strong` で

## NG

- ネオン色・冷色アクセント
- 紫グラデ
- 高密度カードグリッド（雑誌っぽさが失われる）

## 推奨スニペット

- `hero/photo-overlay.html`
- `timeline/itinerary.html`
- `checklist/packing.html`
- `card-grid/2-col-photo.html`
