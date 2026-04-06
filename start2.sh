#!/bin/bash

# Minecraft服务器启动脚本 - 集成白名单监控功能
# 版本: 2.0 (集成监控)

SERVER_DIR="/Users/qiufu/minecraft-server-1.21.11"
MONITOR_SCRIPT="/Users/qiufu/Library/Application Support/LobsterAI/SKILLs/minecraft-whitelist-notify/scripts/monitor.py"
LOG_DIR="/tmp/minecraft-monitor"
MONITOR_PID_FILE="$LOG_DIR/monitor.pid"
MONITOR_LOG="$LOG_DIR/monitor.log"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# 检查监控脚本是否存在
check_monitor_script() {
    if [ ! -f "$MONITOR_SCRIPT" ]; then
        log_error "监控脚本不存在: $MONITOR_SCRIPT"
        log_error "请确保白名单通知技能已正确安装"
        return 1
    fi

    if ! command -v python3 &> /dev/null; then
        log_error "未找到python3，监控功能需要Python 3.7+"
        return 1
    fi

    log_info "监控脚本检查通过"
    return 0
}

# 启动白名单监控
start_monitor() {
    log_info "正在启动白名单监控服务..."

    # 创建日志目录
    mkdir -p "$LOG_DIR"

    # 检查是否已有监控进程在运行
    if [ -f "$MONITOR_PID_FILE" ]; then
        local pid=$(cat "$MONITOR_PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            log_warning "监控进程已在运行 (PID: $pid)"
            log_info "跳过监控启动"
            return 0
        else
            log_warning "发现旧的PID文件，清理中..."
            rm -f "$MONITOR_PID_FILE"
        fi
    fi

    # 启动监控脚本
    local original_dir=$(pwd)
    cd "$(dirname "$MONITOR_SCRIPT")"
    nohup python3 "$(basename "$MONITOR_SCRIPT")" > "$MONITOR_LOG" 2>&1 &
    local monitor_pid=$!
    cd "$original_dir"

    # 保存PID
    echo "$monitor_pid" > "$MONITOR_PID_FILE"

    # 等待监控脚本初始化
    sleep 2

    # 检查监控进程是否存活
    if ps -p "$monitor_pid" > /dev/null 2>&1; then
        log_success "白名单监控服务启动成功 (PID: $monitor_pid)"
        log_info "监控日志: $MONITOR_LOG"
        log_info "PID文件: $MONITOR_PID_FILE"
        return 0
    else
        log_error "监控服务启动失败"
        log_error "请检查日志: $MONITOR_LOG"
        rm -f "$MONITOR_PID_FILE"
        return 1
    fi
}

# 停止白名单监控
stop_monitor() {
    log_info "正在停止白名单监控服务..."

    if [ -f "$MONITOR_PID_FILE" ]; then
        local pid=$(cat "$MONITOR_PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            kill "$pid" 2>/dev/null
            sleep 1
            if ps -p "$pid" > /dev/null 2>&1; then
                kill -9 "$pid" 2>/dev/null
            fi
            log_success "监控服务已停止 (PID: $pid)"
        else
            log_warning "监控进程未运行"
        fi
        rm -f "$MONITOR_PID_FILE"
    else
        log_warning "未找到监控PID文件"
    fi
}

# 清理函数
cleanup() {
    log_info "执行清理..."
    stop_monitor
    log_info "清理完成"
}

# 检查白名单状态
check_whitelist_status() {
    local properties_file="$SERVER_DIR/server.properties"
    if [ ! -f "$properties_file" ]; then
        log_error "服务器配置文件不存在: $properties_file"
        return 1
    fi

    local whitelist_enabled=$(grep -E "^white-list=" "$properties_file" | cut -d'=' -f2)
    local enforce_whitelist=$(grep -E "^enforce-whitelist=" "$properties_file" | cut -d'=' -f2)

    if [ "$whitelist_enabled" = "true" ]; then
        log_info "白名单功能: ${GREEN}已启用${NC}"
        if [ "$enforce_whitelist" = "true" ]; then
            log_info "白名单强制执行: ${GREEN}已启用${NC}"
            log_info "只有白名单中的玩家可以加入服务器"
        else
            log_info "白名单强制执行: ${YELLOW}未启用${NC}"
            log_info "非白名单玩家可以加入，但会被记录"
        fi
    else
        log_info "白名单功能: ${RED}已禁用${NC}"
        log_info "所有玩家都可以直接加入服务器"
    fi

    # 显示白名单玩家数量
    local whitelist_file="$SERVER_DIR/whitelist.json"
    if [ -f "$whitelist_file" ]; then
        local player_count=$(grep -c '"name"' "$whitelist_file" 2>/dev/null || echo "0")
        log_info "白名单玩家数量: ${BLUE}$player_count${NC} 人"
    else
        log_info "白名单文件不存在，暂无白名单玩家"
    fi
}

# 检查Java环境和服务器文件
check_environment() {
    # 检查Java
    if ! command -v java &> /dev/null; then
        log_error "Java未安装！请安装Java 17或更高版本"
        return 1
    fi

    local java_version=$(java -version 2>&1 | head -1 | cut -d'"' -f2)
    local major_version=$(echo "$java_version" | cut -d'.' -f1)

    if [ "$major_version" -lt 17 ]; then
        log_error "Java版本过低 ($java_version)，需要Java 17或更高版本"
        return 1
    fi

    log_info "Java版本: ${GREEN}$java_version${NC} (符合要求)"

    # 检查server.jar
    if [ ! -f "$SERVER_DIR/server.jar" ]; then
        log_error "服务器文件不存在: $SERVER_DIR/server.jar"
        return 1
    fi

    log_info "服务器文件: ${GREEN}server.jar${NC} (存在)"

    # 检查是否已有服务器进程在运行
    local existing_pids=$(ps aux | grep -v grep | grep "server.jar" | grep "$SERVER_DIR" | awk '{print $2}')
    if [ ! -z "$existing_pids" ]; then
        log_error "发现已有Minecraft服务器进程在运行:"
        for pid in $existing_pids; do
            local cmd=$(ps -p $pid -o command= 2>/dev/null)
            log_error "  PID: $pid, 命令: $cmd"
        done
        log_error "请先停止现有服务器进程，或等待其退出"
        log_error "可以使用 stop.sh 脚本停止服务器"
        return 1
    fi

    # 检查端口占用
    if command -v lsof &> /dev/null; then
        local port=$(grep -E "^server-port=" "$SERVER_DIR/server.properties" | cut -d'=' -f2)
        if [ -z "$port" ]; then
            port=25565
        fi
        local port_pid=$(lsof -ti :$port 2>/dev/null)
        if [ ! -z "$port_pid" ]; then
            log_error "端口 $port 已被占用 (PID: $port_pid)"
            log_error "可能已有其他服务器在运行，请先释放端口"
            return 1
        fi
    else
        log_warning "lsof命令不可用，跳过端口检查"
    fi

    return 0
}

# 设置退出时清理
trap cleanup EXIT INT TERM

# 主函数
main() {
    echo "=========================================="
    echo " Minecraft 1.21.11 服务器启动"
    echo " 集成白名单监控功能"
    echo "=========================================="

    # 切换到服务器目录
    cd "$SERVER_DIR"
    log_info "工作目录: $SERVER_DIR"

    # 检查监控脚本
    if check_monitor_script; then
        # 启动监控服务
        if start_monitor; then
            log_success "白名单监控已启用"
            log_info "非白名单玩家登录时，将通过飞书发送通知"
        else
            log_warning "监控启动失败，继续启动服务器..."
        fi
    else
        log_warning "监控功能检查失败，继续启动服务器..."
    fi

    # 检查白名单状态
    check_whitelist_status

    # 检查Java环境和服务器文件
    if ! check_environment; then
        log_error "环境检查失败，无法启动服务器"
        return 1
    fi

    echo "------------------------------------------"
    log_info "正在启动Minecraft服务器..."
    log_info "内存分配: 6GB (Xmx6G, Xms6G)"
    log_info "垃圾回收器: G1GC"
    log_info "Java版本要求: 17+"
    echo "------------------------------------------"

    # 清理旧的PID文件
    if [ -f "$SERVER_DIR/server.pid" ]; then
        rm -f "$SERVER_DIR/server.pid"
    fi

    # 清理可能残留的session.lock文件（防止"already locked"错误）
    local session_lock="$SERVER_DIR/world/session.lock"
    if [ -f "$session_lock" ]; then
        log_warning "发现残留的session.lock文件，正在清理..."
        rm -f "$session_lock"
        log_info "已清理session.lock文件"
    fi

    # 启动Minecraft服务器并保存PID
    log_info "启动服务器进程..."

    # 创建启动错误日志文件
    STARTUP_ERROR_LOG="$SERVER_DIR/server_startup_error.log"
    echo "=== Minecraft服务器启动日志 $(date) ===" > "$STARTUP_ERROR_LOG"

    # 启动服务器并捕获输出
    java -Xmx6G -Xms6G -XX:+UseG1GC -jar "$SERVER_DIR/server.jar" nogui >> "$STARTUP_ERROR_LOG" 2>&1 &
    SERVER_PID=$!
    echo $SERVER_PID > "$SERVER_DIR/server.pid"
    log_info "服务器进程已启动 (PID: $SERVER_PID)"

    # 等待几秒检查进程是否存活
    log_info "检查服务器启动状态..."
    sleep 5

    if ! ps -p $SERVER_PID > /dev/null 2>&1; then
        log_error "服务器进程启动后立即退出，可能启动失败！"
        log_error "请检查启动错误日志: $STARTUP_ERROR_LOG"
        log_error "最近几行错误输出:"
        tail -20 "$STARTUP_ERROR_LOG" | while read line; do
            log_error "  $line"
        done
        return 1
    fi

    log_success "服务器启动成功，进程运行中"
    log_info "启动日志已保存至: $STARTUP_ERROR_LOG"
    log_info "服务器日志目录: $SERVER_DIR/logs"

    # 等待服务器进程结束
    wait $SERVER_PID

    local exit_code=$?

    echo "------------------------------------------"
    if [ $exit_code -eq 0 ]; then
        log_success "Minecraft服务器正常退出"
    else
        log_error "Minecraft服务器异常退出 (代码: $exit_code)"
    fi

    return $exit_code
}

# 执行主函数
main "$@"
