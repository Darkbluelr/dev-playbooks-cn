# setup/（DevBooks 安装）

## 🚀 安装

**让 AI 执行**：
```
请按照 setup/openspec/安装提示词.md 完成 DevBooks 安装
```

**或一键脚本**：
```bash
./setup/global-hooks/install.sh
```

## 目录结构

```
setup/
├── openspec/
│   ├── 安装提示词.md              # 👈 唯一安装入口（AI 执行）
│   └── OpenSpec集成模板...md      # 被安装提示词引用的模板
├── global-hooks/
│   ├── install.sh                 # 一键安装脚本
│   └── augment-context-global.sh  # Hook 脚本模板
├── template/                      # 协议无关模板（非 OpenSpec 项目用）
└── hooks/                         # Git Hooks 配置
```

## 安装后效果

- ✅ 每次对话自动注入相关代码片段和热点文件
- ✅ CKB 图分析工具可用
- ✅ DevBooks Skills 可用
- ✅ 全局生效，无需每个项目单独配置
