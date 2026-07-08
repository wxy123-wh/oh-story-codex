---
name: story-setup
version: 2.0.0
description: "Codex 专属网文写作项目部署。将 oh-story 插件的 Codex agents、hooks、AGENTS.md 与 agent references 安装到当前写作项目。触发方式：$story-setup、/skills、「准备写书」「帮我搭一下环境」「配置写作项目」。"
---
# story-setup：Codex 写作项目部署

你是 Codex 写作基础设施部署器。只部署 Codex 项目结构，不兼容或探测其他软件。

**执行铁律：不覆盖用户已有正文、设定、大纲或追踪文件；项目配置合并而非替换。**

---

## Phase 1：检测项目状态

1. 检查当前目录是否已部署过（存在 `.story-deployed`）。
   - 如果已存在，询问用户是否重新部署；用户确认后继续。
2. 检查是否有书名目录（包含 `追踪/`、`设定/`、`大纲/` 或 `正文/` 的目录）。
   - 有：识别为已有写作项目，保留用户文件。
   - 无：识别为新项目，只部署 Codex 基础设施。
3. 检查 `.active-book` 文件是否存在。
   - 存在：显示当前活跃书目。
   - 不存在：跳过，不强制创建。
4. 只探测 `.codex/` 与 `AGENTS.md` 中的 Codex 部署状态。

## Phase 2：部署 Codex 基础设施

### 2.0 部署清单

| Source path | Target path | Owner class | Merge mode | Validation check |
|-------------|-------------|-------------|------------|------------------|
| `skills/story-setup/references/codex/AGENTS.md.tmpl` | `AGENTS.md` | user+managed | marker/section merge | contains Codex story skill routing sections |
| `skills/story-setup/references/codex/agents/` | `.codex/agents/` | story-setup managed | replace | 7 TOML agent files parse and contain `name`/`description`/`developer_instructions` |
| `skills/story-setup/references/codex/hooks/hooks.json` | `.codex/hooks.json` | user+managed | merge by event+command | hook JSON valid; commands deduped |
| `skills/story-setup/references/codex/hooks/story_codex_hook.py` | `.codex/hooks/story_codex_hook.py` | story-setup managed | replace | Python syntax valid |
| `skills/story-setup/references/agent-references/` | `.codex/skills/story-setup/references/agent-references/` | story-setup managed | replace | every agent reference resolves |
| generated sentinel | `.story-deployed` | story-setup managed | replace | contains `agents_version`, `setup_skill_version`, `target_cli: codex`, `resolver_strategy`, `references_dir` |

### 2.1 合并 AGENTS.md

- 读取 `skills/story-setup/references/codex/AGENTS.md.tmpl`。
- 替换模板占位符：`{项目名}` 使用当前目录名。
- 写入项目根目录 `AGENTS.md`。如已存在，按「AGENTS.md 合并策略」处理。

### 2.2 部署 Codex Agents

- 复制 `skills/story-setup/references/codex/agents/*.toml` 到 `.codex/agents/`。
- Agent 文件属于 story-setup 管理文件，可安全覆盖。
- 校验每个 TOML 都能解析，且包含 `name`、`description`、`developer_instructions`。
- 只读职责 agent（`chapter-extractor`、`consistency-checker`、`story-explorer`）必须保留 `sandbox_mode = "read-only"`。
- 部署后提示用户信任项目 `.codex/` 配置，并新开 Codex 会话；若运行时返回 `unknown agent_type`，调用方必须降级 solo/direct 并报告 fallback。

### 2.3 部署 Codex Hooks

- 复制 `skills/story-setup/references/codex/hooks/story_codex_hook.py` 到 `.codex/hooks/story_codex_hook.py`。
- 将 `skills/story-setup/references/codex/hooks/hooks.json` 合并进 `.codex/hooks.json`。
- 合并规则：按事件名与 command 字符串去重；保留用户已有 hook；新增 story hook 缺失项。
- 校验 `.codex/hooks.json` 是合法 JSON，且每条 story hook 都有 `commandWindows`。

### 2.4 部署 Agent References

- 复制 `skills/story-setup/references/agent-references/` 到 `.codex/skills/story-setup/references/agent-references/`。
- 这是 Codex custom agents 的项目内主参考资料路径。
- 校验所有 `.codex/agents/*.toml` 中出现的 `story-setup/references/agent-references/<file>.md` 都能在目标目录中找到。

### 2.5 写入部署标记

在项目根目录写入 `.story-deployed`：

```yaml
deployed_at: <ISO8601 时间>
agents_version: 16
setup_skill_version: 2.0.0
target_cli: codex
resolver_strategy: codex-project
references_dir: .codex/skills/story-setup/references/agent-references
```

## Phase 3：验证与安装报告

部署后逐项验证：

1. `AGENTS.md` 包含 Codex story skill routing sections。
2. `.codex/agents/` 下存在 7 个 TOML agent，且 TOML 可解析。
3. `.codex/hooks.json` 合法，且包含 story hook launcher。
4. `.codex/hooks/story_codex_hook.py` Python 语法可编译。
5. `.codex/skills/story-setup/references/agent-references/` 下 reference 文件完整。
6. `.story-deployed` 包含 `target_cli: codex` 与当前 `setup_skill_version`。

安装报告必须包含：

- 本次写入/合并的文件清单。
- 已保留用户文件与已有 hooks 的说明。
- 提醒用户信任 `.codex/` 配置层，并新开 Codex 会话。
- 提醒写作前先运行 `$story` 或目标 skill，例如 `$story-long-write`、`$story-review`。

## AGENTS.md 合并策略

用户已有 `AGENTS.md` 时，按 marker/section 合并：

1. 如果存在 `<!-- STORY-SETUP:BEGIN -->` / `<!-- STORY-SETUP:END -->` 标记，只替换标记内内容。
2. 如果没有标记，读取现有 `AGENTS.md` 并在文件末尾追加 story-setup 管理区块。
3. story-setup 管理区块必须带 marker，方便下次升级替换。
4. 不删除用户在 marker 外的任何内容。

## Codex hooks.json 合并策略

1. 读取用户现有 `.codex/hooks.json`，不存在则创建新 JSON。
2. 读取模板 hooks JSON。
3. 对每个事件数组合并 block；同一事件下 command 字符串相同则视为重复并跳过。
4. 保留用户已有 matcher、timeout、statusMessage 与自定义 hooks。
5. 写回格式化 JSON。

## 后续路由

| 用户下一步 | 建议 skill | Codex 调用 |
|---|---|---|
| 开始写长篇 | story-long-write | `$story-long-write` |
| 导入已有小说 | story-import | `$story-import` |
| 审查正文 | story-review | `$story-review` |
| 去 AI 味 | story-deslop | `$story-deslop` |
| 生成封面 | story-cover | `$story-cover` |
| 模糊需求 | story | `$story` |

## 禁止事项

- 只创建 `.codex/` 相关配置。
- 不写任何非 Codex 配置。
- 不使用 `agent_type` 作为 Codex agent 调用字段；Codex custom agents 使用 `agent_type`。
- 不覆盖用户正文、设定、大纲、追踪文件。
