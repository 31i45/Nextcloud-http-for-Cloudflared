#!/bin/bash
set -euo pipefail

# Nextcloud 配置脚本 - 包含性能优化和功能配置

# 目录定义
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$PROJECT_DIR/config"

# 加载环境变量
if [ ! -f "$CONFIG_DIR/.env" ]; then
  echo "错误: 环境配置文件 $CONFIG_DIR/.env 不存在！"
  exit 1
fi

source "$CONFIG_DIR/.env"

# Docker Compose 命令封装
dc() {
  if command -v docker-compose >/dev/null 2>&1; then
    docker-compose "$@"
  else
    docker compose "$@"
  fi
}

# Nextcloud occ 命令封装
occ() {
  dc -p nextcloud -f "$CONFIG_DIR/docker-compose.yml" exec -T nextcloud php occ "$@"
}

# 配置缓存优化
configure_cache() {
  echo "正在配置缓存优化..."
  
  # 多级缓存配置
  occ config:system:set memcache.local --value="\\OC\\Memcache\\Redis" >/dev/null 2>&1 || echo "警告: 配置本地缓存失败"
  occ config:system:set memcache.distributed --value="\\OC\\Memcache\\Redis" >/dev/null 2>&1 || echo "警告: 配置分布式缓存失败"
  occ config:system:set memcache.locking --value="\\OC\\Memcache\\Redis" >/dev/null 2>&1 || echo "警告: 配置锁缓存失败"
  
  # Redis 高级配置
  occ config:system:set redis host --value="redis" >/dev/null 2>&1 || echo "警告: 配置 Redis 主机失败"
  occ config:system:set redis port --value="6379" >/dev/null 2>&1 || echo "警告: 配置 Redis 端口失败"
  occ config:system:set redis password --value="$REDIS_PASSWORD" >/dev/null 2>&1 || echo "警告: 配置 Redis 密码失败"
  occ config:system:set redis timeout --type float --value 1.5 >/dev/null 2>&1 || echo "警告: 配置 Redis 超时失败"
  occ config:system:set redis dbindex --type integer --value 0 >/dev/null 2>&1 || echo "警告: 配置 Redis 数据库索引失败"
  
  echo "缓存优化配置完成！"
}

# 配置文件同步优化
configure_sync() {
  echo "正在配置文件同步优化..."
  
  # Delta Sync 配置
  occ config:system:set filesync.enablesharing --type boolean --value true >/dev/null 2>&1 || echo "警告: 配置文件共享失败"
  
  # 选择性同步优化
  occ config:system:set filesystem_check_changes --type boolean --value false >/dev/null 2>&1 || echo "警告: 配置文件系统检查失败"
  occ config:system:set check_for_updated_files --type boolean --value false >/dev/null 2>&1 || echo "警告: 配置文件更新检查失败"
  
  # 分块文件存储
  occ config:system:set part_file_in_storage --type boolean --value true >/dev/null 2>&1 || echo "警告: 配置分块文件存储失败"
  
  # 同步超时优化
  occ config:system:set davstorage.request_timeout --type integer --value 300 >/dev/null 2>&1 || echo "警告: 配置 DAV 存储超时失败"
  occ config:system:set carddav_sync_request_timeout --type integer --value 300 >/dev/null 2>&1 || echo "警告: 配置 CardDAV 同步超时失败"
  
  echo "文件同步优化配置完成！"
}

# 配置信任域和代理
configure_trusted() {
  echo "正在配置信任域和代理..."
  
  # 解析信任域列表
  IFS=' ' read -r -a domains <<< "$TRUSTED_DOMAINS"
  
  # 添加信任域
  for i in "${!domains[@]}"; do
    domain="${domains[$i]}"
    occ config:system:set trusted_domains "$i" --value="$domain" >/dev/null 2>&1 || echo "警告: 配置信任域 $domain 失败"
  done
  
  # 确保添加 localhost 和 127.0.0.1
  local localhost_index=${#domains[@]}
  occ config:system:set trusted_domains "$localhost_index" --value="localhost:$HTTP_PORT" >/dev/null 2>&1 || echo "警告: 配置信任域 localhost 失败"
  local loopback_index=$((localhost_index + 1))
  occ config:system:set trusted_domains "$loopback_index" --value="127.0.0.1:$HTTP_PORT" >/dev/null 2>&1 || echo "警告: 配置信任域 127.0.0.1 失败"
  
  # 配置信任代理
  occ config:system:set trusted_proxies 0 --value="$TRUSTED_PROXIES" >/dev/null 2>&1 || echo "警告: 配置信任代理失败"
  
  echo "信任域和代理配置完成！"
}

# 配置性能优化
configure_performance() {
  echo "正在配置性能优化..."
  
  # UTF-8 支持
  occ config:system:set mysql.utf8mb4 --type boolean --value true >/dev/null 2>&1 || echo "警告: 配置 MySQL UTF8MB4 失败"
  
  # 文件缓存 TTL
  occ config:system:set filecache.ttl --type integer --value 3600 >/dev/null 2>&1 || echo "警告: 配置文件缓存 TTL 失败"
  
  # 预览设置优化
  occ config:system:set preview_max_x --type integer --value 2048 >/dev/null 2>&1 || echo "警告: 配置预览最大宽度失败"
  occ config:system:set preview_max_y --type integer --value 2048 >/dev/null 2>&1 || echo "警告: 配置预览最大高度失败"
  occ config:system:set preview_max_filesize_image --type integer --value 50 >/dev/null 2>&1 || echo "警告: 配置预览最大文件大小失败"
  
  # 维护窗口设置
  occ config:system:set maintenance_window_start --type integer --value 2 >/dev/null 2>&1 || echo "警告: 配置维护窗口开始时间失败"
  occ config:system:set maintenance_window_end --type integer --value 4 >/dev/null 2>&1 || echo "警告: 配置维护窗口结束时间失败"
  
  # 日志级别设置
  occ config:system:set loglevel --value="2" >/dev/null 2>&1 || echo "警告: 配置日志级别失败"
  
  # 禁用 HSTS（如果使用 HTTP）
  occ config:system:set hsts.enabled --type boolean --value false >/dev/null 2>&1 || echo "警告: 禁用 HSTS 失败"
  
  # 禁用不支持的应用
  occ config:system:set disable_unsupported_apps --type boolean --value true >/dev/null 2>&1 || echo "警告: 禁用不支持的应用失败"
  
  # 禁用互联网连接检测
  occ config:system:set has_internet_connection --type boolean --value false >/dev/null 2>&1 || echo "警告: 禁用互联网连接检测失败"
  
  # 设置默认电话区域
  occ config:system:set default_phone_region --value='CN' >/dev/null 2>&1 || echo "警告: 设置默认电话区域失败"
  
  echo "性能优化配置完成！"
}

# 配置应用管理
configure_apps() {
  echo "正在配置应用管理..."
  
  # 启用必要的应用
  occ app:enable files_external >/dev/null 2>&1 || echo "警告: 启用外部存储应用失败"
  # 启用两步验证（2FA）应用
  occ app:enable twofactor_totp >/dev/null 2>&1 || echo "警告: 启用两步验证应用失败"
  
  # 禁用不必要的应用以提升性能
  local apps_to_disable=(
    "firstrunwizard" 
    "calendar" 
    "contacts" 
    "activity" 
    "gallery" 
    "circles" 
    "comments" 
    "contactsinteraction" 
    "dashboard" 
    "federation" 
    "files_downloadlimit" 
    "files_reminders" 
    "nextcloud_announcements" 
    "recommendations" 
    "related_resources" 
    "sharebymail" 
    "support" 
    "survey_client" 
    "user_status" 
    "weather_status" 
    "webhook_listeners"
  )
  
  for app in "${apps_to_disable[@]}"; do
    # 检查应用是否存在
    if occ app:list | grep -q "$app"; then
      occ app:disable "$app" >/dev/null 2>&1 || echo "警告: 禁用应用 $app 失败"
    fi
  done
  
  echo "应用管理配置完成！"
}

# 清理后台任务
cleanup_background() {
  echo "正在清理后台任务..."
  
  # 清理后台队列
  occ background:queue:clean >/dev/null 2>&1 || echo "警告: 清理后台队列失败"
  occ background:queue:flush >/dev/null 2>&1 || echo "警告: 刷新后台队列失败"
  
  # 设置后台任务为 cron 模式
  occ background:cron >/dev/null 2>&1 || echo "警告: 设置后台任务模式失败"
  
  echo "后台任务清理完成！"
}

# 修复 mimetype
repair_mimetype() {
  echo "正在修复 mimetype..."
  
  # 执行维护修复
  occ maintenance:repair --include-expensive >/dev/null 2>&1 || echo "警告: 执行维护修复失败"
  
  echo "mimetype 修复完成！"
}

# 主配置流程
main() {
  echo "开始配置 Nextcloud..."
  
  # 按顺序执行配置
  configure_cache
  configure_sync
  configure_trusted
  configure_performance
  configure_apps
  cleanup_background
  repair_mimetype
  
  echo "Nextcloud 配置完成！"
}

# 执行主配置流程
main