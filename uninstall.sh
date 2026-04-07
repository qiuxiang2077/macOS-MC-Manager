#!/bin/bash

# Minecraft服务器管理器 - 卸载脚本
# 用于清理配置文件和可选的服务器文件

echo "========================================"
echo "  Minecraft服务器管理器 - 卸载工具"
echo "========================================"
echo ""

# 检查配置文件是否存在
if [ ! -f "config.sh" ]; then
    echo "未找到配置文件 config.sh"
    echo "可能尚未进行初始配置或已清理"
    echo ""
    read -p "是否要清理其他相关文件? (y/n): " CLEAN_ANYWAY
    if [[ ! $CLEAN_ANYWAY =~ ^[Yy]$ ]]; then
        echo "卸载取消"
        exit 0
    fi
else
    echo "找到配置文件 config.sh"
    source config.sh
    echo "当前配置:"
    echo "  服务器路径: $SERVER_PATH"
    echo "  服务器版本: $SERVER_VERSION"
    echo "  模组服务器: $IS_MODDED ($MOD_LOADER)"
    echo ""
fi

echo "请选择要清理的内容:"
echo "1) 仅删除配置文件 (config.sh)"
echo "2) 删除配置文件和服务器目录"
echo "3) 完全清理 (包括所有脚本和文档)"
echo "4) 取消卸载"
echo ""

read -p "请选择 (1-4): " CHOICE

case $CHOICE in
    1)
        echo "正在删除配置文件..."
        rm -f config.sh
        echo "配置文件已删除"
        ;;
    2)
        if [ -n "$SERVER_PATH" ] && [ -d "$SERVER_PATH" ]; then
            echo "警告: 这将删除整个服务器目录: $SERVER_PATH"
            read -p "确认删除服务器目录? (y/n): " CONFIRM
            if [[ $CONFIRM =~ ^[Yy]$ ]]; then
                echo "正在删除服务器目录..."
                rm -rf "$SERVER_PATH"
                echo "服务器目录已删除"
            else
                echo "服务器目录保留"
            fi
        else
            echo "服务器目录不存在或未配置"
        fi
        echo "正在删除配置文件..."
        rm -f config.sh
        echo "配置文件已删除"
        ;;
    3)
        echo "警告: 这将删除所有项目文件!"
        echo "将删除的文件:"
        echo "  - 所有.sh脚本"
        echo "  - 所有.command文件"
        echo "  - 配置文件"
        echo "  - 文档文件"
        echo ""
        read -p "确认完全清理? (y/n): " CONFIRM_FULL
        if [[ $CONFIRM_FULL =~ ^[Yy]$ ]]; then
            echo "正在执行完全清理..."
            rm -f *.sh *.command config.sh *.txt *.md
            echo "完全清理完成"
            echo "注意: README.md 和其他重要文件已被删除"
            echo "如果需要恢复，请重新克隆仓库"
        else
            echo "完全清理取消"
        fi
        ;;
    4)
        echo "卸载取消"
        exit 0
        ;;
    *)
        echo "无效选择，卸载取消"
        exit 1
        ;;
esac

echo ""
echo "========================================"
echo "卸载完成"
echo "========================================"