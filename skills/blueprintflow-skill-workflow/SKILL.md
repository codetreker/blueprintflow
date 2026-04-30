---
name: blueprintflow-skill-workflow
description: Blueprintflow skill 自身的更新流程：worktree → PR → 全员 vote → 合并。触发词：改 skill、更新 skill、skill PR。触发场景：需要新增、修改或删除 blueprintflow skill 时。
version: 1.0.0
---

# Skill Workflow

Blueprintflow skill 的更新流程。所有 skill 修改（新增、编辑、删除）都走这个流程，不直接推 main。

## 流程

### 1. Architect开 worktree + branch

```bash
cd /workspace/blueprintflow
git fetch origin
git worktree add .worktrees/<topic> -b docs/<topic> origin/main
```

- 路径：`.worktrees/<topic>`
- 分支：`docs/<topic>`（如 `docs/generalize-skills`、`docs/add-new-skill`）

### 2. Architect写 draft

在 worktree 里修改 skill 文件，commit + push：

```bash
cd /workspace/blueprintflow/.worktrees/<topic>
# 编辑 skill 文件...
git add -A
git commit -m "docs(<scope>): <description>"
git push -u origin docs/<topic>
```

### 3. Architect提 PR

```bash
gh pr create --repo codetreker/blueprintflow \
  --title "docs(<scope>): <description>" \
  --body "## Summary\n<改了什么、为什么改>\n\n## 影响的 skill\n- <列出受影响的 skill>"
```

### 4. 全员 review

Dev、PM、QA在 PR 上 review + comment：

- **Dev**：实施视角——规则能执行吗？有歧义吗？
- **PM**：用户视角——新团队读得懂吗？认知负担大吗？
- **QA**：验收视角——规则可验证吗？示例够吗？
- **Architect**：一致性——跟其他 skill 矛盾吗？整体结构通吗？
- **全员**：渐进式披露——这个 skill 是否需要拆 references？

**Review 标准**：见 `blueprintflow-pr-review-flow` Review 正模式段。核心：通读整体 + 换位思考 + 认真找问题才 LGTM。

**格式检查**：批量替换/rename 的 PR 必须检查 ASCII 图（时序图、表格、代码块缩进）有没有被误伤。diff 里出现大量纯空格变化 = 红旗。

Review comment 用 `gh pr comment` 或直接在 GitHub PR 页面。

### 5. 达成一致后 Architect合并

全员无异议（或异议已解决）后：

```bash
gh pr merge <N> --repo codetreker/blueprintflow --squash
```

### 6. Architect清理 worktree + branch

```bash
cd /workspace/blueprintflow
git worktree remove .worktrees/<topic>
git branch -d docs/<topic>
git fetch origin --prune
```

## 规则

- **只有 Architect能开 PR 和合并**——其他角色通过 review comment 参与
- **不直接推 main**——任何修改都走 PR
- **PR 必须全员 vote 才能合并**——Architect、PM、Dev、QA、建军全部勾✅，缺任何一个 = 不合并
- **整体阅读**——review 不能只看 diff，要看改完后的完整 skill 文件
- **commit message 格式**：`docs(<skill-name>): <description>`

## 不适用

- 实战项目代码修改（走 blueprintflow-git-workflow）
- 其他项目的 skill（走各项目自己的流程）
- 纯讨论（在频道讨论，结论再走 PR 固化）

## 调用方式

需要修改 blueprintflow skill 时：
```
follow skill skill-workflow
Architect 开 worktree，写 draft，提 PR
```
