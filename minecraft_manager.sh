#!/bin/bash

# Minecraft服务器管理脚本
# 版本: 1.0
# 放在桌面上，一键管理Minecraft 1.21.11服务器

SERVER_DIR="/Users/qiufu/minecraft-server-1.21.11"
PROPERTIES_FILE="$SERVER_DIR/server.properties"
LOGS_DIR="$SERVER_DIR/logs"
START_SCRIPT="$SERVER_DIR/start.sh"
STOP_SCRIPT="$SERVER_DIR/stop.sh"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[信息]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[成功]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[警告]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[错误]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# 检查服务器是否在运行
check_server_running() {
    if ps aux | grep -v grep | grep "server.jar" | grep "$SERVER_DIR" > /dev/null 2>&1; then
        return 0  # 服务器在运行
    else
        return 1  # 服务器未运行
    fi
}

# 获取服务器信息
get_server_info() {
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}        Minecraft服务器管理界面${NC}"
    echo -e "${CYAN}════════════════════════════════════════${NC}"

    # 检查服务器状态
    if check_server_running; then
        echo -e "🟢 ${GREEN}服务器状态: 运行中${NC}"

        # 获取进程信息
        local pid=$(ps aux | grep -v grep | grep "server.jar" | grep "$SERVER_DIR" | awk '{print $2}' | head -1)
        local cpu=$(ps -p $pid -o %cpu 2>/dev/null | tail -1 | xargs)
        local mem=$(ps -p $pid -o %mem 2>/dev/null | tail -1 | xargs)
        echo -e "   PID: $pid | CPU: ${cpu}% | 内存: ${mem}%"

        # 获取运行时间
        local etime=$(ps -p $pid -o etime 2>/dev/null | tail -1 | xargs)
        echo -e "   运行时间: $etime"
    else
        echo -e "🔴 ${RED}服务器状态: 已停止${NC}"
    fi

    # 显示白名单状态
    if [ -f "$PROPERTIES_FILE" ]; then
        local whitelist_enabled=$(grep -E "^white-list=" "$PROPERTIES_FILE" 2>/dev/null | cut -d'=' -f2)
        if [ "$whitelist_enabled" = "true" ]; then
            echo -e "📋 ${GREEN}白名单: 已启用${NC}"
            local player_count=0
            if [ -f "$SERVER_DIR/whitelist.json" ]; then
                player_count=$(grep -c '"name"' "$SERVER_DIR/whitelist.json" 2>/dev/null || echo "0")
            fi
            echo -e "   白名单玩家: ${player_count}人"
        else
            echo -e "📋 ${YELLOW}白名单: 已禁用${NC}"
        fi
    fi

    # 显示服务器端口
    if [ -f "$PROPERTIES_FILE" ]; then
        local port=$(grep -E "^server-port=" "$PROPERTIES_FILE" 2>/dev/null | cut -d'=' -f2)
        if [ -z "$port" ]; then
            port="25565 (默认)"
        fi
        echo -e "🔌 ${CYAN}服务器端口: $port${NC}"

        # 检查RCON状态
        local rcon_enabled=$(grep -E "^enable-rcon=" "$PROPERTIES_FILE" 2>/dev/null | cut -d'=' -f2)
        if [ "$rcon_enabled" = "true" ]; then
            local rcon_port=$(grep -E "^rcon.port=" "$PROPERTIES_FILE" 2>/dev/null | cut -d'=' -f2)
            echo -e "🔐 ${GREEN}RCON远程控制: 已启用 (端口: ${rcon_port})${NC}"
        else
            echo -e "🔐 ${YELLOW}RCON远程控制: 已禁用${NC}"
        fi
    fi

    # 显示在线玩家（如果服务器正在运行）
    if check_server_running && [ -f "$LOGS_DIR/latest.log" ]; then
        local players=$(tail -100 "$LOGS_DIR/latest.log" | grep -E "joined the game|left the game" | tail -5)
        if [ ! -z "$players" ]; then
            echo -e "👥 ${CYAN}最近玩家活动:${NC}"
            echo "$players" | while read line; do
                echo "   $line"
            done
        fi
    fi

    echo -e "${CYAN}════════════════════════════════════════${NC}"
}

# 显示服务器日志
show_server_logs() {
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}        Minecraft服务器日志查看${NC}"
    echo -e "${CYAN}════════════════════════════════════════${NC}"

    if [ ! -f "$LOGS_DIR/latest.log" ]; then
        log_error "日志文件不存在: $LOGS_DIR/latest.log"
        return 1
    fi

    echo -e "${YELLOW}选择日志查看方式:${NC}"
    echo "1. 查看实时日志 (tail -f)"
    echo "2. 查看最近100行日志"
    echo "3. 查看错误日志"
    echo "4. 查看启动日志"
    echo "5. 返回主菜单"
    echo -n "请选择 [1-5]: "

    read choice
    case $choice in
        1)
            log_info "开始查看实时日志 (按Ctrl+C退出)..."
            echo -e "${CYAN}════════════════════════════════════════${NC}"
            tail -f "$LOGS_DIR/latest.log"
            ;;
        2)
            log_info "最近100行日志:"
            echo -e "${CYAN}════════════════════════════════════════${NC}"
            tail -100 "$LOGS_DIR/latest.log"
            echo -e "${CYAN}════════════════════════════════════════${NC}"
            echo -e "${YELLOW}按Enter键继续...${NC}"
            read
            ;;
        3)
            log_info "错误日志:"
            echo -e "${CYAN}════════════════════════════════════════${NC}"
            grep -i "error\|warn\|fail\|exception" "$LOGS_DIR/latest.log" | tail -50
            echo -e "${CYAN}════════════════════════════════════════${NC}"
            echo -e "${YELLOW}按Enter键继续...${NC}"
            read
            ;;
        4)
            log_info "启动日志:"
            echo -e "${CYAN}════════════════════════════════════════${NC}"
            if [ -f "$SERVER_DIR/server_startup_error.log" ]; then
                tail -50 "$SERVER_DIR/server_startup_error.log"
            else
                log_warning "启动日志文件不存在"
            fi
            echo -e "${CYAN}════════════════════════════════════════${NC}"
            echo -e "${YELLOW}按Enter键继续...${NC}"
            read
            ;;
        5)
            return 0
            ;;
        *)
            log_error "无效的选择"
            echo -e "${YELLOW}按Enter键继续...${NC}"
            read
            ;;
    esac
}

# 发送RCON命令
send_rcon_command() {
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}        RCON远程命令发送${NC}"
    echo -e "${CYAN}════════════════════════════════════════${NC}"

    if ! check_server_running; then
        log_error "服务器未运行，无法发送RCON命令"
        echo -e "${YELLOW}按Enter键继续...${NC}"
        read
        return 1
    fi

    if [ ! -f "$PROPERTIES_FILE" ]; then
        log_error "服务器配置文件不存在"
        echo -e "${YELLOW}按Enter键继续...${NC}"
        read
        return 1
    fi

    local rcon_enabled=$(grep -E "^enable-rcon=" "$PROPERTIES_FILE" 2>/dev/null | cut -d'=' -f2)
    if [ "$rcon_enabled" != "true" ]; then
        log_error "RCON未在server.properties中启用"
        echo -e "${YELLOW}按Enter键继续...${NC}"
        read
        return 1
    fi

    local rcon_port=$(grep -E "^rcon.port=" "$PROPERTIES_FILE" 2>/dev/null | cut -d'=' -f2)
    local rcon_password=$(grep -E "^rcon.password=" "$PROPERTIES_FILE" 2>/dev/null | cut -d'=' -f2)

    if [ -z "$rcon_port" ] || [ -z "$rcon_password" ]; then
        log_error "RCON端口或密码未配置"
        echo -e "${YELLOW}按Enter键继续...${NC}"
        read
        return 1
    fi

    echo -e "${GREEN}RCON配置:${NC}"
    echo -e "  端口: $rcon_port"
    echo -e "  密码: $(echo "$rcon_password" | sed 's/./*/g')"
    echo ""

    echo -e "${YELLOW}选择命令类型:${NC}"
    echo "1. 常用命令列表"
    echo "2. 自定义命令"
    echo "3. 返回主菜单"
    echo -n "请选择 [1-3]: "

    read choice
    case $choice in
        1)
            echo -e "${CYAN}════════════════════════════════════════${NC}"
            echo -e "${YELLOW}常用RCON命令:${NC}"
            echo "1.  list - 列出在线玩家"
            echo "2.  say <消息> - 广播消息"
            echo "3.  time set day - 设置为白天"
            echo "4.  time set night - 设置为夜晚"
            echo "5.  weather clear - 设置为晴天"
            echo "6.  weather rain - 设置为雨天"
            echo "7.  gamemode survival <玩家> - 设置生存模式"
            echo "8.  gamemode creative <玩家> - 设置创造模式"
            echo "9.  tp <玩家1> <玩家2> - 传送玩家"
            echo "10. give <玩家> <物品> <数量> - 给予物品"
            echo -e "${CYAN}════════════════════════════════════════${NC}"
            echo -n "选择命令编号 [1-10] 或输入0返回: "

            read cmd_choice
            case $cmd_choice in
                0) return 0 ;;
                1) cmd="list" ;;
                2)
                    echo -n "输入广播消息: "
                    read message
                    cmd="say $message"
                    ;;
                3) cmd="time set day" ;;
                4) cmd="time set night" ;;
                5) cmd="weather clear" ;;
                6) cmd="weather rain" ;;
                7)
                    echo -n "输入玩家名: "
                    read player
                    cmd="gamemode survival $player"
                    ;;
                8)
                    echo -n "输入玩家名: "
                    read player
                    cmd="gamemode creative $player"
                    ;;
                9)
                    echo -n "输入玩家1名: "
                    read player1
                    echo -n "输入玩家2名: "
                    read player2
                    cmd="tp $player1 $player2"
                    ;;
                10)
                    echo -n "输入玩家名: "
                    read player
                    echo -n "输入物品ID (如: minecraft:diamond): "
                    read item
                    echo -n "输入数量: "
                    read count
                    cmd="give $player $item $count"
                    ;;
                *)
                    log_error "无效的选择"
                    echo -e "${YELLOW}按Enter键继续...${NC}"
                    read
                    return 1
                    ;;
            esac

            if [ ! -z "$cmd" ]; then
                log_info "发送命令: $cmd"
                echo -e "${CYAN}════════════════════════════════════════${NC}"

                # 检查是否安装了mcrcon
                if command -v mcrcon >/dev/null 2>&1; then
                    mcrcon -H 127.0.0.1 -P "$rcon_port" -p "$rcon_password" "$cmd"
                else
                    log_warning "未安装mcrcon，使用Python发送RCON命令..."

                    # 使用Python发送RCON命令
                    python3 << EOF
import socket
import struct

host = "127.0.0.1"
port = $rcon_port
password = "$rcon_password"
command = "$cmd"

try:
    # 连接服务器
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(5)
    sock.connect((host, port))

    # 发送认证
    auth_packet = struct.pack('<ii', 3, 0) + password.encode('utf-8') + b'\x00\x00'
    sock.send(struct.pack('<i', len(auth_packet)) + auth_packet)

    # 接收认证响应
    response_len = struct.unpack('<i', sock.recv(4))[0]
    response = sock.recv(response_len)

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
        print("命令已发送，但未收到响应")

    sock.close()

except Exception as e:
    print(f"错误: {e}")
EOF
                fi

                echo -e "${CYAN}════════════════════════════════════════${NC}"
            fi
            ;;
        2)
            echo -n "输入自定义命令: "
            read custom_cmd

            if [ ! -z "$custom_cmd" ]; then
                log_info "发送自定义命令: $custom_cmd"
                echo -e "${CYAN}════════════════════════════════════════${NC}"

                # 检查是否安装了mcrcon
                if command -v mcrcon >/dev/null 2>&1; then
                    mcrcon -H 127.0.0.1 -P "$rcon_port" -p "$rcon_password" "$custom_cmd"
                else
                    log_warning "未安装mcrcon，使用Python发送RCON命令..."

                    # 使用Python发送RCON命令
                    python3 << EOF
import socket
import struct

host = "127.0.0.1"
port = $rcon_port
password = "$rcon_password"
command = "$custom_cmd"

try:
    # 连接服务器
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(5)
    sock.connect((host, port))

    # 发送认证
    auth_packet = struct.pack('<ii', 3, 0) + password.encode('utf-8') + b'\x00\x00'
    sock.send(struct.pack('<i', len(auth_packet)) + auth_packet)

    # 接收认证响应
    response_len = struct.unpack('<i', sock.recv(4))[0]
    response = sock.recv(response_len)

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
        print("命令已发送，但未收到响应")

    sock.close()

except Exception as e:
    print(f"错误: {e}")
EOF
                fi

                echo -e "${CYAN}════════════════════════════════════════${NC}"
            fi
            ;;
        3)
            return 0
            ;;
        *)
            log_error "无效的选择"
            ;;
    esac

    echo -e "${YELLOW}按Enter键继续...${NC}"
    read
}

# 服务器控制
server_control() {
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}        Minecraft服务器控制${NC}"
    echo -e "${CYAN}════════════════════════════════════════${NC}"

    echo -e "${YELLOW}选择操作:${NC}"
    echo "1. 启动服务器"
    echo "2. 停止服务器"
    echo "3. 重启服务器"
    echo "4. 查看服务器状态"
    echo "5. 返回主菜单"
    echo -n "请选择 [1-5]: "

    read choice
    case $choice in
        1)
            if check_server_running; then
                log_error "服务器已经在运行中！"
            else
                log_info "正在启动服务器..."
                echo -e "${CYAN}════════════════════════════════════════${NC}"
                cd "$SERVER_DIR" && "$START_SCRIPT"
                echo -e "${CYAN}════════════════════════════════════════${NC}"
            fi
            ;;
        2)
            if ! check_server_running; then
                log_error "服务器未在运行！"
            else
                log_info "正在停止服务器..."
                echo -e "${CYAN}════════════════════════════════════════${NC}"
                cd "$SERVER_DIR" && "$STOP_SCRIPT"
                echo -e "${CYAN}════════════════════════════════════════${NC}"
            fi
            ;;
        3)
            log_info "重启服务器..."
            if check_server_running; then
                echo -e "${CYAN}════════════════════════════════════════${NC}"
                log_info "正在停止服务器..."
                cd "$SERVER_DIR" && "$STOP_SCRIPT"
                sleep 3
                echo -e "${CYAN}════════════════════════════════════════${NC}"
            fi

            log_info "正在启动服务器..."
            echo -e "${CYAN}════════════════════════════════════════${NC}"
            cd "$SERVER_DIR" && "$START_SCRIPT"
            echo -e "${CYAN}════════════════════════════════════════${NC}"
            ;;
        4)
            get_server_info
            echo -e "${YELLOW}按Enter键继续...${NC}"
            read
            ;;
        5)
            return 0
            ;;
        *)
            log_error "无效的选择"
            echo -e "${YELLOW}按Enter键继续...${NC}"
            read
            ;;
    esac
}

# 白名单管理
whitelist_management() {
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}        白名单管理${NC}"
    echo -e "${CYAN}════════════════════════════════════════${NC}"

    local whitelist_file="$SERVER_DIR/whitelist.json"

    if [ ! -f "$whitelist_file" ]; then
        log_warning "白名单文件不存在，创建新文件..."
        echo '[]' > "$whitelist_file"
    fi

    echo -e "${YELLOW}选择操作:${NC}"
    echo "1. 查看白名单玩家"
    echo "2. 添加玩家到白名单"
    echo "3. 从白名单移除玩家"
    echo "4. 启用/禁用白名单"
    echo "5. 返回主菜单"
    echo -n "请选择 [1-5]: "

    read choice
    case $choice in
        1)
            log_info "白名单玩家列表:"
            echo -e "${CYAN}════════════════════════════════════════${NC}"
            if [ -s "$whitelist_file" ]; then
                python3 << EOF
import json
try:
    with open("$whitelist_file", "r") as f:
        data = json.load(f)

    if isinstance(data, list) and len(data) > 0:
        print(f"共有 {len(data)} 名白名单玩家:")
        for i, player in enumerate(data, 1):
            name = player.get('name', '未知')
            uuid = player.get('uuid', '未知')
            print(f"{i:2d}. 名称: {name:20} UUID: {uuid}")
    else:
        print("白名单为空")
except Exception as e:
    print(f"读取白名单文件时出错: {e}")
EOF
            else
                echo "白名单为空"
            fi
            echo -e "${CYAN}════════════════════════════════════════${NC}"
            echo -e "${YELLOW}按Enter键继续...${NC}"
            read
            ;;
        2)
            echo -n "输入要添加的玩家名: "
            read player_name

            if [ -z "$player_name" ]; then
                log_error "玩家名不能为空"
            else
                log_info "添加玩家: $player_name"
                echo -e "${CYAN}════════════════════════════════════════${NC}"

                # 使用RCON命令添加白名单
                if check_server_running; then
                    send_rcon_command_simple "whitelist add $player_name"
                    log_success "已通过RCON添加玩家到白名单"
                else
                    log_warning "服务器未运行，无法通过RCON添加"
                    log_info "请启动服务器后使用命令: /whitelist add $player_name"
                fi

                echo -e "${CYAN}════════════════════════════════════════${NC}"
            fi
            echo -e "${YELLOW}按Enter键继续...${NC}"
            read
            ;;
        3)
            echo -n "输入要移除的玩家名: "
            read player_name

            if [ -z "$player_name" ]; then
                log_error "玩家名不能为空"
            else
                log_info "移除玩家: $player_name"
                echo -e "${CYAN}════════════════════════════════════════${NC}"

                # 使用RCON命令移除白名单
                if check_server_running; then
                    send_rcon_command_simple "whitelist remove $player_name"
                    log_success "已通过RCON从白名单移除玩家"
                else
                    log_warning "服务器未运行，无法通过RCON移除"
                    log_info "请启动服务器后使用命令: /whitelist remove $player_name"
                fi

                echo -e "${CYAN}════════════════════════════════════════${NC}"
            fi
            echo -e "${YELLOW}按Enter键继续...${NC}"
            read
            ;;
        4)
            if [ ! -f "$PROPERTIES_FILE" ]; then
                log_error "服务器配置文件不存在"
            else
                local current_status=$(grep -E "^white-list=" "$PROPERTIES_FILE" 2>/dev/null | cut -d'=' -f2)
                echo -e "当前白名单状态: ${current_status}"

                echo -n "启用白名单? (y/n): "
                read enable_choice

                if [[ "$enable_choice" =~ ^[Yy]$ ]]; then
                    # 启用白名单
                    sed -i.bak 's/^white-list=.*/white-list=true/' "$PROPERTIES_FILE"
                    log_success "已启用白名单"

                    # 如果服务器正在运行，重新加载白名单
                    if check_server_running; then
                        send_rcon_command_simple "whitelist reload"
                        log_info "已重新加载白名单"
                    fi
                elif [[ "$enable_choice" =~ ^[Nn]$ ]]; then
                    # 禁用白名单
                    sed -i.bak 's/^white-list=.*/white-list=false/' "$PROPERTIES_FILE"
                    log_success "已禁用白名单"

                    # 如果服务器正在运行，重新加载白名单
                    if check_server_running; then
                        send_rcon_command_simple "whitelist reload"
                        log_info "已重新加载白名单"
                    fi
                else
                    log_error "无效的选择"
                fi
            fi
            echo -e "${YELLOW}按Enter键继续...${NC}"
            read
            ;;
        5)
            return 0
            ;;
        *)
            log_error "无效的选择"
            echo -e "${YELLOW}按Enter键继续...${NC}"
            read
            ;;
    esac
}

# 发送简单RCON命令（内部使用）
send_rcon_command_simple() {
    local cmd="$1"

    if [ ! -f "$PROPERTIES_FILE" ]; then
        return 1
    fi

    local rcon_port=$(grep -E "^rcon.port=" "$PROPERTIES_FILE" 2>/dev/null | cut -d'=' -f2)
    local rcon_password=$(grep -E "^rcon.password=" "$PROPERTIES_FILE" 2>/dev/null | cut -d'=' -f2)

    if [ -z "$rcon_port" ] || [ -z "$rcon_password" ]; then
        return 1
    fi

    # 检查是否安装了mcrcon
    if command -v mcrcon >/dev/null 2>&1; then
        mcrcon -H 127.0.0.1 -P "$rcon_port" -p "$rcon_password" "$cmd" >/dev/null 2>&1
        return $?
    else
        # 使用Python发送RCON命令
        python3 << EOF >/dev/null 2>&1
import socket
import struct

host = "127.0.0.1"
port = $rcon_port
password = "$rcon_password"
command = "$cmd"

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
    sock.recv(response_len)

    sock.close()
    exit(0)
except:
    exit(1)
EOF
        return $?
    fi
}

# 主菜单
main_menu() {
    while true; do
        clear
        get_server_info

        echo -e "${YELLOW}════════════════════════════════════════${NC}"
        echo -e "${MAGENTA}            主菜单${NC}"
        echo -e "${YELLOW}════════════════════════════════════════${NC}"
        echo "1. 📊 查看服务器日志"
        echo "2. 🎮 发送RCON命令"
        echo "3. ⚙️  服务器控制 (启动/停止)"
        echo "4. 📋 白名单管理"
        echo "5. 🐚 打开服务器目录"
        echo "6. 🔧 安装mcrcon (RCON客户端)"
        echo "7. ❌ 退出"
        echo -e "${YELLOW}════════════════════════════════════════${NC}"
        echo -n "请选择 [1-7]: "

        read choice
        case $choice in
            1) show_server_logs ;;
            2) send_rcon_command ;;
            3) server_control ;;
            4) whitelist_management ;;
            5)
                log_info "打开服务器目录: $SERVER_DIR"
                open "$SERVER_DIR"
                echo -e "${YELLOW}按Enter键继续...${NC}"
                read
                ;;
            6)
                echo -e "${CYAN}════════════════════════════════════════${NC}"
                echo -e "${MAGENTA}        安装mcrcon RCON客户端${NC}"
                echo -e "${CYAN}════════════════════════════════════════${NC}"
                echo -e "${YELLOW}mcrcon是一个高效的RCON客户端，可以更方便地发送命令。${NC}"
                echo ""
                echo "安装方法:"
                echo "1. 使用Homebrew (推荐):"
                echo "   brew install mcrcon"
                echo ""
                echo "2. 手动编译安装:"
                echo "   git clone https://github.com/Tiiffi/mcrcon.git"
                echo "   cd mcrcon"
                echo "   gcc -std=gnu11 -pedantic -Wall -Wextra -O2 -s -o mcrcon mcrcon.c"
                echo "   sudo cp mcrcon /usr/local/bin/"
                echo ""
                echo "安装后可以在RCON命令界面直接使用mcrcon发送命令。"
                echo -e "${CYAN}════════════════════════════════════════${NC}"
                echo -e "${YELLOW}按Enter键继续...${NC}"
                read
                ;;
            7)
                log_info "退出Minecraft服务器管理界面"
                echo -e "${GREEN}感谢使用！${NC}"
                exit 0
                ;;
            *)
                log_error "无效的选择，请重新输入"
                sleep 1
                ;;
        esac
    done
}

# 脚本入口
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Minecraft服务器管理脚本"
    echo "用法: ./minecraft_manager.sh [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -s, --status   显示服务器状态并退出"
    echo "  -l, --log      查看最近100行日志并退出"
    echo "  -c, --command  发送RCON命令并退出"
    echo ""
    echo "示例:"
    echo "  ./minecraft_manager.sh              # 启动交互式管理界面"
    echo "  ./minecraft_manager.sh --status     # 显示服务器状态"
    echo "  ./minecraft_manager.sh --log        # 查看服务器日志"
    exit 0
elif [ "$1" = "--status" ] || [ "$1" = "-s" ]; then
    get_server_info
    exit 0
elif [ "$1" = "--log" ] || [ "$1" = "-l" ]; then
    if [ -f "$LOGS_DIR/latest.log" ]; then
        tail -100 "$LOGS_DIR/latest.log"
    else
        echo "错误: 日志文件不存在"
        exit 1
    fi
    exit 0
elif [ "$1" = "--command" ] || [ "$1" = "-c" ]; then
    if [ $# -lt 2 ]; then
        echo "错误: 需要指定命令"
        echo "用法: ./minecraft_manager.sh --command '命令内容'"
        exit 1
    fi
    shift
    send_rcon_command_simple "$@"
    exit $?
else
    # 检查服务器目录是否存在
    if [ ! -d "$SERVER_DIR" ]; then
        log_error "服务器目录不存在: $SERVER_DIR"
        exit 1
    fi

    # 检查必要的文件
    if [ ! -f "$PROPERTIES_FILE" ]; then
        log_warning "服务器配置文件不存在: $PROPERTIES_FILE"
    fi

    if [ ! -f "$START_SCRIPT" ]; then
        log_warning "启动脚本不存在: $START_SCRIPT"
    fi

    if [ ! -f "$STOP_SCRIPT" ]; then
        log_warning "停止脚本不存在: $STOP_SCRIPT"
    fi

    # 启动主菜单
    main_menu
fi