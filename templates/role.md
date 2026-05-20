---
Id: <role-id>
Desc: <一句话描述这个 role 的身份>
Capabilities:
  - <capability-1>
  - <capability-2>
---

<!--
frontmatter 字段说明：

- Id：唯一标识；list-roles 输出里显示。
- Desc：一句话描述，帮 LLM 一眼判断这个 role 适合做什么。
- Capabilities：这个 role 提供的能力清单。bf.md 和 task spec.md 里 AC 标的 capability 会被反查到这里。
  这是一个 BF Core 没有集中注册表的隐式 registry：凡是任何 roles/*.md 里出现的 capability 字符串，都是合法 capability。
  bf-harness lint 会扫所有 bf-wo 引用的 capability，必须能在某个 role 文件里找到声明，否则报错（防 typo）。
-->

# {角色名}

## Identity

这个 role 的身份和视角。它从什么角度看问题、关心什么、不关心什么。

## Expertise

这个 role 能做什么、解决什么类型的问题、有什么特定的偏好或者方法论。

## When to Include

什么场景下应该把这个 role 拉进来。可以是 brainstorm / spec / execute / review 任意阶段。
