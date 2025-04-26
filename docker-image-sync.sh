#!/bin/bash

set -e

# 默认参数
INPUT_FILE=""
TARGET_REGISTRY=""
TARGET_ARCH=""

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo "选项:"
    echo "  -i, --input FILE    指定输入文件路径"
    echo "  -r, --registry URL  指定目标 registry"
    echo "  -a, --arch ARCH     指定目标架构 (默认: 当前系统架构)"
    echo "  -h, --help         显示帮助信息"
    exit 0
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--input)
            INPUT_FILE="$2"
            shift 2
            ;;
        -r|--registry)
            TARGET_REGISTRY="$2"
            shift 2
            ;;
        -a|--arch)
            TARGET_ARCH="$2"
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
if [ -z "$INPUT_FILE" ]; then
    echo "错误: 必须指定输入文件路径 (-i 或 --input)"
    show_help
    exit 1
fi

if [ -z "$TARGET_REGISTRY" ]; then
    echo "错误: 必须指定目标 registry (-r 或 --registry)"
    show_help
    exit 1
fi

# 如果没有指定架构，使用当前系统架构
if [ -z "$TARGET_ARCH" ]; then
    TARGET_ARCH=$(uname -m)
fi

# 检查输入文件是否存在
if [ ! -f "$INPUT_FILE" ]; then
    echo "错误: 输入文件 $INPUT_FILE 不存在"
    exit 1
fi

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "错误: Docker 未安装"
    exit 1
fi

# 处理镜像名称
# 支持的镜像格式：
# 1. 官方镜像（无命名空间）：
#    - redis:6-alpine
#    - nginx:latest
#    - 输出格式: ${TARGET_REGISTRY}/library/${image}
#
# 2. 带命名空间的镜像：
#    - langgenius/dify-api:1.3.0
#    - library/nginx:latest
#    - 输出格式: ${TARGET_REGISTRY}/${image}
#
# 3. 带域名的镜像：
#    - docker.elastic.co/elasticsearch/elasticsearch:8.14.3
#    - quay.io/coreos/etcd:v3.5.5
#    - 输出格式: ${TARGET_REGISTRY}/${path}
#
# 4. 带认证信息的镜像：
#    - user:pass@registry.com/image:tag
#    - 输出格式: ${TARGET_REGISTRY}/${path}
#
# 5. 带端口的 registry：
#    - localhost:5000/nginx:latest
#    - 输出格式: ${TARGET_REGISTRY}/${path}
#
# 6. 带认证和端口的组合：
#    - user:pass@localhost:5000/image:tag
#    - 输出格式: ${TARGET_REGISTRY}/${path}
process_image() {
    local image=$1
    local target_registry=$2
    
    # 移除认证信息（如果有）
    local clean_image=${image#*@}
    
    # 分离域名和路径
    if [[ $clean_image == *"/"* ]]; then
        # 检查是否包含域名（包含点或冒号）
        if [[ $clean_image =~ ^[^/]+[.:][^/]+/ ]]; then
            # 提取路径部分
            local path=${clean_image#*/}
            echo "$target_registry/$path"
        else
            # 直接添加目标 registry
            echo "$target_registry/$clean_image"
        fi
    else
        # 处理官方镜像
        echo "$target_registry/library/$clean_image"
    fi
}

# 主循环
while IFS= read -r image || [[ -n "$image" ]]; do
    # 跳过空行
    if [[ -z "$image" ]]; then
        continue
    fi

    echo "处理镜像: $image"
    
    # 处理镜像名称
    target_image=$(process_image "$image" "$TARGET_REGISTRY")
    echo "目标镜像: $target_image"
    
    # 拉取指定架构的镜像
    if ! docker pull --platform linux/$TARGET_ARCH "$image"; then
        echo "错误: 拉取镜像失败: $image (架构: $TARGET_ARCH)"
        continue
    fi
    
    # 重命名镜像
    if ! docker tag "$image" "$target_image"; then
        echo "错误: 重命名镜像失败: $image -> $target_image"
        continue
    fi
    
    # 推送镜像
    if ! docker push "$target_image"; then
        echo "错误: 推送镜像失败: $target_image"
        continue
    fi
    
    echo "成功同步镜像: $target_image (架构: $TARGET_ARCH)"
done < "$INPUT_FILE"

echo "所有镜像处理完成" 