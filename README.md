# Docker 镜像同步工具

将 Docker 镜像同步到指定的 registry。同时支持修改 docker-compose.yaml

## 功能特点

- 支持批量同步 Docker 镜像
- 支持指定目标架构
- 支持修改 docker-compose.yml 中的镜像 registry
- 支持多种镜像格式
- 自动备份原文件
- 支持错误处理和日志记录

## 安装

1. 克隆仓库：
```bash
git clone https://github.com/cqunited/docker-image-sync.git
cd docker-image-sync
```

2. 添加执行权限：
```bash
chmod +x docker-image-sync.sh docker-compose-change-registry.sh
```

## 使用方法

### docker-image-sync.sh

将 Docker 镜像同步到指定的 registry。

```bash
./docker-image-sync.sh -i <输入文件> -r <目标registry> [-a <目标架构>]
```

参数说明：
- `-i, --input`: 指定输入文件路径，每行一个镜像名称
- `-r, --registry`: 指定目标 registry
- `-a, --arch`: 指定目标架构（默认：当前系统架构）

示例：
```bash
# 同步镜像到私有 registry
./docker-image-sync.sh -i images.txt -r registry.example.com

# 同步指定架构的镜像
./docker-image-sync.sh -i images.txt -r registry.example.com -a arm64
```

输入文件格式示例（images.txt）：
```
nginx:latest
redis:6-alpine
langgenius/dify-api:1.3.0
docker.elastic.co/elasticsearch/elasticsearch:8.14.3
```

### docker-compose-change-registry.sh

修改 docker-compose.yml 文件中的镜像 registry。

```bash
./docker-compose-change-registry.sh -f <docker-compose文件> -r <目标registry>
```

参数说明：
- `-f, --file`: 指定 docker-compose.yml 文件路径（默认为当前目录下的 docker-compose.yml）
- `-r, --registry`: 指定目标 registry

示例：
```bash
# 修改当前目录下的 docker-compose.yml
./docker-compose-change-registry.sh -r registry.example.com

# 修改指定路径的 docker-compose.yml
./docker-compose-change-registry.sh -f /path/to/docker-compose.yml -r registry.example.com
```

## 支持的镜像格式

1. 官方镜像（无命名空间）：
   - redis:6-alpine
   - nginx:latest
   - 输出格式: ${TARGET_REGISTRY}/library/${image}

2. 带命名空间的镜像：
   - langgenius/dify-api:1.3.0
   - library/nginx:latest
   - 输出格式: ${TARGET_REGISTRY}/${image}

3. 带域名的镜像：
   - docker.elastic.co/elasticsearch/elasticsearch:8.14.3
   - quay.io/coreos/etcd:v3.5.5
   - 输出格式: ${TARGET_REGISTRY}/${path}

4. 带认证信息的镜像：
   - user:pass@registry.com/image:tag
   - 输出格式: ${TARGET_REGISTRY}/${path}

5. 带端口的 registry：
   - localhost:5000/nginx:latest
   - 输出格式: ${TARGET_REGISTRY}/${path}

6. 带认证和端口的组合：
   - user:pass@localhost:5000/image:tag
   - 输出格式: ${TARGET_REGISTRY}/${path}

## 注意事项

1. 确保已安装 Docker 并具有足够的权限
2. 确保目标 registry 可访问且有足够的存储空间
3. 同步大量镜像时可能需要较长时间
4. 修改 docker-compose.yml 前会自动创建备份文件
5. 建议在测试环境中先进行测试

## 许可证

MIT License
