#!/usr/bin/env node
/**
 * 群组初始化命令处理器
 * 在群组中输入 "群组初始化" 或 "初始化" 即可触发
 */

const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);

if (args.length < 2) {
  console.log(JSON.stringify({
    error: '参数不足'
  }));
  process.exit(1);
}

const [groupId, agentName] = args;
const workspaceSlug = agentName.replace(/[^a-zA-Z0-9\u4e00-\u9fa5]/g, '-').toLowerCase();
const agentId = `agent-${workspaceSlug}`;
const workspaceDir = path.join('/root/.openclaw', `workspace-${workspaceSlug}`);

console.log(JSON.stringify({
  action: 'initializing',
  groupId,
  agentName,
  workspaceSlug,
  agentId,
  workspaceDir
}));

// 检查参数
if (!groupId.startsWith('oc_')) {
  console.log(JSON.stringify({
    error: '群组ID格式错误，应以 oc_ 开头',
    usage: '群组初始化 <群组ID> <Agent名称>'
  }));
  process.exit(1);
}

try {
  // 1. 创建工作空间
  fs.mkdirSync(workspaceDir, { recursive: true });
  fs.mkdirSync(path.join(workspaceDir, 'memory'), { recursive: true });

  // 2. 复制基础文件
  const sourceDir = '/root/.openclaw/workspace-archive-agent';
  const files = ['SOUL.md', 'AGENTS.md', 'USER.md', 'TOOLS.md', 'HEARTBEAT.md'];
  files.forEach(file => {
    const source = path.join(sourceDir, file);
    if (fs.existsSync(source)) {
      fs.copyFileSync(source, path.join(workspaceDir, file));
    }
  });

  // 3. 创建 IDENTITY.md
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
  fs.writeFileSync(path.join(workspaceDir, 'AGENT_CONFIG.json'), JSON.stringify({
    agentId,
    name: agentName,
    workspace: workspaceDir,
    groupId,
    createdAt: new Date().toISOString(),
    skills: []
  }, null, 2));

  // 5. 读取并更新 Gateway 配置
  const gatewayConfigPath = '/root/.openclaw/openclaw.json';
  const config = JSON.parse(fs.readFileSync(gatewayConfigPath, 'utf8'));

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

  config.agents = config.agents || {};
  config.agents.list = config.agents.list || [];
  config.agents.list.push(newAgent);

  config.bindings = config.bindings || [];
  config.bindings.push(newBinding);

  fs.writeFileSync(gatewayConfigPath, JSON.stringify(config, null, 2));

  // 返回成功结果
  console.log(JSON.stringify({
    success: true,
    message: `✅ Agent "${agentName}" 初始化完成！`,
    details: {
      agentId,
      workspace: workspaceDir,
      groupId,
      nextSteps: [
        '1. 运行 openclaw gateway restart 重启 Gateway',
        `2. 在群组 ${groupId} 中添加 Bot 并 @它`
      ]
    }
  }, null, 2));

} catch (error) {
  console.log(JSON.stringify({
    success: false,
    error: error.message
  }));
}
