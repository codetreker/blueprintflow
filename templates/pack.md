---
Id: <pack-id>
Desc: <一句话描述这个 pack 适用什么样的工作>
---

<!--
frontmatter 字段说明：

- Id：必须跟 packs/<pack-id>/ 目录名一致。
- Desc：list-packs 输出里会显示这一句，LLM 在 brainstorm 阶段用它判断是否选这个 pack。
-->

## When to Use

一到三句话，说清楚什么样的工作适合用这个 pack。LLM 在 brainstorm 阶段拿到用户输入后，会读这一节决定选哪个 pack。这一节是必填。

## Domain Vocabulary

这个领域的关键术语和概念。可选，但写出来能帮 LLM 在跟用户对话时用对的语言。

## Brainstorm Guidance

brainstorm 阶段应该问什么样的问题，blueprint 应该长什么形状，什么算是"好的"blueprint。也可以写常见的反 pattern，提醒 LLM 别踩。

## Breakdown Guidance

在这个领域里，一个 task 应该是什么形状：粒度多大、边界怎么划、典型产物是什么、常见的依赖关系等等。

## Execute Guidance

在这个领域里做一个 task 时的通用指导：常见 pattern、反 pattern、典型的 evidence 应该长什么样。doer 在执行任务前会读这一节。
