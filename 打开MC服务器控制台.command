#!/bin/bash

# Minecraft服务器控制台 - 双击打开版本
# 这是一个macOS .command文件，双击即可运行

# 设置窗口标题
echo -e "\033]0;Minecraft服务器控制台\007"

# 切换到脚本所在目录
cd "$(dirname "$0")"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# 清屏
clear

# 显示欢迎信息
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${MAGENTA}            Minecraft 1.21.11 服务器控制台${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""

# 检查服务器状态
SERVER_DIR="/Users/qiufu/minecraft-server-1.21.11"
check_server() {
    if ps aux | grep -v grep | grep "server.jar" | grep "$SERVER_DIR" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 显示服务器状态
if check_server; then
    echo -e "🟢 ${GREEN}服务器状态: 运行中${NC}"

    # 获取进程信息
    PID=$(ps aux | grep -v grep | grep "server.jar" | grep "$SERVER_DIR" | awk '{print $2}' | head -1)
    if [ ! -z "$PID" ]; then
        CPU=$(ps -p $PID -o %cpu 2>/dev/null | tail -1 | xargs)
        MEM=$(ps -p $PID -o %mem 2>/dev/null | tail -1 | xargs)
        ETIME=$(ps -p $PID -o etime 2>/dev/null | tail -1 | xargs)
        echo -e "   PID: $PID | CPU: ${CPU}% | 内存: ${MEM}% | 运行时间: $ETIME"
    fi
else
    echo -e "🔴 ${RED}服务器状态: 已停止${NC}"
fi

echo ""

# 显示白名单状态
if [ -f "$SERVER_DIR/server.properties" ]; then
    WHITELIST_ENABLED=$(grep -E "^white-list=" "$SERVER_DIR/server.properties" 2>/dev/null | cut -d'=' -f2)
    if [ "$WHITELIST_ENABLED" = "true" ]; then
        echo -e "📋 ${GREEN}白名单: 已启用${NC}"
        if [ -f "$SERVER_DIR/whitelist.json" ]; then
            PLAYER_COUNT=$(grep -c '"name"' "$SERVER_DIR/whitelist.json" 2>/dev/null || echo "0")
            echo -e "   白名单玩家: ${PLAYER_COUNT}人"
        fi
    else
        echo -e "📋 ${YELLOW}白名单: 已禁用${NC}"
    fi
fi

echo ""

# 显示最近玩家活动
if check_server && [ -f "$SERVER_DIR/logs/latest.log" ]; then
    echo -e "👥 ${CYAN}最近玩家活动:${NC}"
    RECENT_PLAYERS=$(tail -50 "$SERVER_DIR/logs/latest.log" | grep -E "joined the game|left the game" | tail -3)
    if [ ! -z "$RECENT_PLAYERS" ]; then
        echo "$RECENT_PLAYERS" | while read line; do
            echo "   $line"
        done
    else
        echo "   暂无玩家活动"
    fi
fi

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""

# 显示菜单
echo -e "${YELLOW}请选择要执行的操作:${NC}"
echo ""
echo "1. 📊 查看实时服务器日志"
echo "2. 🎮 发送服务器命令 (RCON)"
echo "3. ⚙️  启动/停止服务器"
echo "4. 📁 打开服务器目录"
echo "5. 🐚 打开高级管理界面"
echo "6. 📋 查看白名单"
echo "7. 🚪 退出"
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -n "请输入选项 [1-7]: "

read CHOICE

case $CHOICE in
    1)
        echo ""
        echo -e "${GREEN}正在打开实时服务器日志... (按Ctrl+C退出)${NC}"
        echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
        echo ""
        if [ -f "$SERVER_DIR/logs/latest.log" ]; then
            tail -f "$SERVER_DIR/logs/latest.log"
        else
            echo -e "${RED}错误: 日志文件不存在${NC}"
            echo ""
            echo -e "${YELLOW}按Enter键返回...${NC}"
            read
            exec "$0"
        fi
        ;;
    2)
        echo ""
        echo -e "${GREEN}正在准备RCON命令发送...${NC}"

        # 检查服务器是否运行
        if ! check_server; then
            echo -e "${RED}错误: 服务器未运行，无法发送命令${NC}"
            echo ""
            echo -e "${YELLOW}按Enter键返回...${NC}"
            read
            exec "$0"
        fi

        # 检查RCON配置
        if [ ! -f "$SERVER_DIR/server.properties" ]; then
            echo -e "${RED}错误: 服务器配置文件不存在${NC}"
            echo ""
            echo -e "${YELLOW}按Enter键返回...${NC}"
            read
            exec "$0"
        fi

        RCON_ENABLED=$(grep -E "^enable-rcon=" "$SERVER_DIR/server.properties" 2>/dev/null | cut -d'=' -f2)
        if [ "$RCON_ENABLED" != "true" ]; then
            echo -e "${RED}错误: RCON未启用${NC}"
            echo "请在server.properties中设置 enable-rcon=true"
            echo ""
            echo -e "${YELLOW}按Enter键返回...${NC}"
            read
            exec "$0"
        fi

        RCON_PORT=$(grep -E "^rcon.port=" "$SERVER_DIR/server.properties" 2>/dev/null | cut -d'=' -f2)
        RCON_PASSWORD=$(grep -E "^rcon.password=" "$SERVER_DIR/server.properties" 2>/dev/null | cut -d'=' -f2)

        echo ""
        echo -e "${CYAN}RCON配置:${NC}"
        echo "  端口: $RCON_PORT"
        echo "  密码: $(echo "$RCON_PASSWORD" | sed 's/./*/g')"
        echo ""

        echo -e "${YELLOW}输入要发送的命令 (例如: 'list', 'say Hello', 'time set day'):${NC}"
        echo -n "命令: "
        read RCON_CMD

        if [ -z "$RCON_CMD" ]; then
            echo -e "${RED}错误: 命令不能为空${NC}"
            echo ""
            echo -e "${YELLOW}按Enter键返回...${NC}"
            read
            exec "$0"
        fi

        echo ""
        echo -e "${GREEN}正在发送命令: $RCON_CMD${NC}"
        echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
        echo ""

        # 尝试使用mcrcon
        if command -v mcrcon >/dev/null 2>&1; then
            mcrcon -H 127.0.0.1 -P "$RCON_PORT" -p "$RCON_PASSWORD" "$RCON_CMD"
        else
            # 使用Python发送
            python3 << EOF
import socket
import struct

host = "127.0.0.1"
port = $RCON_PORT
password = "$RCON_PASSWORD"
command = "$RCON_CMD"

try:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(5)
    sock.connect((host, port))

    # 发送认证
    auth_packet = struct.pack('<ii', 3, 0) + password.encode('utf-8') + b'\x00\x00'
    sock.send(struct.pack('<i', len(auth_packet)) + auth_packet)

    # 接收认证响应
    response_len = struct.unpack('<i', sock.recv(4))[0]
    sock.recv(response_len)

    # 发送命令
    cmd_packet = struct.pack('<ii', 2, 0) + command.encode('utf-8') + b'\x00\x00'
    sock.send(struct.pack('<i', len(cmd_packet)) + cmd_packet)

    # 接收命令响应
    response_len = struct.unpack('<i', sock.recv(4))[0]
    response = sock.recv(response_len)

    # 解析响应
    if len(response) > 8:
        response_text = response[8:].decode('utf-8', errors='ignore').rstrip('\x00')
        print("服务器响应:", response_text)
    else:
        print("命令已发送")

    sock.close()
except Exception as e:
    print(f"错误: {e}")
EOF
        fi

        echo ""
        echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${YELLOW}按Enter键返回...${NC}"
        read
        exec "$0"
        ;;
    3)
        echo ""
        echo -e "${GREEN}服务器控制${NC}"
        echo ""

        if check_server; then
            echo -e "🟢 服务器正在运行"
            echo ""
            echo -e "${YELLOW}要停止服务器吗? (y/n):${NC}"
            read STOP_CHOICE

            if [[ "$STOP_CHOICE" =~ ^[Yy]$ ]]; then
                echo ""
                echo -e "${GREEN}正在停止服务器...${NC}"
                if [ -f "$SERVER_DIR/stop.sh" ]; then
                    cd "$SERVER_DIR" && ./stop.sh
                else
                    PID=$(ps aux | grep -v grep | grep "server.jar" | grep "$SERVER_DIR" | awk '{print $2}' | head -1)
                    if [ ! -z "$PID" ]; then
                        kill $PID
                        echo "已发送停止信号"
                    fi
                fi
            fi
        else
            echo -e "🔴 服务器已停止"
            echo ""
            echo -e "${YELLOW}要启动服务器吗? (y/n):${NC}"
            read START_CHOICE

            if [[ "$START_CHOICE" =~ ^[Yy]$ ]]; then
                echo ""
                echo -e "${GREEN}正在启动服务器...${NC}"
                if [ -f "$SERVER_DIR/start.sh" ]; then
                    cd "$SERVER_DIR" && ./start.sh &
                    echo "服务器启动中..."
                else
                    echo "错误: 启动脚本不存在"
                fi
            fi
        fi

        echo ""
        echo -e "${YELLOW}按Enter键返回...${NC}"
        read
        exec "$0"
        ;;
    4)
        echo ""
        echo -e "${GREEN}正在打开服务器目录...${NC}"
        open "$SERVER_DIR"
        echo ""
        echo -e "${YELLOW}按Enter键返回...${NC}"
        read
        exec "$0"
        ;;
    5)
        echo ""
        echo -e "${GREEN}正在打开高级管理界面...${NC}"
        if [ -f "./minecraft_manager.sh" ]; then
            ./minecraft_manager.sh
        else
            echo -e "${RED}错误: 管理脚本不存在${NC}"
            echo ""
            echo -e "${YELLOW}按Enter键返回...${NC}"
            read
            exec "$0"
        fi
        ;;
    6)
        echo ""
        echo -e "${GREEN}白名单管理${NC}"
        echo ""

        if [ ! -f "$SERVER_DIR/whitelist.json" ]; then
            echo -e "${YELLOW}白名单文件不存在${NC}"
        else
            echo -e "${CYAN}白名单玩家:${NC}"
            python3 << EOF
import json
try:
    with open("$SERVER_DIR/whitelist.json", "r") as f:
        data = json.load(f)

    if isinstance(data, list) and len(data) > 0:
        for i, player in enumerate(data, 1):
            name = player.get('name', '未知')
            uuid = player.get('uuid', '未知')
            print(f"{i:2d}. {name}")
    else:
        print("白名单为空")
except Exception as e:
    print(f"读取错误: {e}")
EOF
        fi

        echo ""
        echo -e "${YELLOW}按Enter键返回...${NC}"
        read
        exec "$0"
        ;;
    7)
        echo ""
        echo -e "${GREEN}退出控制台${NC}"
        echo ""
        exit 0
        ;;
    *)
        echo ""
        echo -e "${RED}无效选项，请重新选择${NC}"
        sleep 1
        exec "$0"
        ;;
esac