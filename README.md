# Nextcloud 一键部署方案

## 项目简介

本项目提供基于 Docker Compose 和 Caddy 的 Nextcloud 一键部署方案，专为个人和小型组织打造，实现高性能、易维护、安全可靠的私有云存储服务，特别优化了相关配置，方便通过 Cloudflared 的内网穿透场景。

### 核心优势

- **本地数据存储**：所有数据通过本地目录挂载，确保数据主权和安全性
- **灵活密码管理**：用户自主设置所有密码，避免容器重启导致密码丢失
- **全面性能优化**：集成 Redis 缓存、PHP 调优、数据库优化等措施
- **模块化架构**：配置文件与脚本分离，结构清晰，便于定制和扩展
- **强化安全配置**：内置两步验证（2FA）支持、HTTP 安全头、信任域配置等
- **简化部署流程**：一键式部署脚本，自动处理环境检查、服务启动和应用配置
- **内网穿透优化**：针对 Cloudflared 穿透场景进行专门配置，确保远程访问稳定性

## 目录结构

```
nextcloud-deploy/
├── README.md                 # 项目说明文档
├── deploy.sh                 # 主部署脚本
├── config/                   # 配置文件目录
│   ├── .env                  # 环境变量配置
│   ├── docker-compose.yml    # Docker Compose 配置
│   └── Caddyfile             # Caddy 服务器配置
├── scripts/                  # 辅助脚本目录
│   └── config_nextcloud.sh   # Nextcloud 应用配置
└── data/                     # 数据存储目录
    ├── nextcloud/            # Nextcloud 应用数据
    ├── mariadb/              # 数据库文件
    ├── redis/                # Redis 缓存数据
    └── caddy/                # Caddy 服务器数据
```

## 安装步骤

### 1. 环境准备

确保系统满足硬件和软件要求，然后进行以下环境检查：

```bash
# 检查 Docker 版本
docker --version

# 检查 Docker Compose 版本
docker-compose --version

# 或使用 docker compose 命令
docker compose version

# 检查用户是否在 docker 组中（Linux）
groups | grep docker
```

### 2. 配置修改

编辑 `config/.env` 文件，设置所有必要的配置：

```bash
# 进入配置目录
cd config

# 编辑环境配置文件（使用你熟悉的编辑器，如 nano、vim 等）
# 例如：nano .env

# 根据实际情况修改以下配置项：
# - SERVER_IP: 服务器 IP 地址（必须根据实际情况修改）
# - HTTP_PORT: HTTP 端口（默认 10081）
# - ADMIN_USER: 管理员用户名（默认 nextcloud）
# - ADMIN_PASSWORD: 管理员密码（必须修改，默认值为占位符）
# - MYSQL_PASSWORD: MySQL 密码（必须修改，默认值为占位符）
# - MYSQL_ROOT_PASSWORD: MySQL 根密码（必须修改，默认值为占位符）
# - REDIS_PASSWORD: Redis 密码（必须修改，默认值为占位符）
# - TRUSTED_DOMAINS: 信任域列表（必须修改，添加你的域名和 IP）
# - TRUSTED_PROXIES: 信任代理 IP 范围（可选，默认 172.31.0.0/16）
# - PHP_MEMORY_LIMIT: PHP 内存限制（可选，默认 1024M）
# - PHP_UPLOAD_LIMIT: PHP 上传限制（可选，默认 10G）
# - PHP_MAX_EXECUTION_TIME: PHP 最大执行时间（可选，默认 3600）
```

### 3. 部署执行

在 `nextcloud-deploy` 目录下运行部署脚本：

```bash
# 赋予执行权限
chmod +x deploy.sh

# 运行部署脚本
./deploy.sh
```

脚本会自动执行以下操作：
1. 检查环境是否满足要求
2. 启动 Docker 容器服务
3. 配置 Nextcloud 应用（包括启用 2FA 支持）
4. 设置定时任务
5. 显示部署信息

### 4. 验证部署

部署完成后，通过浏览器访问：

```
http://SERVER_IP:HTTP_PORT
```

使用设置的管理员账号登录，验证服务是否正常运行。首次登录后，建议完成以下操作：
- 修改默认密码
- 启用两步验证（2FA）
- 配置存储设置
- 创建所需用户账号

## 配置说明

### Docker Compose 配置

`docker-compose.yml` 文件定义了所有服务的配置，主要包括：

- **服务定义**：MariaDB、Redis、Nextcloud 和 Caddy 四个核心服务
- **数据持久化**：所有数据通过本地目录挂载到 `data/` 目录，确保数据安全
- **网络配置**：创建专用网络，实现服务间安全通信
- **资源限制**：可根据服务器硬件情况调整 CPU 和内存限制
- **健康检查**：配置服务健康检查，确保服务正常运行
- **依赖关系**：设置服务启动顺序，确保依赖服务就绪

### Caddy 服务器配置

`Caddyfile` 配置了 Web 服务器的行为，主要包括：

- **协议支持**：支持 HTTP/1.1、HTTP/2 和 HTTP/3
- **并发优化**：调整最大并发连接数和超时设置
- **安全增强**：配置多种安全相关的 HTTP 头，如 X-Content-Type-Options、X-Frame-Options、Content-Security-Policy 等
- **性能优化**：启用 gzip 和 zstd 压缩，提升传输速度
- **WebDAV 支持**：配置 WebDAV 重定向，确保日历和联系人同步正常
- **静态文件处理**：优化静态文件缓存策略，减少重复请求
- **PHP 处理**：配置 PHP FastCGI 处理，支持 Nextcloud 的动态内容

### 服务管理

```bash
# 启动服务
./deploy.sh

# 停止服务
docker-compose -f config/docker-compose.yml down

# 重启服务
docker-compose -f config/docker-compose.yml restart

# 查看服务状态
docker-compose -f config/docker-compose.yml ps

# 查看服务日志
docker-compose -f config/docker-compose.yml logs -f
```

### 数据备份

定期备份是确保数据安全的关键，建议建立定期备份策略：

```bash
# 备份整个数据目录
tar -czf nextcloud-backup-$(date +%Y%m%d).tar.gz data/

# 备份数据库
docker exec -it nextcloud-db mariadb-dump -u root -p$MYSQL_ROOT_PASSWORD nextcloud > nextcloud-db-$(date +%Y%m%d).sql
```

### 服务更新

服务更新流程如下：

1. **数据备份**：参考[数据备份](#数据备份)部分的方法，在更新前备份 `data/` 目录
2. **服务停止**：执行 `docker-compose -f config/docker-compose.yml down` 停止服务
3. **配置更新**：根据需要修改配置文件，如 `.env`、`docker-compose.yml` 或 `Caddyfile`
4. **服务启动**：执行 `./deploy.sh` 重新启动服务
5. **更新验证**：访问 Nextcloud 确认服务正常运行

### 定时任务设置

部署脚本会自动设置 Nextcloud 定时任务，每 5 分钟执行一次后台任务，确保系统正常运行：

```bash
# 定时任务设置（脚本自动执行）
*/5 * * * * docker exec -u www-data nextcloud-app php /var/www/html/cron.php
```

#### 查看定时任务
```bash
crontab -l
```

#### 手动设置定时任务（如果自动设置失败）
```bash
(crontab -l 2>/dev/null | grep -v "php /var/www/html/cron.php"; \
echo "*/5 * * * * docker exec -u www-data nextcloud-app php /var/www/html/cron.php") | crontab -
```

### 应用管理

```bash
# 进入 Nextcloud 容器
docker exec -it nextcloud-app bash

# 使用 occ 命令管理应用
php occ app:list          # 列出所有应用
php occ app:enable appid  # 启用应用
php occ app:disable appid # 禁用应用

# 执行维护操作
php occ maintenance:mode --on   # 开启维护模式
php occ maintenance:mode --off  # 关闭维护模式
php occ maintenance:repair      # 执行维护修复

# 查看系统状态
php occ status

# 清理缓存
php occ files:cleanup
php occ maintenance:cache:clean
```

## 故障排除

### 常见问题

#### 1. 服务启动失败
- **检查 Docker 状态**：`docker info`
- **检查端口占用**：`netstat -tlnp | grep HTTP_PORT`（Linux）或 `netstat -ano | findstr :HTTP_PORT`（Windows）
- **查看服务日志**：参考[日志查看](#日志查看)部分的方法
- **检查配置文件**：确保 `.env` 文件中的配置项正确无误

#### 2. 数据库连接失败
- **检查密码配置**：`grep MYSQL_PASSWORD config/.env`
- **检查服务状态**：`docker ps | grep nextcloud-db`
- **查看数据库日志**：`docker logs nextcloud-db`
- **验证网络连接**：检查容器间网络是否正常

#### 3. Redis 连接失败
- **检查密码配置**：`grep REDIS_PASSWORD config/.env`
- **检查服务状态**：`docker ps | grep nextcloud-redis`
- **查看 Redis 日志**：`docker logs nextcloud-redis`

#### 4. 文件上传失败
- **检查上传限制**：`grep PHP_UPLOAD config/.env`
- **检查磁盘空间**：`df -h`
- **检查文件权限**：`ls -la data/nextcloud/`
- **检查 Caddy 配置**：确保 `Caddyfile` 中的请求体大小限制足够大

#### 5. 访问速度慢
- **检查资源使用**：`docker stats`
- **检查网络连接**：`ping SERVER_IP`
- **优化配置**：参考[性能优化](#性能优化)部分调整配置
- **清理缓存**：执行 `docker exec -u www-data nextcloud-app php occ maintenance:cache:clean`

#### 6. 登录失败
- **检查用户名密码**：确保输入正确的管理员账号和密码
- **检查 2FA 设置**：如果启用了 2FA，确保输入正确的验证码
- **检查信任域**：确保访问的域名或 IP 在 `TRUSTED_DOMAINS` 中

### 日志查看

日志是排查问题的重要工具，以下是查看各服务日志的方法：

```bash
# 查看 Nextcloud 应用日志
docker exec -it nextcloud-app cat /var/www/html/data/nextcloud.log

# 查看 Caddy 服务器日志
docker logs nextcloud-proxy

# 查看数据库服务日志
docker logs nextcloud-db

# 查看 Redis 缓存服务日志
docker logs nextcloud-redis

# 实时查看所有服务日志
docker-compose -f config/docker-compose.yml logs -f
```

## 注意事项

### 权限相关
- **Docker 权限**：执行脚本的用户需要在 docker 用户组中（可通过 `groups | grep docker` 检查）
- **文件权限**：确保 `data/` 目录有正确的读写权限

### 配置依赖
- **工作目录要求**：执行 `deploy.sh` 时必须在 `nextcloud-deploy` 目录下，否则挂载路径会错误
- **信任域配置**：`.env` 中的 `TRUSTED_DOMAINS` 必须包含正确的服务器 IP 和域名，否则可能导致访问被拒绝
- **端口冲突**：确保 `HTTP_PORT` 未被其他服务占用

### 功能缺失（非核心）
- **邮件服务**：未集成邮件发送功能，可能导致密码重置、通知等功能无法正常工作
- **自动备份**：需手动执行备份操作，无自动化备份机制
- **HTTPS 配置**：当前使用 HTTP，通过 Cloudflared 暴露到公网，不建议配置 HTTPS
- **外部存储**：默认未配置外部存储，需手动启用和配置

### 安全注意事项
- **默认密码**：`.env` 文件中的默认密码为占位符，用户必须修改，否则存在安全风险
- **恢复代码管理**：启用 2FA 后，用户需妥善保存恢复代码，否则可能无法登录
- **内网穿透安全**：使用 Cloudflared 时，确保配置了正确的访问控制
- **定期更新**：定期更新 Nextcloud 和相关组件，以修复安全漏洞

### 性能考虑
- **资源限制**：根据服务器硬件情况调整容器资源限制
- **缓存配置**：合理配置 Redis 缓存，提升系统性能
- **数据库优化**：根据使用情况调整数据库配置

### 数据安全
- **备份策略**：建立定期备份策略，确保数据安全
- **数据迁移**：如需迁移数据，确保按照正确的步骤操作
- **加密存储**：考虑使用加密文件系统或 Nextcloud 加密应用

## 性能优化

### 资源配置优化

根据服务器硬件情况，调整 `docker-compose.yml` 中的资源限制，以获得最佳性能：

```yaml
deploy:
  resources:
    limits:
      cpus: '4.0'  # 根据实际 CPU 核心数调整
      memory: 8G    # 根据实际内存大小调整
    reservations:
      cpus: '2.0'
      memory: 4G
```

### PHP 配置优化

调整 `config/.env` 中的 PHP 相关配置，提升处理能力：

```env
# PHP 内存限制
PHP_MEMORY_LIMIT="2048M"

# PHP 上传限制
PHP_UPLOAD_LIMIT="10G"
PHP_POST_MAX_SIZE="10G"
PHP_UPLOAD_MAX_FILESIZE="10G"

# PHP 执行时间
PHP_MAX_EXECUTION_TIME="3600"

# PHP-FPM 并发优化（已在 docker-compose.yml 中配置）
PHP_FPM_MAX_CHILDREN="50"        # PHP-FPM 最大子进程数
PHP_FPM_START_SERVERS="10"       # PHP-FPM 启动时的服务器数量
PHP_FPM_MIN_SPARE_SERVERS="5"    # PHP-FPM 最小空闲服务器数量
PHP_FPM_MAX_SPARE_SERVERS="20"   # PHP-FPM 最大空闲服务器数量
```

### Redis 缓存优化

调整 `docker-compose.yml` 中的 Redis 配置，提升缓存性能：

```yaml
redis:
  command: >
    redis-server 
    --requirepass ${REDIS_PASSWORD} 
    --maxmemory 1GB 
    --maxmemory-policy allkeys-lru 
    --tcp-keepalive 60
    --tcp-backlog 511
    --timeout 300
```

### 数据库优化

调整 `docker-compose.yml` 中的数据库配置，提升数据库性能：

```yaml
mariadb:
  command: >
    --transaction-isolation=READ-COMMITTED 
    --binlog-format=ROW 
    --innodb_buffer_pool_size=1G 
    --innodb_log_file_size=256M 
    --innodb_io_capacity=400 
    --innodb_io_capacity_max=800 
    --max_connections=300
    --query_cache_size=0
    --query_cache_type=0
    --skip-name-resolve
```

### 性能优化建议

- **资源配置**：根据服务器硬件情况，调整 `docker-compose.yml` 中的资源限制
- **缓存策略**：合理配置 Redis 缓存，提升系统响应速度
- **数据库调优**：根据实际使用情况，调整数据库参数
- **PHP 优化**：根据应用需求，调整 PHP 内存限制和执行时间
- **网络优化**：
  - 使用 Docker 自定义网络，提升容器间通信性能
  - 在 Caddyfile 中合理配置最大连接数
  - 适当调整连接超时设置，避免连接占用资源

## 安全建议

### 密码管理

- **使用强密码**：包含大小写字母、数字和特殊字符，长度至少 12 位
- **定期更换密码**：建议每 3-6 个月更换一次密码
- **启用双因素认证**：在 Nextcloud 管理设置中启用双因素认证，提升账号安全

#### 密码生成工具

使用以下 bash 函数生成复杂密码：

```bash
# 生成 16 位复杂密码
generate_password() {
  # 密码中的特殊字符在容器环境变量中可能会被解析为特殊含义，故此仅包含字母和数字
  tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16
}

# 使用示例
echo "生成的密码: $(generate_password)"
```

将此函数添加到您的 `.bashrc` 文件中，或直接在终端中执行以生成密码。

### 访问控制

- **配置信任域**：在 `config/.env` 中设置正确的 `TRUSTED_DOMAINS`，限制可访问的域名和 IP
- **限制访问 IP**：在 Caddyfile 中配置 IP 访问控制，仅允许特定 IP 访问管理界面
- **使用 HTTPS**：如果直接暴露公网（非通过 Cloudflared），建议配置 SSL 证书，启用 HTTPS 访问
- **配置防火墙**：在服务器上配置防火墙，仅开放必要的端口

### 数据安全

- **定期备份**：参考[数据备份](#数据备份)部分，建立定期备份策略，确保数据安全。建议至少每周备份一次，重要数据每天备份
- **加密存储**：考虑使用加密文件系统或 Nextcloud 加密应用，保护敏感数据
- **访问日志**：启用详细的访问日志，监控异常访问行为
- **数据分类**：对数据进行分类管理，不同类型的数据使用不同的安全策略

### 系统安全

- **定期更新**：及时更新 Docker 镜像、Nextcloud 应用和系统补丁，修复安全漏洞
- **最小权限**：使用最小必要权限运行容器，减少安全风险
- **网络隔离**：配置适当的网络隔离，限制容器间通信
- **安全扫描**：定期对服务器进行安全扫描，发现并修复安全问题
- **禁用不必要的服务**：禁用不需要的服务和端口，减少攻击面

### 内网穿透安全

如果使用 Cloudflared 进行内网穿透：
- **配置访问控制**：在 Cloudflare 控制台配置访问控制规则
- **启用 WARP**：考虑启用 Cloudflare WARP，提升连接安全性
- **监控访问**：定期查看访问日志，发现异常访问
- **使用子域名**：为 Nextcloud 使用专门的子域名，便于管理和隔离

## 常见问题解答

### Q: 如何修改 Nextcloud 的默认数据目录？

A: 修改 `docker-compose.yml` 中的 `nextcloud_data` 卷配置，指向新的本地目录：

```yaml
nextcloud_data:
  driver: local
  driver_opts:
    type: none
    o: bind
    device: /path/to/new/data/directory
```

修改后，需要重新启动服务：

```bash
docker-compose -f config/docker-compose.yml down
./deploy.sh
```

### Q: 如何增加上传文件大小限制？

A: 需要修改两个地方的配置：

1. 修改 `config/.env` 中的 PHP 上传限制：

```env
PHP_UPLOAD_LIMIT="20G"
PHP_POST_MAX_SIZE="20G"
PHP_UPLOAD_MAX_FILESIZE="20G"
```

2. 同时修改 `config/Caddyfile` 中的请求体大小限制：

```caddyfile
request_body {
    max_size 20GB
}
```

修改后，重新启动服务以应用配置。

### Q: 如何配置邮件服务？

A: 有两种方法配置邮件服务：

#### 方法 1：通过管理界面配置
1. 登录 Nextcloud 管理界面
2. 进入 "设置" > "基本设置" > "邮件服务器设置"
3. 填写 SMTP 服务器信息并保存

#### 方法 2：通过配置文件配置
在 `config/config.php` 中添加邮件配置：

```php
'mail_smtpmode' => 'smtp',
'mail_smtpsecure' => 'tls',
'mail_sendmailmode' => 'smtp',
'mail_from_address' => 'nextcloud',
'mail_domain' => 'your-domain.com',
'mail_smtpauthtype' => 'LOGIN',
'mail_smtpauth' => 1,
'mail_smtphost' => 'smtp.your-domain.com',
'mail_smtpport' => '587',
'mail_smtpname' => 'your-email@your-domain.com',
'mail_smtppassword' => 'your-email-password',
```

### Q: 如何启用外部存储？

A: 按照以下步骤启用和配置外部存储：

1. 登录 Nextcloud 管理界面
2. 进入 "应用" > "已禁用的应用"
3. 找到并启用 "External storage support" 应用
4. 进入 "设置" > "管理" > "外部存储"
5. 点击 "添加存储"，选择存储类型并填写相关信息
6. 配置访问权限并保存

### Q: 如何备份和恢复 Nextcloud？

A: 

#### 备份

参考[数据备份](#数据备份)部分的方法：

```bash
# 备份数据目录
tar -czf nextcloud-data-$(date +%Y%m%d).tar.gz data/

# 备份数据库
docker exec -it nextcloud-db mariadb-dump -u root -p$MYSQL_ROOT_PASSWORD nextcloud > nextcloud-db-$(date +%Y%m%d).sql
```

#### 恢复

1. 停止服务：`docker-compose -f config/docker-compose.yml down`
2. 恢复数据目录：`tar -xzf nextcloud-data-*.tar.gz`
3. 启动服务：`./deploy.sh`
4. 恢复数据库：`docker exec -i nextcloud-db mariadb -u root -p$MYSQL_ROOT_PASSWORD nextcloud < nextcloud-db-*.sql`
5. 执行维护操作：`docker exec -u www-data nextcloud-app php occ maintenance:repair`

### Q: 如何更新 Nextcloud？

A: 

1. 备份数据：在更新前备份 `data/` 目录
2. 停止服务：`docker-compose -f config/docker-compose.yml down`
3. 更新 Docker 镜像：修改 `docker-compose.yml` 中的 Nextcloud 镜像版本（如果指定了版本）
4. 启动服务：`./deploy.sh`
5. 执行升级：登录 Nextcloud 管理界面，按照提示完成升级

### Q: 如何配置 HTTPS？

A: 如果直接暴露公网（非通过 Cloudflared），建议配置 HTTPS：

1. 在 `docker-compose.yml` 中修改 Caddy 服务的端口映射，添加 443 端口
2. 修改 `Caddyfile`，添加 HTTPS 配置，使用 Let's Encrypt 自动获取证书
3. 更新 `config/.env` 中的 `TRUSTED_DOMAINS`，添加 HTTPS 域名
4. 重新启动服务：`./deploy.sh`

### Q: 如何查看 Nextcloud 日志？

A: 使用以下命令查看 Nextcloud 日志：

```bash
# 查看 Nextcloud 日志
docker exec -it nextcloud-app cat /var/www/html/data/nextcloud.log

# 查看最近的日志
docker exec -it nextcloud-app tail -n 100 /var/www/html/data/nextcloud.log

# 实时查看日志
docker exec -it nextcloud-app tail -f /var/www/html/data/nextcloud.log
```

## 技术支持

如果遇到问题，请参考以下资源：

### 官方文档
- [Nextcloud 官方文档](https://docs.nextcloud.com/server/latest/admin_manual/)
- [Docker 官方文档](https://docs.docker.com/)
- [Caddy 官方文档](https://caddyserver.com/docs/)
- [MariaDB 官方文档](https://mariadb.com/kb/en/documentation/)
- [Redis 官方文档](https://redis.io/documentation)

### 社区支持
- [Nextcloud 论坛](https://help.nextcloud.com/)
- [Docker 社区](https://forums.docker.com/)
- [Caddy 社区](https://caddy.community/)

### 故障排除步骤

参考[故障排除](#故障排除)部分的详细方法，基本步骤如下：

1. 检查服务状态：`docker-compose -f config/docker-compose.yml ps`
2. 查看服务日志：参考[日志查看](#日志查看)部分的方法
3. 执行维护修复：`docker exec -u www-data nextcloud-app php occ maintenance:repair`
4. 重启服务：`docker-compose -f config/docker-compose.yml restart`

### 联系我

如果按照上述步骤仍然无法解决问题，欢迎联系我获取进一步的技术支持。

## 许可证

本项目基于 MIT 许可证开源。

---

**注意**：本部署方案仅供个人或组织内部使用，请勿用于商业用途。使用前请确保遵守相关法律法规。