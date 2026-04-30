# Codex 适配

### Codex（sandbox）[⚠️ 未实跑验证]

**能力：** ✅ 持久化（session 级） ⚠️ 跨 agent 通讯（通过父 agent 中转） ⚠️ 共享 fs（sandbox 隔离） ❌ 定时调度 ⚠️ 并行多角色（调用方 spawn 多个）

**操作对照表：**

| 通用描述 | 具体命令 |
|---------|---------|
| 通知 \<Role\> | 通过调用方中转 |
| 创建 worktree | sandbox 内 `git worktree add` (每个 Codex session 独立) |
| 提交代码 | sandbox 内 commit，完成后 push 到 remote |
| 启动 fast-cron | ❌ 不支持 — 由调用方定期触发 |
| 启动 slow-cron | ❌ 不支持 — 由调用方定期触发 |
| 查看角色状态 | 调用方自行检查 |
| 开 PR | 完成后由调用方 `gh pr create` |
| Merge PR | 由调用方 `gh pr merge <N> --squash` |

**规则适配：**
- ⚠️ **全员叠 commit**：sandbox 隔离，改为各角色独立 commit + push，Teamlead 确认无冲突后开 PR
- ❌ **fast/slow cron**：不支持，由调用方 heartbeat 或定时触发
- ❌ **Ping 协议**：不适用，Codex session 有自己的完成信号
- ⚠️ **并行 review subagent**：可以，调用方可 spawn 多个 session 并行 review

---
