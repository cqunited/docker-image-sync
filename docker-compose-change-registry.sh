#!/bin/bash

# 默认参数
DOCKER_COMPOSE_FILE="docker-compose.yml"
TARGET_REGISTRY=""

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo "选项:"
    echo "  -f, --file FILE    指定 docker-compose.yml 文件路径（默认为当前目录下的 docker-compose.yml）"
    echo "  -r, --registry URL 指定目标 registry"
    echo "  -h, --help        显示帮助信息"
    exit 0
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            DOCKER_COMPOSE_FILE="$2"
            shift 2
            ;;
        -r|--registry)
            TARGET_REGISTRY="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "未知选项: $1"
            show_help
            ;;
    esac
done

# 检查必需参数
if [ -z "$TARGET_REGISTRY" ]; then
    echo "错误: 必须指定目标 registry (-r 或 --registry)"
    show_help
    exit 1
fi

# 检查文件是否存在
if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
    echo "错误: docker-compose.yml 文件不存在: $DOCKER_COMPOSE_FILE"
    exit 1
fi

# 生成唯一的备份文件名（兼容 macOS 和 Linux）
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    TIMESTAMP=$(date +%Y%m%d%H%M%S)
else
    # Linux
    TIMESTAMP=$(date +%Y%m%d%H%M%S)
fi
BACKUP_FILE="${DOCKER_COMPOSE_FILE}.backup.${TIMESTAMP}"

# 备份原文件
cp "$DOCKER_COMPOSE_FILE" "$BACKUP_FILE"
echo "已创建备份文件: $BACKUP_FILE" >&2

# 创建临时文件（兼容 macOS 和 Linux）
if [[ "$OSTYPE" == "darwin"* ]]; then
    TEMP_FILE=$(mktemp -t docker-compose)
else
    TEMP_FILE=$(mktemp)
fi

# 使用更安全的方式处理 YAML 文件
while IFS= read -r line; do
    # 检查是否是镜像行
    if [[ $line =~ ^[[:space:]]*image:[[:space:]]* ]]; then
        # 提取缩进
        indent=${line%%image:*}
        
        # 提取镜像名称（处理带引号和不带引号的情况）
        if [[ $line =~ image:[[:space:]]*['"']([^'"']+)['"'] ]]; then
            # 带引号的情况
            old_image="${BASH_REMATCH[1]}"
            quote="${line:${#indent}+6:1}"  # 获取引号类型
        else
            # 不带引号的情况
            old_image=$(echo "$line" | sed -E 's/^[[:space:]]*image:[[:space:]]*//')
            quote=""
        fi
        
        # 移除认证信息
        clean_image=${old_image#*@}
        
        # 处理镜像名称
        if [[ $clean_image == *"/"* ]]; then
            if [[ $clean_image =~ ^[^/]+[.:][^/]+/ ]]; then
                path=${clean_image#*/}
                new_image="$TARGET_REGISTRY/$path"
            else
                new_image="$TARGET_REGISTRY/$clean_image"
            fi
        else
            new_image="$TARGET_REGISTRY/library/$clean_image"
        fi
        
        # 输出处理后的行
        if [ -n "$quote" ]; then
            echo "${indent}image: ${quote}${new_image}${quote}"
        else
            echo "${indent}image: ${new_image}"
        fi
        
        # 将日志信息输出到标准错误
        echo "已更新镜像:" >&2
        echo "  原镜像: $old_image" >&2
        echo "  新镜像: $new_image" >&2
    else
        # 非镜像行直接输出
        echo "$line"
    fi
done < "$DOCKER_COMPOSE_FILE" > "$TEMP_FILE"

# 检查临时文件是否为空
if [ ! -s "$TEMP_FILE" ]; then
    echo "错误: 处理后的文件为空，恢复原文件" >&2
    mv "$BACKUP_FILE" "$DOCKER_COMPOSE_FILE"
    rm -f "$TEMP_FILE"
    exit 1
fi

# 替换原文件
mv "$TEMP_FILE" "$DOCKER_COMPOSE_FILE"

echo "所有镜像更新完成" >&2 