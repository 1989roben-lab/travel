# 在 Muse 网页版安装附近搜索与出行

打开 [Muse](https://muse.ai/)，把这个仓库的 [nearby-travel/SKILL.md](https://github.com/1989roben-lab/travel/blob/main/nearby-travel/SKILL.md) 链接发给你的 Muse，请它在云端工作区安装并验证 `nearby-travel`。也可以把解压后的 `SKILL.md` 附给它。

Muse 的云端环境支持自定义 Skill。下面使用社区已有的 GitHub 安装方式，具体路径以你账号的运行时为准。[Meta 的云端环境介绍](https://muse.ai/blog/security-and-safety-for-ai-agents-our-approach-with-muse) · [社区安装示例](https://github.com/microsoft/apm/issues/3109)

## 给负责安装的 Muse

1. 从用户给出的仓库链接读取 `nearby-travel/SKILL.md`，确认 YAML 的 `name` 为 `nearby-travel`。
2. 查清当前云端运行时的自定义 Skill 目录，把该文件放入其中名为 `nearby-travel` 的子目录，保留名为 `SKILL.md`。已有同名 Skill 时按用户授权升级。以运行时公布或可验证的路径为准。
3. 检查能否发现所装的 Skill。可在新聊天试问「以杭州钱江世纪城为起点，列全市火车站和最近的 10 家万豪旅享家酒店」。确认能读取 Skill，能按类别采用相应规则，并报告当前可用的数据源。
4. Muse 可以使用账号已有的地图、网页浏览和已授权的连接。macOS 安装脚本用于 Codex，Muse 从同一个 `SKILL.md` 安装。大众点评评分和打车路线以 Muse 实际可访问的来源为准。

本包的 Muse 安装流程依据 Meta 的运行环境说明和社区安装案例整理，尚未在登录后的 Muse 网页环境实测。
