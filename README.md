# Redis 部署脚本
## 兼容性
### 操作系统
+ 兼容 CentOS 7
+ 兼容 RedHat 7
+ 兼容 Ubuntu 20.04
+ 兼容 Kylin V10
+ 兼容 Asianux(红旗 OS)

### 兼容 Redis 版本
+ Redis5
  + redis 5.0.14 经过测试
+ Redis6
  + redis 6.2.7 经过测试

## 脚本配置说明
+ REDIS_PASSWORD：Redis 访问密码，为空则不配置
+ INSTALL_PATH：Redis 部署的目录
+ ENABLE_CLUSTERF：为 1 ，则在部署 redis 时开启 redis cluster 相关配置
  + 并不会直接部署集群，集群初始化操作可按照 https://blog.xiangy.cloud/post/redis-cluster-deploying/ 操作
+ SKIP_SYS_PKG_INSTALL：运行脚本时跳过使用 yum/apt 安装系统包的过程

## 使用(install_redis.conf)
+ 下载源码包放于脚本同级目录下
+ 更改 install_redis.conf，配置 redis 安装配置
+ 运行脚本安装 redis
  + 参数：
    + -h：指定 redis 监听的 bind ip
    + -p：指定 redis 监听的 port，如果使用 cluster 模式，redis 也会使用 port + 1w 段偶
    + -v：指定要部署的 redis 版本

```bash
sudo bash install_redis.sh -h $bind_ip -p $port -v $version
# 如 sudo bash install_redis.sh -h 10.10.0.5 -p 6379 -v 6.2.7
```
+ 部署后会自动开启 redis 并配置开机自启动，可通过 systemctl status redis_$PORT.service 管理服务