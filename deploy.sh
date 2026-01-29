#!/bin/bash
set -euo pipefail

# 主部署脚本 - Nextcloud 部署与配置

# 目录定义
# 使用脚本所在目录作为项目根目录，确保路径可靠
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$PROJECT_DIR/config"
SCRIPTS_DIR="$PROJECT_DIR/scripts"
DATA_DIR="$PROJECT_DIR/data"

# 检查环境配置
check_env_config() {
  echo "========================================"
  echo " 环境配置检查"
  echo "========================================"
  
  if [ ! -f "$CONFIG_DIR/.env" ]; then
    echo "❌ 错误: 环境配置文件 $CONFIG_DIR/.env 不存在！"
    echo "请先创建并配置环境变量文件。"
    exit 1
  fi
  
  # 加载环境变量
  source "$CONFIG_DIR/.env"
  
  # 提示用户确认服务器 IP
  echo "当前配置的服务器 IP: $SERVER_IP"
  echo ""
  echo "请确保此 IP 地址正确，否则可能导致服务无法访问。"
  echo "如需修改，请编辑 config/.env 文件修改 SERVER_IP 配置。"
  echo "========================================"
  echo ""
}

# 检查并更新环境配置
check_env_config

# 环境检查
check_environment() {
  echo "========================================"
  echo " 环境检查"
  echo "========================================"
  
  # 检查 Docker 是否安装
  if ! command -v docker >/dev/null 2>&1; then
    echo "❌ 错误: Docker 未安装！"
    exit 1
  fi
  
  # 检查 Docker Compose 是否安装
  if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
    echo "❌ 错误: Docker Compose 未安装！"
    exit 1
  fi
  
  echo "✅ 环境检查通过！"
  echo ""
}

# Docker Compose 命令封装
dc() {
  if command -v docker-compose >/dev/null 2>&1; then
    docker-compose "$@"
  else
    docker compose "$@"
  fi
}

# 启动服务
start_services() {
  echo "========================================"
  echo " 正在启动 Nextcloud 服务..."
  echo "========================================"
  
  # 启动容器服务，使用 --wait 参数等待服务就绪
  echo "启动容器并等待服务就绪..."
  dc -p nextcloud -f "$CONFIG_DIR/docker-compose.yml" up -d --wait --quiet-pull
  
  if [ $? -eq 0 ]; then
    echo "✅ 服务启动成功！"
    return 0
  else
    echo "❌ 错误: 服务启动失败！"
    echo "建议检查以下内容："
    echo "1. Docker 服务是否正常运行"
    echo "2. 端口 $HTTP_PORT 是否被占用"
    echo "3. 系统资源是否充足"
    echo "4. 查看容器日志，如：docker logs nextcloud-app"
    return 1
  fi
}

# 配置 Nextcloud
configure_nextcloud() {
  echo -e "\n========================================"
  echo " 正在配置 Nextcloud..."
  echo "========================================"
  
  if [ -f "$SCRIPTS_DIR/config_nextcloud.sh" ]; then
    chmod +x "$SCRIPTS_DIR/config_nextcloud.sh"
    echo "执行配置脚本..."
    "$SCRIPTS_DIR/config_nextcloud.sh"
    
    if [ $? -eq 0 ]; then
      echo "✅ Nextcloud 配置成功！"
    else
      echo "⚠️  警告: Nextcloud 配置过程中出现错误，但服务已启动。"
      echo "请手动检查配置状态。"
    fi
  else
    echo "⚠️  警告: 配置脚本 $SCRIPTS_DIR/config_nextcloud.sh 不存在，跳过配置步骤。"
  fi
}

# 设置定时任务
setup_cron() {
  echo -e "\n========================================"
  echo " 正在设置 Nextcloud 定时任务..."
  echo "========================================"
  
  # 临时禁用错误退出，防止定时任务设置失败导致脚本退出
  set +e
  
  # 添加定时任务，每 5 分钟执行一次 cron.php
  (crontab -l 2>/dev/null | grep -v "php /var/www/html/cron.php"; \
   echo "*/5 * * * * docker exec -u www-data nextcloud-app php /var/www/html/cron.php") | crontab -
  
  local cron_result=$?
  
  # 重新启用错误退出
  set -e
  
  if [ $cron_result -eq 0 ]; then
    echo "✅ 定时任务设置成功！"
    echo "当前定时任务："
    crontab -l
  else
    echo "❌ 警告: 定时任务设置失败，请手动设置。"
    echo "请尝试手动执行以下命令："
    echo "(crontab -l 2>/dev/null | grep -v 'php /var/www/html/cron.php'; echo '*/5 * * * * docker exec -u www-data nextcloud-app php /var/www/html/cron.php') | crontab -"
  fi
}

# 缓存清理和维护
maintain_nextcloud() {
  echo "========================================"
  echo " 执行 Nextcloud 维护任务..."
  echo "========================================"
  
  # 清理 Nextcloud 缓存
  echo "1. 清理 Nextcloud 缓存..."
  dc -p nextcloud -f "$CONFIG_DIR/docker-compose.yml" exec -T nextcloud php occ files:cleanup >/dev/null 2>&1 || echo "⚠️  警告: 清理文件缓存失败"
  dc -p nextcloud -f "$CONFIG_DIR/docker-compose.yml" exec -T nextcloud php occ files:scan --all >/dev/null 2>&1 || echo "⚠️  警告: 扫描文件系统失败"
  
  # 清理 Redis 缓存
  echo "2. 清理 Redis 缓存..."
  dc -p nextcloud -f "$CONFIG_DIR/docker-compose.yml" exec -T redis redis-cli -a "$REDIS_PASSWORD" FLUSHALL >/dev/null 2>&1 || echo "⚠️  警告: 清理 Redis 缓存失败"
  
  # 优化数据库
  echo "3. 优化数据库..."
  dc -p nextcloud -f "$CONFIG_DIR/docker-compose.yml" exec -T mariadb mariadb -u root -p"$MYSQL_ROOT_PASSWORD" -e "OPTIMIZE TABLE nextcloud.oc_filecache;" >/dev/null 2>&1 || echo "⚠️  警告: 优化数据库失败"
  
  # 清理日志文件
  echo "4. 清理日志文件..."
  dc -p nextcloud -f "$CONFIG_DIR/docker-compose.yml" exec -T nextcloud sh -c "find /var/www/html/data -name '*.log' -type f -exec truncate -s 0 {} \;" >/dev/null 2>&1 || echo "⚠️  警告: 清理日志文件失败"
  
  # 检查系统状态
  echo "5. 检查系统状态..."
  dc -p nextcloud -f "$CONFIG_DIR/docker-compose.yml" exec -T nextcloud php occ status >/dev/null 2>&1 || echo "⚠️  警告: 检查系统状态失败"
  
  echo "✅ Nextcloud 维护任务执行完成！"
}

# 显示部署信息
display_info() {
  echo -e "\n========================================"
  echo " Nextcloud 部署完成！"
  echo "========================================"
  echo "访问地址: http://$SERVER_IP:$HTTP_PORT"
  echo "管理员用户名: $ADMIN_USER"
  echo "管理员密码: $ADMIN_PASSWORD"
  echo ""
  echo "数据存储路径:"
  echo "- Nextcloud 数据: $DATA_DIR/nextcloud"
  echo "- 数据库数据: $DATA_DIR/mariadb"
  echo "- Redis 数据: $DATA_DIR/redis"
  echo "- Caddy 数据: $DATA_DIR/caddy"
  echo ""
  echo "========================================"
  echo " 部署完成，祝您使用愉快！"
  echo "========================================"
  
  # 后续操作建议
  echo -e "\n📋 后续操作建议："
  echo "1. 访问 Nextcloud 管理界面完成初始化设置"
  echo "2. 配置邮件服务以启用通知功能"
  echo "3. 安装必要的应用插件"
  echo "4. 配置数据备份策略"
  echo "5. 考虑使用 Cloudflared 配置 HTTPS"
  
  # 定时任务说明
  echo -e "\n⏰ 定时任务设置："
  echo "已设置每 5 分钟执行一次 Nextcloud 后台任务"
  echo "查看定时任务：crontab -l"
  echo "手动执行任务：docker exec -u www-data nextcloud-app php /var/www/html/cron.php"
  
  # 维护功能说明
  echo -e "\n🔧 维护功能："
  echo "运行维护任务：bash deploy.sh maintain"
  echo "维护任务包括："
  echo "1. 清理 Nextcloud 缓存"
  echo "2. 清理 Redis 缓存"
  echo "3. 优化数据库"
  echo "4. 清理日志文件"
  echo "5. 检查系统状态"
}

# 主执行流程
main() {
  # 环境配置已在脚本开头检查，这里直接执行后续步骤
  check_environment
  
  # 启动服务
  if ! start_services; then
    echo -e "\n❌ 错误: 服务启动失败，无法继续配置。"
    echo "请解决上述问题后重新运行脚本。"
    exit 1
  fi
  
  # 配置 Nextcloud
  configure_nextcloud
  
  # 设置定时任务
  setup_cron
  
  # 显示部署信息
  display_info
}

# 处理命令行参数
if [ $# -eq 1 ] && [ "$1" = "maintain" ]; then
  # 加载环境变量
  source "$CONFIG_DIR/.env"
  # 执行维护任务
  maintain_nextcloud
  echo "✅ 维护任务执行完成！"
else
  # 执行主流程
  main
fi