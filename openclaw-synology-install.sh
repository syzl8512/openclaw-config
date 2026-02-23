#!/bin/bash
# OpenClaw 群晖/Ubuntu 容器内一键安装脚本
# 与本地 Mac 相同环境：Ubuntu 24.04 + Node 22 + Opencode + OpenClaw
# 用法：在容器内执行 chmod +x 本脚本 && ./本脚本

set -e
export DEBIAN_FRONTEND=noninteractive

echo "==> 1/5 安装基础依赖与 Node.js 22 ..."
apt-get update -qq
apt-get install -y -qq ca-certificates curl gnupg
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y -qq nodejs
node --version
npm --version

echo "==> 2/5 安装 Opencode ..."
curl -fsSL https://opencode.ai/install | bash

echo "==> 3/5 安装 OpenClaw ..."
# shellcheck source=/dev/null
source /root/.bashrc 2>/dev/null || true
curl -fsSL https://molt.bot/install.sh | bash || true
source /root/.bashrc 2>/dev/null || true
command -v openclaw && openclaw --version || { echo "OpenClaw 安装未完成，请重试: curl -fsSL https://molt.bot/install.sh | bash"; exit 1; }

echo "==> 4/5 创建目录与配置模板 ..."
mkdir -p /root/.openclaw/agents/main/sessions /root/.openclaw/credentials
GATEWAY_TOKEN="${OPENCLAW_GATEWAY_TOKEN:-$(openssl rand -hex 24)}"
CONFIG_FILE="/root/.openclaw/openclaw.json"

# 若已有配置则不覆盖
if [ -f "$CONFIG_FILE" ] && [ -s "$CONFIG_FILE" ]; then
  echo "    已存在 openclaw.json，跳过写入。"
else
  cat > "$CONFIG_FILE" << EOF
{
  "gateway": {
    "mode": "local",
    "bind": "lan",
    "auth": { "token": "${GATEWAY_TOKEN}" },
    "controlUi": { "enabled": true, "allowInsecureAuth": true }
  },
  "env": { "MINIMAX_API_KEY": "请替换为你的MiniMax_API_Key" },
  "agents": { "defaults": { "model": { "primary": "minimax/MiniMax-M2.1" } } },
  "models": {
    "mode": "merge",
    "providers": {
      "minimax": {
        "baseUrl": "https://api.minimaxi.com/anthropic",
        "apiKey": "\${MINIMAX_API_KEY}",
        "api": "anthropic-messages",
        "models": [{
          "id": "MiniMax-M2.1",
          "name": "MiniMax M2.1",
          "reasoning": false,
          "input": ["text"],
          "cost": { "input": 15, "output": 60, "cacheRead": 2, "cacheWrite": 10 },
          "contextWindow": 200000,
          "maxTokens": 8192
        }]
      }
    }
  }
}
EOF
  echo "    已生成 $CONFIG_FILE（含随机 Gateway Token）。"
fi

echo ""
echo "==> 5/5 安装浏览器扩展（可选）..."
source /root/.bashrc 2>/dev/null || true
openclaw browser extension install 2>/dev/null || true

echo ""
echo "========== 安装完成 =========="
echo "1. 编辑配置：在宿主机打开挂载的 openclaw-data/openclaw.json"
echo "   - 将 env.MINIMAX_API_KEY 的「请替换为你的MiniMax_API_Key」改为你的 MiniMax API Key"
echo "   - 若需使用上面生成的 Token，请记下：${GATEWAY_TOKEN}"
echo "2. 启动 Gateway："
echo "   source /root/.bashrc && openclaw gateway --port 18789 --bind lan"
echo "   或后台：nohup openclaw gateway --port 18789 --bind lan >> /root/.openclaw/gateway.log 2>&1 &"
echo "3. 浏览器访问：http://<群晖IP>:18789/  粘贴 Token 后点击 Connect"
echo "=========================================="
