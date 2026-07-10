---
name: story-setup
description: "Codex 事件制网文项目部署。初始化少文件写作项目，只创建写作规则.md、全局状态.md、事件库.md、正文/，并可部署 Codex agents/hooks。触发方式：$story-setup、/skills、「准备写书」「初始化」「搭环境」。"
---

# story-setup：事件制写作项目部署

你是 Codex 写作项目部署器。目标是建立少文件、事件制、正文级素材优先的长篇网文项目。

**执行铁律：不覆盖用户已有正文、事件库、全局状态或写作规则。已有文件只提示，不替换。**

## 项目结构

新项目只创建：

```text
写作规则.md
全局状态.md
事件库.md
正文/
```

不默认创建 `设定/`、`大纲/`、`追踪/`、`伏笔/`、`时间线/`、`角色状态/` 等多文件结构。设定和人物资料应尽量写进 `事件库.md` 的正文级事件素材；跨事件、跨卷状态只进入 `全局状态.md`。

## Phase 1：检测项目状态

1. 检查当前目录是否已部署过：存在 `.story-deployed`。
2. 检查核心文件：
   - `写作规则.md`
   - `全局状态.md`
   - `事件库.md`
   - `正文/`
3. 已存在的核心文件必须保留；缺哪个补哪个。
4. 只把 `.codex/`、`AGENTS.md`、`.story-deployed` 视为插件基础设施。

## Phase 2：部署核心项目文件

从 `skills/story-setup/references/codex/project-files/` 复制缺失文件：

| Source path | Target path | Merge mode |
|---|---|---|
| `project-files/写作规则.md` | `写作规则.md` | create-if-missing |
| `project-files/全局状态.md` | `全局状态.md` | create-if-missing |
| `project-files/事件库.md` | `事件库.md` | create-if-missing |

创建 `正文/` 目录。如果目录已存在，不做改动。

## Phase 3：部署 Codex 基础设施

这些文件属于工具层，可以部署或更新：

| Source path | Target path | Merge mode |
|---|---|---|
| `skills/story-setup/references/codex/AGENTS.md.tmpl` | `AGENTS.md` | marker/section merge |
| `skills/story-setup/references/codex/agents/` | `.codex/agents/` | replace managed agent files |
| `skills/story-setup/references/codex/hooks/hooks.json` | `.codex/hooks.json` | merge by event+command |
| `skills/story-setup/references/codex/hooks/story_codex_hook.py` | `.codex/hooks/story_codex_hook.py` | replace |

不再把大型 `agent-references/` 复制进项目，避免项目文件数膨胀。agents 如需参考资料，应优先读取项目根三件套和插件内 skill 规则；缺参考资料时使用内置规则 fallback。

## AGENTS.md 合并策略

1. 如果已有 `<!-- STORY-SETUP:BEGIN -->` / `<!-- STORY-SETUP:END -->`，只替换标记内内容。
2. 如果没有标记，在文件末尾追加 story-setup 管理区块。
3. 标记外用户内容不得删除。

## hooks.json 合并策略

1. 读取用户现有 `.codex/hooks.json`，不存在则创建。
2. 读取模板 hooks JSON。
3. 按事件名和 command 字符串去重合并。
4. 保留用户已有 hook。

## 写入部署标记

`.story-deployed` 写入：

```yaml
deployed_at: <ISO8601 时间>
setup_skill_version: 3.0.0
target_cli: codex
workflow: event-based
core_files:
  - 写作规则.md
  - 全局状态.md
  - 事件库.md
  - 正文/
```

## 安装报告

报告必须包含：

- 本次创建的核心文件。
- 已存在并保留的核心文件。
- `.codex/` 和 `AGENTS.md` 的部署结果。
- 下一步建议：先运行 `$story-event-plan` 生成事件库，再用 `$story-long-draft` 写当前事件。

## 后续路由

| 用户下一步 | 建议 skill |
|---|---|
| 生成本卷事件 | `$story-event-plan` |
| 按事件写正文 | `$story-long-draft` |
| 事件写完结算 | `$story-event-settle` |
| 审查正文/事件 | `$story-review` |
| 去 AI 味 | `$story-deslop` |
| 模糊需求 | `$story` |
