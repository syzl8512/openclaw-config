OpenClaw 群晖部署 - 已就绪

当前状态：
- 目录 /volume1/docker/openclaw-workspace 和 openclaw-data 已创建
- 安装脚本已上传到本目录

⚠ 群晖上尚未安装 Container Manager（Docker），需先安装：

第一步：在 DSM 安装 Docker
  1. 登录 DSM → 套件中心
  2. 搜索「Container Manager」或「Docker」
  3. 安装并启动

第二步：SSH 执行一键脚本
  SSH 登录群晖后执行（需 sudo 密码）：
    cd /volume1/docker/openclaw-data
    echo "你的sudo密码" | sudo -S ./run-after-docker.sh

  脚本会：拉取 Ubuntu 24.04、创建容器、在容器内安装 OpenClaw

第三步：配置与启动
  1. 在 File Station 编辑 openclaw-data/openclaw.json，填入 MINIMAX_API_KEY
  2. 启动 Gateway（见脚本结束时的提示命令）
  3. 浏览器访问 http://群晖IP:18789/ 粘贴 Token 连接

详细说明见仓库：04_System/05_Configuration/OpenClaw_群晖部署说明.md
