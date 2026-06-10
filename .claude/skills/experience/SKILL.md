---
name: experience
description: 复盘并管理 Obsidian 经验库——提炼、查看、晋级或否决经验。用户对"可复用"有最终决定权。
disable-model-invocation: true
---
经验库位于 Obsidian 的 `经验/<项目名>/`,每条是一张带 frontmatter 的卡片(polarity / tag / status)。
status:candidate(候选)、reusable(已确认可复用)、archived(否决)。
正向经验同 tag 满3张会被自动置为 reusable;但用户拥有最高权限,可随时手动晋级/否决,无需等到3次。

根据 $ARGUMENTS 执行:
- 无参数 或 "review":列出本项目所有 status=candidate 的卡片(标题+一句话),让用户挑选。
- "promote <关键词>":把匹配卡片 status 改为 reusable,并追加进同目录 `_playbook.md`(用 `<!--tag:xxx-->` 去重)。这是用户拍板,直接生效。
- "reject <关键词>":把匹配卡片 status 改为 archived。
- "distill":就最近会话或用户指定内容,手动提炼一张经验卡(自动评估漏掉、或想立刻记一条时用)。
- 改动前先把要动的卡片标题列出来让用户确认,改完报告结果。绝不批量改动未确认的卡片。
