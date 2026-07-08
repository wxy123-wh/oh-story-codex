# story-setup upgrading

`story-setup` 现在只部署 Codex 项目基础设施。

## 重新部署

在写作项目根目录运行 `$story-setup`，同步以下文件：

- `.codex/agents/*.toml`
- `.codex/hooks.json`
- `.codex/hooks/story_codex_hook.py`
- `.codex/skills/story-setup/references/agent-references/`
- `AGENTS.md`
- `.story-deployed`

部署后信任项目 `.codex/` 配置层，并新开 Codex 会话。

## 已移除

旧的非 Codex 兼容资产已经移除；升级时不要再恢复其他软件的配置目录或模板。
