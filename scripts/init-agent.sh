#!/bin/bash
# OpenClaw 新群组 Agent 初始化脚本
# 用法: ./init-agent.sh <群组ID> <Agent名称> <工作空间名>

set -e

GROUP_ID="$1"
AGENT_NAME="$2"
WORKSPACE_NAME="$3"

if [ -z "$GROUP_ID" ] || [ -z "$AGENT_NAME" ] || [ -z "$WORKSPACE_NAME" ]; then
    echo "用法: ./init-agent.sh <群组ID> <Agent名称> <工作空间名>"
    echo "示例: ./init-agent.sh oc_xxx 知识库Agent workspace-wiki-agent"
    exit 1
fi

WORKSPACE_DIR="/root/.openclaw/workspace-${WORKSPACE_NAME}"
AGENT_ID="agent-${WORKSPACE_NAME}"

echo "=========================================="
echo "🚀 初始化新 Agent: ${AGENT_NAME}"
echo "📋 群组 ID: ${GROUP_ID}"
echo "📁 工作空间: ${WORKSPACE_DIR}"
echo "=========================================="

# 1. 创建工作空间目录
echo "[1/5] 创建工作空间目录..."
mkdir -p "${WORKSPACE_DIR}/memory"

# 2. 复制基础文件结构
echo "[2/5] 复制基础文件..."
cp -r /root/.openclaw/workspace-archive-agent/*.md "${WORKSPACE_DIR}/" 2>/dev/null || true
cp -r /root/.openclaw/workspace-archive-agent/./* "${WORKSPACE_DIR}/" 2>/dev/null || true

# 3. 更新 IDENTITY.md
echo "[3/5] 更新 Agent 配置..."
cat > "${WORKSPACE_DIR}/IDENTITY.md" << EOF
# IDENTITY.md - Who Am I?

- **Name:** ${AGENT_NAME}
- **Creature:** AI Assistant
- **Vibe:** Helpful and professional
- **Emoji:** 📋
- **Avatar:** 

---

Initialized from group: ${GROUP_ID}
EOF

# 4. 创建 Agent 配置文件
cat > "${WORKSPACE_DIR}/AGENT_CONFIG.json" << EOF
{
  "agentId": "${AGENT_ID}",
  "name": "${AGENT_NAME}",
  "workspace": "${WORKSPACE_DIR}",
  "groupId": "${GROUP_ID}",
  "createdAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

echo "[4/5] 生成 Gateway 配置..."

# 5. 输出需要合并的配置
cat > "${WORKSPACE_DIR}/gateway-config-patch.json" << EOF
{
  "agents": {
    "list": [
      {
        "id": "${AGENT_ID}",
        "name": "${AGENT_NAME}",
        "workspace": "${WORKSPACE_DIR}"
      }
    ]
  },
  "bindings": [
    {
      "agentId": "${AGENT_ID}",
      "match": {
        "channel": "feishu",
        "peer": {
          "kind": "group",
          "id": "${GROUP_ID}"
        }
      }
    }
  ]
}
EOF

echo "[5/5] 完成！"
echo ""
echo "=========================================="
echo "✅ 初始化完成！"
echo "=========================================="
echo ""
echo "📝 下一步操作："
echo "1. 查看生成的配置: cat ${WORKSPACE_DIR}/gateway-config-patch.json"
echo "2. 应用配置到 Gateway (需要手动合并)"
echo "3. 在群组 ${GROUP_ID} 中添加 Bot"
echo ""
