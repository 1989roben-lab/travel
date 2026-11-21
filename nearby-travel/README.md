# 附近搜索与出行

在中国大陆按实际步行距离找最近的 10 家匹配餐厅并列出大众点评综合评分、按打车距离排前 10 的万豪旅享家酒店，或列出全市国铁客运站并逐站估算打车距离和时间。

## Codex（macOS）

1. 完整解压 ZIP。准备 Codex、Git（macOS 的 Xcode Command Line Tools 即可）、Node.js 22.9 或更新版本，以及 Chrome、Edge 或 Chromium。从解压后的目录在终端运行：

   ```bash
   bash install-macos.sh
   ```

2. 按脚本显示的命令打开本机 `.env`，在 `AMAP_API_KEY=` 后填自己的 [高德开放平台 Web 服务 Key](https://lbs.amap.com/)。保存后回到终端。
3. 运行脚本显示的登录命令，在独立浏览器窗口登录大众点评。若搜索页要求验证，在同一个浏览器窗口试搜一个餐厅关键词并完成验证。看到结果后回终端按 `Ctrl+C` 保存并释放会话，再重开 Codex。
4. 输入「用 `$nearby-travel`，以上海静安寺为起点，查全市火车站、最近的 10 家万豪旅享家酒店，以及类似蓝蛙的餐厅，按步行距离列最近的 10 家。」

安装脚本将固定版本的 [FoodNearBy-MCP](https://github.com/FunEnn/FoodNearBy-MCP) 和 [dp-mcp](https://github.com/qianwj/dp-mcp) 下载到 Codex 用户目录的 `mcp-servers/nearby-travel/`，应用包内补丁，并注册 `nearby-amap` 和 `nearby-dianping`。补丁提供按地标搜索和路线查询，并识别大众点评当前的登录页面。已安装且匹配时可重复运行。使用早期未修改版本的用户可用新版脚本升级 Skill。遇到同名但不兼容的配置时，脚本会显示冲突并退出。点评浏览器会话沿用上游默认目录 `~/.dianping-mcp/browser-profile`。

如两个工具未出现，在终端运行 `codex mcp list`，检查服务是否启用，再打开一个新会话。若在点评登录窗口仍开着时调用点评工具，先关闭登录窗口。高德报错时请检查 Key 的类型和状态；Skill 也会用可访问的网页继续查询。

## Muse 网页版

把 [Skill 链接](https://github.com/1989roben-lab/travel/blob/main/nearby-travel/SKILL.md) 发给 [Muse](https://muse.ai/)，请它在云端工作区安装并验证。详见 [Muse 网页版安装说明](MUSE-INSTALL.md)。

分享时发送原始 ZIP。每位用户在自己的机器上完成 Codex 配置。
