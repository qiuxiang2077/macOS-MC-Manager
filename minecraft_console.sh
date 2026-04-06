#!/bin/bash

# Minecraft服务器控制台启动器
# 一键打开服务器控制页面

SCRIPT_DIR="/Users/qiufu/Desktop"
MANAGER_SCRIPT="$SCRIPT_DIR/minecraft_manager.sh"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${GREEN}   Minecraft服务器控制台启动器${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"

# 检查管理脚本是否存在
if [ ! -f "$MANAGER_SCRIPT" ]; then
    echo -e "${YELLOW}警告: 管理脚本不存在，正在创建...${NC}"
    cat > "$MANAGER_SCRIPT" << 'EOF'
#!/bin/bash
echo "Minecraft服务器管理脚本未找到"
echo "请从原始位置复制: ~/minecraft-server-1.21.11/"
exit 1
EOF
    chmod +x "$MANAGER_SCRIPT"
fi

# 检查脚本是否可执行
if [ ! -x "$MANAGER_SCRIPT" ]; then
    chmod +x "$MANAGER_SCRIPT"
fi

echo -e "${GREEN}选择打开方式:${NC}"
echo "1. 在当前终端打开管理界面"
echo "2. 在新终端窗口打开管理界面"
echo "3. 直接查看服务器状态"
echo "4. 查看实时服务器日志"
echo "5. 打开服务器目录"
echo "6. 退出"
echo -n "请选择 [1-6]: "

read choice
case $choice in
    1)
        echo -e "${GREEN}在当前终端打开管理界面...${NC}"
        echo -e "${BLUE}════════════════════════════════════════${NC}"
        exec "$MANAGER_SCRIPT"
        ;;
    2)
        echo -e "${GREEN}在新终端窗口打开管理界面...${NC}"
        # 尝试使用不同的终端打开方式
        if command -v osascript &> /dev/null; then
            # macOS - 使用AppleScript打开新终端
            osascript << EOF
tell application "Terminal"
    do script "cd \"$SCRIPT_DIR\" && ./minecraft_manager.sh"
    activate
end tell
EOF
            echo -e "${YELLOW}新终端窗口已打开${NC}"
        elif command -v x-terminal-emulator &> /dev/null; then
            # Linux - 使用x-terminal-emulator
            x-terminal-emulator -e "cd \"$SCRIPT_DIR\" && ./minecraft_manager.sh" &
        elif command -v gnome-terminal &> /dev/null; then
            # GNOME终端
            gnome-terminal -- bash -c "cd \"$SCRIPT_DIR\" && ./minecraft_manager.sh; exec bash" &
        elif command -v konsole &> /dev/null; then
            # KDE Konsole
            konsole -e "cd \"$SCRIPT_DIR\" && ./minecraft_manager.sh" &
        else
            echo -e "${YELLOW}无法自动打开新终端，请手动打开终端并运行:${NC}"
            echo "cd ~/Desktop && ./minecraft_manager.sh"
        fi
        ;;
    3)
        echo -e "${GREEN}服务器状态:${NC}"
        echo -e "${BLUE}════════════════════════════════════════${NC}"
        "$MANAGER_SCRIPT" --status
        echo -e "${BLUE}════════════════════════════════════════${NC}"
        echo -e "${YELLOW}按Enter键继续...${NC}"
        read
        ;;
    4)
        echo -e "${GREEN}实时服务器日志 (按Ctrl+C退出):${NC}"
        echo -e "${BLUE}════════════════════════════════════════${NC}"
        SERVER_DIR="/Users/qiufu/minecraft-server-1.21.11"
        if [ -f "$SERVER_DIR/logs/latest.log" ]; then
            tail -f "$SERVER_DIR/logs/latest.log"
        else
            echo -e "${YELLOW}日志文件不存在${NC}"
        fi
        ;;
    5)
        echo -e "${GREEN}打开服务器目录...${NC}"
        SERVER_DIR="/Users/qiufu/minecraft-server-1.21.11"
        if [ -d "$SERVER_DIR" ]; then
            open "$SERVER_DIR"
            echo -e "${YELLOW}服务器目录已打开${NC}"
        else
            echo -e "${YELLOW}服务器目录不存在: $SERVER_DIR${NC}"
        fi
        ;;
    6)
        echo -e "${GREEN}退出${NC}"
        exit 0
        ;;
    *)
        echo -e "${YELLOW}无效的选择，默认在当前终端打开...${NC}"
        exec "$MANAGER_SCRIPT"
        ;;
esac

# 如果不是exec执行的，等待用户按Enter
if [ "$choice" != "1" ]; then
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${YELLOW}按Enter键返回...${NC}"
    read
    # 重新启动脚本
    exec "$0"
fi