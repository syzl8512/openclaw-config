#!/usr/bin/env node
/**
 * OpenClaw Agent 初始化命令
 * 用法: node init-agent.js <群组ID> <Agent名称>
 * 
 * 示例:
 *   node init-agent.js oc_xxx "知识库管理Agent"
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const args = process.argv.slice(2);

if (args.length < 2) {
  console.log('用法: node init-agent.js <群组ID> <Agent名称> [工作空间名]');
  console.log('示例: node init-agent.js oc_abc123 "知识库管理Agent" workspace-wiki');
  process.exit(1);
}

const [groupId, agentName, workspaceName] = args;
const workspaceSlug = workspaceName || agentName.replace(/[^a-zA-Z0-9]/g, '-').toLowerCase();
const agentId = `agent-${workspaceSlug}`;
const workspaceDir = path.join('/root/.openclaw', `workspace-${workspaceSlug}`);

console.log('==========================================');
console.log('🚀 初始化新 Agent');
console.log('==========================================');
console.log(`📋 群组 ID: ${groupId}`);
console.log(`📋 Agent 名称: ${agentName}`);
console.log(`📁 工作空间: ${workspaceDir}`);
console.log(`🔧 Agent ID: ${agentId}`);
console.log('');

// 1. 创建工作空间
console.log('[1/6] 创建工作空间目录...');
fs.mkdirSync(workspaceDir, { recursive: true });
fs.mkdirSync(path.join(workspaceDir, 'memory'), { recursive: true });

// 2. 复制基础文件
console.log('[2/6] 复制基础配置文件...');
const sourceDir = '/root/.openclaw/workspace-archive-agent';
const files = ['SOUL.md', 'AGENTS.md', 'USER.md', 'TOOLS.md', 'HEARTBEAT.md'];
files.forEach(file => {
  const source = path.join(sourceDir, file);
  if (fs.existsSync(source)) {
    fs.copyFileSync(source, path.join(workspaceDir, file));
  }
});

// 3. 创建 IDENTITY.md
console.log('[3/6] 创建 Agent 身份文件...');
fs.writeFileSync(path.join(workspaceDir, 'IDENTITY.md'), `# IDENTITY.md - ${agentName}

- **Name:** ${agentName}
- **Creature:** AI Assistant
- **Vibe:** Professional and helpful
- **Emoji:** 📋
- **Avatar:** 

---

Initialized for group: ${groupId}
Date: ${new Date().toISOString()}
`);

// 4. 创建 AGENT_CONFIG.json
console.log('[4/6] 创建 Agent 配置...');
fs.writeFileSync(path.join(workspaceDir, 'AGENT_CONFIG.json'), JSON.stringify({
  agentId,
  name: agentName,
  workspace: workspaceDir,
  groupId,
  createdAt: new Date().toISOString(),
  skills: []
}, null, 2));

// 5. 读取当前 Gateway 配置
console.log('[5/6] 读取当前 Gateway 配置...');
const gatewayConfigPath = '/root/.openclaw/openclaw.json';
const config = JSON.parse(fs.readFileSync(gatewayConfigPath, 'utf8'));

// 6. 生成配置 Patch
console.log('[6/6] 生成配置 Patch...');

const newAgent = {
  id: agentId,
  name: agentName,
  workspace: workspaceDir
};

const newBinding = {
  agentId: agentId,
  match: {
    channel: 'feishu',
    peer: {
      kind: 'group',
      id: groupId
    }
  }
};

// 添加到配置中
if (!config.agents) config.agents = {};
if (!config.agents.list) config.agents.list = [];
config.agents.list.push(newAgent);

if (!config.bindings) config.bindings = [];
config.bindings.push(newBinding);

// 保存配置
fs.writeFileSync(gatewayConfigPath, JSON.stringify(config, null, 2));

console.log('');
console.log('==========================================');
console.log('✅ 初始化完成！');
console.log('==========================================');
console.log('');
console.log('📝 已完成:');
console.log(`   ✅ 创建工作空间: ${workspaceDir}`);
console.log(`   ✅ 添加 Agent: ${agentId}`);
console.log(`   ✅ 绑定群组: ${groupId}`);
console.log('');
console.log('🔄 Gateway 配置已更新，请重启 Gateway 使其生效');
console.log('');
console.log('💡 下一步:');
console.log('   1. 运行: openclaw gateway restart');
console.log(`   2. 在群组 ${groupId} 中添加 Bot 并 @它`);
console.log('');
