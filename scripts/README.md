# scripts/ —— 仓库开发脚本索引

这些脚本用于维护 Codex 专属 oh-story 插件本体，不是 skill 运行时脚本。运行时脚本在各 skill 自己的 `scripts/` 下，Codex 项目 hook 在 `skills/story-setup/references/codex/hooks/` 下。

## 静态守卫（check-*）

| 脚本 | 检查什么 | 何时跑 |
|---|---|---|
| `static-check.sh` | Skill 结构、frontmatter、引用路径、死文件、references 交叉引用 | CI |
| `check-shared-files.sh` | 跨 skill 同名 reference/脚本副本字节一致 | CI |
| `check-codex-adapter.sh` | Codex 插件 manifest、agent TOML、hooks、story-setup 锚点 | CI |
| `check-python-invocation.sh` | 技能文档禁止裸调 `python3`（须 python3→python→py 探测） | CI |

## 测试回归（test-*）

| 脚本 | 测什么 | 何时跑 |
|---|---|---|
| `test-ai-patterns.sh` | 确定性 AI 句式检测器回归 | CI |
| `test-degeneration.sh` | 模型退化检测器回归 | CI |
| `test-codex-hooks.sh` | Codex hook 合成 stdin/stdout 契约 | CI |
| `test-story-continuity.sh` | Codex 连续性兜底回归 | CI |
| `test-charcount-portable.sh` | 跨平台字符统计命令正确性 | CI |
| `test-hook-encoding-portable.sh` | Codex hook 在 Windows 中文系统的编码健壮性 | CI |

## 维护说明

Codex agents 以 `skills/story-setup/references/codex/agents/*.toml` 为源文件。修改 agent 行为时直接编辑这些 TOML，并运行 `bash scripts/check-codex-adapter.sh` 验证。
