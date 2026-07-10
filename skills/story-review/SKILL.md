---
name: story-review
description: "事件制网文审查。检查正文是否兑现事件库、状态是否承接、男频收获循环是否成立，并报告结构、角色、逻辑、文字问题。触发方式：$story-review、/story-review、/审查、「审查一下」「哪里不爽」「逻辑查错」。"
---

# story-review：事件制审查

你是审查协调器。你的职责是找出正文、事件和状态之间的问题，并给出可执行修改建议。审查不是替作者重写，也不是维护旧式资料工程。

## 核心原则

- 默认项目结构只有 `写作规则.md`、`全局状态.md`、`事件库.md`、`正文/`。
- 审查重点是“正文是否兑现事件”，不是检查旧式 `设定/`、`大纲/`、`追踪/` 是否齐全。
- 事件完成后的稳定变化只建议写入 `全局状态.md`，不要要求新增伏笔表、时间线表、角色状态表等多文件追踪。
- 旧项目存在旧资料时可以兼容读取，但不得建议继续扩展旧结构。
- 所有 findings 必须有正文或项目文件证据，不能只写抽象评价。

## 模式

- `/story-review full`：如果 `.codex/agents/` 中部署了 `story-architect`、`character-designer`、`narrative-writer`、`consistency-checker`，可并行审查；任一缺失或当前处于子代理内，降级 solo。
- `/story-review lean`：只用 `story-architect` 和 `consistency-checker`；缺失则降级 solo。
- `/story-review solo`：当前会话直接审查。
- 未指定时默认 `solo`，除非用户明确要求多 agent。

降级时在报告开头写明：

```text
Requested Mode: full | lean | solo
Effective Mode: full | lean | solo
Fallback: none | missing agents -> solo | malformed agents -> solo | agent tool unavailable -> solo | spawn failed -> solo | subagent recursion guard -> solo
Rubric: fanqie | qidian | generic male web-fiction
Rubric Source: file | embedded fallback
```

## 读取顺序

1. 用户指定的正文文件或章节。
2. `事件库.md` 中对应事件和章节切片。
3. `全局状态.md`。
4. `写作规则.md`。
5. `正文/` 上一章、当前事件已写章节、下一章入口。
6. 兼容旧项目时才读取旧 `追踪/`、`大纲/`、`设定/`，只作为证据来源，不作为默认管理方案。

如果用户未指定审查范围，优先审查最近修改的 `正文/` 文件；没有 git 信息时审查 `全局状态.md` 中“下一步/当前进度”对应章节。

## 确定性预检

当审查范围是本地正文文件，先运行本 skill 自带脚本，只报告不修改：

```bash
node scripts/check-ai-patterns.js --check --fail-on=blocking <正文文件...>
node scripts/check-degeneration.js --check <正文文件...>
node scripts/normalize-punctuation.js --check <正文文件...>
```

- `check-degeneration.js` 的 blocking 发现按 S1/S2 处理：复读、截断、占位符、工程词泄漏通常需要重生成该段。
- 工程词包括 `事件库`、`全局状态`、`写作规则`、`细纲`、`情节点`、`本章`、`下一章`、`任务描述` 等。
- `check-ai-patterns.js` 的 blocking 发现按 S2 处理；advisory 只作为 S4 风险。
- `normalize-punctuation.js --check` 只检查标点，不自动改文。

## 审查维度

### 事件兑现

检查正文是否兑现 `事件库.md` 中对应章节：

- 本章主收获是否实际发生。
- 收获前是否有压力、阻碍、误判、代价或竞争。
- 敌人或阻碍方是否主动行动。
- 章尾钩子是否自然接向事件下一切片。
- 如果正文偏离事件库，偏离是否更强；如果更弱，指出最小修法。

### 状态承接

检查 `正文/`、`事件库.md`、`全局状态.md` 是否一致：

- 当前地点、时间、资源、伤势、关系、敌我态势是否断线。
- 事件已完成但 `全局状态.md` 未记录的稳定变化。
- `全局状态.md` 中仍标“待兑现”的问题是否已在正文兑现。
- 下一事件入口是否能从当前状态自然发生。

### 男频收获循环

每章至少检查：

- 读者等什么。
- 主角这一章拿到什么。
- 拿到之前有没有压迫感。
- 主角靠什么行动、判断、资源或代价拿到。
- 旁人或敌人如何反应。
- 新期待是什么。

只有“说明设定”或“角色聊天”，没有收获、压力或状态变化，通常至少 S2。

### 角色与对话

- 角色行为是否符合当前利益、认知、恐惧和底线。
- 反派是否只是等主角推动。
- 对话是否承担试探、压迫、交易、隐瞒、挑衅或关系变化。
- 是否存在科普嘴、同声口、突然信任、突然降智。

### 文字质量

- 是否出现 AI 腔、总结体、解释腔、过度工整、禁用词。
- 是否用抽象判断替代动作、物件、对白和即时利害。
- 标点、段落、对话格式是否影响阅读。
- 正文标题行以外是否漏出写作工程词。

## Agent 使用

只有在 Effective Mode 仍为 full 或 lean 时才 spawn agent。每个 prompt 必须内联：

- 项目路径。
- 审查范围。
- 对应 `事件库.md` 事件片段。
- `全局状态.md` 相关状态。
- 审查基准摘要。
- 统一 Findings Schema。

agent 分工：

- `story-architect`：事件结构、收获循环、钩子、反转、卷内推进。
- `character-designer`：动机、关系、对白、人物弧线。
- `narrative-writer`：文字自然度、AI 味、格式、标点、工程词。
- `consistency-checker`：状态断线、事实矛盾、因果漏洞、规则边界。

不要要求子 agent 读取旧 `story-setup/references/agent-references/`。项目内 agents 如需资料，只读三件套、正文和必要参考。

## Findings Schema

所有问题按以下结构输出：

```yaml
- severity: S1 | S2 | S3 | S4
  category: event | state | structure | character | prose | consistency | format | platform
  location: 文件路径:行号 或 章节/段落描述
  evidence: "原文或项目文件证据"
  issue: "问题描述"
  fix: "最小可执行修法"
```

严重度：

- S1：破坏主线、核心设定、角色可信度或读者信任，需优先修。
- S2：明显削弱本章收获、爽点、冲突、节奏或连载期待，建议本轮修。
- S3：局部质量问题，可排期修。
- S4：提示项或风格微调。

## 输出模板

```md
=== 故事审查报告 ===
Requested Mode: {full | lean | solo}
Effective Mode: {full | lean | solo}
Fallback: {none | ...}
Rubric: {fanqie | qidian | generic male web-fiction}
Rubric Source: {file | embedded fallback}
审查范围: {文件/章节/事件}

## 结论
APPROVE / CONCERNS / REJECT

## Severity Counts
- S1: n
- S2: n
- S3: n
- S4: n

## 事件兑现
{本章/本事件是否兑现事件库，缺口在哪里}

## 状态承接
{全局状态、事件库、正文之间的断线或需结算项}

## Findings
{按 severity 排序，使用统一 schema}

## 最小修法
{按 S1 -> S4 排列，只给可执行改法}
```

## 参考资料

按需加载，不作为运行前提：

| 文件 | 用途 |
|---|---|
| [references/quality-checklist.md](references/quality-checklist.md) | 通用质量清单 |
| [references/quality-rubric.md](references/quality-rubric.md) | 通用网文评分标准 |
| [references/anti-ai-writing.md](references/anti-ai-writing.md) | AI 味与解释腔检查 |
| [references/banned-words.md](references/banned-words.md) | 禁用词检查 |
| [references/plot-core-methods.md](references/plot-core-methods.md) | 剧情循环与高潮结构参考 |
| [references/character-relations.md](references/character-relations.md) | 角色关系参考 |
| [references/dialogue-mastery.md](references/dialogue-mastery.md) | 对话质量参考 |
| [scripts/check-ai-patterns.js](scripts/check-ai-patterns.js) | AI 句式预检 |
| [scripts/check-degeneration.js](scripts/check-degeneration.js) | 退化与工程词泄漏预检 |
| [scripts/normalize-punctuation.js](scripts/normalize-punctuation.js) | 标点预检 |

## 流程衔接

| 情况 | 下一步 |
|---|---|
| 事件缺正文级素材 | `$story-event-plan` 补事件 |
| 正文需要重写或续写 | `$story-long-draft` |
| 事件已写完但状态未结算 | `$story-event-settle` |
| 文字 AI 味需要处理 | `$story-deslop` |

## 语言

- 跟随用户的语言回复。
- 中文回复直接、具体、可执行。
