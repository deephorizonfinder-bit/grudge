# 记仇 / Grudge

让 Claude Code 学会记仇。不是记忆，是沉淀。

## 一句话原理

每次 Claude Code 会话结束，SessionEnd hook 自动触发复盘：这次挖出什么能复用的招？踩了什么坑？写成 Markdown 卡片塞进你的 Obsidian。同一招出现 3 次，自动晋升成强制 SOP，写进 `_playbook.md`。

## 文件结构

```
.claude/
  skills/experience/SKILL.md      # skill 定义
  hooks/experience-capture.sh     # 复盘 hook 脚本
  settings.json                   # SessionEnd 触发配置
```

## 前置依赖

- [jq](https://jqlang.github.io/jq/)
- bash (Windows 可用 Git Bash / WSL)
- Obsidian vault（修改脚本里的 `VAULT` 路径指向你的库）

## 安装

1. 把 `.claude/` 下的内容复制到你项目的 `.claude/` 目录
2. 修改 `.claude/hooks/experience-capture.sh` 第 6 行的 `VAULT` 为你的 Obsidian 绝对路径
3. 确保系统装了 jq

## 诚实局限

- 强杀进程时 hook 不跑，不保证 100% 触发
- 超长会话 AI 评估可能漏东西
- Claude 是否照做是概率工程，不是确定性工程

---

**不是程序员，是做短视频的。被气到自己动手。**
