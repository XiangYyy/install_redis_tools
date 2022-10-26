# Redis 部署脚本
## 兼容性
### 操作系统
+ 兼容 CentOS 7
+ 兼容 RedHat 7
+ 兼容 Ubuntu 20.04

### 兼容 Redis 版本
+ Redis5
  + redis 5.0.14 经过测试
+ Redis6
  + redis 6.2.7 经过测试

## 脚本配置说明
+ PORT：部署的 Redis 要使用的端口
+ BIND_IP：部署的 Reids 要监听的 ip
+ REDIS_PASSWORD：Redis 访问密码，为空则不配置
+ INSTALL_PATH：Redis 部署的目录
+ PKG_VERSION：要部署的 Redis 的版本
+ ENABLE_CLUSTERF：为 1 ，则在部署 redis 时开启 redis cluster 相关配置
  + 并不会直接部署集群，集群初始化操作可按照 https://blog.xiangy.cloud/post/redis-cluster-deploying/ 操作
+ SKIP_SYS_PKG_INSTALL：运行脚本时跳过使用 yum/apt 安装系统包的过程

## 使用(install_redis.conf)
+ 下载源码包放于脚本同级目录下
+ 更改 install_redis.conf，配置 redis 安装配置
+ 运行脚本安装 redis

```bash
sudo bash install_redis.sh
```
+ 部署后会自动开启 redis 并配置开机自启动，可通过 systemctl status redis_$PORT.service 管理服务