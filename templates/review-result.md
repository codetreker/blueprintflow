# Desc

本次 review 的范围。比如：在 review 哪个 task、哪一轮、针对的具体 contract 文件路径等。

## Results

按 severity 分组。Blocker 和 High 任意出现一条都会让 verify 直接 FAIL；Minor 和 Nit 不阻塞。

### Blocker

阻塞性问题。出现就 verify FAIL。每条带具体的 file:line 和描述。

### High

高严重问题。出现就 verify FAIL。

### Minor

中度问题。不阻塞，但建议负责的 actor 处理。

### Nit

建议性问题。不阻塞。

## Accepted Criteria

本 reviewer 签到通过的验收标准列表。

规则：
- 必须用 bf.md 或者 task spec.md 里原始的验收标准 id（比如 AC-1、AC-2）。
- Task Verification / Final Acceptance 中，如果本轮没有 Blocker 或 High，
  at least one provider-role review file 接受某条 AC id，bf-harness verify
  就会把这条 AC 视为 signed。
- Spec Review 和某些流程可能要求多个独立 reviewer actor instances；这是
  coordinator 执行的 actor 独立性规则，不是 harness 从文件名机械判断的规则。
- 一份 reviewer 的 result 文件里如果出现了 Blocker 或 High，bf-harness 不会去看这一节的签到 —— 因为整轮已经 FAIL 了。

- {id1}: 一句话说明 reviewer 怎么验证通过的（怎么得出"这条满足了"的判断）
- {id2}: ...
