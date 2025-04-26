#!/bin/bash

# 默认参数
COMPOSE_FILE="docker-compose.yml"
OUTPUT_FILE=""

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo "选项:"
    echo "  -f, --file FILE    指定 docker-compose.yml 文件路径（默认为当前目录下的 docker-compose.yml）"
    echo "  -o, --output FILE  指定输出文件路径"
    echo "  -h, --help        显示帮助信息"
    exit 0
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            COMPOSE_FILE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
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
if [ -z "$OUTPUT_FILE" ]; then
    echo "错误: 必须指定输出文件路径 (-o 或 --output)"
    show_help
    exit 1
fi

# 检查 docker-compose 文件是否存在
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "错误: docker-compose 文件 '$COMPOSE_FILE' 不存在"
    exit 1
fi

# 创建输出文件
touch "$OUTPUT_FILE"

# 提取所有服务中的镜像
echo "正在从 $COMPOSE_FILE 提取镜像清单..."

# 使用 grep 和 sed 提取镜像信息
# 1. 查找所有包含 image: 的行
# 2. 移除 image: 前缀
# 3. 移除引号和空格
# 4. 排序并去重
grep -E '^\s*image:' "$COMPOSE_FILE" | \
    sed 's/^[[:space:]]*image:[[:space:]]*//' | \
    sed 's/^["'\'']//;s/["'\'']$//' | \
    sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | \
    grep -v '^$' | \
    sort | uniq > "$OUTPUT_FILE"

# 检查是否成功提取到镜像
if [ ! -s "$OUTPUT_FILE" ]; then
    echo "警告: 没有找到任何镜像信息"
    exit 1
fi

echo "镜像清单已保存到 $OUTPUT_FILE"
echo "共找到 $(wc -l < "$OUTPUT_FILE") 个镜像" 