#!/bin/bash
# 在群晖 SSH 上执行（安装 Container Manager 之后）
# 用途：创建 OpenClaw 容器并进入容器执行安装
# 用法：chmod +x 本脚本 && sudo ./本脚本  或  bash 本脚本

set -e
WORKSPACE="${OPENCLAW_WORKSPACE:-/volume1/docker/openclaw-workspace}"
DATA="${OPENCLAW_DATA:-/volume1/docker/openclaw-data}"
CONTAINER_NAME="${OPENCLAW_CONTAINER_NAME:-openclaw}"

if ! command -v docker &>/dev/null; then
  echo "错误：未找到 docker。请先在 DSM 套件中心安装 Container Manager。"
  exit 1
fi

if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "容器 ${CONTAINER_NAME} 已存在。启动并进入执行安装..."
  docker start "${CONTAINER_NAME}" 2>/dev/null || true
  docker exec -it "${CONTAINER_NAME}" bash -c "chmod +x /root/.openclaw/openclaw-synology-install.sh 2>/dev/null; /root/.openclaw/openclaw-synology-install.sh"
  echo "安装已执行。启动 Gateway 请进入容器运行："
  echo "  docker exec -it ${CONTAINER_NAME} bash -c 'source /root/.bashrc && openclaw gateway --port 18789 --bind lan'"
  exit 0
fi

echo "创建容器 ${CONTAINER_NAME}（Ubuntu 24.04，端口 18789，卷 ${WORKSPACE}、${DATA}）..."
docker run -d --name "${CONTAINER_NAME}" \
  --restart unless-stopped \
  -p 18789:18789 \
  -v "${WORKSPACE}:/workspace" \
  -v "${DATA}:/root/.openclaw" \
  ubuntu:24.04 \
  sleep infinity

echo "等待容器就绪..."
sleep 3
echo "在容器内执行安装脚本..."
docker exec -it "${CONTAINER_NAME}" bash -c "/root/.openclaw/openclaw-synology-install.sh"

echo ""
echo "========== 下一步 =========="
echo "1. 在 File Station 编辑 ${DATA}/openclaw.json，填入你的 MINIMAX_API_KEY"
echo "2. 启动 Gateway："
echo "   docker exec -d ${CONTAINER_NAME} bash -c 'source /root/.bashrc && nohup openclaw gateway --port 18789 --bind lan >> /root/.openclaw/gateway.log 2>&1 &'"
echo "3. 浏览器访问：http://<群晖IP>:18789/  粘贴 Token 后 Connect"
echo "============================"
