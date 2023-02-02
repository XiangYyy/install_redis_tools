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
  + redis 6.2.6 经过测试
  + redis 6.2.7 经过测试
  + redis 6.2.10 经过测试

### 权限
+ 支持拥有 sudo 权限部署和无 sudo 权限部署，可通过配置文件内 RUN_WITH_SUDO 控制
  + 拥有 sudo 权限部署，服务会配置 systemclt，并配置开机自启
  + 无 sudo 权限部署，会在部署目录下生成 redis_$PORT.sh 脚本，通过命令控制

## 脚本配置说明
+ RUN_USER：redis 运行的用户
  + 如果有 sudo 权限部署，用户不存在时会自动创建用户
  + 如果无 sudo 权限部署，需配置为执行安装脚本的用户
+ REDIS_PASSWORD：Redis 访问密码，为空则不配置密码
+ INSTALL_PATH：Redis 部署的目录
  + 如果无 sudo 权限部署，需注意目录权限
+ ENABLE_CLUSTERF：为 1 ，则在部署 redis 时开启 redis cluster 相关配置
  + 并不会直接部署集群，集群初始化操作可按照 https://blog.xiangy.cloud/post/redis-cluster-deploying/ 操作
+ RENAME_STRING：重命名部分高风险的 redis 命令，提高安全性
+ MAXMEMORY：设置 redis 可用的最大内存大小，为空则不设限
  + 注意：**redis 内存限制为淘汰机制，会通过策略删除 key 以控制内存使用**
+ RUN_WITH_SUDO：部署时是否拥有 sudo 权限
  + 如无 sudo 权限，部署时会跳过用户创建和安装系同统依赖包等步骤
  + sudo 模式时，会配置 systemctl 并配置开机自启；无 sudo 模式是会在 redis 目录下生成启动控制脚本，无法配置开机自启
+ SERVICE_PATH：sudo 模式配置 systemctl 时，配置文件存储的路径(推荐使用 /etc/systemd/system)
+ SKIP_SYS_PKG_INSTALL：运行脚本时跳过使用 yum/apt 安装系统包的过程

## 使用(install_redis.conf)
+ 下载源码包放于脚本同级目录下
+ 更改 install_redis.conf，配置 redis 安装配置
+ 运行脚本安装 redis
  + 参数：
    + -h：指定 redis 监听的 bind ip
    + -p：指定 redis 监听的 port，如果使用 cluster 模式，redis 也会使用 port + 1w 端口
    + -v：指定要部署的 redis 版本

+ sudo 模式

```bash
sudo bash install_redis.sh -h $bind_ip -p $port -v $version
# 如 sudo bash install_redis.sh -h 10.10.0.5 -p 6379 -v 6.2.7
```
+ 非 sudo 模式

```bash
bash install_redis.sh -h $bind_ip -p $port -v $version
# 如 bash install_redis.sh -h 10.10.0.5 -p 6379 -v 6.2.7
```
## 服务管理
+ 以部署 redis 服务的端口为 6379 为例

+ sudo 模式

```bash
# 启动 redis
systemctl start redis_6379
# 停止 redis
systemctl stop redis_6379
# 查看 redis 状态
systemctl status redis_6379
```

+ 非 sudo 模式

```bash
cd /data/xxx/redis/redis_6379/
# 启动 redis
bash redis_6379.sh start
# 停止 redis
bash redis_6379.sh stop
# 查看 redis 状态
bash redis_6379.sh status
```