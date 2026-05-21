# Desc

本次 review 的范围。比如：在 review 哪个 task、哪一轮、针对的具体 contract 文件路径等。

## Results

按 severity 分组。Blocker 和 High 任意出现一条都会让 verify 直接 FAIL；Minor 和 Nit 不阻塞。

### Blocker

阻塞性问题。出现就 verify FAIL。每条带具体的 file:line 和描述。

### High

高严重问题。出现就 verify FAIL。

### Minor

中度问题。不阻塞，但建议 doer 处理。

### Nit

建议性问题。不阻塞。

## Accepted Criteria

本 reviewer 签到通过的验收标准列表。

规则：
- 必须用 bf.md 或者 task spec.md 里原始的验收标准 id（比如 AC-1、AC-2）。
- 每条 AC 需要所有 required reviewer 都签到，才算 signed，bf-harness verify 才会翻 checkbox。
- 一份 reviewer 的 result 文件里如果出现了 Blocker 或 High，bf-harness 不会去看这一节的签到 —— 因为整轮已经 FAIL 了。

- {id1}: 一句话说明 reviewer 怎么验证通过的（怎么得出"这条满足了"的判断）
- {id2}: ...
