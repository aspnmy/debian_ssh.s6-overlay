# Telegrarcm 交流
[Telegrarcm Club](https://t.me/+2SRIxuCE7v9lZjJl)

# 科学上网
[一点点鸡肠](https://sbairport.com/#/register?code=sTHcpv7y)

# 构建样本

- [批量构建模板](./dockerfile/sample/dockerfile-ssh-s6-overlay.sample)
- 使用模板的时候要主要默认的构建文件资源放在app/下,请改成自己的路径

# About debian_ssh.s6-overlay

- 集成了s6-overlay进程管理器的debian_ssh版本(容器内直接打开ssh端口22,可直接访问容器内业务)

- 默认root密码root@#1314, 使用时请自行修改
- 默认的ssh端口是622,使用时请自行放通防火墙,用云服务器的还需要放通安全组
- 默认网络模式为桥接,宿主机需要映射端口,如果使用host模式,可以直接访问622即可

# Docker-compose运行
```docker
name: debian-ssh:s6-overlay-v12.7
services:
    debian-s6-overlay-622:
        stdin_open: true
        tty: true
        container_name: debian-s6-overlay-622
        ports:
            - 622:622
        image: aspnmy/debian-ssh:s6-overlay-v12.7

```

# 什么是s6-overlay
s6-overlay是一个基于s6工具集的进程管理器,它被设计用于容器化环境,并提供了进程监督、管理和日志记录功能。它是一个轻量级的init系统替代品,适用于Docker容器中运行多个进程的场景。

**安装s6-overlay**:
- 通常通过官方提供的安装脚本来完成。
- 安装后,s6-overlay的进程pid为1,意味着它将作为容器的init进程。

**配置服务**:
- 主服务(例如nginx)通常写在CMD里面。
- 辅助服务则放在`/etc/services.d/`目录下,并以项目名区分。

**使用示例**:
- 可以在容器中运行crontab服务。
- 编写服务启动脚本`run`和结束脚本`finish`。

**脚本示例**:
- 权限脚本可以设置文件或目录的权限。
- 初始化脚本可以在服务启动前做一些准备工作。
- 服务启动脚本定义了服务如何启动。
- 日志输出可以使用s6-log,s6-overlay提供了封装好的`logutil-service`。

**Docker基础镜像**:
- Home Assistant等项目使用s6-overlay作为其Docker基础镜像的进程管理器。

**PHP应用**:
- s6-overlay适合运行PHP应用,因为它通常需要同时运行多个进程。
- PHP-FPM用于提高效率,而静态文件(如JavaScript、图片等)通常由反向代理服务器(如Apache或NGINX)处理。

**使用s6-overlay的理由**:
- 提供轻量级的进程管理。
- 适用于容器化环境,有助于管理容器内的多个进程。
- 可以自定义服务的启动、结束脚本,以及如何处理服务崩溃。

**注意**:
- 如果你覆盖了Docker容器的入口点或命令,可能需要调整以适应s6-overlay。
- s6-overlay的生命周期包括初始化、服务扫描和执行、停止服务和执行结束脚本。

s6-overlay的官方GitHub地址是:[https://github.com/just-containers/s6-overlay](https://github.com/just-containers/s6-overlay)