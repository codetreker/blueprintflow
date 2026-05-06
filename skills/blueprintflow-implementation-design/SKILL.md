---
name: blueprintflow-implementation-design
description: "4 件套后写代码前, Dev 主写实现方案设计 (数据流/数据模型/API contract/边界 case/多方案/集成点), 由 Architect+PM+Security+QA 4 角色 review 全 ✅ 才放行写代码; 设计文档跟 4 件套 + 实施同 milestone PR, 不开独立 PR。触发: 4 件套已就位, 涉及代码改动的 milestone 启动写代码前 / 重要 refactor / 跨模块改动设计。反触发: 非代码 milestone (docs-only / config-only / 字面调整) / 4 件套未就位 (先走 4 件套) / 已通过 design review 进实施 (设计已 frozen, 直接写代码) / typo / hotfix 紧急路径。"
version: 1.0.0
---

# Implementation Design

milestone 4 件套之后、动代码之前, **Dev 主写**一份实现方案设计文档, 由 Architect / PM / Security / QA 4 角色 review, 全 ✅ 才放行写代码。

## 为什么有这步

4 件套 (spec / stance / acceptance / content-lock) 锁的是 **"做什么 / 不做什么"** 的产品立场, 不锁实现路径。

直接进代码常出的问题:
- 数据流没想清, 写一半发现接口形状不对, 推倒重来
- 多方案没比, 选了第一个想到的, 后期发现性能/可维护性差
- 边界 case + 错误处理在写代码时才发现 (实施 PR 撞车)
- 安全/权限路径漏审 (admin god-mode / cross-org / cookie 域)
- 跟既有代码集成点没反向 grep, 集成时一堆 mismatch

实现设计这步把这些前置, 由 4 角色 review pass 后再动代码。

## 反 ivory tower 立场 (用户拍板真值)

设计**不前置**到 4 件套之前, 也不前置到 milestone 起始。

- 4 件套先出 (产品立场锁定 + 拆段 + 验收 + 文案锁)
- 设计才出 (基于已锁立场出实现路径)
- 设计 review pass → 动代码

如果设计前置, 容易脱离产品立场空想架构, 是 ivory tower 反模式。

## 触发条件

- ✅ **涉及代码的 milestone 必走** (schema / server / client 任一改动)
- ✅ 重要 refactor / 跨模块改动
- ❌ 非代码 milestone 可跳:
  - docs-only (蓝图字面调整 / spec brief patch)
  - config-only (env / CI 阈值微调)
  - 字面调整 (文案锁 byte-identical 修齐)

拿不准 → 走设计 (举证责任在 "可以跳" 那边)。

## 作者: Dev 主写

不是 Architect, 也不是 PM。Dev 主写 — 因为是 Dev 要按这份文档干活。

Architect 在 review 阶段把架构关, 不替 Dev 写设计。

## 产出

**Path**: `docs/implementation/design/<milestone>.md`

**长度**: **不限**, 足够反映实现方案即可。

反约束:
- ❌ 不要凑长度 (写够就停, 不灌水)
- ❌ 不要省关键设计 (数据流 / 多方案对比 / 边界 case 必写)
- ❌ **不贴代码** — 最多伪代码 (反 "复制粘贴未来代码" 反模式; 真代码留在实施 commit 里)

## 建议结构 (不强制, 按 milestone 性质裁)

### §1 数据流

sequence diagram / call graph (文字或 mermaid 都行)。

回答: 用户操作 → 哪些组件 → 哪些 API → 哪些 DB 表 → 哪些 side effect。

### §2 数据模型

schema 改动 / migration 真值。

- 新增/修改的表/字段 (含类型 + 约束 + index)
- migration v 号
- 跟既有 schema 兼容性 (rolling deploy 期间双写? 字段 nullable?)

### §3 API contract

path + shape + status code, **byte-identical 对齐 client/server** 想象。

- 请求形状 (path / method / body schema / query param)
- 响应形状 (success / error envelope)
- error code 列表 (不只 "失败 → 500")

### §4 边界 case + 错误处理

- empty / null / oversized 输入
- 并发 (race condition 真路径)
- 部分失败 (transaction rollback / 重试语义)
- 用户态边界 (未登录 / token 过期 / 权限不够)

### §5 多方案

**≥2 个候选方案 + 选谁 + 真因**。

不允许只写一个方案当 "唯一选项"。即便最终方案明显更好, 也要写出被拒方案 + 拒因, 留 review 反驳余地。

格式建议:
- 方案 A: <一句话> | 优: ... | 劣: ...
- 方案 B: <一句话> | 优: ... | 劣: ...
- **选 A**, 真因: ...

**例外**: 如确实只有一个可行方案, 写明其他路径不可行真因 (e.g. schema migration 加单字段无并行方案 / 性能/兼容/合规约束唯一解 / 上游 API 只暴露一个 endpoint), 反硬凑陪跑方案 (写两个差不多的方案让其中一个明显输, 是凑数不是真选型)。例外条款不放水: 必须真写 "为什么没其他方案", 不接受 "我只想到这个"。

### §6 跟既有代码集成点

反向 grep 接口锚:
- 调用了哪些既有函数 / 复用了哪些组件 (列具体路径)
- 既有代码假设跟新设计冲突点 (e.g. 既有 schema 不允许 null, 新设计需要; 怎么处理)
- 反向影响: 改了 A 模块, 谁会受影响 (列依赖)

## 4 角色 review (全 ✅ 阻塞放行写代码)

| 角色 | review 角度 |
|------|-----------|
| **Architect** | ① 立场承袭 (蓝图 §X.Y 不漂) ② **架构设计对不对/合不合理** (核心新加责任) — 数据流抽象层级 / 多方案选型理由 / 跟既有架构一致性 |
| **PM** | 用户价值真兑现 + 文案/UX (设计文档里出现的字面跟 content-lock 对得上) |
| **Security** | 所有代码改动必须 review — 鉴权 / capability / 数据隔离 / cookie 域 / admin god-mode / cross-org 路径 |
| **QA** | 可测性 + 边界 case 完备 (§4 列的 case 跟 acceptance template 1:1 对得上) |

> **Architect review 不只看立场**: 之前 Architect 仅做立场承袭审查, 在设计 review 里**新加架构合理性责任** — 数据流抽象 / 多方案选型 / 跨模块边界。立场守门 ≠ 架构守门, 两件事都要做。

> **Security 必须独立角色, 不允许 Architect 兼任**: 见 `blueprintflow-team-roles`。安全视角跟架构视角是独立维度, 合并后两边都失声。

### Review 协议

- 任一 ❌ 阻塞放行 (Dev 不许动代码)
- ≥3 轮 review 还过不了 → 升 Teamlead + 用户拍 (反僵局)
- review 在 PR comment / 通讯通道走 (按 runtime-adapter), 不开独立 PR

## PR 协议 (用户铁律)

设计文档 **不是独立 PR**。严格守 "一 milestone 一 PR" 铁律。

- 设计文档跟 4 件套 + 实施 + e2e + REG flip + acceptance + PROGRESS [x] **全在同一 PR 内**
- worktree 内顺序:
  1. 4 件套 (Architect/PM/QA 并行)
  2. 设计文档 (Dev 主写)
  3. 4 角色 review pass
  4. 实施代码 (Dev 三段)
  5. e2e
  6. closure (REG flip / acceptance ⚪→✅ / PROGRESS [x])
  7. teamlead 唯一开 PR

review 阶段在 worktree 内通过通讯/comment 进行, **不靠开 PR 来获 review**。

## 反模式

- ❌ Dev 边写边设计 (设计要先出, 写代码前)
- ❌ 把设计文档当走过场凑文档 (4 角色给真值反驳, 不让水)
- ❌ Architect review 只看立场不看架构合理性 (两件事都要做)
- ❌ Security 让 Architect 兼任 (必须独立角色, 见 team-roles)
- ❌ 设计文档独立 PR (违 "一 milestone 一 PR" 铁律)
- ❌ 设计文档贴真代码 (用伪代码, 反 "复制粘贴未来代码")
- ❌ 多方案只写一个不写真因 (强制 ≥2 + 拒因; 真单解走例外条款写"为什么没其他方案")
- ❌ 设计前置到 4 件套之前 (ivory tower, 脱离产品立场)
- ❌ 非代码 milestone 也强走设计 (docs-only / config-only 跳)

## 调用方式

milestone 4 件套就绪后:

```
follow skill blueprintflow-implementation-design
派 Dev 写 docs/implementation/design/<milestone>.md
派 Architect/PM/Security/QA 4 角色 review
全 ✅ → 放行写代码
```
