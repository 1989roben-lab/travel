# 在 Muse 网页版安装附近搜索与出行

打开 [Muse](https://muse.ai/)，把这个仓库的 [nearby-travel 目录](https://github.com/1989roben-lab/travel/tree/main/nearby-travel) 或完整 ZIP 发给 Muse，请它在云端工作区安装并验证 `nearby-travel`。需要一同安装 `scripts/stations.py` 和 `data/`，才能使用本地铁路车站索引。

Muse 的云端环境支持自定义 Skill。下面使用社区已有的 GitHub 安装方式，具体路径以你账号的运行时为准。[Meta 的云端环境介绍](https://muse.ai/blog/security-and-safety-for-ai-agents-our-approach-with-muse) · [社区安装示例](https://github.com/microsoft/apm/issues/3109)

## 给负责安装的 Muse

1. 从用户给出的仓库链接读取完整 `nearby-travel` 目录，确认 `SKILL.md` 的 YAML `name` 为 `nearby-travel`。
2. 查清当前云端运行时的自定义 Skill 目录，把 `SKILL.md`、`scripts/stations.py` 和 `data/` 放入其中名为 `nearby-travel` 的子目录。已有同名 Skill 时按用户授权升级。以运行时公布或可验证的路径为准。
3. 检查能否发现所装的 Skill。可在新聊天试问「以杭州钱江世纪城为起点，列全市火车站、最近的 10 家万豪旅享家酒店和步行距离最近的 10 家类似蓝蛙的餐厅」。确认能读取 Skill，能按类别采用相应规则，并报告当前可用的数据源。
4. Muse 可以使用账号已有的地图和网页浏览能力。macOS 安装脚本用于 Codex，Muse 从同一个 `SKILL.md` 安装。餐厅评分、人均及路线以可访问的高德地图数据为准；无法核对的字段标注待确认。

本包的 Muse 安装流程依据 Meta 的运行环境说明和社区安装案例整理，尚未在登录后的 Muse 网页环境实测。
