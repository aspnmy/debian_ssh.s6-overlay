# bestHosts 

- 主要解决内外环境的业务监控问题

## bestHostsMonitor 脚本工作原理

- 主要部署在节点、容器、服务器内，常驻运行，定时拉取线上的最优hosts加速文件，用于本地状态更新

## bestHostsClient 脚本工作原理

- bestHostsClient 通过定时监控 节点、容器、服务器当前外网ip，判断是国际环境还是国内环境，从公共URL中下载统一的加速资源
    包括对hosts、镜像源等统一变更，一次部署多资产维护的时候变得so easy

## 常用URL

### CN 区

- hosts：主要针对cloudflare和github的加速 访问入口  /cn/besthosts.list

- sources.list 主要针对镜像源的加速 /cn/sources.list

- docker 主要针对 docker hub加速源的维护 /cn/docker.list

### EN 区

- hosts：主要针对cloudflare和github的加速 访问入口  /en/besthosts.list

- sources.list 主要针对镜像源的加速 /en/sources.list

- docker 主要针对 docker hub加速源的维护 /en/docker.list

## 测速频率

- 一般3-5天更新测速一次