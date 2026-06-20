# translate.qcheck.md

## context
sample: newslog_auto/最新3日分から 評価値 >= 3 の記事を10件、`title_raw` と `title_ja` のペアを取得

## checks
- [ ] title_ja が原文の意味を保っているか
- [ ] 文末が不自然に切れていないか（語尾欠落・助詞止め等）
- [ ] 専門用語（transformer, embedding, fine-tuning 等）が文脈に合った訳になっているか
- [ ] 日本語として読みやすい語順か
