# OpenClaw MC Manager

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

一个专为macOS设计的Minecraft中小型服务器管理系统，提供便捷的服务器管理功能。

## ✨ 功能特性

- 🚀 **一键启停服务器** - 简单启动和停止Minecraft服务器
- 📊 **服务器状态监控** - 实时显示CPU、内存使用情况和运行时间
- 🎮 **RCON远程命令** - 通过RCON发送服务器命令
- ⚙️ **白名单管理** - 便捷添加/移除白名单玩家
- 📋 **CLI控制面板** - 交互式命令行界面
- 📁 **文件管理** - 快速访问服务器目录和日志

## 📁 文件说明

| 文件名 | 描述 |
|--------|------|
| `README.md` | 项目说明文档（您正在阅读的文件） |
| `setup.sh` | 初始配置脚本，交互式设置服务器参数 |
| `uninstall.sh` | 卸载脚本，清理配置文件和可选的服务器文件 |
| `config.sh` | 配置文件，由setup.sh生成（运行后自动创建） |
| `minecraft_manager.sh` | 功能完整的管理界面脚本，提供交互式菜单控制服务器 |
| `minecraft_console.sh` | 服务器启动器脚本，用于启动Minecraft服务器 |
| `start2.sh` | 备用启动脚本，包含白名单监控功能 |
| `打开MC服务器控制台.command` | macOS双击运行脚本，方便用户快速启动管理界面 |
| `Minecraft服务器管理说明.txt` | 详细的使用说明和配置文档 |

## 🛠️ 系统要求

- **操作系统**: macOS (支持其他Unix-like系统)
- **依赖**: Bash, Java (用于运行Minecraft服务器)
- **可选**: mcrcon (更好的RCON客户端)

## 📦 安装

1. 克隆此仓库：
   ```bash
   git clone https://github.com/qiuxiang2077/macOS-MC-Manager.git
   cd macOS-MC-Manager
   ```

2. 确保脚本有执行权限：
   ```bash
   chmod +x *.sh *.command
   ```

3. **首次运行配置**：
   ```bash
   ./setup.sh
   ```
   按照提示设置您的服务器路径、版本和其他参数。

4. 可选：安装mcrcon以获得更好的RCON体验：
   ```bash
   brew install mcrcon
   ```

## 🚀 使用方法

### 方法一：双击运行（推荐）
直接双击 `打开MC服务器控制台.command` 文件，会自动打开终端并显示管理界面。

### 方法二：命令行运行
```bash
# 打开交互式管理界面
./minecraft_manager.sh

# 查看服务器状态
./minecraft_manager.sh --status

# 查看最近日志
./minecraft_manager.sh --log

# 发送RCON命令
./minecraft_manager.sh --command "list"
```

### 方法三：使用启动器
```bash
./minecraft_console.sh
```

### 方法四：卸载和清理
```bash
./uninstall.sh
```
选择清理级别：仅配置文件、配置文件+服务器目录，或完全清理所有文件。

## ⚙️ 配置

### RCON设置
确保Minecraft服务器的 `server.properties` 中：
```
enable-rcon=true
rcon.password=your_password
rcon.port=25575
```

### 白名单设置
在 `server.properties` 中：
```
white-list=true
```

## 📖 详细文档

请查看 [`Minecraft服务器管理说明.txt`](Minecraft服务器管理说明.txt) 获取完整的使用说明和高级配置选项。

## 🤝 贡献

欢迎提交Issue和Pull Request！

1. Fork 此仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## ⚠️ 注意事项

- 使用RCON功能前请确保服务器正在运行
- 白名单管理需要RCON权限或直接编辑JSON文件
- 首次运行可能需要配置服务器路径和RCON密码

## 🆘 故障排除

如果遇到问题，请检查：
1. Java是否正确安装
2. 服务器文件路径是否正确
3. RCON设置是否启用
4. 脚本执行权限是否正确

---

** 祝您拥有一个愉快的Minecraft服务器管理体验！ 🎮**
